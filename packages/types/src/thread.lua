-- upstream :https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/thread.ts

local PackageRoot = script.Parent

local Stacktrace = require(PackageRoot.stacktrace)
type Stacktrace = Stacktrace.Stacktrace

export type Thread = {
    id: number?,
    name: string?,
    stacktrace: Stacktrace?,
    crashed: boolean?,
    current: boolean?,
}

return {}
