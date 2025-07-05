-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/textencoder.ts

--- Vendored type from TS 3.8 `typescript/lib/lib.dom.d.ts`.
---
--- Type is vendored in so that users don't have to opt-in to DOM types.
export type TextEncoderCommon = {
    --- Returns "utf-8".
    encoding: string,
}

--- Combination of global TextEncoder and Node require('util').TextEncoder
export type TextEncoderInternal = TextEncoderCommon & {
    -- deviation: Luau does not have an equivalent of `Uint8Array`
    encode: (input: string?) -> { number },
}

return {}
