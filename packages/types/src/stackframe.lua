-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/stackframe.ts

type Array<T> = { T }
type Map<K, V> = { [K]: V }

export type StackFrame = {
    filename: string?,
    -- deviation: `function` is a keyword in Luau and cannot be a table or type key. This will have to be changed before
    --  getting sent to Sentry.
    function_: string?,
    module: string?,
    platform: string?,
    lineno: number?,
    colno: number?,
    abs_path: string?,
    context_line: string?,
    pre_context: Array<string>?,
    post_context: Array<string>?,
    in_app: boolean?,
    instruction_addr: string?,
    addr_mode: string?,
    vars: Map<string, any>?,
    debug_id: string?,
    module_metadata: any?,
}

return {}
