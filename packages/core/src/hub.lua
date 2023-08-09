-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/hub.ts

local Types = require("@packages/types")
type Breadcrumb = Types.Breadcrumb
type BreadcrumbHint = Types.BreadcrumbHint
type Client = Types.Client
type CustomSamplingContext = Types.CustomSamplingContext
type Event = Types.Event
type EventHint = Types.EventHint
type Extra = Types.Extra
type Extras = Types.Extras
type HubInterface = Types.Hub
type Integration = Types.Integration
type IntegrationClass<T> = Types.IntegrationClass<T>
type Primitive = Types.Primitive
type Session = Types.Session
type SessionContext = Types.SessionContext
type SeverityLevel = Types.SeverityLevel
type Transaction = Types.Transaction
type TransactionContext = Types.TransactionContext
type User = Types.User
type Scope = Types.Scope

local Utils = require("@packages/utils")
local consoleSandbox = Utils.consoleSandbox
local dateTimestampInSeconds = Utils.dateTimestampInSeconds
local getGlobalSingleton = Utils.getGlobalSingleton
local GLOBAL_OBJ = Utils.GLOBAL_OBJ
local logger = Utils.logger
local uuid4 = Utils.uuid4
local Error = Utils.Polyfill.Error
local mergeObjects = Utils.Polyfill.Object.mergeObjects

local Constants = require("./constants")
local DEFAULT_ENVIRONMENT = Constants.DEFAULT_ENVIRONMENT

local Scope = require("./scope")

local Session = require("./session")
local closeSession = Session.closeSession
local makeSession = Session.makeSession
local updateSession = Session.updateSession

type Array<T> = { T }
type Map<K, V> = { [K]: V }

type Function = (...any) -> ...any

local HubExports = {}

--- API compatibility version of this hub.
---
--- WARNING: This number should only be increased when the global interface
--- changes and new methods are introduced.
---
--- @hidden
local API_VERSION = 4
HubExports.API_VERSION = API_VERSION

--- Default maximum number of breadcrumbs added to an event. Can be overwritten
--- with {@link Options.maxBreadcrumbs}.
local DEFAULT_BREADCRUMBS = 100

export type RunWithAsyncContextOptions = {
    --- Whether to reuse an existing async context if one exists. Defaults to false.
    reuseExisting: boolean?,
}

--- @private Private API with no semver guarantees!
---
--- Strategy used to track async context.
export type AsyncContextStrategy = {
    --- Gets the current async context. Returns undefined if there is no current async context.
    getCurrentHub: () -> Hub | nil,
    --- Runs the supplied callback in its own async context.
    runWithAsyncContext: <T>(callback: () -> T, options: RunWithAsyncContextOptions) -> T,
}

--- A layer in the process stack.
--- @hidden
export type Layer = {
    client: Client?,
    scope: Scope,
}

--- An object that contains a hub and maintains a scope stack.
--- @hidden
export type Carrier = {
    __SENTRY__: {
        hub: Hub?,
        acs: AsyncContextStrategy?,
        --- Extra Hub properties injected by various SDKs
        integrations: Array<Integration>?,
        --- Extension methods for the hub, which are bound to the current Hub instance
        extensions: Map<string, Function>?,
    }?,
}

export type Hub = typeof(setmetatable(
    {} :: HubInterface & {
        --- Is a {@link Layer}[] containing the client and scope
        _stack: Array<Layer>,
        --- Contains the last event id of a captured event.
        _lastEventId: string?,
        _version: number,

        getStack: (self: Hub) -> Array<Layer>,
        getStackTop: (self: Hub) -> Layer,

        _sendSessionUpdate: (self: Hub) -> (),
        _withClient: (self: Hub, callback: (client: Client, scope: Scope) -> ()) -> (),
        _callExtensionMethod: <T>(self: Hub, method: string, ...any) -> T,
    },
    {} :: {
        __index: Hub,
    }
))

local Hub = {}
Hub.__index = Hub

--- Returns the global shim registry.
---
--- FIXME: This function is problematic, because despite always returning a valid Carrier,
--- it has an optional `__SENTRY__` property, which then in turn requires us to always perform an unnecessary check
--- at the call-site. We always access the carrier through this function, so we can guarantee that `__SENTRY__` is there.
local function getMainCarrier(): Carrier
    GLOBAL_OBJ.__SENTRY__ = GLOBAL_OBJ.__SENTRY__ or {
        extensions = {},
        hub = nil,
    }
    return GLOBAL_OBJ :: any
end
HubExports.getMainCarrier = getMainCarrier

--- This will set passed {@link Hub} on the passed object's __SENTRY__.hub attribute
--- @param carrier object
--- @param hub Hub
--- @returns A boolean indicating success or failure
local function setHubOnCarrier(carrier: Carrier, hub: Hub): boolean
    if not carrier then
        return false
    end
    carrier.__SENTRY__ = carrier.__SENTRY__ or {};
    (carrier.__SENTRY__ :: any).hub = hub
    return true
end
HubExports.setHubOnCarrier = setHubOnCarrier

--- This will create a new {@link Hub} and add to the passed object on
--- __SENTRY__.hub.
--- @param carrier object
--- @hidden
local function getHubFromCarrier(carrier: Carrier): Hub
    return getGlobalSingleton("hub", function()
        return Hub.new()
    end, carrier)
end
HubExports.getHubFromCarrier = getHubFromCarrier

--- Replaces the current main hub with the passed one on the global object
---
--- @returns The old replaced hub
local function makeMain(hub: Hub): Hub
    local registry = getMainCarrier()
    local oldHub = getHubFromCarrier(registry)
    setHubOnCarrier(registry, hub)
    return oldHub
end
HubExports.makeMain = makeMain

--- This will tell whether a carrier has a hub on it or not
--- @param carrier object
local function hasHubOnCarrier(carrier: Carrier): boolean
    return not not (carrier and carrier.__SENTRY__ and carrier.__SENTRY__.hub)
end

local function getGlobalHub(registry_: Carrier?): Hub
    local registry = registry_ or getMainCarrier()

    -- If there's no hub, or its an old API, assign a new one
    if not hasHubOnCarrier(registry) or getHubFromCarrier(registry):isOlderThan(API_VERSION) then
        setHubOnCarrier(registry, Hub.new())
    end

    -- Return hub that lives on a global object
    return getHubFromCarrier(registry)
end

--- Returns the default hub instance.
---
--- If a hub is already registered in the global carrier but this module
--- contains a more recent version, it replaces the registered version.
--- Otherwise, the currently registered hub will be returned.
local function getCurrentHub(): Hub
    -- Get main carrier (global for every environment)
    local registry = getMainCarrier()

    if registry.__SENTRY__ and registry.__SENTRY__.acs then
        local hub = registry.__SENTRY__.acs.getCurrentHub()

        if hub then
            return hub
        end
    end

    -- Return hub that lives on a global object
    return getGlobalHub(registry)
end
HubExports.getCurrentHub = getCurrentHub

--- @private Private API with no semver guarantees!
---
--- If the carrier does not contain a hub, a new hub is created with the global hub client and scope.
local function ensureHubOnCarrier(carrier: Carrier, parent_: Hub?)
    local parent = parent_ or getGlobalHub()

    -- If there's no hub on current domain, or it's an old API, assign a new one
    if not hasHubOnCarrier(carrier) or getHubFromCarrier(carrier):isOlderThan(API_VERSION) then
        local globalHubTopStack = parent:getStackTop()
        setHubOnCarrier(carrier, Hub.new(globalHubTopStack.client, Scope.clone(globalHubTopStack.scope :: any)))
    end
end
HubExports.ensureHubOnCarrier = ensureHubOnCarrier

--- @private Private API with no semver guarantees!
---
--- Sets the global async context strategy
local function setAsyncContextStrategy(strategy: AsyncContextStrategy | nil)
    -- Get main carrier (global for every environment)
    local registry = getMainCarrier()
    registry.__SENTRY__ = registry.__SENTRY__ or {};
    (registry.__SENTRY__ :: any).acs = strategy
end
HubExports.setAsyncContextStrategy = setAsyncContextStrategy

--- Runs the supplied callback in its own async context. Async Context strategies are defined per SDK.
---
--- @param callback The callback to run in its own async context
--- @param options Options to pass to the async context strategy
--- @returns The result of the callback
local function runWithAsyncContext<T>(callback: () -> T, options_: RunWithAsyncContextOptions): T
    local options: RunWithAsyncContextOptions = options_ or {}

    local registry = getMainCarrier()

    if registry.__SENTRY__ and registry.__SENTRY__.acs then
        return registry.__SENTRY__.acs.runWithAsyncContext(callback, options)
    end

    -- if there was no strategy, fallback to just calling the callback
    return callback()
end
HubExports.runWithAsyncContext = runWithAsyncContext

function Hub.new(client: Client?, scope_: Scope?, version_: number?)
    local scope = scope_ or Scope.new()
    local version = version_ or API_VERSION

    local self = (setmetatable({}, Hub) :: any) :: Hub
    self._stack = { { scope = scope } }
    self._version = version

    if client then
        self:bindClient(client)
    end

    return self
end

function Hub.isOlderThan(self: Hub, version: number): boolean
    return self._version < version
end

function Hub.bindClient(self: Hub, client: Client?)
    local top = self:getStackTop()
    top.client = client
    if client and client.setupIntegrations then
        client:setupIntegrations()
    end
end

function Hub.pushScope(self: Hub): Scope
    -- We want to clone the content of prev scope
    local scope = Scope.clone(self:getScope() :: any)
    table.insert(self:getStack(), {
        client = self:getClient(),
        scope = scope,
    })
    return scope
end

function Hub.popScope(self: Hub): boolean
    if #self:getStack() <= 1 then
        return false
    end
    return not not table.remove(self:getStack())
end

function Hub.withScope(self: Hub, callback: (scope: Scope) -> ())
    local scope = self:pushScope()
    pcall(callback, scope)
    self:popScope()
end

function Hub.getClient(self: Hub): Client | nil
    return self:getStackTop().client
end

--- Returns the scope of the top stack.
function Hub.getScope(self: Hub): Scope
    return self:getStackTop().scope
end

--- Returns the scope stack for domains or the process.
function Hub.getStack(self: Hub): Array<Layer>
    return self._stack
end

--- Returns the topmost scope layer in the order domain > local > process.
function Hub.getStackTop(self: Hub): Layer
    return self._stack[#self._stack]
end

function Hub.captureException(self: Hub, exception: unknown, hint: EventHint?): string
    local eventId = if hint and hint.event_id then hint.event_id else uuid4()
    self._lastEventId = eventId
    local syntheticException = Error.new("Sentry syntheticException")
    self:_withClient(function(client, scope)
        client:captureException(
            exception,
            mergeObjects(
                { originalException = exception, syntheticException = syntheticException },
                hint or {},
                { event_id = eventId }
            ),
            scope
        )
    end)
    return eventId
end

function Hub.captureMessage(self: Hub, message: string, level: SeverityLevel?, hint: EventHint?): string
    local eventId = if hint and hint.event_id then hint.event_id else uuid4()
    self._lastEventId = eventId
    local syntheticException = Error.new(message)
    self:_withClient(function(client, scope)
        client:captureMessage(
            message,
            level,
            mergeObjects(
                { originalException = message, syntheticException = syntheticException },
                hint or {},
                { event_id = eventId }
            ),
            scope
        )
    end)
    return eventId
end

function Hub.captureEvent(self: Hub, event: Event, hint: EventHint?): string
    local eventId = if hint and hint.event_id then hint.event_id else uuid4()
    self._lastEventId = eventId
    if not event.type then
        self._lastEventId = eventId
    end

    self:_withClient(function(client, scope)
        client:captureException(event, mergeObjects(hint or {}, { event_id = eventId }), scope)
    end)
    return eventId
end

function Hub.lastEventId(self: Hub): string | nil
    return self._lastEventId
end

function Hub.addBreadcrumb(self: Hub, breadcrumb: Breadcrumb, hint: BreadcrumbHint?)
    local stackTop = self:getStackTop()
    local scope, client = stackTop.scope, stackTop.client

    if not client then
        return
    end

    local options = (client.getOptions and client:getOptions()) or {}
    local beforeBreadcrumb, maxBreadcrumbs = options.beforeBreadcrumb, options.maxBreadcrumbs or DEFAULT_BREADCRUMBS

    if maxBreadcrumbs <= 0 then
        return
    end

    local timestamp = dateTimestampInSeconds()
    local mergedBreadcrumb = mergeObjects({ timestamp = timestamp }, breadcrumb)
    local finalBreadcrumb = if beforeBreadcrumb
        then (consoleSandbox(function()
            return beforeBreadcrumb(mergedBreadcrumb, hint)
        end))
        else mergedBreadcrumb

    if finalBreadcrumb == nil then
        return
    end

    local emit = client.emit
    if emit then
        (emit :: Function)("beforeAddBreadcrumb", finalBreadcrumb, hint)
    end

    scope.addBreadcrumb(finalBreadcrumb, maxBreadcrumbs)
end

function Hub.setUser(self: Hub, user: User | nil)
    self:getScope():setUser(user)
end

function Hub.setTags(self: Hub, tags: Map<string, Primitive>)
    self:getScope():setTags(tags)
end

function Hub.setExtras(self: Hub, extras: Extras)
    self:getScope():setExtras(extras)
end

function Hub.setTag(self: Hub, key: string, value: Primitive)
    self:getScope():setTag(key, value)
end

function Hub.setExtra(self: Hub, key: string, extra: Extra)
    self:getScope():setExtra(key, extra)
end

function Hub.setContext(self: Hub, name: string, context: Map<string, any> | nil)
    self:getScope():setContext(name, context)
end

function Hub.configureScope(self: Hub, callback: (scope: Scope) -> ())
    local stackTop = self:getStackTop()
    local scope, client = stackTop.scope, stackTop.client
    if client then
        callback(scope)
    end
end

function Hub.run(self: Hub, callback: (hub: Hub) -> ())
    local oldHub = makeMain(self)
    pcall(callback, self)
    makeMain(oldHub)
end

function Hub.getIntegration<T>(self: Hub, integration: IntegrationClass<T>): T | nil
    local client = self:getClient()
    if not client then
        return nil
    end

    local success, result = pcall(client.getIntegration, client, integration)
    if success then
        return result
    else
        -- selene: allow(global_usage)
        if _G.__SENTRY_DEV__ then
            logger.warn(`Cannot retrieve integration {integration.id} from the current Hub`)
        end
        return nil
    end
end

function Hub.startTransaction(
    self: Hub,
    context: TransactionContext,
    customSamplingContext: CustomSamplingContext?
): Transaction
    local result: Transaction = self:_callExtensionMethod("startTransaction", context, customSamplingContext)

    -- selene: allow(global_usage)
    if _G.__SENTRY_DEV__ and not result then
        logger.warn(
            `Tracing extension 'startTransaction' has not been added. Call 'addTracingExtensions' before calling 'init':\nSentry.addTracingExtensions();\nSentry.init(\{...});\n`
        )
    end

    return result
end

function Hub.traceHeaders(self: Hub): Map<string, string>
    return self:_callExtensionMethod("traceHeaders")
end

function Hub.captureSession(self: Hub, endSession_: boolean?)
    local endSession = if endSession_ == nil then false else endSession_
    -- both send the update and pull the session from the scope
    if endSession then
        return self:endSession()
    end

    -- only send the update
    self:_sendSessionUpdate()
end

function Hub.endSession(self: Hub)
    local layer = self:getStackTop()
    local scope = layer.scope
    local session = scope:getSession()
    if session then
        closeSession(session)
    end
    self:_sendSessionUpdate()

    -- the session is over; take it off of the scope
    scope:setSession()
end

function Hub.startSession(self: Hub, context: SessionContext?): Session
    local stackTop = self:getStackTop()
    local scope, client = stackTop.scope, stackTop.client

    local options = (client and client:getOptions()) or {}
    local release, environment = options.release, options.environment or DEFAULT_ENVIRONMENT

    -- Will fetch userAgent if called from browser sdk
    local userAgent = if GLOBAL_OBJ.navigator then GLOBAL_OBJ.navigator.userAgent else nil

    local session = makeSession(mergeObjects({
        release = release,
        environment = environment,
        user = scope:getUser(),
    }, if userAgent then { userAgent = userAgent } else {}, context or {}))

    -- End existing session if there's one
    local currentSession = scope.getSession and scope:getSession()
    if currentSession and currentSession.status == "ok" then
        updateSession(currentSession, { status = "exited" })
    end
    self:endSession()

    -- Afterwards we set the new session on the scope
    scope:setSession(session)

    return session
end

--- Returns if default PII should be sent to Sentry and propagated in outgoing requests
--- when Tracing is used.
function Hub.shouldSendDefaultPii(self: Hub): boolean
    local client = self:getClient()
    local options = client and client:getOptions()
    return options and options.sendDefaultPii
end

--- Sends the current Session on the scope
function Hub._sendSessionUpdate(self: Hub)
    local stackTop = self:getStackTop()
    local scope, client = stackTop.scope, stackTop.client

    local session = scope:getSession()
    if session and client then
        local captureSession = client.captureSession
        if captureSession then
            captureSession(client, session)
        end
    end
end

--- Internal helper function to call a method on the top client if it exists.
---
--- @param method The method to call on the client.
--- @param args Arguments to pass to the client function.
function Hub._withClient(self: Hub, callback: (client: Client, scope: Scope) -> ())
    local stackTop = self:getStackTop()
    local scope, client = stackTop.scope, stackTop.client
    if client then
        callback(client, scope)
    end
end

--- Calls global extension method and binding current instance to the function call
function Hub._callExtensionMethod<T>(self: Hub, method: string, ...: any): T
    local args = { ... }

    local carrier = getMainCarrier()
    local sentry = carrier.__SENTRY__
    if sentry and sentry.extensions and type(sentry.extensions[method]) == "function" then
        return sentry.extensions[method](self, args)
    end

    -- selene: allow(global_usage)
    if _G.__SENTRY_DEV__ then
        logger.warn(`Extension method ${method} couldn't be found, doing nothing.`)
    end
    return nil :: any
end

HubExports.Hub = Hub
return HubExports
