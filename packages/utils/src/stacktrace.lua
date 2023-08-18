-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/stacktrace.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type StackFrame = Types.StackFrame
type StackLineParser = Types.StackLineParser
type StackLineParserFn = Types.StackLineParserFn
type StackParser = Types.StackParser

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local String = LuauPolyfill.String

local STACKTRACE_FRAME_LIMIT = 50

type Array<T> = { T }

local Stacktrace = {}

--- Creates a stack parser with the supplied line parsers
---
--- StackFrames are returned in the correct order for Sentry Exception
--- frames and with Sentry SDK internal frames removed from the top and bottom
function Stacktrace.createStackParser(...: StackLineParser): StackParser
    local parsers = { ... }
    local sortedParsers_ = Array.sort(parsers, function(a, b)
        return a.priority - b.priority
    end)
    local sortedParsers: Array<StackLineParserFn> = Array.map(sortedParsers_, function(p)
        return p.parser
    end)

    return function(stack: string, skipFirst_: number?): Array<StackFrame>
        local firstSkip = skipFirst_ or 1

        local frames = {}
        local lines = string.split(stack, "\n")

        for i = firstSkip, #lines do
            local line = lines[i]

            -- Ignore lines over 1kb as they are unlikely to be stack frames.
            -- Many of the regular expressions use backtracking which results in run time that increases exponentially
            -- with input size. Huge strings can result in hangs/Denial of Service:
            -- https://github.com/getsentry/sentry-javascript/issues/2286
            if #line > 1024 then
                continue
            end

            -- deviation: Remove empty stack lines
            if #String.trim(line) == 0 then
                continue
            end

            for _, parser in sortedParsers do
                local frame = parser(line)

                if frame then
                    if #Object.keys(frame) == 1 and frame.in_app ~= nil then
                        continue
                    end

                    table.insert(frames, frame)
                    break
                end
            end

            if #frames > STACKTRACE_FRAME_LIMIT then
                continue
            end
        end

        return Stacktrace.stripSentryFramesAndReverse(frames)
    end
end

--- Gets a stack parser implementation from Options.stackParser
--- @see Options
---
--- If options contains an array of line parsers, it is converted into a parser
function Stacktrace.stackParserFromStackParserOptions(stackParser: StackParser | Array<StackLineParser>): StackParser
    if type(stackParser) == "table" then
        return Stacktrace.createStackParser(table.unpack(stackParser))
    end
    return stackParser
end

--- Removes Sentry frames from the top and bottom of the stack if present and enforces a limit of max number of frames.
--- Assumes stack input is ordered from top to bottom and returns the reverse representation so call site of the
--- function that caused the crash is the last frame in the array.
--- @hidden
function Stacktrace.stripSentryFramesAndReverse(stack: Array<StackFrame>): Array<StackFrame>
    if #stack == 0 then
        return {}
    end

    local localStack = Array.slice(stack, 1, STACKTRACE_FRAME_LIMIT)

    -- local lastFrameFunction = localStack[#localStack].function_
    -- -- If stack starts with one of our API calls, remove it (starts, meaning it's the top of the stack - aka last call)
    -- if lastFrameFunction and string.find(lastFrameFunction, "sentryWrapped") then
    --     table.remove(localStack, #localStack)
    -- end

    -- -- Reversing in the middle of the procedure allows us to just pop the values off the stack
    -- localStack = Array.reverse(localStack)

    -- local firstFrameFunction = localStack[#localStack].function_
    -- -- If stack ends with one of our internal API calls, remove it (ends, meaning it's the bottom of the stack - aka top-most call)
    -- if
    --     firstFrameFunction
    --     and (string.find(firstFrameFunction, "captureMessage") or string.find(firstFrameFunction, "captureException"))
    -- then
    --     table.remove(localStack, #localStack)
    -- end

    -- deviation: Don't reverse the frames in Lua
    local firstFrameFunction = localStack[1].function_
    -- If stack ends with one of our internal API calls, remove it (ends, meaning it's the bottom of the stack - aka top-most call)
    if
        firstFrameFunction
        and (string.find(firstFrameFunction, "captureMessage") or string.find(firstFrameFunction, "captureException"))
    then
        table.remove(localStack, #localStack)
    end

    local lastFrameFunction = localStack[#localStack].function_
    -- If stack starts with one of our API calls, remove it (starts, meaning it's the top of the stack - aka last call)
    if lastFrameFunction and string.find(lastFrameFunction, "sentryWrapped") then
        table.remove(localStack, #localStack)
    end

    return Array.map(localStack, function(frame: StackFrame)
        return Object.assign(table.clone(frame), {
            filename = frame.filename or localStack[#localStack].filename,
            function_ = frame.function_ or "?",
        })
    end)
end

local defaultFunctionName = "<anonymous>"

--- Safely extract function name from itself
function Stacktrace.getFunctionName(fn: unknown): string
    if type(fn) ~= "function" then
        return defaultFunctionName
    else
        local name = debug.info(fn :: () -> (), "n")
        if name == nil or name == "" then
            return defaultFunctionName
        else
            return name
        end
    end
end

return Stacktrace
