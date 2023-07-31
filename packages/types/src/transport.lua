local Client = require("./client")

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

return {}
