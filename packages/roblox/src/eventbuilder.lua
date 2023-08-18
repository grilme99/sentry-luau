-- based on: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/eventbuilder.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error

local Promise = require(Packages.Promise)

local Types = require(Packages.SentryTypes)
type Event = Types.Event
type EventHint = Types.EventHint
type Exception = Types.Exception
type SeverityLevel = Types.SeverityLevel
type StackFrame = Types.StackFrame
type StackParser = Types.StackParser
type PromiseLike<T> = Types.PromiseLike<T>

local Core = require(Packages.SentryCore)
local getCurrentHub = Core.getCurrentHub

local Utils = require(Packages.SentryUtils)
local addExceptionMechanism = Utils.addExceptionMechanism
local addExceptionTypeValue = Utils.addExceptionTypeValue
local extractExceptionKeysForMessage = Utils.extractExceptionKeysForMessage
local isError = Utils.isError
local isPlainObject = Utils.isPlainObject
local logger = Utils.logger
local normalizeToSize = Utils.normalizeToSize

type Array<T> = { T }
type Map<K, V> = { [K]: V }

local EventBuilder = {}

--- There are cases where stacktrace.message is an Event object
--- https://github.com/getsentry/sentry-javascript/issues/1949
--- In this specific case we try to extract stacktrace.message.error.message
local function extractMessage(ex: Error & { message: string | { error: Error? } }): string
    local message = ex and ex.message
    if not message then
        return "No error message"
    end
    if type(message) == "table" and message.error and type(message.error.message) == "string" then
        return message.error.message
    end
    return message
end

local function getNonErrorObjectExceptionValue(exception: Map<string, unknown>, isUnhandledRejection: boolean?): string
    local keys = extractExceptionKeysForMessage(exception)
    local captureType = if isUnhandledRejection then "promise rejection" else "exception"

    return `Object captured as {captureType} with keys: {keys}`
end

local function removeLocationFromErrorMessage(errorMessage: string)
    local cleanedMessage = string.match(errorMessage, "^[^:]+:%d+: (.+)$")
    return cleanedMessage or errorMessage
end

--- This function creates an exception from a JavaScript Error
function EventBuilder.exceptionFromError(stackParser: StackParser, ex: Error): Exception
    -- Get the frames first since Opera can lose the stack if we touch anything else first
    local parserErr: Error & { framesToPop: number?, stacktrace: string? } = ex :: any
    parserErr.framesToPop = 2 -- Remove the message from the top

    local frames = EventBuilder.parseStackFrames(stackParser, parserErr)

    local exception: Exception = {
        type = ex and ex.name,
        value = extractMessage(ex),
    }

    if #frames > 0 then
        exception.stacktrace = { frames = frames }
    end

    if exception.type == nil and exception.value == "" then
        exception.value = "Unrecoverable error caught"
    end

    return exception
end

function EventBuilder.eventFromPlainObject(
    stackParser: StackParser,
    exception: Map<string, unknown>,
    syntheticException: Error?,
    isUnhandledRejection: boolean?
): Event
    local hub = getCurrentHub()
    local client = hub:getClient()
    local normalizeDepth = client and client:getOptions().normalizeDepth

    local event: Event = {
        exception = {
            values = {
                {
                    -- TODO: NO clear way how to get the constructor name of the event in Luau
                    -- type = if isEvent(exception)
                    --     then (exception :: Event).constructor.name
                    --     elseif isUnhandledRejection then "UnhandledRejection"
                    type = if isUnhandledRejection then "UnhandledRejection" else "Error",
                    value = getNonErrorObjectExceptionValue(exception, isUnhandledRejection),
                },
            },
        },
        extra = {
            __serialized__ = normalizeToSize(exception, normalizeDepth),
        },
    }

    if syntheticException then
        local frames = EventBuilder.parseStackFrames(stackParser, syntheticException :: any)
        if #frames > 0 then
            -- event.exception.values[1] has been set above
            (event.exception :: { values: Array<Exception> }).values[1].stacktrace = { frames }
        end
    end

    return event
end

function EventBuilder.eventFromError(stackParser: StackParser, ex: Error): Event
    return {
        exception = {
            values = { EventBuilder.exceptionFromError(stackParser, ex) },
        },
    }
end

local function getPopSize(ex: Error & { framesToPop: number? }): number
    if ex and ex.framesToPop then
        return ex.framesToPop
    end

    return 1
end

function EventBuilder.parseStackFrames(
    stackParser: StackParser,
    ex: Error & { framesToPop: number?, stacktrace: string? }
): Array<StackFrame>
    local stacktrace = ex.stacktrace or ex.stack or ""
    local popSize = getPopSize(ex)

    local success, result = pcall(stackParser, stacktrace, popSize)
    if success then
        return result
    else
        if _G.__SENTRY_DEV__ then
            logger.warn(`Failed to parse stack frames:`, result)
        end
    end

    return {}
end

--- Creates an {@link Event} from all inputs to `captureException` and non-primitive inputs to `captureMessage`.
--- @hidden
function EventBuilder.eventFromException(
    stackParser: StackParser,
    exception: unknown,
    hint: EventHint?,
    attachStacktrace: boolean?
): PromiseLike<Event>
    local syntheticException = hint and hint.syntheticException
    local event = EventBuilder.eventFromUnknownInput(stackParser, exception, syntheticException, attachStacktrace)
    addExceptionMechanism(event) -- defaults to { type = "generic", handled = true }
    event.level = "error"
    if hint and hint.event_id then
        event.event_id = hint.event_id
    end
    return Promise.resolve(event)
end

--- Builds and Event from a Message
--- @hidden
function EventBuilder.eventFromMessage(
    stackParser: StackParser,
    message: string,
    level_: SeverityLevel?,
    hint: EventHint?,
    attachStacktrace: boolean?
): PromiseLike<Event>
    local level: SeverityLevel = level_ or "info"

    local syntheticException = (hint and hint.syntheticException) or nil
    local event = EventBuilder.eventFromString(stackParser, message, syntheticException, attachStacktrace)
    event.level = level
    if hint and hint.event_id then
        event.event_id = hint.event_id
    end
    return Promise.resolve(event)
end

function EventBuilder.eventFromUnknownInput(
    stackParser: StackParser,
    exception: unknown,
    syntheticException: Error?,
    attachStacktrace: boolean?,
    isUnhandledRejection: boolean?
): Event
    local event: Event

    -- if isErrorEvent(exception :: ErrorEvent) and (exception :: ErrorEvent).error then
    --     -- If it is an ErrorEvent with `error` property, extract it to get actual Error
    --     local errorEvent = exception :: ErrorEvent
    --     return EventBuilder.eventFromError(stackParser, errorEvent.error :: Error)
    -- end

    if isError(exception) then
        -- we have a real Error object, do nothing
        return EventBuilder.eventFromError(stackParser, exception :: Error)
    end
    if isPlainObject(exception) then
        -- If it's a plain object or an instance of `Event` (the built-in JS kind, not this SDK's `Event` type), serialize
        -- it manually. This will allow us to group events based on top-level keys which is much better than creating a new
        -- group on any key/value change.
        local objectException = exception :: Map<string, unknown>
        event =
            EventBuilder.eventFromPlainObject(stackParser, objectException, syntheticException, isUnhandledRejection)
        addExceptionMechanism(event, {
            synthetic = true,
        })
        return event
    end

    -- If none of previous checks were valid, then it means that it's not:
    -- - an instance of Event
    -- - an instance of Error
    -- - a plain Object
    --
    -- So bail out and capture it as a simple message:
    event = EventBuilder.eventFromString(stackParser, exception :: string, syntheticException, attachStacktrace)
    addExceptionTypeValue(event, `{exception}`, nil)
    addExceptionMechanism(event, {
        synthetic = true,
    })

    return event
end

function EventBuilder.eventFromString(
    stackParser: StackParser,
    input: string,
    syntheticException: Error?,
    attachStacktrace: boolean?
): Event
    local message = removeLocationFromErrorMessage(input)
    local event: Event = {
        message = message,
    }

    if attachStacktrace and syntheticException then
        local frames = EventBuilder.parseStackFrames(stackParser, syntheticException :: any)
        if #frames > 0 then
            event.exception = {
                values = {
                    { value = message, stacktrace = { frames = frames } },
                },
            }
        end
    end

    return event
end

return EventBuilder
