local Types = require("@packages/types")

type Attachment = Types.Attachment
type Breadcrumb = Types.Breadcrumb
type CaptureContext = Types.CaptureContext
type Context = Types.Context
type Contexts = Types.Contexts
type Event = Types.Event
type EventHint = Types.EventHint
type EventProcessor = Types.EventProcessor
type Extra = Types.Extra
type Extras = Types.Extras
type Primitive = Types.Primitive
type PropagationContext = Types.PropagationContext
type RequestSession = Types.RequestSession
type ScopeInterface = Types.Scope
type ScopeContext = Types.ScopeContext
type Session = Types.Session
type SeverityLevel = Types.SeverityLevel
type Span = Types.Span
type Transaction = Types.Transaction
type User = Types.User
type PromiseLike<T> = Types.PromiseLike<T>

local Utils = require("@packages/utils")
local arrayify = Utils.arrayify
local dateTimestampInSeconds = Utils.dateTimestampInSeconds
local getGlobalSingleton = Utils.getGlobalSingleton
local isPlainObject = Utils.isPlainObject
local isThenable = Utils.isThenable
local logger = Utils.logger
local uuid4 = Utils.uuid4
local instanceof = Utils.Polyfill.instanceof
local Promise = Utils.Promise
local mergeObjects = Utils.Polyfill.Object.mergeObjects

local Session = require("./session")
local updateSession = Session.updateSession

type Array<T> = { T }
type Map<K, V> = { [K]: V }

--- Default value for maximum number of breadcrumbs added to an event.
local DEFAULT_MAX_BREADCRUMBS = 100

local function generatePropagationContext(): PropagationContext
    return {
        traceId = uuid4(),
        spanId = string.sub(uuid4(), 16),
        sampled = false,
    }
end

local function getGlobalEventProcessors(): Array<EventProcessor>
    return getGlobalSingleton("globalEventProcessors", function()
        return {}
    end)
end

local function ObjectKeys<T>(obj: Map<T, any>): Array<T>
    local keys = {}
    for k, _ in obj do
        table.insert(keys, k)
    end
    return keys
end

export type Scope = typeof(setmetatable(
    {} :: ScopeInterface & {
        --- Flag if notifying is happening.
        _notifyingListeners: boolean,
        --- Callback for client to receive scope changes.
        _scopeListeners: Array<(scope: Scope) -> ()>,
        --- Callback list that will be called after {@link applyToEvent}.
        _eventProcessors: Array<EventProcessor>,
        _breadcrumbs: Array<Breadcrumb>,
        _user: User,
        _tags: Map<string, Primitive>,
        _extra: Extras,
        _contexts: Contexts,
        _attachments: Array<Attachment>,
        --- Propagation Context for distributed tracing
        _propagationContext: PropagationContext,
        --- A place to stash data which is needed at some point in the SDK's event processing pipeline but which
        --- shouldn't get sent to Sentry
        _sdkProcessingMetadata: Map<string, unknown>,
        _fingerprint: Array<string>?,
        _level: SeverityLevel?,
        _transactionName: string?,
        _span: Span?,
        _session: Session?,
        --- Request Mode Session Status
        _requestSession: RequestSession?,

        _notifyEventProcessors: (
            self: Scope,
            processors: Array<EventProcessor>,
            event: Event | nil,
            hint: EventHint,
            index_: number?
        ) -> PromiseLike<Event | nil>,
        _notifyScopeListeners: (self: Scope) -> (),
        _applyFingerprint: (self: Scope, event: Event) -> (),
    },
    {} :: {
        __index: Scope,
    }
))

--- Holds additional event information. {@link Scope.applyToEvent} will be called by the client before an event will be
--- sent.
local Scope = {}
Scope.__index = Scope

function Scope.new()
    local self = (setmetatable({}, Scope) :: any) :: Scope
    self._notifyingListeners = false
    self._scopeListeners = {} :: Array<(scope: ScopeInterface) -> ()>
    self._eventProcessors = {} :: Array<EventProcessor>
    self._breadcrumbs = {} :: Array<Breadcrumb>
    self._user = {} :: User
    self._tags = {} :: Map<string, Primitive>
    self._extra = {} :: Extras
    self._contexts = {} :: Contexts
    self._attachments = {} :: Array<Attachment>
    self._propagationContext = generatePropagationContext()
    self._sdkProcessingMetadata = {} :: Map<string, unknown>
    self._fingerprint = nil :: Array<string>?
    self._level = nil :: SeverityLevel?
    self._transactionName = nil :: string?
    self._span = nil :: Span?
    self._session = nil :: Session?
    self._requestSession = nil :: RequestSession?

    return self
end

-- export type Scope = typeof(Scope.new(...))

--- Inherit values from the parent scope.
--- @param scope to clone.
function Scope.clone(scope: Scope?): Scope
    local newScope = Scope.new()
    if scope then
        newScope._breadcrumbs = table.clone(scope._breadcrumbs)
        newScope._tags = table.clone(scope._tags)
        newScope._extra = table.clone(scope._extra)
        newScope._contexts = table.clone(scope._contexts) :: any
        newScope._user = scope._user
        newScope._level = scope._level
        newScope._span = scope._span
        newScope._session = scope._session
        newScope._transactionName = scope._transactionName
        newScope._fingerprint = scope._fingerprint
        newScope._eventProcessors = table.clone(scope._eventProcessors)
        newScope._requestSession = scope._requestSession
        newScope._attachments = table.clone(scope._attachments)
        newScope._sdkProcessingMetadata = table.clone(scope._sdkProcessingMetadata)
        newScope._propagationContext = table.clone(scope._propagationContext)
    end
    return newScope
end

--- Add internal on change listener. Used for sub SDKs that need to store the scope.
--- @hidden
function Scope.addScopeListener(self: Scope, callback: (scope: Scope) -> ())
    table.insert(self._scopeListeners, callback)
end

function Scope.addEventProcessor(self: Scope, callback: EventProcessor): Scope
    table.insert(self._eventProcessors, callback)
    return self
end

function Scope.setUser(self: Scope, user: User | nil): Scope
    self._user = user or {}
    if self._session then
        updateSession(self._session, { user })
    end
    self:_notifyScopeListeners()
    return self
end

function Scope.getUser(self: Scope): User | nil
    return self._user
end

function Scope.getRequestSession(self: Scope): RequestSession | nil
    return self._requestSession
end

function Scope.setRequestSession(self: Scope, requestSession: RequestSession?): Scope
    self._requestSession = requestSession
    return self
end

function Scope.setTags(self: Scope, tags: Map<string, Primitive>): Scope
    self._tags = mergeObjects(self._tags, tags)
    self:_notifyScopeListeners()
    return self
end

function Scope.setTag(self: Scope, key: string, value: Primitive): Scope
    self._tags = mergeObjects(self._tags, { [key] = value })
    self:_notifyScopeListeners()
    return self
end

function Scope.setExtras(self: Scope, extras: Extras): Scope
    self._extra = mergeObjects(self._extra, extras)
    self:_notifyScopeListeners()
    return self
end

function Scope.setExtra(self: Scope, key: string, extra: Extra): Scope
    self._extra = mergeObjects(self._extra, { [key] = extra })
    self:_notifyScopeListeners()
    return self
end

function Scope.setFingerprint(self: Scope, fingerprint: Array<string>): Scope
    self._fingerprint = fingerprint
    self:_notifyScopeListeners()
    return self
end

function Scope.setLevel(self: Scope, level: SeverityLevel): Scope
    self._level = level
    self:_notifyScopeListeners()
    return self
end

function Scope.setTransactionName(self: Scope, name: string?): Scope
    self._transactionName = name
    self:_notifyScopeListeners()
    return self
end

function Scope.setContext(self: Scope, key: string, context: Context?): Scope
    if context == nil then
        (self._contexts :: any)[key] = nil
    else
        (self._contexts :: any)[key] = context
    end

    self:_notifyScopeListeners()
    return self
end

function Scope.setSpan(self: Scope, span: Span?): Scope
    self._span = span
    self:_notifyScopeListeners()
    return self
end

function Scope.getSpan(self: Scope): Span | nil
    return self._span
end

function Scope.getTransaction(self: Scope): Transaction | nil
    -- Often, self span (if it exists at all) will be a transaction, but it's not guaranteed to be. Regardless, it will
    -- have a pointer to the currently-active transaction.
    local span = self:getSpan()
    return span and span.transaction
end

function Scope.setSession(self: Scope, session: Session?): Scope
    self._session = session
    self:_notifyScopeListeners()
    return self
end

function Scope.getSession(self: Scope): Session | nil
    return self._session
end

function Scope.update(self: Scope, captureContext_: CaptureContext?): Scope
    if not captureContext_ then
        return self
    end

    if type(captureContext_) == "function" then
        local captureContext = (captureContext_ :: any) :: <T>(scope: T) -> T
        local updatedScope = captureContext(self)
        return if instanceof(updatedScope, Scope) then updatedScope else self
    end

    if instanceof(captureContext_, Scope) then
        local captureContext = captureContext_ :: Scope

        self._tags = mergeObjects(self._tags, captureContext._tags)
        self._extra = mergeObjects(self._extra, captureContext._extra)
        self._contexts = mergeObjects(self._contexts, captureContext._contexts)
        if captureContext._user and #ObjectKeys(captureContext._user) > 0 then
            self._user = captureContext._user
        end
        if captureContext._level then
            self._level = captureContext._level
        end
        if captureContext._fingerprint then
            self._fingerprint = captureContext._fingerprint
        end
        if captureContext._requestSession then
            self._requestSession = captureContext._requestSession
        end
        if captureContext._propagationContext then
            self._propagationContext = captureContext._propagationContext
        end
    elseif isPlainObject(captureContext_) then
        -- eslint-disable-next-line no-param-reassign
        local captureContext = captureContext_ :: ScopeContext
        self._tags = mergeObjects(self._tags, captureContext.tags)
        self._extra = mergeObjects(self._extra, captureContext.extra)
        self._contexts = mergeObjects(self._contexts, captureContext.contexts)
        if captureContext.user then
            self._user = captureContext.user
        end
        if captureContext.level then
            self._level = captureContext.level
        end
        if captureContext.fingerprint then
            self._fingerprint = captureContext.fingerprint
        end
        if captureContext.requestSession then
            self._requestSession = captureContext.requestSession
        end
        if captureContext.propagationContext then
            self._propagationContext = captureContext.propagationContext
        end
    end

    return self
end

function Scope.clear(self: Scope): Scope
    self._breadcrumbs = {}
    self._tags = {}
    self._extra = {}
    self._user = {}
    self._contexts = {} :: any
    self._level = nil
    self._transactionName = nil
    self._fingerprint = nil
    self._requestSession = nil
    self._span = nil
    self._session = nil
    self:_notifyScopeListeners()
    self._attachments = {}
    self._propagationContext = generatePropagationContext()
    return self
end

function Scope.addBreadcrumb(self: Scope, breadcrumb: Breadcrumb, maxBreadcrumbs: number?): Scope
    local maxCrumbs = if type(maxBreadcrumbs) == "number" then maxBreadcrumbs else DEFAULT_MAX_BREADCRUMBS

    -- No data has been changed, so don't notify scope listeners
    if maxCrumbs <= 0 then
        return self
    end

    local mergedBreadcrumb = table.clone(breadcrumb)
    mergedBreadcrumb.timestamp = dateTimestampInSeconds()

    table.insert(self._breadcrumbs, mergedBreadcrumb)

    local crumbCount = #self._breadcrumbs
    if crumbCount > maxCrumbs then
        local countToRemove = crumbCount - maxCrumbs
        for _ = 1, countToRemove do
            table.remove(self._breadcrumbs, 1)
        end
    end

    self:_notifyScopeListeners()

    return self
end

function Scope.getLastBreadcrumb(self: Scope): Breadcrumb | nil
    return self._breadcrumbs[#self._breadcrumbs]
end

function Scope.clearBreadcrumbs(self: Scope): Scope
    table.clear(self._breadcrumbs)
    self:_notifyScopeListeners()
    return self
end

function Scope.addAttachment(self: Scope, attachment: Attachment): Scope
    table.insert(self._attachments, attachment)
    return self
end

function Scope.getAttachments(self: Scope): Array<Attachment>
    return self._attachments
end

function Scope.clearAttachments(self: Scope): Scope
    self._attachments = {}
    return self
end

--- Applies data from the scope to the event and runs all event processors on it.
---
--- @param event Event
--- @param hint Object containing additional information about the original exception, for use by the event processors.
--- @hidden
function Scope.applyToEvent(self: Scope, event: Event, hint_: EventHint?): PromiseLike<Event | nil>
    local hint = hint_ or {}

    if self._extra and #ObjectKeys(self._extra) > 0 then
        event.extra = mergeObjects(self._extra, event.extra or {})
    end
    if self._tags and #ObjectKeys(self._tags) > 0 then
        event.tags = mergeObjects(self._tags, event.tags or {})
    end
    if self._user and #ObjectKeys(self._user) > 0 then
        event.user = mergeObjects(self._user, event.user or {})
    end
    if self._contexts and #ObjectKeys(self._contexts) > 0 then
        event.contexts = mergeObjects(self._contexts, event.contexts or {})
    end
    if self._level then
        event.level = self._level
    end
    if self._transactionName then
        event.transaction = self._transactionName
    end

    -- We want to set the trace context for normal events only if there isn't already
    -- a trace context on the event. There is a product feature in place where we link
    -- errors with transaction and it relies on that.
    if self._span then
        event.contexts = mergeObjects(event.contexts or {}, { trace = self._span:getTraceContext() })
        local transaction = self._span.transaction
        if transaction then
            event.sdkProcessingMetadata = mergeObjects(event.sdkProcessingMetadata or {}, {
                dynamicSamplingContext = transaction:getDynamicSamplingContext(),
            })
            local transactionName = transaction.name
            if transactionName then
                event.tags = mergeObjects(event.tags or {}, { transaction = transactionName })
            end
        end
    end

    self:_applyFingerprint(event)

    local eventBreadcrumbs = event.breadcrumbs or {}
    event.breadcrumbs = table.move(self._breadcrumbs, 1, #self._breadcrumbs, #eventBreadcrumbs + 1, eventBreadcrumbs)
    event.breadcrumbs = if #(event.breadcrumbs :: any) > 0 then event.breadcrumbs else nil

    event.sdkProcessingMetadata = mergeObjects(
        event.sdkProcessingMetadata or {},
        self._sdkProcessingMetadata,
        { propagationContext = self._propagationContext }
    )

    local globalProcessors = table.clone(getGlobalEventProcessors())
    local mergedProcessors =
        table.move(self._eventProcessors, 1, #self._eventProcessors, #globalProcessors + 1, globalProcessors)

    return self:_notifyEventProcessors(mergedProcessors, event, hint)
end

--- Add data which will be accessible during event processing but won't get sent to Sentry
function Scope.setSDKProcessingMetadata(self: Scope, newData: Map<string, unknown>): Scope
    self._sdkProcessingMetadata = mergeObjects(self._sdkProcessingMetadata, newData)
    return self
end

function Scope.setPropagationContext(self: Scope, context: PropagationContext): Scope
    self._propagationContext = context
    return self
end

function Scope.getPropagationContext(self: Scope): PropagationContext
    return self._propagationContext
end

function Scope._notifyEventProcessors(
    self: Scope,
    processors: Array<EventProcessor>,
    event: Event | nil,
    hint: EventHint,
    index_: number?
): PromiseLike<Event | nil>
    local index = index_ or 1
    return Promise.new(function(resolve, reject)
        local processor = processors[index]
        if event == nil or type(processor.fn) ~= "function" then
            resolve(event)
        else
            local result = processor.fn(table.clone(event), hint)

            
            if _G.__SENTRY_DEV__ and processor.id and result == nil then
                logger.log(`Event processor "{processor.id}" dropped event`)
            end

            if isThenable(result) then
                local result_ = result :: PromiseLike<any>
                result_
                    :andThen(function(final)
                        self:_notifyEventProcessors(processors, final, hint, index + 1):andThen(resolve)
                    end)
                    :andThen(nil, reject)
            else
                local result_ = result :: any
                self:_notifyEventProcessors(processors, result_, hint, index + 1):andThen(resolve):andThen(nil, reject)
            end
        end
    end)
end

--- self will be called on every set call.
function Scope._notifyScopeListeners(self: Scope)
    -- We need self check for self._notifyingListeners to be able to work on scope during updates
    -- If self check is not here we'll produce endless recursion when something is done with the scope
    -- during the callback.
    if not self._notifyingListeners then
        self._notifyingListeners = true
        for _, callback in self._scopeListeners do
            callback(self)
        end
        self._notifyingListeners = false
    end
end

--- Applies fingerprint from the scope to the event if there's one,
--- uses message if there's one instead or get rid of empty fingerprint
function Scope._applyFingerprint(self: Scope, event: Event)
    -- Make sure it's an array first and we actually have something in place
    event.fingerprint = if event.fingerprint then arrayify(event.fingerprint) else {}

    -- If we have something on the scope, then merge it with event
    if self._fingerprint then
        local eventFingerprint = event.fingerprint or {}
        event.fingerprint =
            table.move(self._fingerprint, 1, #self._fingerprint, #eventFingerprint + 1, eventFingerprint)
    end

    -- If we have no data at all, remove empty array default
    if event.fingerprint and #event.fingerprint == 0 then
        event.fingerprint = nil
    end
end

--- Add a EventProcessor to be kept globally.
--- @param callback EventProcessor to add
function Scope.addGlobalEventProcessor(callback: EventProcessor)
    table.insert(getGlobalEventProcessors(), callback)
end

return Scope
