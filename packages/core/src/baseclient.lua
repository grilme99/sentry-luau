-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/baseclient.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local instanceof = LuauPolyfill.instanceof

local Promise = require(Packages.Promise)

local Types = require(Packages.SentryTypes)
type Breadcrumb = Types.Breadcrumb
type BreadcrumbHint = Types.BreadcrumbHint
type Client = Types.Client
type ClientOptions = Types.ClientOptions
type DataCategory = Types.DataCategory
type DsnComponents = Types.DsnComponents
type DynamicSamplingContext = Types.DynamicSamplingContext
type Envelope = Types.Envelope
type ErrorEvent = Types.ErrorEvent
type Event = Types.Event
type EventDropReason = Types.EventDropReason
type EventHint = Types.EventHint
type Integration = Types.Integration
type IntegrationClass<T> = Types.IntegrationClass<T>
type Outcome = Types.Outcome
type PropagationContext = Types.PropagationContext
type SdkMetadata = Types.SdkMetadata
type Session = Types.Session
type SessionAggregates = Types.SessionAggregates
type SeverityLevel = Types.SeverityLevel
type Transaction = Types.Transaction
type TransactionEvent = Types.TransactionEvent
type Transport = Types.Transport
type TransportMakeRequestResponse = Types.TransportMakeRequestResponse
type PromiseLike<T> = Types.PromiseLike<T>

local Utils = require(Packages.SentryUtils)
local addItemToEnvelope = Utils.addItemToEnvelope
local checkOrSetAlreadyCaught = Utils.checkOrSetAlreadyCaught
local createAttachmentEnvelopeItem = Utils.createAttachmentEnvelopeItem
local isPlainObject = Utils.isPlainObject
local isPrimitive = Utils.isPrimitive
local isThenable = Utils.isThenable
local logger = Utils.logger
local makeDsn = Utils.makeDsn
local SentryError = Utils.SentryError
type SentryError = Utils.SentryError

local Api = require(PackageRoot.api)
local getEnvelopeEndpointWithUrlEncodedAuth = Api.getEnvelopeEndpointWithUrlEncodedAuth

local Envelope = require(PackageRoot.envelope)
local createEventEnvelope = Envelope.createEventEnvelope
local createSessionEnvelope = Envelope.createSessionEnvelope

local Integration = require(PackageRoot.integration)
type IntegrationIndex = Integration.IntegrationIndex
local setupIntegration = Integration.setupIntegration
local setupIntegrations = Integration.setupIntegrations

local Scope = require(PackageRoot.scope)
type Scope = Scope.Scope

local Session = require(PackageRoot.session)
local updateSession = Session.updateSession

local DynamicSamplingContext = require(PackageRoot.tracing.dynamicSamplingContext)
local getDynamicSamplingContextFromClient = DynamicSamplingContext.getDynamicSamplingContextFromClient

local PrepareEventUtils = require(PackageRoot.utils.prepareEvent)
local prepareEvent = PrepareEventUtils.prepareEvent

local ALREADY_SEEN_ERROR = "Not capturing exception because it's already been captured."

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type Function = (...any) -> ...any

export type BaseClient<O> = typeof(setmetatable(
    {} :: Client & {
        --- Options passed to the SDK.
        _options: ClientOptions & O,
        --- The client Dsn, if specified in options. Without this Dsn, the SDK will be disabled.
        _dsn: DsnComponents?,
        _transport: Transport?,
        --- Array of set up integrations.
        _integrations: IntegrationIndex,
        --- Indicates whether this client's integrations have been set up.
        _integrationsInitialized: boolean,
        --- Number of calls being processed
        _numProcessing: number,
        --- Holds flushable
        _outcomes: Map<string, number>,
        _hooks: Map<string, Array<Function>>,

        --- Occupies the client with processing and event
        _process: <T>(self: BaseClient<O>, promise: PromiseLike<T>) -> (),
        --- Processes the event and logs an error in case of rejection
        _captureEvent: (
            self: BaseClient<O>,
            event: Event,
            hint: EventHint?,
            scope: Scope?
        ) -> PromiseLike<string | nil>,
        --- Determines whether this SDK is enabled and a valid Dsn is present.
        _isEnabled: (self: BaseClient<O>) -> boolean,
        --- Determine if the client is finished processing. Returns a promise because it will wait `timeout` ms before
        --- saying "no" (resolving to `false`) in order to give the client a chance to potentially finish first.
        ---
        --- @param timeout The time, in ms, after which to resolve to `false` if the client is still busy. Passing `0`
        --- (or not passing anything) will make the promise wait as long as it takes for processing to finish before
        --- resolving to `true`.
        --- @return A promise which will resolve to `true` if processing is already done or finishes before the timeout,
        --- and `false` otherwise
        _isClientDoneProcessing: (self: BaseClient<O>, timeout: number?) -> PromiseLike<boolean>,
        --- Gets an installed integration by its `id`.
        --- @return The installed integration or `nil` if no integration with that `id` was installed.
        getIntegrationById: (self: BaseClient<O>, integrationId: string) -> Integration | nil,
        _sendEnvelope: (
            self: BaseClient<O>,
            envelope: Envelope
        ) -> PromiseLike<TransportMakeRequestResponse | nil> | nil,
        --- Updates existing session based on the provided event
        _updateSessionFromEvent: (self: BaseClient<O>, session: Session, event: Event) -> (),
        --- Adds common information to events.
        ---
        --- The information includes release and environment from `options`,
        --- breadcrumbs and context (extra, tags and user) from the scope.
        ---
        --- Information that is already present in the event is never overwritten. For
        --- nested objects, such as the context, keys are merged.
        ---
        --- @param event The original event.
        --- @param hint May contain additional information about the original exception.
        --- @param scope A scope containing event metadata.
        --- @return A new event with more information.
        _prepareEvent: (
            self: BaseClient<O>,
            event: Event,
            hint: EventHint,
            scope: Scope?
        ) -> PromiseLike<Event | nil>,
        --- Processes an event (either error or message) and sends it to Sentry.
        ---
        --- This also adds breadcrumbs and context information to the event. However,
        --- platform specific meta data (such as the User's IP address) must be added
        --- by the SDK implementor.
        ---
        ---
        --- @param event The event to send to Sentry.
        --- @param hint May contain additional information about the original exception.
        --- @param scope A scope containing event metadata.
        --- @return A SyncPromise that resolves with the event or rejects in case event was/will not be send.
        _processEvent: (self: BaseClient<O>, event: Event, hint: EventHint, scope: Scope?) -> PromiseLike<Event>,
        --- Clears outcomes on this client and returns them.
        _clearOutcomes: (self: BaseClient<O>) -> Array<Outcome>,
    },
    {} :: {
        __index: BaseClient<O>,
    }
))

--- Verifies that return value of configured `beforeSend` or `beforeSendTransaction` is of expected type, and returns
--- the value if so.
local function _validateBeforeSendResult(
    beforeSendResult_: PromiseLike<Event | nil> | Event | nil,
    beforeSendLabel: string
): PromiseLike<Event | nil> | Event | nil
    local invalidValueError = `{beforeSendLabel} must return \`nil\` or a valid event.`
    if isThenable(beforeSendResult_) then
        local beforeSendResult: PromiseLike<Event | nil> = beforeSendResult_ :: any
        return beforeSendResult:andThen(function(event)
            if not isPlainObject(event) and event ~= nil then
                error(SentryError.new(invalidValueError))
            end
            return event
        end, function(e)
            error(SentryError.new(`{beforeSendLabel} rejected with {e}`))
        end)
    elseif not isPlainObject(beforeSendResult_) and beforeSendResult_ ~= nil then
        error(SentryError.new(invalidValueError))
    end
    return beforeSendResult_
end

function isErrorEvent(event: Event): boolean
    return event.type == nil
end

function isTransactionEvent(event: Event): boolean
    return event.type == "transaction"
end

--- Process the matching `beforeSendXXX` callback.
local function processBeforeSend(
    options: ClientOptions,
    event: Event,
    hint: EventHint
): PromiseLike<Event | nil> | Event | nil
    local beforeSend, beforeSendTransaction = options.beforeSend, options.beforeSendTransaction

    if isErrorEvent(event) and beforeSend then
        return beforeSend(event :: any, hint)
    end

    if isTransactionEvent(event) and beforeSendTransaction then
        return beforeSendTransaction(event :: any, hint)
    end

    return event
end

--- Base implementation for all Lua SDK clients.
---
--- Call the constructor with the corresponding options
--- specific to the client subclass. To access these options later, use
--- {@link Client.getOptions}.
---
--- If a Dsn is specified in the options, it will be parsed and stored. Use
--- {@link Client.getDsn} to retrieve the Dsn at any moment. In case the Dsn is
--- invalid, the constructor will throw a {@link SentryException}. Note that
--- without a valid Dsn, the SDK will not send any events to Sentry.
---
--- Before sending an event, it is passed through
--- {@link BaseClient._prepareEvent} to add SDK information and scope data
--- (breadcrumbs and context). To add more custom information, override this
--- method and extend the resulting prepared event.
---
--- To issue automatically created events (e.g. via instrumentation), use
--- {@link Client.captureEvent}. It will prepare the event and pass it through
--- the callback lifecycle. To issue auto-breadcrumbs, use
--- {@link Client.addBreadcrumb}.
local BaseClient = {}
BaseClient.__index = BaseClient

function BaseClient.new<O>(options: ClientOptions & O)
    local self: BaseClient<O> = setmetatable({}, BaseClient) :: any
    self._integrations = {}
    self._integrationsInitialized = false
    self._numProcessing = 0
    self._outcomes = {}
    self._hooks = {}

    self._options = options
    if options.dsn then
        self._dsn = makeDsn(options.dsn)
    else
        if _G.__SENTRY_DEV__ then
            logger.warn("No DSN provided, client will not do anything.")
        end
    end

    if self._dsn then
        local url = getEnvelopeEndpointWithUrlEncodedAuth(self._dsn, options)
        self._transport = (options :: any).transport(Object.assign({
            url = url,
            recordDroppedEvent = function(...)
                self:recordDroppedEvent(...)
            end,
        }, options.transportOptions :: any))
    end

    return self
end

function BaseClient.captureException(
    self: BaseClient<any>,
    exception: any,
    hint: EventHint?,
    scope: Scope?
): string | nil
    -- ensure we haven't captured this very object before
    if checkOrSetAlreadyCaught(exception) then
        if _G.__SENTRY_DEV__ then
            logger.log(ALREADY_SEEN_ERROR)
        end
        return
    end

    local eventId = hint and hint.event_id

    self:_process(self:eventFromException(exception, hint)
        :andThen(function(event)
            return self:_captureEvent(event, hint, scope) :: any
        end)
        :andThen(function(result_: any)
            -- TODO Luau: Promise types don't resolve returns correctly, so we need to assert this as a string
            local result = result_ :: string
            eventId = result
        end))

    return eventId
end

function BaseClient.captureMessage(
    self: BaseClient<any>,
    message: string,
    level: SeverityLevel?,
    hint: EventHint?,
    scope: Scope
): string | nil
    local eventId = hint and hint.event_id

    local promisedEvent: PromiseLike<Event> = if isPrimitive(message)
        then self:eventFromMessage(tostring(message), level, hint)
        else self:eventFromException(message, hint)

    self:_process(promisedEvent
        :andThen(function(event)
            return self:_captureEvent(event, hint, scope) :: any
        end)
        :andThen(function(result_: any)
            -- TODO Luau: Promise types don't resolve returns correctly, so we need to assert this as a string
            local result = result_ :: string
            eventId = result
        end))

    return eventId
end

function BaseClient.captureEvent(self: BaseClient<any>, event: Event, hint: EventHint?, scope: Scope?): string | nil
    -- ensure we haven't captured this very object before
    if hint and hint.originalException and checkOrSetAlreadyCaught(hint.originalException) then
        if _G.__SENTRY_DEV__ then
            logger.log(ALREADY_SEEN_ERROR)
        end
        return
    end

    local eventId = hint and hint.event_id

    self:_process(self:_captureEvent(event, hint, scope):andThen(function(result)
        eventId = result
    end))

    return eventId
end

function BaseClient.captureSession(self: BaseClient<any>, session: Session)
    if not self:_isEnabled() then
        if _G.__SENTRY_DEV__ then
            logger.warn("SDK not enabled, will not capture session.")
        end
        return
    end

    if not (type(session.release) == "string") then
        if _G.__SENTRY_DEV__ then
            logger.warn("Discarded session because of missing or non-string release")
        end
    else
        self:sendSession(session)
        -- After sending, we set init false to indicate it's not the first occurrence
        updateSession(session, { init = false })
    end
end

function BaseClient.getDsn(self: BaseClient<any>): DsnComponents | nil
    return self._dsn
end

function BaseClient.getOptions(self: BaseClient<any>): any
    return self._options
end

function BaseClient.getSdkMetadata(self: BaseClient<any>): SdkMetadata | nil
    return self._options._metadata
end

function BaseClient.getTransport(self: BaseClient<any>): Transport | nil
    return self._transport
end

function BaseClient.flush(self: BaseClient<any>, timeout: number?): PromiseLike<boolean>
    local transport = self._transport
    if transport then
        return self:_isClientDoneProcessing(timeout):andThen(function(clientFinished)
            return transport.flush(timeout):andThen(function(transportFlushed)
                return clientFinished and transportFlushed
            end)
        end)
    else
        return Promise.resolve(true)
    end
end

function BaseClient.close(self: BaseClient<any>, timeout: number?): PromiseLike<boolean>
    return self:flush(timeout):andThen(function(result)
        self:getOptions().enabled = false
        return result
    end)
end

function BaseClient.setupIntegrations(self: BaseClient<any>)
    if self:_isEnabled() and not self._integrationsInitialized then
        self._integrations = setupIntegrations(self._options.integrations)
        self._integrationsInitialized = true
    end
end

function BaseClient.getIntegrationById(self: BaseClient<any>, integrationId: string): Integration | nil
    return self._integrations[integrationId]
end

function BaseClient.getIntegration<T>(self: BaseClient<any>, integration: IntegrationClass<T>): T | nil
    local instance: T? = self._integrations[integration.id] :: any
    if instance then
        return instance
    else
        if _G.__SENTRY_DEV__ then
            logger.warn(`Cannot retrieve integration {integration.id} from the current Client`)
        end
        return nil
    end
end

function BaseClient.addIntegration(self: BaseClient<any>, integration: Integration)
    setupIntegration(integration :: any, self._integrations)
end

function BaseClient.sendEvent(self: BaseClient<any>, event: Event, hint_: EventHint?)
    local hint: EventHint = hint_ or {}

    if self._dsn then
        local env = createEventEnvelope(event, self._dsn, self._options._metadata, self._options.tunnel)

        if hint.attachments then
            for _, attachment in hint.attachments do
                env = addItemToEnvelope(env, createAttachmentEnvelopeItem(attachment))
            end
        end

        local promise = self:_sendEnvelope(env)
        if promise then
            promise:andThen(function(sendResponse)
                return (self :: any):emit("afterSendEvent", event, sendResponse)
            end, nil)
        end
    end
end

function BaseClient.sendSession(self: BaseClient<any>, session: Session | SessionAggregates)
    if self._dsn then
        local env = createSessionEnvelope(session, self._dsn, self._options._metadata) -- , self._options.tunnel)
        self:_sendEnvelope(env)
    end
end

function BaseClient.recordDroppedEvent(
    self: BaseClient<any>,
    reason: EventDropReason,
    category: DataCategory,
    _event: Event?
)
    -- Note: we use `event` in replay, where we overwrite this hook.

    if self._options.sendClientReports then
        -- We want to track each category (error, transaction, session, replay_event) separately
        -- but still keep the distinction between different type of outcomes.
        -- We could use nested maps, but it's much easier to read and type this way.
        -- A correct type for map-based implementation if we want to go that route
        -- would be `Partial<Record<SentryRequestType, Partial<Record<Outcome, number>>>>`
        -- With typescript 4.1 we could even use template literal types
        local key = `{reason}:{category}`
        if _G.__SENTRY_DEV__ then
            logger.log(`Adding outcome: "{key}"`)
        end

        if self._outcomes[key] == nil then
            self._outcomes[key] = 0
        end
        self._outcomes[key] += 1
    end
end

function BaseClient.on(self: BaseClient<any>, hook: string, callback: Function)
    if not self._hooks[hook] then
        self._hooks[hook] = {}
    end

    table.insert(self._hooks[hook], callback)
end

function BaseClient.emit(self: BaseClient<any>, hook: string, ...: unknown)
    if self._hooks[hook] then
        for _, callback in self._hooks[hook] do
            callback(...)
        end
    end
end

function BaseClient._updateSessionFromEvent(self: BaseClient<any>, session: Session, event: Event)
    local crashed = false
    local errored = false
    local exceptions = event.exception and event.exception.values

    if exceptions then
        errored = true

        for _, ex in exceptions do
            local mechanism = ex.mechanism
            if mechanism and mechanism.handled == false then
                crashed = true
                break
            end
        end
    end

    -- A session is updated and that session update is sent in only one of the two following scenarios:
    -- 1. Session with non terminal status and 0 errors + an error occurred -> Will set error count to 1 and send update
    -- 2. Session with non terminal status and 1 error + a crash occurred -> Will set status crashed and send update
    local sessionNonTerminal = session.status == "ok"
    local shouldUpdateAndSend = (sessionNonTerminal and session.errors == 0) or (sessionNonTerminal and crashed)

    if shouldUpdateAndSend then
        updateSession(
            session,
            Object.assign(
                if crashed then { status = "crashed" } else {},
                { errors = session.errors or if errored or crashed then 1 else 0 }
            )
        )
        local cap = self.captureSession
        if cap then
            cap(self, session)
        end
    end
end

function BaseClient._isClientDoneProcessing(self: BaseClient<any>, timeout: number?): PromiseLike<boolean>
    return Promise.new(function(resolve)
        local ticked = 0
        local tick = 0.001

        local running = true
        task.spawn(function()
            while running do
                if self._numProcessing == 0 then
                    running = false
                    resolve(true)
                else
                    ticked += tick
                    if timeout and ticked >= timeout then
                        running = false
                        resolve(false)
                    end
                end
            end

            task.wait(tick)
        end)
    end)
end

function BaseClient._isEnabled(self: BaseClient<any>): boolean
    return self._options.enabled ~= false and self._dsn ~= nil
end

function BaseClient._prepareEvent(
    self: BaseClient<any>,
    event: Event,
    hint: EventHint,
    scope: Scope?
): PromiseLike<Event | nil>
    local options = self:getOptions()
    local integrations = Object.keys(self._integrations)
    if not hint.integrations and #integrations > 0 then
        hint.integrations = integrations
    end

    return prepareEvent(options, event, hint, scope):andThen(function(evt)
        if evt == nil then
            return evt
        end

        -- If a trace context is not set on the event, we use the propagationContext set on the event to
        -- generate a trace context. If the propagationContext does not have a dynamic sampling context, we
        -- also generate one for it.
        local propagationContext: PropagationContext? = evt.sdkProcessingMetadata
            and evt.sdkProcessingMetadata.propagationContext
        local trace = evt.contexts and evt.contexts.trace
        if not trace and propagationContext then
            local traceId, spanId, parentSpanId, dsc =
                propagationContext.traceId,
                propagationContext.spanId,
                propagationContext.parentSpanId,
                propagationContext.dsc

            evt.contexts = Object.assign({
                trace = {
                    trace_id = traceId,
                    span_id = spanId,
                    parent_span_id = parentSpanId,
                },
            }, evt.contexts or {})

            local dynamicSamplingContext: DynamicSamplingContext = if dsc
                then dsc
                else getDynamicSamplingContextFromClient(traceId, self, scope)

            evt.sdkProcessingMetadata =
                Object.assign({ dynamicSamplingContext = dynamicSamplingContext }, evt.sdkProcessingMetadata or {})
        end

        return evt
    end)
end

function BaseClient._captureEvent(
    self: BaseClient<any>,
    event: Event,
    hint_: EventHint?,
    scope: Scope?
): PromiseLike<string | nil>
    local hint: EventHint = hint_ or {}

    return self:_processEvent(event, hint, scope):andThen(function(finalEvent)
        return finalEvent.event_id :: any
    end, function(sentryError: SentryError)
        if _G.__SENTRY_DEV__ then
            -- If something's gone wrong, log the error as a warning. If it's just us having used a `SentryError` for
            -- control flow, log just the message (no stack) as a log-level log.
            if sentryError.logLevel == "log" then
                logger.log(sentryError.message)
            else
                logger.warn(sentryError)
            end
        end
        return nil
    end) :: any
end

function BaseClient._processEvent(
    self: BaseClient<any>,
    event: Event,
    hint: EventHint,
    scope: Scope?
): PromiseLike<Event | nil>
    local options = self:getOptions()
    local sampleRate = options.sampleRate

    if not self:_isEnabled() then
        return Promise.reject(SentryError.new("SDK not enabled, will not capture event", "log"))
    end

    local isTransaction = isTransactionEvent(event)
    local isError = isErrorEvent(event)
    local eventType = event.type or "error"
    local beforeSendLabel = `before send for type \`{eventType}\``

    -- 1.0 === 100% events are sent
    -- 0.0 === 0% events are sent
    -- Sampling for transaction happens somewhere else
    if isError and type(sampleRate) == "number" and math.random() > sampleRate then
        self:recordDroppedEvent("sample_rate", "error", event)
        return Promise.reject(
            SentryError.new(
                `Discarding event because it's not included in the random sample (sampling rate = {sampleRate})`,
                "log"
            )
        )
    end

    local dataCategory: DataCategory = if eventType == "replay_event" then "replay" else eventType :: DataCategory

    return self:_prepareEvent(event, hint, scope)
        :andThen(function(prepared)
            if prepared == nil then
                self:recordDroppedEvent("event_processor", dataCategory, event)
                error(SentryError.new("An event processor returned `null`, will not send event.", "log"))
            end

            local isInternalException = type(hint.data) == "table" and hint.data.__sentry__ == true
            if isInternalException then
                return prepared
            end

            local result = processBeforeSend(options :: any, prepared, hint)
            return _validateBeforeSendResult(result, beforeSendLabel)
        end)
        :andThen(function(processedEvent)
            if processedEvent == nil then
                self:recordDroppedEvent("before_send", dataCategory, processedEvent)
                error(SentryError.new(`{beforeSendLabel} returned \`nil\`, will not send event.`, "log"))
            end

            local session = scope and scope:getSession()
            if not isTransaction and session then
                self:_updateSessionFromEvent(session, processedEvent)
            end

            -- None of the Sentry built event processor will update transaction name,
            -- so if the transaction name has been changed by an event processor, we know
            -- it has to come from custom event processor added by a user
            local transactionInfo = processedEvent.transaction_info
            if isTransaction and transactionInfo and processedEvent.transaction ~= processedEvent.transaction then
                local source = "custom"
                processedEvent.transaction_info = Object.assign({}, transactionInfo, {
                    source = source,
                })
            end

            self:sendEvent(processedEvent, hint)
            return processedEvent
        end)
        :andThen(nil, function(reason)
            if instanceof(reason, SentryError) then
                error(reason)
            end

            self:captureException(reason, {
                data = {
                    __sentry__ = true,
                },
                originalException = reason,
            })

            error(
                SentryError.new(
                    `Event processing pipeline threw an error, original event will not be sent. Details have been sent as a new event.\nReason: {reason}`
                )
            )
        end)
end

function BaseClient._process<T>(self: BaseClient<any>, promise: PromiseLike<T>)
    self._numProcessing += 1
    promise:andThen(function(value)
        self._numProcessing -= 1
        return value
    end, function(reason)
        self._numProcessing -= 1
        return reason
    end)
end

function BaseClient._sendEnvelope(
    self: BaseClient<any>,
    envelope: Envelope
): PromiseLike<TransportMakeRequestResponse | nil> | nil
    if self._transport and self._dsn then
        (self :: any):emit("beforeEnvelope", envelope)

        return self._transport.send(envelope):andThen(nil, function(reason)
            if _G.__SENTRY_DEV__ then
                logger.error("Error while sending event:", reason)
            end
        end)
    else
        if _G.__SENTRY_DEV__ then
            logger.error("Transport disabled")
        end
    end
    return nil
end

function BaseClient._clearOutcomes(self: BaseClient<any>): Array<Outcome>
    local outcomes = self._outcomes
    self._outcomes = {}
    return Array.map(Object.keys(outcomes), function(key)
        local parts = key:split(":") :: any
        local reason: EventDropReason, category: DataCategory = parts[1], parts[2]
        return {
            reason = reason,
            category = category,
            quantity = outcomes[key],
        }
    end)
end

return BaseClient
