-- based on: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/integrations/globalhandlers.ts

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local Core = require(Packages.SentryCore)
local getCurrentHub = Core.getCurrentHub

local Types = require(Packages.SentryTypes)
type Event = Types.Event
type EventHint = Types.EventHint
type Hub = Types.Hub
type Integration = Types.Integration
type Primitive = Types.Primitive
type StackParser = Types.StackParser
type MaybePromiseLibrary = Types.MaybePromiseLibrary

local Utils = require(Packages.SentryUtils)
local addExceptionMechanism = Utils.addExceptionMechanism
local logger = Utils.logger
local Object = Utils.Polyfill.Object
local Error = Utils.Polyfill.Error
local Array = Utils.Polyfill.Array

local Client = require(PackageRoot.client)
type RobloxClient = Client.RobloxClient

local Helpers = require(PackageRoot.helpers)
local shouldIgnoreOnError = Helpers.shouldIgnoreOnError

local EventBuilder = require(PackageRoot.eventbuilder)
local eventFromUnknownInput = EventBuilder.eventFromUnknownInput

type Array<T> = { T }
type Map<K, V> = { [K]: V }

type GlobalHandlersIntegrationsOptionKeys = "onerror" | "onunhandledrejection"
type GlobalHandlersIntegrations = {
    onerror: boolean,
    onunhandledrejection: boolean,
}

local function getHubAndOptions(): (Hub, StackParser, boolean | nil)
    local hub = getCurrentHub()
    local client: RobloxClient = hub:getClient() :: any
    local options = (client and client:getOptions())
        or {
            stackParser = function() end :: any,
            attachStacktrace = false,
        }
    return hub, options.stackParser, options.attachStacktrace
end

local function addMechanismAndCapture(hub: Hub, error: string, event: Event, type: string)
    addExceptionMechanism(event, {
        handled = false,
        type = type,
    })
    hub:captureEvent(event, {
        originalException = error,
    })
end

local function hasAncestorThatMatchesName(obj: Instance, name: string): boolean
    local function checkParentRecursive(instance: Instance?): boolean
        if not instance or instance == game then
            return false
        end

        if string.match(string.lower(instance.Name), name) then
            return true
        else
            return checkParentRecursive(instance.Parent)
        end
    end

    local matchesName = checkParentRecursive(obj.Parent)
    return matchesName
end

--- Search through modules in the game for any Promise libraries that expose an onUnhandledRejection hook.
--- Warning: This could yield if any required modules yield.
local function discoveryPromiseLibrariesAsync(): Array<MaybePromiseLibrary>
    local promiseLibraries = {}

    local promiseLocations: Array<Instance> = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
    }

    if game:GetService("RunService"):IsStudio() then
        table.insert(promiseLocations, game:GetService("ServerStorage"))
        table.insert(promiseLocations, game:GetService("ServerScriptService"))
    else
        table.insert(promiseLocations, game:GetService("StarerPlayer"))
        table.insert(promiseLocations, game:GetService("Players").LocalPlayer)
    end

    for _, location in promiseLocations do
        local candidates = location:GetDescendants()
        for _, candidate in candidates do
            if candidate:IsA("ModuleScript") then
                local name = string.lower(candidate.Name)
                if string.match(name, "promise") or hasAncestorThatMatchesName(candidate, "promise") then
                    local success, result = pcall(require, candidate)
                    if success then
                        local onUnhandledRejection = result.onUnhandledRejection
                        if type(onUnhandledRejection) == "function" then
                            local argCount = debug.info(onUnhandledRejection, "a")
                            if argCount == 1 then
                                table.insert(promiseLibraries, result)
                            end
                        end
                    end
                end
            end
        end
    end

    return promiseLibraries
end

local GlobalHandlers = {}
GlobalHandlers.id = "GlobalHandlers"
GlobalHandlers.__index = GlobalHandlers

--- Hooks the global ScriptContext.Error event to collect uncaught errors globally. This generally doesn't give the best
--- information about errors because the `Error` event omits a lot of useful info.
local function _installGlobalOnErrorHandler()
    local ScriptContext = game:GetService("ScriptContext")

    ScriptContext.Error:Connect(function(message, stacktrace)
        local hub, stackParser, attachStacktrace = getHubAndOptions()
        if not hub:getIntegration(GlobalHandlers :: any) then
            return
        end
        if shouldIgnoreOnError() then
            return
        end

        local syntheticException = Error.new()
        syntheticException.stack = stacktrace

        local event = eventFromUnknownInput(stackParser, message, syntheticException, attachStacktrace, false)
        event.level = "error"

        local error = `{message}\n{stacktrace}`
        addMechanismAndCapture(hub, error, event, "onerror")
    end)
end

local function _installGlobalOnUnhandledRejectionHandler()
    local promiseLibraries = discoveryPromiseLibrariesAsync()
    for _, promiseLibrary in promiseLibraries do
        local onUnhandledRejection = promiseLibrary.onUnhandledRejection
        -- Just in case
        pcall(function()
            onUnhandledRejection(function(_promise, args)
                local hub, stackParser, attachStacktrace = getHubAndOptions()
                if not hub:getIntegration(GlobalHandlers :: any) then
                    return
                end
                if shouldIgnoreOnError() then
                    return
                end

                local kind, error, trace_ = args.kind, args.error, args.trace

                local traceLines = string.split(trace_ or "", "\n")
                local trace = table.concat(Array.slice(traceLines, 2), "\n")

                local syntheticException = Error.new()
                syntheticException.name = kind or "Error"
                syntheticException.stack = trace

                local event = eventFromUnknownInput(stackParser, error, syntheticException, attachStacktrace, true)
                event.level = "error"
                event.tags = Object.mergeObjects(event.tags or {}, {
                    promiseKind = kind,
                })

                addMechanismAndCapture(hub, trace or "", event, "onunhandledrejection")
            end)
        end)
    end
end

export type GlobalHandlers = typeof(setmetatable(
    {} :: Integration & {
        _options: GlobalHandlersIntegrations,
        _installFunc: Map<GlobalHandlersIntegrationsOptionKeys, ((() -> ()) | nil)>,
    },
    {} :: {
        __index: GlobalHandlers,
    }
))

function GlobalHandlers.new(options: GlobalHandlersIntegrations?)
    local self: GlobalHandlers = setmetatable({}, GlobalHandlers) :: any
    self.name = GlobalHandlers.id
    self._options = Object.mergeObjects({
        onerror = true,
        onunhandledrejection = true,
    }, options or {})
    self._installFunc = {
        onerror = _installGlobalOnErrorHandler,
        onunhandledrejection = _installGlobalOnUnhandledRejectionHandler,
    }
    return self
end

function GlobalHandlers.setupOnce(self: GlobalHandlers)
    local options = self._options

    for key: GlobalHandlersIntegrationsOptionKeys, enabled: boolean in options :: any do
        local installFunc = self._installFunc[key]
        if installFunc and enabled then
            -- note: Installing hooks could yield, but that shouldn't block the rest of the SDK from starting
            task.spawn(function()
                installFunc()
                self._installFunc[key] = nil

                if _G.__SENTRY_DEV__ then
                    logger.log(`Global Handler attached: {key}`)
                end
            end)
        end
    end
end

return GlobalHandlers
