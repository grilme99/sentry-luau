-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/context.ts

local PackageRoot = script.Parent

local Misc = require(PackageRoot.misc)
type Primitive = Misc.Primitive

type Array<T> = { T }
-- note: Luau does not currently have a Record type, but it is basically a Map
type Record<K, V> = { [K]: V }
type Map<K, V> = { [K]: V }

export type Context = Record<string, unknown>

export type Contexts = Record<string, Context | nil> & {
    app: AppContext?,
    device: DeviceContext?,
    os: OsContext?,
    culture: CultureContext?,
    response: ResponseContext?,
    trace: TraceContext?,
}

export type AppContext = Record<string, unknown> & {
    app_name: string?,
    app_start_time: string?,
    app_version: string?,
    app_identifier: string?,
    build_type: string?,
    app_memory: number?,
}

export type DeviceContext = Record<string, unknown> & {
    name: string?,
    family: string?,
    model: string?,
    model_id: string?,
    arch: string?,
    battery_level: number?,
    orientation: ("portrait" | "landscape")?,
    manufacturer: string?,
    brand: string?,
    screen_resolution: string?,
    screen_height_pixels: number?,
    screen_width_pixels: number,
    screen_density: number,
    screen_dpi: number,
    online: boolean,
    charging: boolean,
    low_memory: boolean,
    simulator: boolean,
    memory_size: number,
    free_memory: number,
    usable_memory: number,
    storage_size: number,
    free_storage: number,
    external_storage_size: number,
    external_free_storage: number,
    boot_time: string,
    processor_count: number,
    cpu_description: string,
    processor_frequency: number,
    device_type: string,
    battery_status: string,
    device_unique_identifier: string,
    supports_vibration: boolean,
    supports_accelerometer: boolean,
    supports_gyroscope: boolean,
    supports_audio: boolean,
    supports_location_service: boolean,
}

export type OsContext = Record<string, unknown> & {
    name: string,
    version: string,
    build: string,
    kernel_version: string,
}

export type CultureContext = Record<string, unknown> & {
    calendar: string,
    display_name: string,
    locale: string,
    is_24_hour_format: boolean,
    timezone: string,
}

export type ResponseContext = Record<string, unknown> & {
    type: string,
    cookies: Array<Array<string>> | Record<string, string>,
    headers: Record<string, string>,
    status_code: number,
    body_size: number, -- in bytes
}

export type TraceContext = Record<string, unknown> & {
    data: Map<string, any>?,
    description: string?,
    op: string?,
    parent_span_id: string?,
    span_id: string,
    status: string?,
    tags: Map<string, Primitive>?,
    trace_id: string,
}

return {}
