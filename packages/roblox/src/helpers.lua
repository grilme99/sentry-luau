-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/helpers.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type DsnLike = Types.DsnLike
type SentryEvent = Types.Event
type Mechanism = Types.Mechanism
type Scope = Types.Scope

local Core = require(Packages.SentryCore)
local captureException = Core.captureException
local withScope = Core.withScope

local Utils = require(Packages.SentryUtils)
local addExceptionMechanism = Utils.addExceptionMechanism
local addExceptionTypeValue = Utils.addExceptionTypeValue
local Array = Utils.Polyfill.Array
local Object = Utils.Polyfill.Object

type Function = (...any) -> ...any

local Helpers = {}

local ignoreOnError: number = 0

local function shouldIgnoreOnError(): boolean
    return ignoreOnError > 0
end
Helpers.shouldIgnoreOnError = shouldIgnoreOnError

local function ignoreNextOnError()
    -- onerror should trigger before task.defer
    ignoreOnError += 1
    task.defer(function()
        ignoreOnError -= 1
    end)
end
Helpers.ignoreNextOnError = ignoreNextOnError

--- Instruments the given function and sends an event to Sentry every time the
--- function throws an exception.
---
--- @param fn A function to wrap. It is generally safe to pass an unbound function, because the returned wrapper always
--- has a correct `this` context.
--- @returns The wrapped function.
--- @hidden
function wrap<A..., R...>(
    fn: (A...) -> R...,
    options_: {
        mechanism: Mechanism?,
    }?
): (A...) -> R...
    local options: { mechanism: Mechanism? } = options_ or {}

    if type(fn) ~= "function" then
        return fn :: any
    end

    local function sentryWrapped(...: any): ...any
        local args: { any } = { ... }
        local wrappedArguments = Array.map(args, function(arg: any)
            return wrap(arg, options)
        end)

        local success, result = (pcall :: any)(fn, table.unpack(wrappedArguments))
        if success then
            return result
        else
            ignoreNextOnError()

            withScope(function(scope)
                scope:addEventProcessor(function(event: SentryEvent)
                    if options.mechanism then
                        addExceptionTypeValue(event, nil, nil)
                        addExceptionMechanism(event, options.mechanism)
                    end

                    event.extra = Object.mergeObjects(event.extra or {}, {
                        arguments = args,
                    })

                    return event
                end)

                captureException(result)
            end)

            error(result)
        end
    end

    return sentryWrapped
end
Helpers.wrap = wrap

return Helpers
