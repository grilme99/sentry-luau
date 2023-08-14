-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/transports/index.ts

local HttpServiceTransport = require("./httpservice")
local makeHttpServiceTransport = HttpServiceTransport.makeHttpServiceTransport

local Transports = {}

Transports.makeHttpServiceTransport = makeHttpServiceTransport

return Transports
