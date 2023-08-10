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
