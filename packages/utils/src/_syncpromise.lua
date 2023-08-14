-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/syncpromise.ts

--!nonstrict

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type PromiseLike<T> = Types.PromiseLike<T>

local Is = require(PackageRoot.is)
local isThenable = Is.isThenable

type Array<T> = { T }

local SyncPromise = {}
SyncPromise.__index = SyncPromise

--- SyncPromise internal states
local States = table.freeze({
    PENDING = 0,
    RESOLVED = 1,
    REJECTED = 2,
})

type States = number

--- Creates a resolved sync promise.
---
--- @param value the value to resolve the promise with
--- @return the resolved sync promise
local function resolvedSyncPromise<T>(value: (T | PromiseLike<T>)?): PromiseLike<T>
    return SyncPromise.new(function(resolve, _)
        resolve(value)
    end) :: any
end

--- Creates a rejected sync promise.
---
--- @param value the value to reject the promise with
--- @returns the rejected sync promise
local function rejectedSyncPromise<T>(reason: any?): PromiseLike<T>
    return SyncPromise.new(function(_, reject)
        reject(reason)
    end) :: any
end

export type SyncPromise<T> = typeof(setmetatable(
    {} :: {
        andThen: (
            self: SyncPromise<T>,
            resolve: ((T) -> ...(nil | T | PromiseLike<T>))?,
            reject: ((any) -> ...(nil | T | PromiseLike<T>))?
        ) -> SyncPromise<T>,
        catch: (SyncPromise<T>, (any) -> ...(nil | T | PromiseLike<nil>)) -> SyncPromise<T>,
        finally: (SyncPromise<T>, (any) -> ...(nil | T | PromiseLike<nil>)) -> SyncPromise<T>,
    },
    {} :: {
        __index: SyncPromise<T>,
    }
))

function SyncPromise.new<T>(
    executor: (resolve: (value: T | PromiseLike<T> | nil) -> (), reject: (reason: any?) -> ()) -> ()
): SyncPromise<T>
    local self = setmetatable({}, SyncPromise)
    self._state = States.PENDING
    self._handlers = {} :: Array<{
        b: boolean,
        resolve: (value: T) -> (),
        reject: (reason: any) -> any,
    }>
    self._value = nil :: any

    local success, result = pcall(executor, function(...)
        (self :: any):_resolve(...)
    end, function(...)
        (self :: any):_reject(...)
    end)

    if not success then
        (self :: any):_reject(result)
    end

    return self :: any
end

function SyncPromise._resolve(self: SyncPromise<any>, value: any?)
    (self :: any):_setResult(States.RESOLVED, value)
end

function SyncPromise._reject(self: SyncPromise<any>, reason: any)
    (self :: any):_setResult(States.REJECTED, reason)
end

function SyncPromise._setResult(self: SyncPromise<any>, state: States, value: any)
    if (self :: any)._state ~= States.PENDING then
        return
    end

    if isThenable(value) then
        (value :: PromiseLike<any>):andThen(function(...)
            (self :: any):_resolve(...)
        end, function(...)
            (self :: any):_reject(...)
        end)

        return
    end

    (self :: any)._state = state;
    (self :: any)._value = value;

    (self :: any):_executeHandlers()
end

function SyncPromise._executeHandlers(self: SyncPromise<any>)
    if (self :: any)._state == States.PENDING then
        return
    end

    local cachedHandlers = table.clone((self :: any)._handlers) :: Array<any>
    table.clear((self :: any)._handlers)

    for _, handler in cachedHandlers do
        if handler.b then
            return
        end

        if (self :: any)._state == States.RESOLVED then
            handler.resolve((self :: any)._value)
        end

        if (self :: any)._state == States.REJECTED then
            handler.reject((self :: any)._value)
        end

        handler.b = true
    end
end

return SyncPromise
