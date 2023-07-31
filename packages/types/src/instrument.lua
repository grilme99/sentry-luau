-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/instrument.ts

type Array<T> = { T }

-- deviation: Lua has no notion of Xhr or Fetch, so we replace those interfaces with a standard Request type

type SentryRequestData = {
    method: string,
    url: string,
    request_body_size: number?,
    response_body_size: number?,
}

export type HandlerDataFetch = {
    args: Array<any>,
    fetchData: SentryRequestData,
    startTimestamp: number,
    endTimestamp: number?,
    response: unknown?,
}

return {}
