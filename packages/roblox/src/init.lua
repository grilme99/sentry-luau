-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/sdk.ts

local PackageRoot = script
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

local Promise = require(Packages.Promise)

local SentryCore = require(Packages.SentryCore)

local RobloxSdk = {}

local Types = require(Packages.SentryTypes)
type UserFeedback = Types.UserFeedback
type Hub = Types.Hub
type Integration = Types.Integration
type PromiseLike<T> = Types.PromiseLike<T>

local Core = require(Packages.SentryCore)
RobloxSdk.addGlobalEventProcessor = Core.addGlobalEventProcessor
RobloxSdk.addBreadcrumb = Core.addBreadcrumb
RobloxSdk.captureException = Core.captureException
RobloxSdk.captureEvent = Core.captureEvent
RobloxSdk.captureMessage = Core.captureMessage
RobloxSdk.configureScope = Core.configureScope
RobloxSdk.createTransport = Core.createTransport
RobloxSdk.getHubFromCarrier = Core.getHubFromCarrier
local getCurrentHub = Core.getCurrentHub
RobloxSdk.getCurrentHub = getCurrentHub
RobloxSdk.Hub = Core.Hub
RobloxSdk.makeMain = Core.makeMain
RobloxSdk.Scope = Core.Scope
RobloxSdk.startTransaction = Core.startTransaction
RobloxSdk.SDK_VERSION = Core.SDK_VERSION
RobloxSdk.setContext = Core.setContext
RobloxSdk.setExtra = Core.setExtra
RobloxSdk.setExtras = Core.setExtras
RobloxSdk.setTag = Core.setTag
RobloxSdk.setTags = Core.setTags
RobloxSdk.setUser = Core.setUser
RobloxSdk.withScope = Core.withScope
local getIntegrationsToSetup = Core.getIntegrationsToSetup
local initAndBind = Core.initAndBind
local CoreIntegrations = Core.Integrations

local Transports = require(PackageRoot.transports)
local makeHttpServiceTransport = Transports.makeHttpServiceTransport
RobloxSdk.makeHttpServiceTransport = makeHttpServiceTransport

local EventBuilder = require(PackageRoot.eventbuilder)
RobloxSdk.eventFromException = EventBuilder.eventFromException
RobloxSdk.eventFromMessage = EventBuilder.eventFromMessage

local Utils = require(Packages.SentryUtils)
-- local addInstrumentationHandler = Utils.addInstrumentationHandler
local logger = Utils.logger
local stackParserFromStackParserOptions = Utils.stackParserFromStackParserOptions

local RobloxClient = require(PackageRoot.client)
type RobloxClient = RobloxClient.RobloxClient
type RobloxClientOptions = RobloxClient.RobloxClient
type RobloxOptions = RobloxClient.RobloxOptions

local Helpers = require(PackageRoot.helpers)
local internalWrap = Helpers.wrap

local makeRobloxStackParser = require(PackageRoot.stackparser)

local Integrations = require(PackageRoot.integrations)
RobloxSdk.Integrations = {}
RobloxSdk.Integrations.Dedupe = Integrations.Dedupe
RobloxSdk.Integrations.GlobalHandlers = Integrations.GlobalHandlers
RobloxSdk.Integrations.InApp = Integrations.InApp

RobloxSdk.Integrations.InboundFilters = CoreIntegrations.InboundFilters

type Array<T> = { T }

local defaultIntegrations: Array<Integration> = {
    CoreIntegrations.InboundFilters.new(),
    Integrations.GlobalHandlers.new(),
    Integrations.InApp.new(),
    Integrations.Dedupe.new(),
}
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
        else
            options.release = "{no_release}"
        end
    end
    if options.autoSessionTracking == nil then
        options.autoSessionTracking = true
    end
    if options.sendClientReports == nil then
        options.sendClientReports = true
    end

    local clientOptions: RobloxClientOptions = Object.assign({}, options, {
        stackParser = stackParserFromStackParserOptions(
            options.stackParser :: any or makeRobloxStackParser(options).defaultStackParser
        ),
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
    local client = getCurrentHub():getClient()
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
    local client = getCurrentHub():getClient()
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
function RobloxSdk.wrap<A..., R...>(fn: (A...) -> R..., ...: A...): R...
    return internalWrap(fn)(...)
end

return RobloxSdk
