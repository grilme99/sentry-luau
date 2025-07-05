-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/exports.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Breadcrumb = Types.Breadcrumb
type CaptureContext = Types.CaptureContext
type CheckIn = Types.CheckIn
type CustomSamplingContext = Types.CustomSamplingContext
type Event = Types.Event
type EventHint = Types.EventHint
type Extra = Types.Extra
type Extras = Types.Extras
type MonitorConfig = Types.MonitorConfig
type Primitive = Types.Primitive
type SeverityLevel = Types.SeverityLevel
type TransactionContext = Types.TransactionContext
type Transaction = Types.Transaction
type User = Types.User
type Scope = Types.Scope

local Utils = require(Packages.SentryUtils)
local logger = Utils.logger
local uuid4 = Utils.uuid4

local Hub = require(PackageRoot.hub)
type Hub = Hub.Hub
local getCurrentHub = Hub.getCurrentHub

type Map<K, V> = { [K]: V }

local Exports = {}

--- Captures an exception event and sends it to Sentry.
---
--- @param exception An exception-like object.
--- @param captureContext Additional scope data to apply to exception event.
--- @returns The generated eventId.
function Exports.captureException(exception: any, captureContext: CaptureContext?): string
    return getCurrentHub():captureException(exception, { captureContext })
end

--- Captures a message event and sends it to Sentry.
---
--- @param message The message to send to Sentry.
--- @param Severity Define the level of the message.
--- @returns The generated eventId.
function Exports.captureMessage(message: string, captureContext: (CaptureContext | SeverityLevel)?): string
    -- This is necessary to provide explicit scopes upgrade, without changing the original
    -- rarity of the `captureMessage(message, level)` method.
    local level = if type(captureContext) == "string" then captureContext else nil
    local context = if type(captureContext) ~= "string" then { captureContext = captureContext } else nil
    return getCurrentHub():captureMessage(message, level :: SeverityLevel, context)
end

--- Captures a manually created event and sends it to Sentry.
---
--- @param event The event to send to Sentry.
--- @returns The generated eventId.
function Exports.captureEvent(event: Event, hint: EventHint?): string
    return getCurrentHub():captureEvent(event, hint)
end

--- Callback to set context information onto the scope.
--- @param callback Callback function that receives Scope.
function Exports.configureScope(callback: (scope: Scope) -> ())
    getCurrentHub():configureScope(callback)
end

--- Records a new breadcrumb which will be attached to future events.
---
--- Breadcrumbs will be added to subsequent events to provide more context on
--- user's actions prior to an error or crash.
---
--- @param breadcrumb The breadcrumb to record.

function Exports.addBreadcrumb(breadcrumb: Breadcrumb)
    getCurrentHub():addBreadcrumb(breadcrumb)
end

--- Sets context data with the given name.
--- @param name of the context
--- @param context Any kind of data. This data will be normalized.
function Exports.setContext(name: string, context: Map<string, any> | nil)
    getCurrentHub():setContext(name, context)
end

--- Set an object that will be merged sent as extra data with the event.
--- @param extras Extras object to merge into current context.
function Exports.setExtras(extras: Extras)
    getCurrentHub():setExtras(extras)
end

--- Set key:value that will be sent as extra data with the event.
--- @param key String of extra
--- @param extra Any kind of data. This data will be normalized.
function Exports.setExtra(key: string, extra: Extra)
    getCurrentHub():setExtra(key, extra)
end

--- Set an object that will be merged sent as tags data with the event.
--- @param tags Tags context object to merge into current context.
function Exports.setTags(tags: Map<string, Primitive>)
    getCurrentHub():setTags(tags)
end

--- Set key:value that will be sent as tags data with the event.
---
--- Can also be used to unset a tag, by passing `undefined`.
---
--- @param key String key of tag
--- @param value Value of tag
function Exports.setTag(key: string, value: Primitive)
    getCurrentHub():setTag(key, value)
end

--- Updates user context information for future events.
---
--- @param user User context object to be set in the current context. Pass `null` to unset the user.
function Exports.setUser(user: User | nil)
    getCurrentHub():setUser(user)
end

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
--- @param callback that will be enclosed into push/popScope.
function Exports.withScope(callback: (scope: Scope) -> ())
    getCurrentHub():withScope(callback)
end

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
--- NOTE: This function should only be used for ---manual--- instrumentation. Auto-instrumentation should call
--- `startTransaction` directly on the hub.
---
--- @param context Properties of the new `Transaction`.
--- @param customSamplingContext Information given to the transaction sampling function (along with context-dependent
--- default values). See {@link Options.tracesSampler}.
---
--- @returns The transaction which was just started
function Exports.startTransaction(
    context: TransactionContext,
    customSamplingContext: CustomSamplingContext?
): Transaction
    return getCurrentHub():startTransaction(table.clone(context) :: any, customSamplingContext)
end

--- Create a cron monitor check in and send it to Sentry.
---
--- @param checkIn An object that describes a check in.
--- @param upsertMonitorConfig An optional object that describes a monitor config. Use this if you want
--- to create a monitor automatically when sending a check in.
function Exports.captureCheckIn(checkIn: CheckIn, upsertMonitorConfig: MonitorConfig?): string
    local hub = getCurrentHub()
    local scope = hub:getScope()
    local client = hub:getClient()
    local captureCheckIn = client and client.captureCheckIn
    if not client then
        if _G.__SENTRY_DEV__ then
            logger.warn("Cannot capture check-in. No client defined.")
        end
    elseif not captureCheckIn then
        if _G.__SENTRY_DEV__ then
            logger.warn("Cannot capture check-in. Client does not support sending check-ins.")
        end
    else
        return captureCheckIn(client, checkIn, upsertMonitorConfig, scope)
    end

    return uuid4()
end

return Exports
