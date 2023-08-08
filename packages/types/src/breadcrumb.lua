-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/breadcrumb.ts

local Severity = require("./severity")
type SeverityLevel = Severity.SeverityLevel

type Array<T> = {T}
type Map<K, V> = {[K]: V}

export type Breadcrumb = {
  type: string?;
  level: SeverityLevel | nil;
  event_id: string?;
  category: string?;
  message: string?;
  data: Map<string, any>?;
  timestamp: number?;
}

export type BreadcrumbHint = Map<string, any>

-- deviation: Lua has no concept of Fetch or Xhr, expose a single Request type
export type RequestBreadcrumbData = {
  method: string;
  url: string;
  status_code: number?;
  request_body_size: number?;
  response_body_size: number?;
}

-- deviation: Lua has no concept of Fetch or Xhr, expose a single Request type
export type RequestBreadcrumbHint = {
  input: Array<any>;
  data: unknown?;
  response: unknown?;
  startTimestamp: number;
  endTimestamp: number;
}

return {}
