export type PromiseLike<T> = {
    andThen: (
        self: PromiseLike<T>,
        resolve: ((T) -> ...(nil | T | PromiseLike<T>))?,
        reject: ((any) -> ...(nil | T | PromiseLike<T>))?
    ) -> PromiseLike<T>,
}

type PromiseStatus = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type Promise<T> = {
    andThen: (
        self: Promise<T>,
        resolve: ((T) -> ...(nil | T | PromiseLike<T>))?,
        reject: ((any) -> ...(nil | T | PromiseLike<T>))?
    ) -> Promise<T>,

    catch: (Promise<T>, (any) -> ...(nil | T | PromiseLike<nil>)) -> Promise<T>,

    onCancel: (Promise<T>, () -> ()?) -> boolean,

    expect: (Promise<T>) -> ...T,

    -- FIXME Luau: need union type packs to parse  (...T) | () | PromiseLike<T> here
    await: (Promise<T>) -> (boolean, ...(T | any)),

    getStatus: (self: Promise<T>) -> PromiseStatus,
    -- FIXME Luau: need union type packs to parse  (...T) | () | PromiseLike<T> here
    awaitStatus: (self: Promise<T>) -> (PromiseStatus, ...(T | any)),
}

type RejectionArgs = {
    context: string?,
    createdTick: number?,
    createdTrace: string?,
    error: string?,
    kind: string?,
    trace: string?,
}

export type MaybePromiseLibrary = {
    --- Registers a callback that runs when an unhandled rejection happens. An unhandled rejection happens when a Promise
    --- is rejected, and the rejection is not observed with `:catch`.

    --- The callback is called with the actual promise that rejected, followed by the rejection values.

    --- @since v3.2.0
    --- @param callback (promise: Promise, ...: any) -- A callback that runs when an unhandled rejection happens.
    --- @return () -> () -- Function that unregisters the `callback` when called
    onUnhandledRejection: (callback: (promise: PromiseLike<any>, args: RejectionArgs) -> ()) -> () -> (),
}

return {}
