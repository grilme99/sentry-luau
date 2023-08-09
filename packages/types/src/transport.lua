local Client = require("./client")

local Envelope = require("./envelope")
type Envelope = Envelope.Envelope

local Promise = require("./promise")
type PromiseLike<T> = Promise.PromiseLike<T>

local TextEncoder = require("./textencoder")
type TextEncoderInternal = TextEncoder.TextEncoderInternal

type Map<K, V> = { [K]: V }

export type TransportRequest = {
    body: string,
}

export type TransportMakeRequestResponse = {
    statusCode: number?,
    headers: (Map<string, string> & {
        --   "x-sentry-rate-limits": string | nil;
        --   "retry-after": string | nil;
    })?,
}

export type InternalBaseTransportOptions = {
    bufferSize: number?,
    recordDroppedEvent: Client.RecordDroppedEvent,
    textEncoder: TextEncoderInternal?,
}

export type BaseTransportOptions = InternalBaseTransportOptions & {
    --- url to send the event
    --- transport does not care about dsn specific - client should take care of
    --- parsing and figuring that out
    url: string,
}

export type Transport = {
    send: (request: Envelope) -> PromiseLike<TransportMakeRequestResponse>,
    flush: (timeout: number?) -> PromiseLike<boolean>,
}

export type TransportRequestExecutor = (request: TransportRequest) -> PromiseLike<TransportMakeRequestResponse>

return {}
