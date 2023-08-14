-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/hub.ts

local PackageRoot = script.Parent

local Breadcrumb = require(PackageRoot.breadcrumb)
type Breadcrumb = Breadcrumb.Breadcrumb
type BreadcrumbHint = Breadcrumb.BreadcrumbHint

local Client = require(PackageRoot.client)
type Client = Client.Client

local Event = require(PackageRoot.event)
type Event = Event.Event
type EventHint = Event.EventHint

local Extra = require(PackageRoot.extra)
type Extra = Extra.Extra
type Extras = Extra.Extras

local Integration = require(PackageRoot.integration)
type Integration = Integration.Integration
type IntegrationClass<T> = Integration.IntegrationClass<T>

local Primitive = require(PackageRoot.misc)
type Primitive = Primitive.Primitive

local Scope = require(PackageRoot.scope)
type Scope = Scope.Scope

local Session = require(PackageRoot.session)
type Session = Session.Session

local Severity = require(PackageRoot.severity)
type SeverityLevel = Severity.SeverityLevel

local Transaction = require(PackageRoot.transaction)
type CustomSamplingContext = Transaction.CustomSamplingContext
type Transaction = Transaction.Transaction
type TransactionContext = Transaction.TransactionContext

local User = require(PackageRoot.user)
type User = User.User

type Map<K, V> = { [K]: V }

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
    getIntegration: <T>(integration: IntegrationClass<T>) -> T | nil,

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

return {}
