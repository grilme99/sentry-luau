-- Enables debug logic across all Sentry packages. Must be set before first requiring any Sentry package.
_G.__SENTRY_DEV__ = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Sentry = require(Packages.Sentry)

local Sourcemap = require(ReplicatedStorage.Sourcemap)

Sentry.init({
    -- note: DSN exported to ignored module for security. See `dsn.example.lua`.
    dsn = require(script.dsn) :: any,
    tracesSampleRate = 1.0,
    attachStacktrace = true,
    projectSourcemap = Sourcemap,
})

pcall(function()
    local function functionThatErrors(_foo: string, _bar: string)
        error("Something went really quite wrong here!")
    end

    print("wrapping")
    local _result = Sentry.wrap(functionThatErrors, "a", "b")
    print("did error!")
end)

print("oop")
