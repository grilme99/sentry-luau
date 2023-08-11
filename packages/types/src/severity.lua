-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/severity.ts

-- Note: If this is ever changed, the `validSeverityLevels` array in `sentry-utils` needs to be changed, also. (See
-- note there for why we can't derive one from the other.)
export type SeverityLevel = "fatal" | "error" | "warning" | "log" | "info" | "debug"

return {}
