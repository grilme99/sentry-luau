-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/session.ts

local User = require("./user")
type User = User.User

type Array<T> = { T }

export type RequestSession = {
    status: RequestSessionStatus?,
}

export type Session = {
    sid: string,
    did: (string | number)?,
    init: boolean,
    -- seconds since the UNIX epoch
    timestamp: number,
    -- seconds since the UNIX epoch
    started: number,
    duration: number?,
    status: SessionStatus,
    release: string?,
    environment: string?,
    userAgent: string?,
    ipAddress: string?,
    errors: number,
    user: (User | nil)?,
    ignoreDuration: boolean,

    --- Overrides default JSON serialization of the Session because
    --- the Sentry servers expect a slightly different schema of a session
    --- which is described in the interface @see SerializedSession in this file.
    ---
    --- @return a Sentry-backend conforming JSON object of the session
    toJSON: () -> SerializedSession,
}

-- deviation: Luau has no Partial helper like Typescript does, so we have to re-define Session with all properties optional.
export type SessionContext = {
    sid: string?,
    did: (string | number)?,
    init: boolean?,
    -- seconds since the UNIX epoch
    timestamp: number?,
    -- seconds since the UNIX epoch
    started: number?,
    duration: number?,
    status: SessionStatus?,
    release: string?,
    environment: string?,
    userAgent: string?,
    ipAddress: string?,
    errors: number?,
    user: (User | nil)?,
    ignoreDuration: boolean?,

    --- Overrides default JSON serialization of the Session because
    --- the Sentry servers expect a slightly different schema of a session
    --- which is described in the interface @see SerializedSession in this file.
    ---
    --- @return a Sentry-backend conforming JSON object of the session
    toJSON: (() -> SerializedSession)?,
}

export type SessionStatus = "ok" | "exited" | "crashed" | "abnormal"
export type RequestSessionStatus = "ok" | "errored" | "crashed"

export type SessionAggregates = {
    attrs: {
        environment: string?,
        release: string?,
    }?,
    aggregates: Array<AggregationCounts>,
}

export type SessionFlusherLike = {

    --- Increments the Session Status bucket in SessionAggregates Object corresponding to the status of the session
    --- captured
    incrementSessionStatusCount: () -> (),

    --- Empties Aggregate Buckets and Sends them to Transport Buffer
    flush: () -> (),

    --- Clears setInterval and calls flush
    close: () -> (),
}

export type AggregationCounts = {
    started: string,
    errored: number?,
    exited: number?,
    crashed: number?,
}

export type SerializedSession = {
    init: boolean,
    sid: string,
    did: string?,
    timestamp: string,
    started: string,
    duration: number?,
    status: SessionStatus,
    errors: number,
    attrs: {
        release: string?,
        environment: string?,
        user_agent: string?,
        ip_address: string?,
    }?,
}

return {}
