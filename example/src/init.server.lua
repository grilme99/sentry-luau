-- Enables debug logic across all Sentry packages. Must be set before first requiring any Sentry package.
_G.__SENTRY_DEV__ = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Error = require(Packages.SentryUtils.polyfill.error)
local Promise = require(Packages.SentryUtils.vendor.promise)
local Sentry = require(Packages.Sentry)

local Sourcemap = require(ReplicatedStorage.Sourcemap)

Sentry.init({
    -- note: DSN exported to ignored module for security. See `dsn.example.lua`.
    dsn = require(script.dsn) :: any,
    tracesSampleRate = 1.0,
    attachStacktrace = true,
    projectSourcemap = Sourcemap,
} :: any)

Sentry.configureScope(function(scope)
    scope:setUser({ id = "75380482", username = "grilme99" })
end)

wait(2)

-- error("Some error that caused a crash!")
Promise.new(function()
    error("Oops! This promise errored!!!")
end)

-- Sentry.addBreadcrumb({
--     message = "My Breadcrumb",
-- })

-- pcall(function()
--     local function erroringFunction(_foo: string, _bar: string)
--         error(Error.new("Attempt to index a nil value")) -- Example error
--     end

--     Sentry.wrap(erroringFunction, "a", "b")
-- end)

-- task.wait(2)

-- local lastEvent = Sentry.lastEventId()
-- print("last event:", lastEvent)
-- print("sending user feedback")

-- local client = Sentry.getCurrentHub():getClient()
-- client:captureUserFeedback({
--     event_id = lastEvent,
--     name = "grilme99",
--     comments = "All of my UI disappeared and I had to rejoin to fix the error",
-- })
