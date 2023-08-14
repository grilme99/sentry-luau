-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/scope.ts

local PackageRoot = script.Parent

local Attachment = require(PackageRoot.attachment)
type Attachment = Attachment.Attachment

local Breadcrumb = require(PackageRoot.breadcrumb)
type Breadcrumb = Breadcrumb.Breadcrumb

local Context = require(PackageRoot.context)
type Context = Context.Context
type Contexts = Context.Contexts

local EventProcessor = require(PackageRoot.eventprocessor)
type EventProcessor = EventProcessor.EventProcessor

local Extra = require(PackageRoot.extra)
type Extra = Extra.Extra
type Extras = Extra.Extras

local Event = require(PackageRoot.event)
type Event = Event.Event
type EventHint = Event.EventHint

local Misc = require(PackageRoot.misc)
type Primitive = Misc.Primitive

local Session = require(PackageRoot.session)
type RequestSession = Session.RequestSession
type Session = Session.Session

local Severity = require(PackageRoot.severity)
type SeverityLevel = Severity.SeverityLevel

local Span = require(PackageRoot.span)
type Span = Span.Span

local Tracing = require(PackageRoot.tracing)
type PropagationContext = Tracing.PropagationContext

local Transaction = require(PackageRoot.transaction)
type Transaction = Transaction.Transaction

local User = require(PackageRoot.user)
type User = User.User

local Promise = require(PackageRoot.promise)
type PromiseLike<T> = Promise.PromiseLike<T>

type Map<K, V> = { [K]: V }
type Array<T> = { T }

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

return {}
