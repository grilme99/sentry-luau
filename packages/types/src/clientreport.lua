-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/clientreport.ts

local DataCategory = require("./datacategory")
type DataCategory = DataCategory.DataCategory

type Array<T> = { T }

export type EventDropReason =
    "before_send"
    | "event_processor"
    | "network_error"
    | "queue_overflow"
    | "ratelimit_backoff"
    | "sample_rate"
    | "send_error"
    | "internal_sdk_error"

export type Outcome = {
    reason: EventDropReason,
    category: DataCategory,
    quantity: number,
}

export type ClientReport = {
    timestamp: number,
    discarded_events: Array<Outcome>,
}

return {}
