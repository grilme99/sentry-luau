-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/transports/types.ts

local Types = require("@packages/types")
type BaseTransportOptions = Types.BaseTransportOptions

type Map<K, V> = { [K]: V }

export type RobloxTransportOptions = BaseTransportOptions & {
    --- Custom headers for the transport. Used by HttpServiceTransport.
    headers: Map<string, string>,
}

return {}
