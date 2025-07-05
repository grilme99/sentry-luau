-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/integrations/dedupe.ts

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Event = Types.Event
type EventProcessor = Types.EventProcessor
type Exception = Types.Exception
type Hub = Types.Hub
type Integration = Types.Integration
type StackFrame = Types.StackFrame

local Utils = require(Packages.SentryUtils)
local logger = Utils.logger

type Array<T> = { T }

local function _getFramesFromEvent(event: Event): Array<StackFrame> | nil
    local exception = event.exception

    if exception then
        local value = exception and exception.values and exception.values[1]
        return value and value.stacktrace and value.stacktrace.frames
    end
    return nil
end

local function _getExceptionFromEvent(event: Event): Exception | nil
    return event.exception and event.exception.values and event.exception.values[1]
end

local function _isSameFingerprint(currentEvent: Event, previousEvent: Event): boolean
    local currentFingerprint = currentEvent.fingerprint
    local previousFingerprint = previousEvent.fingerprint

    -- If neither event has a fingerprint, they are assumed to be the same
    if not currentFingerprint and not previousFingerprint then
        return true
    end

    -- If only one event has a fingerprint, but not the other one, they are not the same
    if (currentFingerprint and not previousFingerprint) or (not currentFingerprint and previousFingerprint) then
        return false
    end

    local currentFingerprint_ = currentFingerprint :: Array<string>
    local previousFingerprint_ = previousFingerprint :: Array<string>

    -- Otherwise, compare the two
    return not not (table.concat(currentFingerprint_, "") == table.concat(previousFingerprint_, ""))
end

local function _isSameStacktrace(currentEvent: Event, previousEvent: Event): boolean
    local currentFrames = _getFramesFromEvent(currentEvent)
    local previousFrames = _getFramesFromEvent(previousEvent)

    -- If neither event has a stacktrace, they are assumed to be the same
    if not currentFrames and not previousFrames then
        return true
    end

    -- If only one event has a stacktrace, but not the other one, they are not the same
    if (currentFrames and not previousFrames) or (not currentFrames and previousFrames) then
        return false
    end

    local currentFrames_ = currentFrames :: Array<StackFrame>
    local previousFrames_ = previousFrames :: Array<StackFrame>

    -- If number of frames differ, they are not the same
    if #previousFrames_ ~= #currentFrames_ then
        return false
    end

    -- Otherwise, compare the two
    for i = 1, #previousFrames_ do
        local frameA = previousFrames_[i]
        local frameB = currentFrames_[i]

        if
            frameA.filename ~= frameB.filename
            or frameA.lineno ~= frameB.lineno
            or frameA.colno ~= frameB.colno
            or frameA.function_ ~= frameB.function_
        then
            return false
        end
    end

    return true
end

local function _isSameExceptionEvent(currentEvent: Event, previousEvent: Event): boolean
    local previousException = _getExceptionFromEvent(previousEvent)
    local currentException = _getExceptionFromEvent(currentEvent)

    if not previousException or not currentException then
        return false
    end

    if previousException.type ~= currentException.type or previousException.value ~= currentException.value then
        return false
    end

    if not _isSameFingerprint(currentEvent, previousEvent) then
        return false
    end

    if not _isSameStacktrace(currentEvent, previousEvent) then
        return false
    end

    return true
end

local function _isSameMessageEvent(currentEvent: Event, previousEvent: Event): boolean
    local currentMessage = currentEvent.message
    local previousMessage = previousEvent.message

    -- If neither event has a message property, they were both exceptions, so bail out
    if not currentMessage and not previousMessage then
        return false
    end

    -- If only one event has a stacktrace, but not the other one, they are not the same
    if (currentMessage and not previousMessage) or (not currentMessage and previousMessage) then
        return false
    end

    if currentMessage ~= previousMessage then
        return false
    end

    if not _isSameFingerprint(currentEvent, previousEvent) then
        return false
    end

    if not _isSameStacktrace(currentEvent, previousEvent) then
        return false
    end

    return true
end

local function _shouldDropEvent(currentEvent: Event, previousEvent: Event?): boolean
    if not previousEvent then
        return false
    end

    if _isSameMessageEvent(currentEvent, previousEvent) then
        return true
    end

    if _isSameExceptionEvent(currentEvent, previousEvent) then
        return true
    end

    return false
end

local Dedupe = {}
Dedupe.id = "Dedupe"
Dedupe.__index = Dedupe

export type Dedupe = typeof(setmetatable(
    {} :: Integration & {
        _previousEvent: Event?,
    },
    {} :: {
        __index: Dedupe,
    }
))

function Dedupe.new()
    local self: Dedupe = setmetatable({}, Dedupe) :: any
    self.name = Dedupe.id
    return self
end

function Dedupe.setupOnce(
    self: Dedupe,
    addGlobalEventProcessor: (callback: EventProcessor) -> (),
    getCurrentHub: () -> Hub
)
    local function eventProcessor(currentEvent: Event): Event?
        -- We want to ignore any non-error type events, e.g. transactions or replays
        -- These should never be deduped, and also not be compared against as _previousEvent.
        if currentEvent.type then
            return currentEvent
        end

        local this = getCurrentHub():getIntegration(Dedupe)
        if this then
            -- Juuust in case something goes wrong
            if _shouldDropEvent(currentEvent, self._previousEvent) then
                if _G.__SENTRY_DEV__ then
                    logger.warn("Event dropped due to being a duplicate of previously captured event.")
                end
                return nil
            end

            self._previousEvent = currentEvent
            return currentEvent
        end

        return currentEvent
    end

    addGlobalEventProcessor({
        id = self.name,
        fn = eventProcessor,
    })
end

return Dedupe
