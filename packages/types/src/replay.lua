-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/replay.ts

local PackageRoot = script.Parent

local Event = require(PackageRoot.event)
type Event = Event.Event

type Array<T> = { T }

---  NOTE: These types are still considered Beta and subject to change.
export type ReplayEvent = Event & {
    urls: Array<string>,
    replay_start_timestamp: number?,
    error_ids: Array<string>,
    trace_ids: Array<string>,
    replay_id: string,
    segment_id: number,
    replay_type: ReplayRecordingMode,
}

---  NOTE: These types are still considered Beta and subject to change.
export type ReplayRecordingData = string

---  NOTE: These types are still considered Beta and subject to change.
export type ReplayRecordingMode = "session" | "buffer"

return {}
