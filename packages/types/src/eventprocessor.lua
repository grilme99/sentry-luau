-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/eventprocessor.ts

local Event = require("./event")
type Event = Event.Event
type EventHint = Event.EventHint

local Promise = require("./promise")
type PromiseLike<T> = Promise.PromiseLike<T>

--- Event processors are used to change the event before it will be send.
--- We strongly advise to make this function sync.
--- Returning a PromiseLike<Event | null> will work just fine, but better be sure that you know what you are doing.
--- Event processing will be deferred until your Promise is resolved.
export type EventProcessor = {
    -- deviation: Luau doesn't have Typescript's interface syntax, so we have to make `fn` named property.
    fn: (event: Event, hint: EventHint) -> PromiseLike<Event | nil> | Event | nil,
    id: string?, -- This field can't be named "name" because functions already have this field natively
}

return {}
