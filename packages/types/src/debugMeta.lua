-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/debugMeta.ts

type Array<T> = { T }

--- Holds meta information to customize the behavior of Sentry's server-side event processing.
export type DebugMeta = {
    images: Array<DebugImage>?,
}

export type DebugImage = WasmDebugImage | SourceMapDebugImage

type WasmDebugImage = {
    type: "wasm",
    debug_id: string,
    code_id: (string | nil)?,
    code_file: string,
    debug_file: (string | nil)?,
}

type SourceMapDebugImage = {
    type: "sourcemap",
    code_file: string, -- filename
    debug_id: string, -- uuid
}

return {}
