-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/error.ts

-- deviation: Luau has no Error object like JavaScript has, so re-create one here
export type Error = { name: string, message: string, stack: string? }

--- Just an Error object with arbitrary attributes attached to it.
export type ExtendedError = Error & { [string]: any }

return {}
