-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/promisebuffer.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type PromiseLike<T> = Types.PromiseLike<T>

local Promise = require(PackageRoot.vendor.promise)
local SentryError = require(PackageRoot.error)

local Array = require(PackageRoot.polyfill.array)
type Array<T> = { T }

local PromiseBuffer = {}

export type PromiseBuffer<T> = {
    -- exposes the internal array so tests can assert on the state of it.
    -- XXX: this really should not be public api.
    __buffer: Array<PromiseLike<T>>,
    add: (taskProducer: () -> PromiseLike<T>) -> PromiseLike<T>,
    drain: (timeout: number?) -> PromiseLike<boolean>,
}

--- Creates an new PromiseBuffer object with the specified limit
--- @param limit max number of promises that can be stored in the buffer
function PromiseBuffer.makePromiseBuffer<T>(limit: number?): PromiseBuffer<T>
    local buffer: Array<PromiseLike<T>> = {}

    local function isReady(): boolean
        return limit == nil or #buffer < limit
    end

    --- Remove a promise from the queue.
    ---
    --- @param task Can be any PromiseLike<T>
    --- @returns Removed promise.
    local function remove(task: PromiseLike<T>): PromiseLike<T>
        return Array.splice(buffer, Array.indexOf(buffer, task), 1)[1]
    end

    --- Add a promise (representing an in-flight action) to the queue, and set it to remove itself on fulfillment.
    ---
    --- @param taskProducer A function producing any PromiseLike<T>; In previous versions this used to be `task:
    ---        PromiseLike<T>`, but under that model, Promises were instantly created on the call-site and their executor
    ---        functions therefore ran immediately. Thus, even if the buffer was full, the action still happened. By
    ---        requiring the promise to be wrapped in a function, we can defer promise creation until after the buffer
    ---        limit check.
    --- @returns The original promise.
    local function add(taskProducer: () -> PromiseLike<T>): PromiseLike<T>
        if not isReady() then
            return Promise.reject(SentryError.new("Not adding Promise because buffer limit was reached."))
        end

        -- start the task and add its promise to the queue
        local task = taskProducer()
        if Array.indexOf(buffer, task) == -1 then
            table.insert(buffer, task)
        end
        task
            :andThen(function()
                return remove(task)
            end)
            -- Use `then(null, rejectionHandler)` rather than `catch(rejectionHandler)` so that we can use `PromiseLike`
            -- rather than `Promise`. `PromiseLike` doesn't have a `.catch` method, making its polyfill smaller. (ES5 didn't
            -- have promises, so TS has to polyfill when down-compiling.)
            :andThen(
                nil,
                function()
                    return remove(task):andThen(nil, function()
                        -- We have to add another catch here because `remove()` starts a new promise chain.
                    end)
                end
            )

        return task
    end

    -- Wait for all promises in the queue to resolve or for timeout to expire, whichever comes first.
    ---
    --- @param timeout The time, in ms, after which to resolve to `false` if the queue is still non-empty. Passing `0` (or
    --- not passing anything) will make the promise wait as long as it takes for the queue to drain before resolving to
    --- `true`.
    --- @returns A promise which will resolve to `true` if the queue is already empty or drains before the timeout, and
    --- `false` otherwise
    local function drain(timeout: number?): PromiseLike<boolean>
        return Promise.new(function(resolve, reject)
            local counter = #buffer
            if counter == 0 then
                return resolve(true)
            end

            local capturedDelay = task.delay(timeout, function()
                if timeout and timeout > 0 then
                    resolve(false)
                end
            end)

            -- if all promises resolve in time, cancel the timer and resolve to `true`
            for _, item in buffer do
                item:andThen(function()
                    counter -= 1
                    if counter == 0 then
                        task.cancel(capturedDelay)
                        resolve(true)
                    end
                end, reject)
            end
        end)
    end

    return {
        __buffer = buffer,
        add = add,
        drain = drain,
    }
end

return PromiseBuffer
