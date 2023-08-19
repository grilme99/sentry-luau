-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/logger.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Global = require(PackageRoot.global)
local getGlobalSingleton = Global.getGlobalSingleton
local GLOBAL_OBJ = Global.GLOBAL_OBJ

local Console = require(Packages.LuauPolyfill).console

local PrettyFormat = require(PackageRoot.vendor.prettyformat)

local Logger = {}

--- Prefix for logging strings
local PREFIX = "Sentry Logger "
local CONSOLE_LEVELS = { "debug", "info", "warn", "error", "log", "assert", "trace" }
export type ConsoleLevel = "debug" | "info" | "warn" | "error" | "log" | "assert" | "trace"

type LoggerMethod = (...unknown) -> ()
type LoggerConsoleMethods = {
    debug: LoggerMethod,
    info: LoggerMethod,
    warn: LoggerMethod,
    error: LoggerMethod,
    log: LoggerMethod,
    assert: LoggerMethod,
    trace: LoggerMethod,
}

type Logger = LoggerConsoleMethods & {
    disable: () -> (),
    enable: () -> (),
}

function Logger.consoleSandbox<T>(callback: () -> T): T
    -- TODO: Translate and implement JS sandbox behaviour
    return callback()
end

local function makeLogger(): Logger
    local enabled = false
    local logger = {
        enable = function()
            enabled = true
        end,
        disable = function()
            enabled = false
        end,
    }

    if _G.__SENTRY_DEV__ then
        for _, name in CONSOLE_LEVELS do
            logger[name] = function(...)
                local args = { ... }
                if enabled then
                    Logger.consoleSandbox(function()
                        if GLOBAL_OBJ.console == nil then
                            GLOBAL_OBJ.console = Console
                        end

                        local console = GLOBAL_OBJ.console :: any
                        local str = `{PREFIX}[{name}]:`
                        for _, arg in args do
                            str ..= " " .. if type(arg) == "string" then arg else PrettyFormat.format(arg)
                        end
                        console[name](str)
                        return nil
                    end)
                end
            end
        end
    else
        for _, name in CONSOLE_LEVELS do
            logger[name] = function() end
        end
    end

    return logger
end

-- Ensure we only have a single logger instance, even if multiple versions of @sentry/utils are being used

if _G.__SENTRY_DEV__ then
    Logger.logger = getGlobalSingleton("logger", makeLogger)
else
    Logger.logger = makeLogger()
end

return Logger
