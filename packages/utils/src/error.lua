-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/error.ts

local logger = require("./logger")
type ConsoleLevel = logger.ConsoleLevel

local Error = require("./polyfill/error")
type Error = Error.Error

local SentryError = {}
SentryError.__index = SentryError
setmetatable(SentryError, Error)

function SentryError.new(message: string, logLevel_: ConsoleLevel?)
    local logLevel = logLevel_ or "warn"

    local self = setmetatable({}, SentryError)
    self.message = message
    self.name = "SentryError"
    self.logLevel = logLevel

    return self :: any
end

export type SentryError = typeof(setmetatable(
    {} :: {
        name: string,
        message: string,
        logLevel: ConsoleLevel,
    },
    SentryError
))

return SentryError
