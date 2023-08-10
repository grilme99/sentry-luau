-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/utils/prepareEvent.ts

local Types = require("@packages/types")
type ClientOptions = Types.ClientOptions
type Event = Types.Event
type EventHint = Types.EventHint
type StackFrame = Types.StackFrame
type StackParser = Types.StackParser
type Integration = Types.Integration
type DebugMeta = Types.DebugMeta
type DebugImage = Types.DebugImage
type Scope = Types.Scope
type Span = Types.Span
type PromiseLike<T> = Types.PromiseLike<T>

local Utils = require("@packages/utils")
local dateTimestampInSeconds = Utils.dateTimestampInSeconds
local GLOBAL_OBJ = Utils.GLOBAL_OBJ
local normalize = Utils.normalize
local truncate = Utils.truncate
local uuid4 = Utils.uuid4
local Promise = Utils.Promise
local Object = Utils.Polyfill.Object
local Array = Utils.Polyfill.Array

local Constants = require("../constants")
local DEFAULT_ENVIRONMENT = Constants.DEFAULT_ENVIRONMENT

local Scope = require("../scope")

type Array<T> = { T }
type Map<K, V> = { [K]: V }

local PrepareEvent = {}

---  Enhances event using the client configuration.
---  It takes care of all "static" values like environment, release and `dist`,
---  as well as truncating overly long values.
--- @param event event instance to be enhanced
local function applyClientOptions(event: Event, options: ClientOptions)
    -- const { environment, release, dist, maxValueLength = 250 } = options;
    local environment, release, dist, maxValueLength_ =
        options.environment, options.dist, options.dist, options.maxValueLength
    local maxValueLength = maxValueLength_ or 250

    if event.environment == nil then
        event.environment = if options.environment then environment else DEFAULT_ENVIRONMENT
    end

    if event.release == nil and release ~= nil then
        event.release = release
    end

    if event.dist == nil and dist ~= nil then
        event.dist = dist
    end

    if event.message then
        event.message = truncate(event.message, maxValueLength)
    end

    local exception = event.exception and event.exception.values and event.exception.values[1]
    if exception and exception.value then
        exception.value = truncate(exception.value, maxValueLength)
    end

    local request = event.request
    if request and request.url then
        request.url = truncate(request.url, maxValueLength)
    end
end

---  This function adds all used integrations to the SDK info in the event.
--- @param event The event that will be filled with all integrations.
local function applyIntegrationsMetadata(event: Event, integrationNames: Array<string>)
    if #integrationNames > 0 then
        event.sdk = event.sdk or {}
        local sdk = event.sdk :: Types.SdkInfo
        sdk.integrations = Array.concat(sdk.integrations or {}, integrationNames)
    end
end

--- Applies `normalize` function on necessary `Event` attributes to make them safe for serialization.
--- Normalized keys:
--- - `breadcrumbs.data`
--- - `user`
--- - `contexts`
--- - `extra`
--- @param event Event
-- @returns Normalized event
local function normalizeEvent(event: Event | nil, depth: number, maxBreadth: number): Event | nil
    if event == nil then
        return nil
    end

    local normalized: Event = Object.mergeObjects(
        event,
        if event.breadcrumbs
            then {
                breadcrumbs = Array.map(event.breadcrumbs, function(b)
                    return Object.mergeObjects(
                        b,
                        if b.data then { data = normalize(b.data, depth, maxBreadth) } else {}
                    )
                end),
            }
            else {},
        if event.user then { user = normalize(event.user, depth, maxBreadth) } else {},
        if event.contexts then { contexts = normalize(event.contexts, depth, maxBreadth) } else {},
        if event.extra then { extra = normalize(event.extra, depth, maxBreadth) } else {}
    )

    -- event.contexts.trace stores information about a Transaction. Similarly,
    -- event.spans[] stores information about child Spans. Given that a
    -- Transaction is conceptually a Span, normalization should apply to both
    -- Transactions and Spans consistently.
    -- For now the decision is to skip normalization of Transactions and Spans,
    -- so this block overwrites the normalized event to add back the original
    -- Transaction information prior to normalization.
    if event.contexts and event.contexts.trace and normalized.contexts then
        normalized.contexts.trace = event.contexts.trace :: any
        local trace: any = normalized.contexts.trace

        -- event.contexts.trace.data may contain circular/dangerous data so we need to normalize it
        if trace.data then
            trace.data = normalize(trace.data, depth, maxBreadth)
        end
    end

    -- event.spans[].data may contain circular/dangerous data so we need to normalize it
    if event.spans then
        normalized.spans = Array.map(event.spans, function(span: Span)
            -- We cannot use the spread operator here because `toJSON` on `span` is non-enumerable
            if span.data then
                span.data = normalize(span.data, depth, maxBreadth)
            end
            return span
        end)
    end

    return normalized
end

--- Adds common information to events.
---
--- The information includes release and environment from `options`,
--- breadcrumbs and context (extra, tags and user) from the scope.
---
--- Information that is already present in the event is never overwritten. For
--- nested objects, such as the context, keys are merged.
---
--- Note: This also triggers callbacks for `addGlobalEventProcessor`, but not `beforeSend`.
---
--- @param event The original event.
--- @param hint May contain additional information about the original exception.
--- @param scope A scope containing event metadata.
--- @return A new event with more information.
--- @hidden
function PrepareEvent.prepareEvent(
    options: ClientOptions,
    event: Event,
    hint: EventHint,
    scope: Scope?
): PromiseLike<Event | nil>
    --   const { normalizeDepth = 3, normalizeMaxBreadth = 1_000 } = options;
    local normalizeDepth_, normalizeMaxBreadth_ = options.normalizeDepth, options.normalizeMaxBreadth
    local normalizeDepth = normalizeDepth_ or 3
    local normalizeMaxBreadth = normalizeMaxBreadth_ or 1000

    local prepared: Event = Object.mergeObjects(event, {
        event_id = event.event_id or hint.event_id or uuid4(),
        timestamp = event.timestamp or dateTimestampInSeconds(),
    })
    local integrations = hint.integrations
        or Array.map(options.integrations, function(i: Integration)
            return i.name
        end)

    applyClientOptions(prepared, options)
    applyIntegrationsMetadata(prepared, integrations)

    -- Only put debug IDs onto frames for error events.
    if event.type == nil then
        PrepareEvent.applyDebugIds(prepared, options.stackParser)
    end

    -- If we have scope given to us, use it as the base for further modifications.
    -- This allows us to prevent unnecessary copying of data if `captureContext` is not provided.
    local finalScope = scope
    if hint.captureContext then
        finalScope = Scope.clone(finalScope :: any):update(hint.captureContext)
    end

    -- We prepare the result here with a resolved Event.
    local result: PromiseLike<Event | nil> = Promise.resolve()

    -- This should be the last thing called, since we want that
    -- {@link Hub.addEventProcessor} gets the finished prepared event.
    --
    -- We need to check for the existence of `finalScope.getAttachments`
    -- because `getAttachments` can be undefined if users are using an older version
    -- of `@sentry/core` that does not have the `getAttachments` method.
    -- See: https://github.com/getsentry/sentry-javascript/issues/5229
    if finalScope then
        -- Collect attachments from the hint and scope
        if finalScope.getAttachments then
            --   const attachments = [...(hint.attachments || []), ...finalScope.getAttachments()];
            local attachments = Array.concat(hint.attachments or {}, finalScope:getAttachments())

            if #attachments > 0 then
                hint.attachments = attachments
            end
        end

        -- In case we have a hub we reassign it.
        result = finalScope:applyToEvent(prepared, hint)
    end

    return result:andThen(function(evt)
        if evt then
            -- We apply the debug_meta field only after all event processors have ran, so that if any event processors modified
            -- file names (e.g.the RewriteFrames integration) the filename -> debug ID relationship isn't destroyed.
            -- This should not cause any PII issues, since we're only moving data that is already on the event and not adding
            -- any new data
            PrepareEvent.applyDebugMeta(evt)
        end

        if type(normalizeDepth) == "number" and normalizeDepth > 0 then
            return normalizeEvent(evt, normalizeDepth, normalizeMaxBreadth)
        end
        return evt
    end)
end

-- deviation: No WeakMap in Lua. Could this cause problems?
local debugIdStackParserCache: Map<StackParser, Map<string, Array<StackFrame>>> = {}

--- Puts debug IDs into the stack frames of an error event.
function PrepareEvent.applyDebugIds(event: Event, stackParser: StackParser)
    local debugIdMap = GLOBAL_OBJ._sentryDebugIds

    if not debugIdMap then
        return
    end

    local debugIdStackFramesCache: Map<string, Array<StackFrame>>
    local cachedDebugIdStackFrameCache = debugIdStackParserCache[stackParser]
    if cachedDebugIdStackFrameCache then
        debugIdStackFramesCache = cachedDebugIdStackFrameCache
    else
        debugIdStackFramesCache = {}
        debugIdStackParserCache[stackParser] = debugIdStackFramesCache
    end

    -- Build a map of filename -> debug_id
    local debugKeys = Object.keys(debugIdMap)
    local filenameDebugIdMap: Map<string, string> = Array.reduce(debugKeys, function(acc, debugIdStackTrace)
        local parsedStack: Array<StackFrame>
        local cachedParsedStack = debugIdStackFramesCache[debugIdStackTrace]
        if cachedParsedStack then
            parsedStack = cachedParsedStack
        else
            parsedStack = stackParser(debugIdStackTrace)
            debugIdStackFramesCache[debugIdStackTrace] = parsedStack
        end

        for _, stackFrame in parsedStack do
            if stackFrame.filename then
                acc[stackFrame.filename] = debugIdMap[debugIdStackTrace]
                break
            end
        end
        return acc
    end)

    local exceptionValues = event.exception and event.exception.values
    if exceptionValues then
        for _, exception in exceptionValues do
            local frames = exception.stacktrace and exception.stacktrace.frames
            if frames then
                for _, frame in frames do
                    if frame.filename then
                        frame.debug_id = filenameDebugIdMap[frame.filename]
                    end
                end
            end
        end
    end
end

--- Moves debug IDs from the stack frames of an error event into the debug_meta field.
function PrepareEvent.applyDebugMeta(event: Event)
    -- Extract debug IDs and filenames from the stack frames on the event.
    local filenameDebugIdMap: Map<string, string> = {}
    local exceptionValues = event.exception and event.exception.values
    if exceptionValues then
        for _, exception in exceptionValues do
            local frames = exception.stacktrace and exception.stacktrace.frames
            if frames then
                for _, frame in frames do
                    if frame.debug_id then
                        if frame.abs_path then
                            filenameDebugIdMap[frame.abs_path] = frame.debug_id
                        elseif frame.filename then
                            filenameDebugIdMap[frame.filename] = frame.debug_id
                        end
                        frame.debug_id = nil
                    end
                end
            end
        end
    end

    if #Object.keys(filenameDebugIdMap) == 0 then
        return
    end

    -- Fill debug_meta information
    event.debug_meta = event.debug_meta or {}
    local debugMeta = event.debug_meta :: DebugMeta

    debugMeta.images = debugMeta.images or {}
    local images = debugMeta.images :: DebugImage
    for _, filename in Object.keys(filenameDebugIdMap) do
        table.insert(images, {
            type = "sourcemap",
            code_file = filename,
            debug_id = filenameDebugIdMap[filename],
        })
    end
end

return PrepareEvent
