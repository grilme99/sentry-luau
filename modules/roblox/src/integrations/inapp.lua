-- note: no upstream

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local String = LuauPolyfill.String

local Types = require(Packages.SentryTypes)
type Event = Types.Event
type EventProcessor = Types.EventProcessor
type Hub = Types.Hub
type Integration = Types.Integration

type Array<T> = { T }

export type InAppOptions = {
    --- Paths to locations that contain project dependencies. Any stack frames in these directories will have `in_app`
    --- set to false.
    dependencyPaths: Array<string>?,
}

local InApp = {}
InApp.id = "InApp"
InApp.__index = InApp

export type InApp = typeof(setmetatable(
    {} :: Integration & {
        options: InAppOptions,
    },
    {} :: {
        __index: InApp,
    }
))

function InApp.new(options_: InAppOptions?)
    local self: InApp = setmetatable({}, InApp) :: any
    self.name = InApp.id
    self.options = options_ or {}
    self.options.dependencyPaths = self.options.dependencyPaths
        or {
            -- Default support for instance locations and fs paths
            "replicatedstorage.packages",
            "replicatedfirst.packages",
            "packages/",
            "dependencies/",
            "deps/",
        }

    return self
end

function InApp.setupOnce(
    self: InApp,
    addGlobalEventProcessor: (callback: EventProcessor) -> (),
    getCurrentHub: () -> Hub
)
    local function eventProcessor(currentEvent: Event): Event?
        -- We want to ignore any non-error type events, e.g. transactions or replays
        if currentEvent.type then
            return currentEvent
        end

        if getCurrentHub():getIntegration(InApp) then
            local exValues = currentEvent.exception and currentEvent.exception.values
            if exValues then
                for _, exception in exValues do
                    local frames = exception.stacktrace and exception.stacktrace.frames
                    if frames then
                        for _, frame in frames do
                            local filename = frame.filename
                            if filename == nil then
                                continue
                            end

                            local outsideApp = Array.some(self.options.dependencyPaths :: Array<string>, function(path)
                                return String.startsWith(filename :: string, path)
                            end)

                            frame.in_app = not outsideApp
                        end
                    end
                end
            end

            return currentEvent
        end

        return currentEvent
    end

    addGlobalEventProcessor({
        id = self.name,
        fn = eventProcessor,
    })
end

return InApp
