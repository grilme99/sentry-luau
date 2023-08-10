-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/sdk.ts

local Types = require("@packages/types")
type Client = Types.Client
type ClientOptions = Types.ClientOptions

local Utils = require("@packages/utils")
local logger = Utils.logger

local Hub = require("./hub")
local getCurrentHub = Hub.getCurrentHub

local Sdk = {}

export type ClientClass<F = Client, O = ClientOptions> = (options: O) -> F

--- Internal function to create a new SDK client instance. The client is
--- installed and then bound to the current scope.
---
--- @param newClientClass Constructor for the client class.
--- @param options Options to pass to the client.
function Sdk.initAndBind<F, O>(newClientClass: ClientClass<F & Client, O>, options: ClientOptions & O)
    if options.debug == true then
        
        if _G.__SENTRY_DEV__ then
            logger.enable()
        else
            -- use `warn` rather than `logger.warn` since by non-debug bundles have all `logger.x` statements stripped
            warn("[Sentry] Cannot initialize SDK with `debug` option using a non-debug bundle.")
        end
    end

    local hub = getCurrentHub()
    local scope = hub:getScope()
    scope:update(options.initialScope)

    local client = newClientClass(options)
    hub:bindClient(client)
end

return Sdk
