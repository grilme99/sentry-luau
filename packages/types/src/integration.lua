-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/integration.ts

local PackageRoot = script.Parent

local EventProcessor = require(PackageRoot.eventprocessor)
type EventProcessor = EventProcessor.EventProcessor

local Hub = require(PackageRoot.hub)
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

return {}
