-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/client.ts

local Breadcrumb = require("./breadcrumb")
type Breadcrumb = Breadcrumb.Breadcrumb
type BreadcrumbHint = Breadcrumb.BreadcrumbHint

local CheckIn = require("./checkin")
type CheckIn = CheckIn.CheckIn
type MonitorConfig = CheckIn.MonitorConfig

local ClientReport = require("./clientreport")
type EventDropReason = ClientReport.EventDropReason

local DataCategory = require("./datacategory")
type DataCategory = DataCategory.DataCategory

local Dsn = require("./dsn")
type DsnComponents = Dsn.DsnComponents

local Envelope = require("./envelope")
type DynamicSamplingContext = Envelope.DynamicSamplingContext
type Envelope = Envelope.Envelope

local Event = require("./event")
type Event = Event.Event
type EventHint = Event.EventHint

local Integration = require("./integration")
type Integration = Integration.Integration
type IntegrationClass<T> = Integration.IntegrationClass<T>

local Options = require("./options")
type ClientOptions = Options.ClientOptions

local Scope = require("./scope")
type Scope = Scope.Scope

local SdkMetadata = require("./sdkmetadata")
type SdkMetadata = SdkMetadata.SdkMetadata

local Session = require("./session")
type Session = Session.Session
type SessionAggregates = Session.SessionAggregates

local Severity = require("./severity")
type Severity = Severity.Severity
type SeverityLevel = Severity.SeverityLevel

local Transaction = require("./transaction")
type Transaction = Transaction.Transaction

local Transport = require("./transport")
type Transport = Transport.Transport
type TransportMakeRequestResponse = Transport.TransportMakeRequestResponse

local Promise = require("./promise")
type PromiseLike<T> = Promise.PromiseLike<T>

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
type HookOnCreateDsc<O> = (
    self: Client<O>,hook: "createDsc", callback: (dsc: DynamicSamplingContext) -> ()) -> ()

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
    --- @returns The event id
    captureException: (self: Client<O>, exception: any, hint: EventHint?, scope: Scope?) -> string | nil,
    --- Captures a message event and sends it to Sentry.
    ---
    --- @param message -- The message to send to Sentry.
    --- @param level -- Define the level of the message.
    --- @param hint -- May contain additional information about the original exception.
    --- @param scope -- An optional scope containing event metadata.
    --- @returns The event id
    captureMessage: (
        self: Client<O>,
        message: string,
        level: (Severity | SeverityLevel)?,
        hint: EventHint?,
        scope: Scope?
    ) -> string | nil,

    --- Captures a manually created event and sends it to Sentry.
    ---
    --- @param event -- The event to send to Sentry.
    --- @param hint -- May contain additional information about the original exception.
    --- @param scope -- An optional scope containing event metadata.
    --- @returns The event id
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
    --- @returns A string representing the id of the check in.
    captureCheckIn: ((self: Client<O>, checkIn: CheckIn, monitorConfig: MonitorConfig?, scope: Scope?) -> string) | nil,

    --- Returns the current Dsn.
    getDsn: (self: Client<O>) -> DsnComponents | nil,

    --- Returns the current options.
    getOptions: (self: Client<O>) -> O,

    getSdkMetadata: (self: Client<O>) -> SdkMetadata | nil,

    --- Returns the transport that is used by the client.
    --- Please note that the transport gets lazy initialized so it will only be there once the first event has been sent.
    ---
    --- @returns The transport.
    getTransport: (self: Client<O>) -> Transport | nil,

    --- Flush the event queue and set the client to `enabled = false`. See {@link Client.flush}.
    ---
    --- @param timeout -- Maximum time in ms the client should wait before shutting down. Omitting this parameter will cause
    ---   the client to wait until all events are sent before disabling itself.
    --- @returns A promise which resolves to `true` if the flush completes successfully before the timeout, or `false` if
    --- it doesn't.
    close: (self: Client<O>, timeout: number?) -> PromiseLike<boolean>,

    --- Wait for all events to be sent or the timeout to expire, whichever comes first.
    ---
    --- @param timeout -- Maximum time in ms the client should wait for events to be flushed. Omitting this parameter will
    ---   cause the client to wait until all events are sent before resolving the promise.
    --- @returns A promise that will resolve with `true` if all events are sent before the timeout, or `false` if there are
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
        level: (Severity | SeverityLevel)?,
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

return {}
