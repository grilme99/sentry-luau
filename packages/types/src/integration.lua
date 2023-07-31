local EventProcessor = require("./eventprocessor")
type EventProcessor = EventProcessor.EventProcessor

local Hub = require("./hub")
type Hub = Hub.Hub

--- Integration Class Interface
export type IntegrationClass<T> = {
    --- Property that holds the integration name
    id: string,

    new: (...any) -> T,
}

--- Integration interface
export type Integration = {
    --- Returns {@link IntegrationClass.id}
    name: string,

    --- Sets the integration up only once.
    --- This takes no options on purpose, options should be passed in the constructor
    setupOnce: (addGlobalEventProcessor: (callback: EventProcessor) -> (), getCurrentHub: () -> Hub) -> (),
}
