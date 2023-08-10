-- upstream: https:---github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/checkin.ts

local Context = require("./context")
type TraceContext = Context.TraceContext

type CrontabSchedule = {
    type: "crontab",
    --- The crontab schedule string, e.g. 0 * * * *.
    value: string,
}

type IntervalSchedule = {
    type: "interval",
    value: number,
    unit: "year" | "month" | "week" | "day" | "hour" | "minute",
}

type MonitorSchedule = CrontabSchedule | IntervalSchedule

export type SerializedMonitorConfig = {
    schedule: MonitorSchedule,
    --- The allowed allowed margin of minutes after the expected check-in time that
    --- the monitor will not be considered missed for.
    checkin_margin: number?,
    --- The allowed allowed duration in minutes that the monitor may be `in_progress`
    --- for before being considered failed due to timeout.
    max_runtime: number?,
    --- A tz database string representing the timezone which the monitor's execution schedule is in.
    --- See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    timezone: string?,
}

-- https://develop.sentry.dev/sdk/check-ins/
export type SerializedCheckIn = {
    --- Check-In ID (unique and client generated).
    check_in_id: string,
    --- The distinct slug of the monitor.
    monitor_slug: string,
    --- The status of the check-in.
    status: "in_progress" | "ok" | "error",
    --- The duration of the check-in in seconds. Will only take effect if the status is ok or error.
    duration: number?,
    release: string?,
    environment: string?,
    monitor_config: SerializedMonitorConfig?,
    contexts: {
        trace: TraceContext?,
    }?,
}

export type InProgressCheckIn = {
    --- The distinct slug of the monitor.
    monitorSlug: string,
    --— The status of the check-in.
    status: "in_progress",
}

export type FinishedCheckIn = {
    --- The distinct slug of the monitor.
    monitorSlug: string,
    --- The status of the check-in.
    status: "ok" | "error",
    --- Check-In ID (unique and client generated).
    checkInId: string,
    --- The duration of the check-in in seconds. Will only take effect if the status is ok or error.
    duration: number?,
}

export type CheckIn = InProgressCheckIn | FinishedCheckIn

export type MonitorConfig = {
    schedule: MonitorSchedule,
    --- The allowed allowed margin of minutes after the expected check-in time that
    --- the monitor will not be considered missed for.
    checkinMargin: number?,
    --- The allowed allowed duration in minutes that the monitor may be `in_progress`
    --- for before being considered failed due to timeout.
    maxRuntime: number?,
    --- A tz database string representing the timezone which the monitor's execution schedule is in.
    --- See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    timezone: string?,
}

return {}
