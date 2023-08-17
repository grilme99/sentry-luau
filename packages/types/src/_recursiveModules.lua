-- note: Lots of the type modules require each other recursively, so we'll put them all here to avoid that issue.

local PackageRoot = script.Parent

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/client.ts

local Breadcrumb = require(PackageRoot.breadcrumb)
type Breadcrumb = Breadcrumb.Breadcrumb
type BreadcrumbHint = Breadcrumb.BreadcrumbHint

local CheckIn = require(PackageRoot.checkin)
type CheckIn = CheckIn.CheckIn
type MonitorConfig = CheckIn.MonitorConfig
type SerializedCheckIn = CheckIn.SerializedCheckIn

local ClientReport = require(PackageRoot.clientreport)
type ClientReport = ClientReport.ClientReport
type Outcome = ClientReport.Outcome
type EventDropReason = ClientReport.EventDropReason

local DataCategory = require(PackageRoot.datacategory)
type DataCategory = DataCategory.DataCategory

local Dsn = require(PackageRoot.dsn)
type DsnComponents = Dsn.DsnComponents

local SdkMetadata = require(PackageRoot.sdkmetadata)
type SdkMetadata = SdkMetadata.SdkMetadata

local SdkInfo = require(PackageRoot.sdkinfo)
type SdkInfo = SdkInfo.SdkInfo

local Session = require(PackageRoot.session)
type Session = Session.Session
type SessionAggregates = Session.SessionAggregates
type SerializedSession = Session.SerializedSession
type RequestSession = Session.RequestSession

local Severity = require(PackageRoot.severity)
type SeverityLevel = Severity.SeverityLevel

local Promise = require(PackageRoot.promise)
type PromiseLike<T> = Promise.PromiseLike<T>
local Attachment = require(PackageRoot.attachment)
type Attachment = Attachment.Attachment

local Contexts = require(PackageRoot.context)
type Context = Contexts.Context
type Contexts = Contexts.Contexts

local DebugMeta = require(PackageRoot.debugMeta)
type DebugMeta = DebugMeta.DebugMeta

local Exception = require(PackageRoot.exception)
type Exception = Exception.Exception

local Measurements = require(PackageRoot.measurement)
type Measurements = Measurements.Measurements

local Primitive = require(PackageRoot.misc)
type Primitive = Primitive.Primitive

local Thread = require(PackageRoot.thread)
type Thread = Thread.Thread

local Extra = require(PackageRoot.extra)
type Extra = Extra.Extra
type Extras = Extra.Extras

local TextEncoder = require(PackageRoot.textencoder)
type TextEncoderInternal = TextEncoder.TextEncoderInternal

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/options.ts

local Instrumenter = require(PackageRoot.instrumenter)
type Instrumenter = Instrumenter.Instrumenter

local Stacktrace = require(PackageRoot.stacktrace)
type StackLineParser = Stacktrace.StackLineParser
type StackParser = Stacktrace.StackParser

-- TODO Luau: No utility types
type Partial<T> = T

-- TODO: Import RegExp into project
type RegExp = nil

export type ClientOptions<TO = BaseTransportOptions> = TO & {
    --- Enable debug functionality in the SDK itself
    debug: boolean?,

    --- Specifies whether this SDK should send events to Sentry.
    --- Defaults to true.
    enabled: boolean?,

    --- Attaches stacktraces to pure capture message / log integrations
    attachStacktrace: boolean?,

    --- A flag enabling Sessions Tracking feature.
    --- By default, Sessions Tracking is enabled.

    autoSessionTracking: boolean?,

    --- Send SDK Client Reports.
    --- By default, Client Reports are enabled.
    sendClientReports: boolean?,

    --- The Dsn used to connect to Sentry and identify the project. If omitted, the
    --- SDK will not send any data to Sentry.
    dsn: string?,

    --- The release identifier used when uploading respective source maps. Specify
    --- this value to allow Sentry to resolve the correct source maps when
    --- processing events.
    release: string?,

    --- The current environment of your application (e.g. "production").
    environment: string?,

    --- Sets the distribution for all events
    dist: string?,

    --- List of integrations that should be installed after SDK was initialized.
    integrations: Array<Integration>,

    --- The instrumenter to use. Defaults to `sentry`.
    --- When not set to `sentry`, auto-instrumentation inside of Sentry will be disabled,
    --- in favor of using external auto instrumentation.
    ---
    --- NOTE: Any option except for `sentry` is highly experimental and subject to change!
    instrumenter: Instrumenter?,

    --- A function that takes transport options and returns the Transport object which is used to send events to Sentry.
    --- The function is invoked internally when the client is initialized.
    transport: (transportOptions: TO) -> Transport,

    --- A stack parser implementation
    --- By default, a stack parser is supplied for all supported platforms
    stackParser: StackParser,

    --- Options for the default transport that the SDK uses.
    transportOptions: Partial<TO>?,

    --- Sample rate to determine trace sampling.
    ---
    --- 0.0 = 0% chance of a given trace being sent (send no traces) 1.0 = 100% chance of a given trace being sent (send
    --- all traces)
    ---
    --- Tracing is enabled if either this or `tracesSampler` is defined. If both are defined, `tracesSampleRate` is
    --- ignored.
    tracesSampleRate: number?,

    --- If this is enabled, transactions and trace data will be generated and captured.
    --- This will set the `tracesSampleRate` to the recommended default of `1.0` if `tracesSampleRate` is undefined.
    --- Note that `tracesSampleRate` and `tracesSampler` take precedence over this option.
    enableTracing: boolean?,

    --- Initial data to populate scope.
    initialScope: CaptureContext?,

    --- The maximum number of breadcrumbs sent with events. Defaults to 100.
    --- Sentry has a maximum payload size of 1MB and any events exceeding that payload size will be dropped.
    maxBreadcrumbs: number?,

    --- A global sample rate to apply to all events.
    ---
    --- 0.0 = 0% chance of a given event being sent (send no events) 1.0 = 100% chance of a given event being sent (send
    --- all events)
    sampleRate: number?,

    --- Maximum number of chars a single value can have before it will be truncated.
    maxValueLength: number?,

    --- Maximum number of levels that normalization algorithm will traverse in objects and arrays.
    --- Used when normalizing an event before sending, on all of the listed attributes:
    --- - `breadcrumbs.data`
    --- - `user`
    --- - `contexts`
    --- - `extra`
    --- Defaults to `3`. Set to `0` to disable.
    normalizeDepth: number?,

    --- Maximum number of properties or elements that the normalization algorithm will output in any single array or object included in the normalized event.
    --- Used when normalizing an event before sending, on all of the listed attributes:
    --- - `breadcrumbs.data`
    --- - `user`
    --- - `contexts`
    --- - `extra`
    --- Defaults to `1000`
    normalizeMaxBreadth: number?,

    --- Controls how many milliseconds to wait before shutting down. The default is
    --- SDK-specific but typically around 2 seconds. Setting this too low can cause
    --- problems for sending events from command line applications. Setting it too
    --- high can cause the application to block for users with network connectivity
    --- problems.

    shutdownTimeout: number?,

    --- A pattern for error messages which should not be sent to Sentry.
    --- By default, all errors will be sent.
    ignoreErrors: Array<string | RegExp>?,

    --- A pattern for transaction names which should not be sent to Sentry.
    --- By default, all transactions will be sent.
    ignoreTransactions: Array<string | RegExp>?,

    --- A URL to an envelope tunnel endpoint. An envelope tunnel is an HTTP endpoint
    --- that accepts Sentry envelopes for forwarding. This can be used to force data
    --- through a custom server independent of the type of data.
    tunnel: string?,

    --- Controls if potentially sensitive data should be sent to Sentry by default.
    --- Note that this only applies to data that the SDK is sending by default
    --- but not data that was explicitly set (e.g. by calling `Sentry.setUser()`).
    ---
    --- Defaults to `false`.
    ---
    --- NOTE: This option currently controls only a few data points in a selected
    --- set of SDKs. The goal for this option is to eventually control all sensitive
    --- data the SDK sets by default. However, this would be a breaking change so
    --- until the next major update this option only controls data points which were
    --- added in versions above `7.9.0`.
    sendDefaultPii: boolean?,

    --- Set of metadata about the SDK that can be internally used to enhance envelopes and events,
    --- and provide additional data about every request.
    _metadata: SdkMetadata?,

    --- Options which are in beta, or otherwise not guaranteed to be stable.
    _experiments: Map<string, any>?,

    --- A pattern for error URLs which should exclusively be sent to Sentry.
    --- This is the opposite of {@link Options.denyUrls}.
    --- By default, all errors will be sent.
    ---
    --- Requires the use of the `InboundFilters` integration.
    allowUrls: Array<string | RegExp>?,

    --- A pattern for error URLs which should not be sent to Sentry.
    --- To allow certain errors instead, use {@link Options.allowUrls}.
    --- By default, all errors will be sent.
    ---
    --- Requires the use of the `InboundFilters` integration.
    denyUrls: Array<string | RegExp>?,

    --- List of strings/regex controlling to which outgoing requests
    --- the SDK will attach tracing headers.
    ---
    --- By default the SDK will attach those headers to all outgoing
    --- requests. If this option is provided, the SDK will match the
    --- request URL of outgoing requests against the items in this
    --- array, and only attach tracing headers if a match was found.
    ---
    --- @example
    --- ```js
    --- Sentry.init({
    ---   tracePropagationTargets: ['api.site.com'],
    --- });
    --- ```
    tracePropagationTargets: TracePropagationTargets?,

    --- Function to compute tracing sample rate dynamically and filter unwanted traces.
    ---
    --- Tracing is enabled if either this or `tracesSampleRate` is defined. If both are defined, `tracesSampleRate` is
    --- ignored.
    ---
    --- Will automatically be passed a context object of default and optional custom data. See
    --- {@link Transaction.samplingContext} and {@link Hub.startTransaction}.
    ---
    --- @return A sample rate between 0 and 1 (0 drops the trace, 1 guarantees it will be sent). Returning `true` is
    --- equivalent to returning 1 and returning `false` is equivalent to returning 0.
    tracesSampler: ((samplingContext: SamplingContext) -> number | boolean)?,

    -- TODO (v8): Narrow the response type to `ErrorEvent` - this is technically a breaking change.

    --- An event-processing callback for error and message events, guaranteed to be invoked after all other event
    --- processors, which allows an event to be modified or dropped.
    ---
    --- Note that you must return a valid event from this callback. If you do not wish to modify the event, simply return
    --- it at the end. Returning `null` will cause the event to be dropped.
    ---
    --- @param event The error or message event generated by the SDK.
    --- @param hint Event metadata useful for processing.
    --- @return A new event that will be sent | null.
    beforeSend: ((event: ErrorEvent, hint: EventHint) -> PromiseLike<Event | nil> | Event | nil)?,

    -- TODO (v8): Narrow the response type to `TransactionEvent` - this is technically a breaking change.

    --- An event-processing callback for transaction events, guaranteed to be invoked after all other event
    --- processors. This allows an event to be modified or dropped before it's sent.
    ---
    --- Note that you must return a valid event from this callback. If you do not wish to modify the event, simply return
    --- it at the end. Returning `null` will cause the event to be dropped.
    ---
    --- @param event The error or message event generated by the SDK.
    --- @param hint Event metadata useful for processing.
    --- @return A new event that will be sent | null.
    beforeSendTransaction: ((event: TransactionEvent, hint: EventHint) -> PromiseLike<Event | nil> | Event | nil)?,

    --- A callback invoked when adding a breadcrumb, allowing to optionally modify
    --- it before adding it to future events.
    ---
    --- Note that you must return a valid breadcrumb from this callback. If you do
    --- not wish to modify the breadcrumb, simply return it at the end.
    --- Returning null will cause the breadcrumb to be dropped.
    ---
    --- @param breadcrumb The breadcrumb as created by the SDK.
    --- @return The breadcrumb that will be added | null.
    beforeBreadcrumb: ((breadcrumb: Breadcrumb, hint: BreadcrumbHint?) -> Breadcrumb | nil)?,
}

--- Base configuration options for every SDK.
export type Options<TO = BaseTransportOptions> = ClientOptions<TO> & {
    --- If this is set to false, default integrations will not be added, otherwise this will internally be set to the
    --- recommended default integrations.
    defaultIntegrations: (false | Array<Integration>)?,

    --- List of integrations that should be installed after SDK was initialized.
    --- Accepts either a list of integrations or a function that receives
    --- default integrations and returns a new, updated list.
    integrations: (Array<Integration> | ((integrations: Array<Integration>) -> Array<Integration>))?,

    --- A function that takes transport options and returns the Transport object which is used to send events to Sentry.
    --- The function is invoked internally during SDK initialization.
    --- By default, the SDK initializes its default transports.
    transport: ((transportOptions: TO) -> Transport)?,

    --- A stack parser implementation or an array of stack line parsers
    --- By default, a stack parser is supplied for all supported browsers
    stackParser: (StackParser | Array<StackLineParser>)?,
}

export type RecordDroppedEvent<O> = (
    self: Client<O>,
    reason: EventDropReason,
    dataCategory: DataCategory,
    event: Event?
) -> ()

--- Register a callback for transaction start and finish.
type HookOnFinallyTransaction<O> = (
    self: Client<O>,
    hook: "startTransaction" | "finishTransaction",
    callback: (transaction: Transaction) -> ()
) -> ()

--- Register a callback for transaction start and finish.
type HookOnBeforeEnvelope<O> = (self: Client<O>, hook: "beforeEnvelope", callback: (envelope: Envelope) -> ()) -> ()

--- Register a callback for when an event has been sent.
type HookOnAfterSendEvent<O> = (
    self: Client<O>,
    hook: "afterSendEvent",
    callback: (event: Event, sendResponse: TransportMakeRequestResponse | nil) -> ()
) -> ()

--- Register a callback before a breadcrumb is added.
type HookOnBeforeAddBreadcrumb<O> = (
    self: Client<O>,
    hook: "beforeAddBreadcrumb",
    callback: (breadcrumb: Breadcrumb, hint: BreadcrumbHint?) -> ()
) -> ()

--- Register a callback when a DSC (Dynamic Sampling Context) is created.
type HookOnCreateDsc<O> = (self: Client<O>, hook: "createDsc", callback: (dsc: DynamicSamplingContext) -> ()) -> ()

type OnHook<O> =
    HookOnFinallyTransaction<O>
    | HookOnBeforeEnvelope<O>
    | HookOnAfterSendEvent<O>
    | HookOnBeforeAddBreadcrumb<O>
    | HookOnCreateDsc<O>

--- Fire a hook event for transaction start and finish. Expects to be given a transaction as the
--- second argument.
type HookEmitFinallyTransaction<O> = (
    self: Client<O>,
    hook: "startTransaction" | "finishTransaction",
    transaction: Transaction
) -> ()

--- Fire a hook event for envelope creation and sending. Expects to be given an envelope as the
--- second argument.
type HookEmitBeforeEnvelope<O> = (self: Client<O>, hook: "beforeEnvelope", envelope: Envelope) -> ()

--- Fire a hook event after sending an event. Expects to be given an Event as the
--- second argument.
type HookEmitAfterSendEvent<O> = (
    self: Client<O>,
    hook: "afterSendEvent",
    event: Event,
    sendResponse: TransportMakeRequestResponse | nil
) -> ()

--- Fire a hook for when a breadcrumb is added. Expects the breadcrumb as second argument.
type HookEmitBeforeAddBreadcrumb<O> = (
    self: Client<O>,
    hook: "beforeAddBreadcrumb",
    breadcrumb: Breadcrumb,
    hint: BreadcrumbHint?
) -> ()

--- Fire a hook for when a DSC (Dynamic Sampling Context) is created. Expects the DSC as second argument.
type HookEmitCreateDsc<O> = (self: Client<O>, hook: "createDsc", dsc: DynamicSamplingContext) -> ()

type EmitHook<O> =
    HookEmitFinallyTransaction<O>
    | HookEmitBeforeEnvelope<O>
    | HookEmitAfterSendEvent<O>
    | HookEmitBeforeAddBreadcrumb<O>
    | HookEmitCreateDsc<O>

--- User-Facing Sentry SDK Client.
---
--- This interface contains all methods to interface with the SDK once it has
--- been installed. It allows to send events to Sentry, record breadcrumbs and
--- set a context included in every event. Since the SDK mutates its environment,
--- there will only be one instance during runtime.
export type Client<O = ClientOptions> = {
    --- Captures an exception event and sends it to Sentry.
    ---
    --- @param exception -- An exception-like object.
    --- @param hint -- May contain additional information about the original exception.
    --- @param scope -- An optional scope containing event metadata.
    --- @return The event id
    captureException: (self: Client<O>, exception: any, hint: EventHint?, scope: Scope?) -> string | nil,
    --- Captures a message event and sends it to Sentry.
    ---
    --- @param message -- The message to send to Sentry.
    --- @param level -- Define the level of the message.
    --- @param hint -- May contain additional information about the original exception.
    --- @param scope -- An optional scope containing event metadata.
    --- @return The event id
    captureMessage: (
        self: Client<O>,
        message: string,
        level: SeverityLevel?,
        hint: EventHint?,
        scope: Scope?
    ) -> string | nil,

    --- Captures a manually created event and sends it to Sentry.
    ---
    --- @param event -- The event to send to Sentry.
    --- @param hint -- May contain additional information about the original exception.
    --- @param scope -- An optional scope containing event metadata.
    --- @return The event id
    captureEvent: (self: Client<O>, event: Event, hint: EventHint?, scope: Scope?) -> string | nil,

    --- Captures a session
    ---
    --- @param session -- Session to be delivered
    captureSession: ((self: Client<O>, session: Session) -> ()) | nil,

    --- Create a cron monitor check in and send it to Sentry. This method is not available on all clients.
    ---
    --- @param checkIn -- An object that describes a check in.
    --- @param upsertMonitorConfig -- An optional object that describes a monitor config. Use this if you want
    --- to create a monitor automatically when sending a check in.
    --- @param scope -- An optional scope containing event metadata.
    --- @return A string representing the id of the check in.
    captureCheckIn: ((
        self: Client<O>,
        checkIn: CheckIn,
        monitorConfig: MonitorConfig?,
        scope: Scope?
    ) -> string) | nil,

    --- Returns the current Dsn.
    getDsn: (self: Client<O>) -> DsnComponents | nil,

    --- Returns the current options.
    getOptions: (self: Client<O>) -> O,

    getSdkMetadata: (self: Client<O>) -> SdkMetadata | nil,

    --- Returns the transport that is used by the client.
    --- Please note that the transport gets lazy initialized so it will only be there once the first event has been sent.
    ---
    --- @return The transport.
    getTransport: (self: Client<O>) -> Transport | nil,

    --- Flush the event queue and set the client to `enabled = false`. See {@link Client.flush}.
    ---
    --- @param timeout -- Maximum time in ms the client should wait before shutting down. Omitting this parameter will cause
    ---   the client to wait until all events are sent before disabling itself.
    --- @return A promise which resolves to `true` if the flush completes successfully before the timeout, or `false` if
    --- it doesn't.
    close: (self: Client<O>, timeout: number?) -> PromiseLike<boolean>,

    --- Wait for all events to be sent or the timeout to expire, whichever comes first.
    ---
    --- @param timeout -- Maximum time in ms the client should wait for events to be flushed. Omitting this parameter will
    ---   cause the client to wait until all events are sent before resolving the promise.
    --- @return A promise that will resolve with `true` if all events are sent before the timeout, or `false` if there are
    --- still events in the queue when the timeout is reached.
    flush: (self: Client<O>, timeout: number?) -> PromiseLike<boolean>,

    getIntegration: <T>(self: Client<O>, integration: IntegrationClass<T>) -> T | nil,

    --- Add an integration to the client.
    --- This can be used to e.g. lazy load integrations.
    --- In most cases, this should not be necessary, and you're better off just passing the integrations via `integrations: []` at initialization time.
    --- However, if you find the need to conditionally load & add an integration, you can use `addIntegration` to do so.
    addIntegration: (self: Client<O>, integration: Integration) -> (),

    --- This is an internal function to setup all integrations that should run on the client.
    setupIntegrations: (self: Client<O>) -> (),

    --- Creates an {@link Event} from all inputs to `captureException` and non-primitive inputs to `captureMessage`.
    eventFromException: (self: Client<O>, exception: any, hint: EventHint?) -> PromiseLike<Event>,

    --- Creates an {@link Event} from primitive inputs to `captureMessage`.
    eventFromMessage: (
        self: Client<O>,
        message: string,
        level: SeverityLevel?,
        hint: EventHint?
    ) -> PromiseLike<Event>,

    --- Submits the event to Sentry.
    sendEvent: (self: Client<O>, event: Event, hint: EventHint?) -> (),

    --- Submits the session to Sentry.
    sendSession: (self: Client<O>, session: Session | SessionAggregates) -> (),

    --- Record on the client that an event got dropped (ie, an event that will not be sent to sentry).
    ---
    --- @param reason -- The reason why the event got dropped.
    --- @param category -- The data category of the dropped event.
    --- @param event -- The dropped event.
    recordDroppedEvent: RecordDroppedEvent<O>,

    -- HOOKS
    on: OnHook<O>,
    emit: EmitHook<O>,
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/envelope.ts

-- Based on: https://develop.sentry.dev/sdk/envelopes/

local User = require(PackageRoot.user)
type UserFeedback = User.UserFeedback

type Map<K, V> = { [K]: V }
type Array<T> = { T }

export type DynamicSamplingContext = {
    trace_id: string,
    public_key: string,
    sample_rate: string?,
    release: string?,
    environment: string?,
    transaction: string?,
    user_segment: string?,
    replay_id: string?,
    sampled: string?,
}

export type EnvelopeItemType =
    "client_report"
    | "user_report"
    | "session"
    | "sessions"
    | "transaction"
    | "attachment"
    | "event"
    | "profile"
    | "replay_event"
    | "replay_recording"
    | "check_in"

export type BaseEnvelopeHeaders = Map<string, unknown> & {
    dsn: string?,
    sdk: SdkInfo?,
}

export type BaseEnvelopeItemHeaders = Map<string, unknown> & {
    type: EnvelopeItemType,
    length: number?,
}

-- deviation: This is a tuple in Typescript, but there is no equivalent in Luau. Tables are the most obvious
--  alternative.
type BaseEnvelopeItem<ItemHeaders, Payload> = {
    headers: ItemHeaders & BaseEnvelopeItemHeaders,
    payload: Payload,
}

-- deviation: This is a tuple in Typescript, but there is no equivalent in Luau. Tables are the most obvious
--  alternative.
type BaseEnvelope<EnvelopeHeaders, Item> = {
    headers: EnvelopeHeaders & BaseEnvelopeHeaders,
    items: Array<Item & BaseEnvelopeItem<BaseEnvelopeItemHeaders, unknown>>,
}

type EventItemHeaders = {
    type: "event" | "transaction" | "profile",
}
type AttachmentItemHeaders = {
    type: "attachment",
    length: number,
    filename: string,
    content_type: string?,
    attachment_type: string?,
}
type UserFeedbackItemHeaders = { type: "user_report" }
type SessionItemHeaders = { type: "session" }
type SessionAggregatesItemHeaders = { type: "sessions" }
type ClientReportItemHeaders = { type: "client_report" }
type ReplayEventItemHeaders = { type: "replay_event" }
type ReplayRecordingItemHeaders = { type: "replay_recording", length: number }
type CheckInItemHeaders = { type: "check_in" }

export type EventItem = BaseEnvelopeItem<EventItemHeaders, Event>
export type AttachmentItem = BaseEnvelopeItem<AttachmentItemHeaders, string>
export type UserFeedbackItem = BaseEnvelopeItem<UserFeedbackItemHeaders, UserFeedback>
export type SessionItem =
    -- TODO(v8): Only allow serialized session here (as opposed to Session or SerializedSesison)
    BaseEnvelopeItem<
        SessionItemHeaders,
        Session | SerializedSession
    > | BaseEnvelopeItem<SessionAggregatesItemHeaders, SessionAggregates>
export type ClientReportItem = BaseEnvelopeItem<ClientReportItemHeaders, ClientReport>
export type CheckInItem = BaseEnvelopeItem<CheckInItemHeaders, SerializedCheckIn>
type ReplayEventItem = BaseEnvelopeItem<ReplayEventItemHeaders, ReplayEvent>
type ReplayRecordingItem = BaseEnvelopeItem<ReplayRecordingItemHeaders, ReplayRecordingData>

export type EventEnvelopeHeaders = { event_id: string, sent_at: string, trace: DynamicSamplingContext? }
type SessionEnvelopeHeaders = { sent_at: string }
type CheckInEnvelopeHeaders = { trace: DynamicSamplingContext? }
type ClientReportEnvelopeHeaders = BaseEnvelopeHeaders
type ReplayEnvelopeHeaders = BaseEnvelopeHeaders

export type EventEnvelope = BaseEnvelope<EventEnvelopeHeaders, EventItem | AttachmentItem | UserFeedbackItem>
export type SessionEnvelope = BaseEnvelope<SessionEnvelopeHeaders, SessionItem>
export type ClientReportEnvelope = BaseEnvelope<ClientReportEnvelopeHeaders, ClientReportItem>
-- deviation: This is a tuple in Typescript, but there is no equivalent in Luau. Tables are the most obvious
--  alternative.
export type ReplayEnvelope = {
    headers: ReplayEnvelopeHeaders,
    items: {
        eventItem: ReplayEventItem,
        recordingItem: ReplayRecordingItem,
    },
}

export type CheckInEnvelope = BaseEnvelope<CheckInEnvelopeHeaders, CheckInItem>

export type Envelope = EventEnvelope | SessionEnvelope | ClientReportEnvelope | ReplayEnvelope | CheckInEnvelope
export type EnvelopeItem =
    EventItem
    | AttachmentItem
    | UserFeedbackItem
    | SessionItem
    | ClientReportItem
    | ReplayEventItem
    | ReplayRecordingItem
    | CheckInItem

export type EnvelopeHeaders =
    EventEnvelopeHeaders
    | SessionEnvelopeHeaders
    | ClientReportEnvelopeHeaders
    | ReplayEnvelopeHeaders
    | CheckInEnvelopeHeaders

export type EnvelopeItems =
    EventItem
    | AttachmentItem
    | UserFeedbackItem
    | SessionItem
    | ClientReportItem
    | ReplayEventItem
    | ReplayRecordingItem
    | CheckInItem

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/transport.ts

export type TransportRequest = {
    body: string,
}

export type TransportMakeRequestResponse = {
    statusCode: number?,
    headers: (Map<string, string> & {
        --   "x-sentry-rate-limits": string | nil;
        --   "retry-after": string | nil;
    })?,
    body: any,
}

export type InternalBaseTransportOptions = {
    bufferSize: number?,
    recordDroppedEvent: RecordDroppedEvent<BaseTransportOptions>?,
    textEncoder: TextEncoderInternal?,
}

export type BaseTransportOptions = InternalBaseTransportOptions & {
    --- url to send the event
    --- transport does not care about dsn specific - client should take care of
    --- parsing and figuring that out
    url: string,
}

export type Transport = {
    send: (request: Envelope) -> PromiseLike<TransportMakeRequestResponse>,
    flush: (timeout: number?) -> PromiseLike<boolean>,
}

export type TransportRequestExecutor = (request: TransportRequest) -> PromiseLike<TransportMakeRequestResponse>

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/event.ts

type User = User.User

local Error = require(PackageRoot.error)
type Error = Error.Error

export type Event = {
    event_id: string?,
    message: string?,
    timestamp: number?,
    start_timestamp: number?,
    level: SeverityLevel?,
    platform: string?,
    logger: string?,
    server_name: string?,
    release: string?,
    dist: string?,
    environment: string?,
    sdk: SdkInfo?,
    -- request: Request?,
    transaction: string?,
    modules: Map<string, string>?,
    fingerprint: Array<string>?,
    exception: {
        values: Array<Exception>?,
    }?,
    breadcrumbs: Array<Breadcrumb>?,
    contexts: Contexts?,
    tags: Map<string, Primitive>?,
    extra: Extras?,
    user: User?,
    type: EventType?,
    spans: Array<Span>?,
    measurements: Measurements?,
    debug_meta: DebugMeta?,
    -- A place to stash data which is needed at some point in the SDK's event processing pipeline but which shouldn't get sent to Sentry
    sdkProcessingMetadata: Map<string, any>?,
    transaction_info: {
        source: TransactionSource,
    }?,
    threads: {
        values: Array<Thread>,
    }?,
}

--- The type of an `Event`.
--- Note that `ErrorEvent`s do not have a type (hence its undefined),
--- while all other events are required to have one.
export type EventType = "transaction" | "profile" | "replay_event" | nil

export type ErrorEvent = Event & {
    type: nil,
}
export type TransactionEvent = Event & {
    type: "transaction",
}

export type EventHint = {
    event_id: string?,
    captureContext: CaptureContext?,
    syntheticException: (Error | nil)?,
    originalException: unknown?,
    attachments: Array<Attachment>?,
    data: any?,
    integrations: Array<string>?,
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/eventprocessor.ts

--- Event processors are used to change the event before it will be send.
--- We strongly advise to make this function sync.
--- Returning a PromiseLike<Event | null> will work just fine, but better be sure that you know what you are doing.
--- Event processing will be deferred until your Promise is resolved.
export type EventProcessor = {
    -- deviation: Luau doesn't have Typescript's interface syntax, so we have to make `fn` named property.
    fn: (event: Event, hint: EventHint) -> PromiseLike<Event | nil> | Event | nil,
    id: string?, -- This field can't be named "name" because functions already have this field natively
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/hub.ts

--- Internal class used to make sure we always have the latest internal functions
--- working in case we have a version conflict.

export type Hub = {
    --- Checks if this hub's version is older than the given version.
    ---
    --- @param version -- A version number to compare to.
    --- @return True if the given version is newer; otherwise false.
    ---
    --- @hidden
    isOlderThan: (self: Hub, version: number) -> boolean,

    --- This binds the given client to the current scope.
    --- @param client -- An SDK client (client) instance.
    bindClient: (self: Hub, client: Client?) -> (),

    --- Create a new scope to store context information.
    ---
    --- The scope will be layered on top of the current one. It is isolated, i.e. all
    --- breadcrumbs and context information added to this scope will be removed once
    --- the scope ends. Be sure to always remove this scope with {@link this.popScope}
    --- when the operation finishes or throws.
    ---
    --- @return Scope, the new cloned scope
    pushScope: (self: Hub) -> Scope,

    --- Removes a previously pushed scope from the stack.
    ---
    --- This restores the state before the scope was pushed. All breadcrumbs and
    --- context information added since the last call to {@link this.pushScope} are
    --- discarded.
    popScope: (self: Hub) -> boolean,

    --- Creates a new scope with and executes the given operation within.
    --- The scope is automatically removed once the operation
    --- finishes or throws.
    ---
    --- This is essentially a convenience function for:
    ---
    ---     pushScope();
    ---     callback();
    ---     popScope();
    ---
    --- @param callback -- that will be enclosed into push/popScope.
    withScope: (self: Hub, callback: (scope: Scope) -> ()) -> (),

    --- Returns the client of the top stack.
    getClient: (self: Hub) -> Client | nil,

    --- Returns the scope of the top stack
    getScope: (self: Hub) -> Scope,

    --- Captures an exception event and sends it to Sentry.
    ---
    --- @param exception -- An exception-like object.
    --- @param hint -- May contain additional information about the original exception.
    --- @return The generated eventId.
    captureException: (self: Hub, exception: any, hint: EventHint?) -> string,

    --- Captures a message event and sends it to Sentry.
    ---
    --- @param message -- The message to send to Sentry.
    --- @param level -- Define the level of the message.
    --- @param hint -- May contain additional information about the original exception.
    --- @return The generated eventId.
    captureMessage: (self: Hub, message: string, level: SeverityLevel?, hint: EventHint?) -> string,

    --- Captures a manually created event and sends it to Sentry.
    ---
    --- @param event -- The event to send to Sentry.
    --- @param hint May contain additional information about the original exception.
    captureEvent: (self: Hub, event: Event, hint: EventHint?) -> string,

    --- This is the getter for lastEventId.
    ---
    --- @return The last event id of a captured event.
    lastEventId: (self: Hub) -> string | nil,

    --- Records a new breadcrumb which will be attached to future events.
    ---
    --- Breadcrumbs will be added to subsequent events to provide more context on
    --- user's actions prior to an error or crash.
    ---
    --- @param breadcrumb -- The breadcrumb to record.
    --- @param hint May contain additional information about the original breadcrumb.
    addBreadcrumb: (self: Hub, breadcrumb: Breadcrumb, hint: BreadcrumbHint?) -> (),

    --- Updates user context information for future events.
    ---
    --- @param user -- User context object to be set in the current context. Pass `null` to unset the user.
    setUser: (self: Hub, user: User | nil) -> (),

    --- Set an object that will be merged sent as tags data with the event.
    ---
    --- @param tags -- Tags context object to merge into current context.
    setTags: (self: Hub, tags: Map<string, Primitive>) -> (),

    --- Set key:value that will be sent as tags data with the event.
    ---
    --- Can also be used to unset a tag, by passing `undefined`.
    ---
    --- @param key -- String key of tag
    --- @param value -- Value of tag
    setTag: (self: Hub, key: string, value: Primitive) -> (),

    --- Set key:value that will be sent as extra data with the event.
    --- @param key -- String of extra
    --- @param extra -- Any kind of data. This data will be normalized.
    setExtra: (self: Hub, key: string, extra: Extra) -> (),

    --- Set an object that will be merged sent as extra data with the event.
    --- @param extras -- Extras object to merge into current context.
    setExtras: (self: Hub, extras: Extras) -> (),

    --- Sets context data with the given name.
    --- @param name -- of the context
    --- @param context -- Any kind of data. This data will be normalized.

    setContext: (self: Hub, name: string, context: Map<string, any> | nil) -> (),

    --- Callback to set context information onto the scope.
    ---
    --- @param callback -- Callback function that receives Scope.
    configureScope: (self: Hub, callback: (scope: Scope) -> ()) -> (),

    --- For the duration of the callback, this hub will be set as the global current Hub.
    --- This function is useful if you want to run your own client and hook into an already initialized one
    --- e.g.: Reporting issues to your own sentry when running in your component while still using the users configuration.
    run: (self: Hub, callback: (hub: Hub) -> ()) -> (),

    --- Returns the integration if installed on the current client.
    getIntegration: <T>(self: Hub, integration: IntegrationClass<T>) -> T | nil,

    --- Returns all trace headers that are currently on the top scope.
    traceHeaders: (self: Hub) -> Map<string, string>,

    --- Starts a new `Transaction` and returns it. This is the entry point to manual tracing instrumentation.
    ---
    --- A tree structure can be built by adding child spans to the transaction, and child spans to other spans. To start a
    --- new child span within the transaction or any span, call the respective `.startChild()` method.
    ---
    --- Every child span must be finished before the transaction is finished, otherwise the unfinished spans are discarded.
    ---
    --- The transaction must be finished with a call to its `.finish()` method, at which point the transaction with all its
    --- finished child spans will be sent to Sentry.
    ---
    --- @param context -- Properties of the new `Transaction`.
    --- @param customSamplingContext -- Information given to the transaction sampling function (along with context-dependent
    --- default values). See {@link Options.tracesSampler}.
    ---
    --- @return The transaction which was just started
    startTransaction: (
        self: Hub,
        context: TransactionContext,
        customSamplingContext: CustomSamplingContext?
    ) -> Transaction,

    --- Starts a new `Session`, sets on the current scope and returns it.
    ---
    --- To finish a `session`, it has to be passed directly to `client.captureSession`, which is done automatically
    --- when using `hub.endSession()` for the session currently stored on the scope.
    ---
    --- When there's already an existing session on the scope, it'll be automatically ended.
    ---
    --- @param context -- Optional properties of the new `Session`.
    ---
    --- @return The session which was just started
    startSession: (self: Hub, context: Session?) -> Session,

    --- Ends the session that lives on the current scope and sends it to Sentry
    endSession: (self: Hub) -> (),

    --- Sends the current session on the scope to Sentry
    --- @param endSession -- If set the session will be marked as exited and removed from the scope
    captureSession: (self: Hub, endSession: boolean?) -> (),

    --- Returns if default PII should be sent to Sentry and propagated in outgoing requests
    --- when Tracing is used.
    shouldSendDefaultPii: (self: Hub) -> boolean,
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/integration.ts

--- Integration Class Interface
export type IntegrationClass<T> = {
    --- Property that holds the integration name
    id: string,

    new: (...any) -> T,
}

--- Integration interface
export type Integration = {
    --- Returns {@link IntegrationClass.id}
    name: string,

    --- Sets the integration up only once.
    --- This takes no options on purpose, options should be passed in the constructor
    setupOnce: (
        self: Integration,
        addGlobalEventProcessor: (callback: EventProcessor) -> (),
        getCurrentHub: () -> Hub
    ) -> (),
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/replay.ts

---  NOTE: These types are still considered Beta and subject to change.
export type ReplayEvent = Event & {
    urls: Array<string>,
    replay_start_timestamp: number?,
    error_ids: Array<string>,
    trace_ids: Array<string>,
    replay_id: string,
    segment_id: number,
    replay_type: ReplayRecordingMode,
}

---  NOTE: These types are still considered Beta and subject to change.
export type ReplayRecordingData = string

---  NOTE: These types are still considered Beta and subject to change.
export type ReplayRecordingMode = "session" | "buffer"

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/scope.ts

export type CaptureContext = Scope | ScopeContext | ((scope: Scope) -> Scope)

export type ScopeContext = {
    user: User,
    level: SeverityLevel,
    extra: Extras,
    contexts: Contexts,
    tags: Map<string, Primitive>,
    fingerprint: Array<string>,
    requestSession: RequestSession,
    propagationContext: PropagationContext,
}

--- Holds additional event information. {@link Scope.applyToEvent} will be called by the client before an event is sent.
export type Scope = {
    --- Add new event processor that will be called after {@link applyToEvent}.
    addEventProcessor: (self: Scope, callback: EventProcessor) -> Scope,

    --- Applies data from the scope to the event and runs all event processors on it.
    ---
    --- @param event Event
    --- @param hint Object containing additional information about the original exception, for use by the event processors.
    --- @hidden
    applyToEvent: (self: Scope, event: Event, hint_: EventHint?) -> PromiseLike<Event | nil>,

    --- Updates user context information for future events.
    ---
    --- @param user User context object to be set in the current context. Pass `null` to unset the user.
    setUser: (self: Scope, user: User | nil) -> Scope,

    --- Returns the `User` if there is one
    getUser: (self: Scope) -> User | nil,

    --- Set an object that will be merged sent as tags data with the event.
    --- @param tags Tags context object to merge into current context.
    setTags: (self: Scope, tags: Map<string, Primitive>) -> Scope,

    --- Set key:value that will be sent as tags data with the event.
    ---
    --- Can also be used to unset a tag by passing `undefined`.
    ---
    --- @param key String key of tag
    --- @param value Value of tag
    setTag: (self: Scope, key: string, value: Primitive) -> Scope,

    --- Set an object that will be merged sent as extra data with the event.
    --- @param extras Extras object to merge into current context.
    setExtras: (self: Scope, extras: Extras) -> Scope,

    --- Set key:value that will be sent as extra data with the event.
    --- @param key String of extra
    --- @param extra Any kind of data. This data will be normalized.
    setExtra: (self: Scope, key: string, extra: Extra) -> Scope,

    --- Sets the fingerprint on the scope to send with the events.
    --- @param fingerprint string[] to group events in Sentry.
    setFingerprint: (self: Scope, fingerprint: Array<string>) -> Scope,

    --- Sets the level on the scope for future events.
    --- @param level string {@link SeverityLevel}
    setLevel: (self: Scope, level: SeverityLevel) -> Scope,

    --- Sets the transaction name on the scope for future events.
    setTransactionName: (self: Scope, name: string?) -> Scope,

    --- Sets context data with the given name.
    --- @param name of the context
    --- @param context an object containing context data. This data will be normalized. Pass `nil` to unset the context.
    setContext: (self: Scope, name: string, context: Context | nil) -> Scope,

    --- Sets the Span on the scope.
    --- @param span Span
    setSpan: (self: Scope, span: Span?) -> Scope,

    --- Returns the `Span` if there is one
    getSpan: (self: Scope) -> Span | nil,

    --- Returns the `Transaction` attached to the scope (if there is one)
    getTransaction: (self: Scope) -> Transaction | nil,

    --- Returns the `Session` if there is one
    getSession: (self: Scope) -> Session | nil,

    --- Sets the `Session` on the scope
    setSession: (self: Scope, session: Session?) -> Scope,

    --- Returns the `RequestSession` if there is one
    getRequestSession: (self: Scope) -> RequestSession | nil,

    --- Sets the `RequestSession` on the scope
    setRequestSession: (self: Scope, requestSession: RequestSession?) -> Scope,

    --- Updates the scope with provided data. Can work in three variations:
    --- - plain object containing updatable attributes
    --- - Scope instance that'll extract the attributes from
    --- - callback function that'll receive the current scope as an argument and allow for modifications
    --- @param captureContext scope modifier to be used
    update: (self: Scope, captureContext: CaptureContext?) -> Scope,

    --- Clears the current scope and resets its properties.
    clear: (self: Scope) -> Scope,

    --- Sets the breadcrumbs in the scope
    --- @param breadcrumbs Breadcrumb
    --- @param maxBreadcrumbs number of max breadcrumbs to merged into event.
    addBreadcrumb: (self: Scope, breadcrumb: Breadcrumb, maxBreadcrumbs: number?) -> Scope,

    --- Get the last breadcrumb.
    getLastBreadcrumb: (self: Scope) -> Breadcrumb | nil,

    --- Clears all currently set Breadcrumbs.
    clearBreadcrumbs: (self: Scope) -> Scope,

    --- Adds an attachment to the scope
    --- @param attachment Attachment options
    addAttachment: (self: Scope, attachment: Attachment) -> Scope,

    --- Returns an array of attachments on the scope
    getAttachments: (self: Scope) -> Array<Attachment>,

    --- Clears attachments from the scope
    clearAttachments: (self: Scope) -> Scope,

    --- Add data which will be accessible during event processing but won't get sent to Sentry
    setSDKProcessingMetadata: (self: Scope, newData: Map<string, unknown>) -> Scope,

    --- Add propagation context to the scope, used for distributed tracing
    setPropagationContext: (self: Scope, context: PropagationContext) -> Scope,

    --- Get propagation context from the scope, used for distributed tracing
    getPropagationContext: (self: Scope) -> PropagationContext,
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/span.ts

--- Interface holding all properties that can be set on a Span on creation.
export type SpanContext = {
    --- Description of the Span.
    description: string?,

    --- Operation of the Span.
    op: string?,

    --- Completion status of the Span.
    --- See: {@sentry/tracing SpanStatus} for possible values
    status: string?,

    --- Parent Span ID
    parentSpanId: string?,

    --- Was this span chosen to be sent as part of the sample?
    sampled: boolean?,

    --- Span ID
    spanId: string?,

    --- Trace ID
    traceId: string?,

    --- Tags of the Span.
    tags: Map<string, Primitive>?,

    --- Data of the Span.
    data: Map<string, any>?,

    --- Timestamp in seconds (epoch time) indicating when the span started.
    startTimestamp: number?,

    --- Timestamp in seconds (epoch time) indicating when the span ended.
    endTimestamp: number?,

    --- The instrumenter that created this span.
    instrumenter: Instrumenter?,
}

--- Span holding trace_id, span_id
export type Span = SpanContext & {
    --- @inheritDoc
    spanId: string,

    --- @inheritDoc
    traceId: string,

    --- @inheritDoc
    startTimestamp: number,

    --- @inheritDoc
    tags: Map<string, Primitive>,

    --- @inheritDoc
    data: Map<string, any>,

    --- The transaction containing this span
    transaction: Transaction?,

    --- The instrumenter that created this span.
    instrumenter: Instrumenter,

    --- Sets the finish timestamp on the current span.
    --- @param endTimestamp Takes an endTimestamp if the end should not be the time when you call this function.
    finish: (self: Span, endTimestamp: number?) -> (),

    --- Sets the tag attribute on the current span.
    ---
    --- Can also be used to unset a tag, by passing `undefined`.
    ---
    --- @param key Tag key
    --- @param value Tag value
    setTag: (self: Span, key: string, value: Primitive) -> Span,

    --- Sets the data attribute on the current span
    --- @param key Data key
    --- @param value Data value
    setData: (self: Span, key: string, value: any) -> Span,

    --- Sets the status attribute on the current span
    --- See: {@sentry/tracing SpanStatus} for possible values
    --- @param status http code used to set the status
    setStatus: (self: Span, status: string) -> Span,

    --- Sets the status attribute on the current span based on the http code
    --- @param httpStatus http code used to set the status
    setHttpStatus: (self: Span, httpStatus: number) -> Span,

    --- Creates a new `Span` while setting the current `Span.id` as `parentSpanId`.
    --- Also the `sampled` decision will be inherited.
    startChild: (self: Span, spanContext: SpanContext?) -> Span,

    --- Determines whether span was successful (HTTP200)
    isSuccess: (self: Span) -> boolean,

    --- Return a traceparent compatible header string
    toTraceparent: (self: Span) -> string,

    --- Returns the current span properties as a `SpanContext`
    toContext: (self: Span) -> SpanContext,

    --- Updates the current span with a new `SpanContext`
    updateWithContext: (self: Span, spanContext: SpanContext) -> Span,

    --- Convert the object to JSON for w. spans array info only
    getTraceContext: (
        self: Span
    ) -> {
        data: Map<string, any>?,
        description: string?,
        op: string?,
        parent_span_id: string?,
        span_id: string,
        status: string?,
        tags: Map<string, Primitive>?,
        trace_id: string,
    },

    --- Convert the object to JSON
    toJSON: (
        self: Span
    ) -> {
        data: Map<string, any>,
        description: string?,
        op: string?,
        parent_span_id: string?,
        span_id: string,
        start_timestamp: number,
        status: string?,
        tags: Map<string, Primitive>?,
        timestamp: number?,
        trace_id: string,
    },
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/tracing.ts

-- deviation: No support for RegExp currently
-- export type TracePropagationTargets = Array<string | RegExp>;
export type TracePropagationTargets = Array<string>

export type PropagationContext = {
    traceId: string,
    spanId: string,
    sampled: boolean,
    parentSpanId: string?,
    dsc: DynamicSamplingContext?,
}

-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/transaction.ts

local Measurement = require(PackageRoot.measurement)
type MeasurementUnit = Measurement.MeasurementUnit

--- Interface holding Transaction-specific properties
export type TransactionContext = SpanContext & {

    --- Human-readable identifier for the transaction
    name: string,

    --- If true, sets the end timestamp of the transaction to the highest timestamp of child spans, trimming
    --- the duration of the transaction. This is useful to discard extra time in the transaction that is not
    --- accounted for in child spans, like what happens in the idle transaction Tracing integration, where we finish the
    --- transaction after a given "idle time" and we don't want this "idle time" to be part of the transaction.
    trimEnd: boolean?,

    --- If this transaction has a parent, the parent's sampling decision
    parentSampled: boolean?,

    --- Metadata associated with the transaction, for internal SDK use.
    metadata: Partial<TransactionMetadata>,
}

-- deviation: Luau has no equivalent of Typescript's Pick type, manually write the interface
--- Data pulled from a `sentry-trace` header
-- export type TraceparentData = Pick<TransactionContext, "traceId" | "parentSpanId" | "parentSampled">
export type TraceparentData = {
    traceId: string?,
    parentSpanId: string?,
    parentSampled: boolean?,
}

--- Transaction "Class", inherits Span only has `setName`
export type Transaction = TransactionContext & Span & {

    --- @inheritDoc
    spanId: string,

    --- @inheritDoc
    traceId: string,

    --- @inheritDoc
    startTimestamp: number,

    --- @inheritDoc
    tags: Map<string, Primitive>,

    --- @inheritDoc
    data: Map<string, any>,

    --- Metadata about the transaction
    metadata: TransactionMetadata,

    --- The instrumenter that created this transaction.
    instrumenter: Instrumenter,

    --- Set the name of the transaction
    setName: (self: Transaction, name: string, source: TransactionSource?) -> (),

    --- Set the context of a transaction event
    setContext: (self: Transaction, key: string, context: Context) -> (),

    --- Set observed measurement for this transaction.
    ---
    --- @param name Name of the measurement
    --- @param value Value of the measurement
    --- @param unit Unit of the measurement. (Defaults to an empty string)
    setMeasurement: (self: Transaction, name: string, value: number, unit: MeasurementUnit) -> (),

    --- Returns the current transaction properties as a `TransactionContext`
    toContext: (self: Transaction) -> TransactionContext,

    ---Updates the current transaction with a new `TransactionContext`
    updateWithContext: (self: Transaction, transactionContext: TransactionContext) -> Transaction,

    --- Set metadata for this transaction.
    --- @hidden
    setMetadata: (self: Transaction, newMetadata: Partial<TransactionMetadata>) -> (),

    --- Return the current Dynamic Sampling Context of this transaction
    getDynamicSamplingContext: (self: Transaction) -> Partial<DynamicSamplingContext>,
}

--- Context data passed by the user when starting a transaction, to be used by the tracesSampler method.
export type CustomSamplingContext = Map<string, any>

--- Data passed to the `tracesSampler` function, which forms the basis for whatever decisions it might make.
---
--- Adds default data to data provided by the user. See {@link Hub.startTransaction}
export type SamplingContext = CustomSamplingContext & {

    --- Context data with which transaction being sampled was created
    transactionContext: TransactionContext,

    --- Sampling decision from the parent transaction, if any.
    parentSampled: boolean?,

    --- Object representing the URL of the current page or worker script. Passed by default when using the `BrowserTracing`
    --- integration.
    -- location: WorkerLocation?,

    --- Object representing the incoming request to a node server. Passed by default when using the TracingHandler.
    -- request: ExtractedNodeRequestData?,
}

export type TransactionMetadata = {
    --- The sample rate used when sampling this transaction
    sampleRate: number?,

    --- The Dynamic Sampling Context of a transaction. If provided during transaction creation, its Dynamic Sampling
    --- Context Will be frozen
    dynamicSamplingContext: Partial<DynamicSamplingContext>,

    --- For transactions tracing server-side request handling, the request being tracked.
    --- deviation: Not applicable to Luau currently.
    -- request: PolymorphicRequest?,

    ---Compatibility shim for transitioning to the `RequestData` integration. The options passed to our Express request
    --- handler controlling what request data is added to the event.
    --- TODO (v8): This should go away
    requestDataOptionsFromExpressHandler: Map<string, unknown>?,

    --- For transactions tracing server-side request handling, the path of the request being tracked.
    ---TODO: If we rm -rf `instrumentServer`, this can go, too
    requestPath: string?,

    ---Information on how a transaction name was generated.
    source: TransactionSource,

    ---Metadata for the transaction's spans, keyed by spanId
    spanMetadata: Map<string, Map<string, unknown>>,
}

--- Contains information about how the name of the transaction was determined. This will be used by the server to decide
--- whether or not to scrub identifiers from the transaction name, or replace the entire name with a placeholder.
export type TransactionSource =
    ---User-defined name 
    "custom"
    ---Raw URL, potentially containing identifiers 
    | "url"
    ---Parametrized URL / route 
    | "route"
    ---Name of the view handling the request 
    | "view"
    ---Named after a software component, such as a function or class name. 
    | "component"
    ---Name of a background task (e.g. a Celery task) 
    | "task"

return {}
