-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/dsn.ts

--- Supported Sentry transport protocols in a Dsn.
export type DsnProtocol = "http" | "https"

--- Primitive components of a Dsn.
export type DsnComponents = {
    --- Protocol used to connect to Sentry.
    protocol: DsnProtocol,
    --- Public authorization key.
    publicKey: string?,
    --- Private authorization key (deprecated, optional).
    pass: string?,
    --- Hostname of the Sentry instance.
    host: string,
    --- Port of the Sentry instance.
    port: string?,
    --- Sub path/
    path: string?,
    --- Project ID
    projectId: string,
}

--- Anything that can be parsed into a Dsn.
export type DsnLike = string | DsnComponents

return {}
