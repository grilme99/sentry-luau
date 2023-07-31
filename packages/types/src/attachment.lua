-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/attachment.ts

export type Attachment = {
    -- deviation: Luau does not have `Uint8Array`, use a number array as an equivalent
    data: string | { number },
    filename: string,
    contentType: string?,
    attachmentType: string?,
}

return {}
