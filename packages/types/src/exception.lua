-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/exception.ts

local Mechanism = require("./mechanism")
type Mechanism = Mechanism.Mechanism

local Stacktrace = require("./stacktrace")
type Stacktrace = Stacktrace.Stacktrace

export type Exception = {
  type: string?;
  value: string?;
  mechanism: Mechanism?;
  module: string?;
  thread_id: number?;
  stacktrace: Stacktrace?;
}

return {}
