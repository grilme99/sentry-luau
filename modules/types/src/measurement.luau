-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/measurement.ts

type Record<K, V> = { [K]: V }

-- Based on https://getsentry.github.io/relay/relay_metrics/enum.MetricUnit.html
-- For more details, see measurement key in https://develop.sentry.dev/sdk/event-payloads/transaction/

--- A time duration.
export type DurationUnit = "nanosecond" | "microsecond" | "millisecond" | "second" | "minute" | "hour" | "day" | "week"

--- Size of information derived from bytes.
export type InformationUnit =
    "bit"
    | "byte"
    | "kilobyte"
    | "kibibyte"
    | "megabyte"
    | "mebibyte"
    | "gigabyte"
    | "terabyte"
    | "tebibyte"
    | "petabyte"
    | "exabyte"
    | "exbibyte"

--- Fractions such as percentages.
export type FractionUnit = "ratio" | "percent"

--- Untyped value without a unit.
export type NoneUnit = "" | "none"

export type MeasurementUnit = DurationUnit | InformationUnit | FractionUnit | NoneUnit

export type Measurements = Record<string, { value: number, unit: MeasurementUnit }>

return {}
