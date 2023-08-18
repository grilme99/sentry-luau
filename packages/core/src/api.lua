-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/api.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

local Types = require(Packages.SentryTypes)
type ClientOptions = Types.ClientOptions
type DsnComponents = Types.DsnComponents
type DsnLike = Types.DsnLike
type SdkInfo = Types.SdkInfo

local Utils = require(Packages.SentryUtils)
local dsnToString = Utils.dsnToString
local makeDsn = Utils.makeDsn
local urlEncode = Utils.urlEncode

type Map<K, V> = { [K]: V }

local SENTRY_API_VERSION = "7"

--- Returns the prefix to construct Sentry ingestion API endpoints.
function getBaseApiEndpoint(dsn: DsnComponents): string
    local protocol = if dsn.protocol then `{dsn.protocol}:` else ""
    local port = if dsn.port ~= "" then `:{dsn.port}` else ""
    return `{protocol}//{dsn.host}{port}{if dsn.path ~= "" then `/{dsn.path}` else ""}/api/`
end

--- Returns the ingest API endpoint for target.
function _getIngestEndpoint(dsn: DsnComponents): string
    return `{getBaseApiEndpoint(dsn)}{dsn.projectId}/envelope/`
end

--- Returns a URL-encoded string with auth config suitable for a query string.
function _encodedAuth(dsn: DsnComponents, sdkInfo: SdkInfo | nil): string
    return urlEncode(Object.assign({
        -- We send only the minimum set of required information. See
        -- https://github.com/getsentry/sentry-javascript/issues/2572.
        sentry_key = dsn.publicKey,
        sentry_version = SENTRY_API_VERSION,
    }, if sdkInfo then { sentry_client = `{sdkInfo.name}/{sdkInfo.version}` } else {}))
end

local Api = {}

--- Returns the envelope endpoint URL with auth in the query string.
---
--- Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
function Api.getEnvelopeEndpointWithUrlEncodedAuth(
    dsn: DsnComponents,
    -- TODO (v8): Remove `tunnelOrOptions` in favor of `options`, and use the substitute code below
    -- options: ClientOptions = {} as ClientOptions,
    tunnelOrOptions_: (string | ClientOptions)?
): string
    -- TODO (v8): Use this code instead
    -- const { tunnel, _metadata = {} } = options;
    -- return tunnel ? tunnel : `${_getIngestEndpoint(dsn)}?${_encodedAuth(dsn, _metadata.sdk)}`;

    local tunnelOrOptions = tunnelOrOptions_ or {} :: ClientOptions

    local tunnel = if type(tunnelOrOptions) == "string" then tunnelOrOptions else tunnelOrOptions.tunnel
    local sdkInfo = if type(tunnelOrOptions) == "string" or not tunnelOrOptions._metadata
        then nil
        else tunnelOrOptions._metadata.sdk

    return if tunnel then tunnel else `{_getIngestEndpoint(dsn)}?{_encodedAuth(dsn, sdkInfo)}`
end

--- Returns the url to the report dialog endpoint. */
function Api.getReportDialogEndpoint(
    dsnLike: DsnLike,
    dialogOptions: Map<string, any> & {
        user: { name: string?, email: string? }?,
    }
): string
    if not game then
        error("getReportDialogEndpoint is unaviable in this environment because encodeURIComponent is unsupported")
    end

    local HttpService = game:GetService("HttpService")

    local dsn = makeDsn(dsnLike)
    if not dsn then
        return ""
    end

    local endpoint = `{getBaseApiEndpoint(dsn)}embed/error-page/`

    local encodedOptions = `dsn={dsnToString(dsn)}`
    for key, value in dialogOptions :: Map<string, any> do
        if key == "dsn" then
            continue
        end

        if key == "user" then
            local user: { name: string?, email: string? } = dialogOptions.user
            if user == nil then
                continue
            end

            if user.name then
                encodedOptions ..= `&name={HttpService:UrlEncode(user.name)}`
            end
            if user.email then
                encodedOptions ..= `&email={HttpService:UrlEncode(user.email)}`
            end
        else
            encodedOptions ..= `&{HttpService:UrlEncode(key)}={HttpService:UrlEncode(value)}`
        end
    end

    return `{endpoint}?{encodedOptions}`
end

return Api
