-- upstream: https://github.com/getsentry/sentry-javascript/blob/d3abf450b844c595dfa576f2afcfe223fb038c51/packages/utils/src/misc.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Event = Types.Event
type Exception = Types.Exception
type Mechanism = Types.Mechanism
type PartialMechanism = Types.PartialMechanism
type StackFrame = Types.StackFrame

local RegExp = require(Packages.RegExp)
type RegExp = RegExp.RegExp

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local String = LuauPolyfill.String

type Array<T> = { T }

-- TODO Luau: Luau has no helper types, shim this type to silence errors
type Partial<T> = T

local MiscUtils = {}

--- UUID4 generator
function MiscUtils.uuid4(): string
    -- -- deviation: Luau has no crypto library out of the box, so the simplest option right now is to just use math.random.
    -- -- TODO: Should this be revisited to use a better rng implementation? Math.random shares a global seed and this may
    -- --  cause issues with other scripts.
    -- local function getRandomByte()
    --     math.randomseed(os.time() * os.clock())
    --     return math.random() * 16
    -- end

    -- -- http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/2117523#2117523
    -- -- Concatenating the following numbers as strings results in '10000000100040008000100000000000'
    -- local uuid = (`{1e7}{1e3}{4e3}{8e3}{1e11}`):gsub("[018]", function(c)
    --     local numC = tonumber(c) :: number
    --     return string.format("%x", bit32.bxor(numC, bit32.arshift(bit32.band(getRandomByte(), 15), numC / 4)))
    -- end)

    -- return uuid

    local HttpService = game:GetService("HttpService")
    return string.gsub(HttpService:GenerateGUID(false), "-", "")
end

--- Checks whether the given input is already an array, and if it isn't, wraps it in one.
---
--- @param maybeArray Input to turn into an array, if necessary
--- @return The input, if already an array, or an array with the input as the only element, if not
function MiscUtils.arrayify<T>(maybeArray: T | Array<T>): Array<T>
    return if Array.isArray(maybeArray) then maybeArray :: Array<T> else { maybeArray :: T }
end

--- Checks whether or not we've already captured the given exception (note: not an identical exception - the very object
--- in question), and marks it captured if not.
---
--- This is useful because it's possible for an error to get captured by more than one mechanism. After we intercept and
--- record an error, we rethrow it (assuming we've intercepted it before it's reached the top-level global handlers), so
--- that we don't interfere with whatever effects the error might have had were the SDK not there. At that point, because
--- the error has been rethrown, it's possible for it to bubble up to some other code we've instrumented. If it's not
--- caught after that, it will bubble all the way up to the global handlers (which of course we also instrument). This
--- function helps us ensure that even if we encounter the same error more than once, we only record it the first time we
--- see it.
---
--- Note: It will ignore primitives (always return `false` and not mark them as seen), as properties can't be set on
--- them. {@link: Object.objectify} can be used on exceptions to convert any that are primitives into their equivalent
--- object wrapper forms so that this check will always work. However, because we need to flag the exact object which
--- will get rethrown, and because that rethrowing happens outside of the event processing pipeline, the objectification
--- must be done before the exception captured.
---
--- @param A thrown exception to check or flag as having been seen
--- @return `true` if the exception has already been captured, `false` if not (with the side effect of marking it seen)
function MiscUtils.checkOrSetAlreadyCaught(exception: unknown): boolean
    local success, result = pcall(function()
        if exception and (exception :: any).__sentry_captured__ then
            return true
        end
        return false
    end)

    if success and result == true then
        return true
    end

    pcall(function()
        local e = exception :: { [string]: unknown }
        e.__sentry_captured__ = true
    end)

    -- If the pcalls failed then `exception` is a primitive, so we can't mark it seen

    return false
end

local function getFirstException(event: Event): Exception | nil
    return if event.exception and event.exception.values then event.exception.values[1] else nil
end

--- Adds exception values, type and value to an synthetic Exception.
--- @param event The event to modify.
--- @param value Value of the exception.
--- @param type Type of the exception.
--- @hidden
function MiscUtils.addExceptionTypeValue(event: Event, value: string?, type: string?)
    local exception: { values: { Exception }? } = event.exception or {}
    if event.exception == nil then
        event.exception = exception
    end
    local values: { Exception } = exception.values or {}
    if values == nil then
        exception.values = values
    end
    local firstException: Exception = values[1] or {}
    if firstException == nil then
        values[1] = firstException
    end

    if not firstException.value then
        firstException.value = value or ""
    end
    if not firstException.type then
        firstException.type = type or "Error"
    end
end

--- Adds exception mechanism data to a given event. Uses defaults if the second parameter is not passed.
---
--- @param event The event to modify.
--- @param newMechanism Mechanism data to add to the event.
--- @hidden
function MiscUtils.addExceptionMechanism(event: Event, newMechanism: PartialMechanism?)
    local firstException = getFirstException(event)
    if not firstException then
        return
    end

    local defaultMechanism = { type = "generic", handled = true }
    local currentMechanism = firstException.mechanism
    firstException.mechanism = Object.assign(defaultMechanism, currentMechanism or {}, newMechanism or {})

    if newMechanism and newMechanism.data ~= nil then
        local mergedData = Object.assign(if currentMechanism then currentMechanism.data else {}, newMechanism.data);
        (firstException.mechanism :: Mechanism).data = mergedData
    end
end

--- Extracts either message or type+value from an event that can be used for user-facing logs
--- @returns event's description
function MiscUtils.getEventDescription(event: Event): string
    local message, eventId = event.message, event.event_id
    if message then
        return message
    end

    local firstException = getFirstException(event)
    if firstException then
        if firstException.type and firstException.value then
            return `{firstException.type}: {firstException.value}`
        end
        return firstException.type or firstException.value or eventId or "<unknown>"
    end
    return eventId or "<unknown>"
end

--- Checks if the given value matches a regex or string
---
--- @param value The string to test
--- @param pattern Either a regex or a string against which `value` will be matched
--- @param requireExactStringMatch If true, `value` must match `pattern` exactly. If false, `value` will match
---`pattern` if it contains `pattern`. Only applies to string-type patterns.
function MiscUtils.isMatchingPattern(
    value: string,
    pattern: RegExp | string,
    requireExactStringMatch_: boolean?
): boolean
    local requireExactStringMatch = if requireExactStringMatch_ == nil then false else requireExactStringMatch_

    if type(pattern) == "string" then
        return if requireExactStringMatch then value == pattern else String.includes(value, pattern)
    else
        return pattern:test(value)
    end
end

--- Test the given string against an array of strings and regexes. By default, string matching is done on a
--- substring-inclusion basis rather than a strict equality basis
---
--- @param testString The string to test
--- @param patterns The patterns against which to test the string
--- @param requireExactStringMatch If true, `testString` must match one of the given string patterns exactly in order to
--- count. If false, `testString` will match a string pattern if it contains that pattern.
function MiscUtils.stringMatchesSomePattern(
    testString: string,
    patterns_: Array<string | RegExp>?,
    requireExactStringMatch_: boolean?
): boolean
    local patterns: Array<string | RegExp> = patterns_ or {}
    local requireExactStringMatch = if requireExactStringMatch_ == nil then false else requireExactStringMatch_

    return Array.some(patterns, function(pattern)
        return MiscUtils.isMatchingPattern(testString, pattern, requireExactStringMatch)
    end)
end

return MiscUtils
