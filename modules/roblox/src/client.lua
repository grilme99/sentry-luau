-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/client.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type ClientOptions<T> = Types.ClientOptions<T>
type Event = Types.Event
type EventHint = Types.EventHint
type Options<T> = Types.Options<T>
type SeverityLevel = Types.SeverityLevel
type UserFeedback = Types.UserFeedback
type SdkMetadata = Types.SdkMetadata
type Scope = Types.Scope
type PromiseLike<T> = Types.PromiseLike<T>

local Core = require(Packages.SentryCore)
local BaseClient = Core.BaseClient
type BaseClient<T> = Core.BaseClient<T>
local SDK_VERSION = Core.SDK_VERSION

local Utils = require(Packages.SentryUtils)
local logger = Utils.logger

local EventBuilder = require(PackageRoot.eventbuilder)
local eventFromException = EventBuilder.eventFromException
local eventFromMessage = EventBuilder.eventFromMessage

local TransportTypes = require(PackageRoot.transports.types)
type RobloxTransportOptions = TransportTypes.RobloxTransportOptions

local UserFeedback = require(PackageRoot.userfeedback)
local createUserFeedbackEnvelope = UserFeedback.createUserFeedbackEnvelope

local ClientTypes = require(PackageRoot.types)
type RobloxStackParserOptions = ClientTypes.RobloxStackParserOptions

--- Configuration options for the Sentry Roblox SDK Client class
export type RobloxClientOptions = ClientOptions<RobloxTransportOptions> & RobloxStackParserOptions

--- Configuration options for the Sentry Roblox SDK.
export type RobloxOptions = Options<RobloxTransportOptions> & RobloxClientOptions

export type RobloxClient = typeof(setmetatable(
    {} :: BaseClient<RobloxClientOptions> & {
        captureUserFeedback: (self: RobloxClient, feedback: UserFeedback) -> (),
    },
    {} :: {
        __index: RobloxClient,
    }
))

local RobloxClient = {}
RobloxClient.__index = RobloxClient
setmetatable(RobloxClient, BaseClient)

function RobloxClient.new(options: RobloxClientOptions)
    -- TODO: Inject SDK source at release/build time
    local sdkSource = "wally"

    options._metadata = options._metadata or {}
    local metadata = options._metadata :: SdkMetadata
    metadata.sdk = metadata.sdk
        or {
            name = "sentry.lua.roblox",
            packages = {
                {
                    name = `{sdkSource}:Neura-Studios/sentry-roblox`,
                    version = SDK_VERSION,
                },
            },
            version = SDK_VERSION,
        }

    local self: RobloxClient = BaseClient.new(options :: any) :: any
    setmetatable(self, RobloxClient)

    return self :: any
end

function RobloxClient.eventFromException(self: RobloxClient, exception: unknown, hint: EventHint?): PromiseLike<Event>
    return eventFromException(self._options.stackParser :: any, exception, hint, self._options.attachStacktrace)
end

function RobloxClient.eventFromMessage(
    self: RobloxClient,
    message: string,
    level_: SeverityLevel?,
    hint: EventHint?
): PromiseLike<Event>
    local level: SeverityLevel = level_ or "info"
    return eventFromMessage(self._options.stackParser :: any, message, level, hint, self._options.attachStacktrace)
end

function RobloxClient.captureUserFeedback(self: RobloxClient, feedback: UserFeedback)
    if not self:_isEnabled() then
        if _G.__SENTRY_DEV__ then
            logger.warn("SDK not enabled, will not capture user feedback.")
        end
        return
    end

    local envelope = createUserFeedbackEnvelope(feedback, {
        metadata = self:getSdkMetadata(),
        dsn = self:getDsn(),
        tunnel = self:getOptions().tunnel,
    })
    self:_sendEnvelope(envelope)
end

return RobloxClient
