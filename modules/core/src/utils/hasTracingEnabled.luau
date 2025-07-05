-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/utils/hasTracingEnabled.ts

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Options = Types.Options

local Hub = require(PackageRoot.hub)
local getCurrentHub = Hub.getCurrentHub

--- Determines if tracing is currently enabled.
--- Tracing is enabled when at least one of `tracesSampleRate` and `tracesSampler` is defined in the SDK config.
local function hasTracingEnabled(maybeOptions: Options?): boolean
    if _G.__SENTRY_TRACING__ == false then
        return false
    end

    local client = getCurrentHub():getClient()
    local options = maybeOptions or (client and client:getOptions())
    return options ~= nil and (options.enableTracing or options.tracesSampleRate ~= nil or options.tracesSampler ~= nil)
end

return hasTracingEnabled
