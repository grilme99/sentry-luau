-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/stacktrace.ts

local PackageRoot = script.Parent

local StackFrame = require(PackageRoot.stackframe)
type StackFrame = StackFrame.StackFrame

type Array<T> = { T }

export type Stacktrace = {
    frames: Array<StackFrame>?,
    -- deviation: Luau does not support tuples here, so we'll make this an array
    frames_omitted: Array<number>?,
}

export type StackParser = (stack: string, skipFirst: number?) -> Array<StackFrame>
export type StackLineParserFn = (line: string) -> StackFrame | nil
-- deviation: Luau does not support tuples here, so we'll make it an object with explicit keys
export type StackLineParser = {
    priority: number,
    parser: StackLineParserFn,
}

return {}
