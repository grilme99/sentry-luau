-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/tracing/dynamicSamplingContext.ts

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Client = Types.Client
type DynamicSamplingContext = Types.DynamicSamplingContext
type Scope = Types.Scope
type DsnComponents = Types.DsnComponents
type User = Types.User

local Constants = require(PackageRoot.constants)
local DEFAULT_ENVIRONMENT = Constants.DEFAULT_ENVIRONMENT

local DynamicSamplingContext = {}

--- Creates a dynamic sampling context from a client.
---
--- Dispatches the `createDsc` lifecycle hook as a side effect.
function DynamicSamplingContext.getDynamicSamplingContextFromClient(
    trace_id: string,
    client: Client,
    scope: Scope?
): DynamicSamplingContext
    local options = client:getOptions()

    local dsn = client:getDsn() or {} :: DsnComponents
    local publicKey = dsn.publicKey

    local user = (scope and scope:getUser()) or {} :: User
    local segment = user.segment

    local dsc = {
        environment = options.environment or DEFAULT_ENVIRONMENT,
        release = options.release,
        user_segment = segment,
        public_key = publicKey,
        trace_id = trace_id,
    } :: DynamicSamplingContext

    if client.emit then
        (client.emit :: any)("createDsc", dsc)
    end

    return dsc
end

return DynamicSamplingContext
