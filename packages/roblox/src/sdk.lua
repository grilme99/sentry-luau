-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/sdk.ts

local Types = require("@packages/types")
type UserFeedback = Types.UserFeedback
type Hub = Types.Hub
type PromiseLike<T> = Types.PromiseLike<T>

local Core = require("@packages/core")
local getCurrentHub = Core.getCurrentHub
local getIntegrationsToSetup = Core.getIntegrationsToSetup
local initAndBind = Core.initAndBind
-- local CoreIntegrations

local Utils = require("@packages/utils")
-- local addInstrumentationHandler = Utils.addInstrumentationHandler
local logger = Utils.logger
local Promise = Utils.Promise
local stackParserFromStackParserOptions = Utils.stackParserFromStackParserOptions
local Object = Utils.Polyfill.Object

local RobloxClient = require("./client")
type RobloxClient = RobloxClient.RobloxClient
type RobloxClientOptions = RobloxClient.RobloxClient
type RobloxOptions = RobloxClient.RobloxOptions

local Helpers = require("./helpers")
local internalWrap = Helpers.wrap

local StackParsers = require("./stack-parser")
local defaultStackParser = StackParsers.defaultStackParser

local Transports = require("./transports/init")
local makeHttpServiceTransport = Transports.makeHttpServiceTransport

local RobloxSdk = {}

local defaultIntegrations = {}
RobloxSdk.defaultIntegrations = defaultIntegrations

local function startSessionOnHub(hub: Hub)
    hub:startSession({ ignoreDuration = true } :: any)
    hub:captureSession()
end

local function startSessionTracking()
    local hub = getCurrentHub()
    startSessionOnHub(hub)
end

--- The Sentry Roblox SDK Client.
---
--- To use this SDK, call the {@link init} function as early as possible when
--- loading the game. To set context information or send manual events, use
--- the provided methods.
function RobloxSdk.init(options_: RobloxOptions?)
    local options: RobloxOptions = options_ or {} :: any
    if options.defaultIntegrations == nil then
        options.defaultIntegrations = defaultIntegrations
    end
    if options.release == nil then
        -- This allows build tooling to find-and-replace __SENTRY_RELEASE__ to inject a release value
        local injectedRelease = _G.__SENTRY_RELEASE__
        if injectedRelease then
            options.release = injectedRelease
        end
    end
    if options.autoSessionTracking == nil then
        options.autoSessionTracking = true
    end
    if options.sendClientReports == nil then
        options.sendClientReports = true
    end

    local clientOptions: RobloxClientOptions = Object.mergeObjects(options, {
        stackParser = stackParserFromStackParserOptions(options.stackParser or defaultStackParser),
        integrations = getIntegrationsToSetup(options :: any),
        transport = options.transport or makeHttpServiceTransport,
    })

    initAndBind(RobloxClient.new, clientOptions :: any)

    if options.autoSessionTracking then
        startSessionTracking()
    end
end

--- This is the getter for lastEventId.
--- @return The last event id of a captured event.
function RobloxSdk.lastEventId(): string | nil
    return getCurrentHub():lastEventId()
end

--- Call `flush()` on the current client, if there is one. See {@link Client.flush}.
---
--- @param timeout Maximum time in seconds the client should wait to flush its event queue. Omitting this parameter will
--- cause the client to wait until all events are sent before resolving the promise.
--- @return A promise which resolves to `true` if the queue successfully drains before the timeout, or `false` if it
--- doesn't (or if there's no client defined).
function RobloxSdk.flush(timeout: number?): PromiseLike<boolean>
    local client: RobloxClient? = getCurrentHub():getClient()
    if client then
        return client:flush(timeout)
    end
    if _G.__SENTRY_DEV__ then
        logger.warn("Cannot flush events. No client defined.")
    end
    return Promise.resolve(false)
end

--- Call `close()` on the current client, if there is one. See {@link Client.close}.
---
--- @param timeout Maximum time in seconds the client should wait to flush its event queue before shutting down.
--- Omitting this parameter will cause the client to wait until all events are sent before disabling itself.
--- @return A promise which resolves to `true` if the queue successfully drains before the timeout, or `false` if it
--- doesn't (or if there's no client defined).
function RobloxSdk.close(timeout: number?): PromiseLike<boolean>
    local client: RobloxClient? = getCurrentHub():getClient()
    if client then
        return client:close(timeout)
    end
    if _G.__SENTRY_DEV__ then
        logger.warn("Cannot flush events and disable SDK. No client defined.")
    end
    return Promise.resolve(false)
end

--- Wrap code within a try/catch block so the SDK is able to capture errors.
--- @param fn A function to wrap.
--- @return The result of wrapped function call.
function RobloxSdk.wrap<A..., R...>(fn: (A...) -> R...): R...
    return internalWrap(fn)()
end

return RobloxSdk
