-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/worldwide.ts

-- note: In order to avoid circular dependencies, if you add a function to this module and it needs to print something,
-- you must either a) use `console.log` rather than the logger, or b) put your function elsewhere.

-- note: This module is called `worldwide` in upstream to avoid bundler issues. That isn't a concern with Lua, so we've
-- gone back to the original name (`global`) for explicitness.

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Integration = Types.Integration

local Console = require(PackageRoot.polyfill.console)
type Console = Console.Console

type Array<T> = { T }
type Record<K, V> = { [K]: V }

type Function = (...any) -> any

local GlobalUtils = {}

---Internal global with common properties and Sentry extensions
export type InternalGlobal = {
    navigator: { userAgent: string? }?,
    console: Console?,
    Sentry: {
        Integrations: Array<Integration>?,
    }?,
    onerror: {
        -- deviation: this function is unnamed in upstream, which isn't possible in Luau.
        fn: (msg: unknown, url: unknown, line: unknown, column: unknown, error: unknown) -> boolean,
        __SENTRY_INSTRUMENTED__: true?,
        __SENTRY_LOADER__: true?,
    }?,
    onunhandledrejection: {
        -- deviation: this function is unnamed in upstream, which isn't possible in Luau.
        fn: (event: unknown) -> boolean,
        __SENTRY_INSTRUMENTED__: true?,
        __SENTRY_LOADER__: true?,
    }?,
    SENTRY_ENVIRONMENT: string?,
    SENTRY_DSN: string?,
    SENTRY_RELEASE: {
        id: string?,
    }?,
    -- deviation: Lua doesn't need to know about the SDK source, this value is for JS bundling purposes
    -- SENTRY_SDK_SOURCE: SdkSource?,
    --- Debug IDs are indirectly injected by Sentry CLI or bundler plugins to directly reference a particular source map
    --- for resolving of a source file. The injected code will place an entry into the record for each loaded bundle/JS
    --- file.
    _sentryDebugIds: Record<string, string>?,
    __SENTRY__: {
        globalEventProcessors: any,
        hub: any,
        logger: any,
        --- Extension methods for the hub, which are bound to the current Hub instance
        extensions: { [string]: Function }?,
    },
    --- Raw module metadata that is injected by bundler plugins.
    ---
    --- Keys are `error.stack` strings, values are the metadata.
    _sentryModuleMetadata: Record<string, any>?,
}

-- deviation: Luau has no `keyof` operator for types, so we'll manually type the keys of __SENTRY__ global
type keyof__SENTRY__ = "globalEventProcessors" | "hub" | "logger" | "extensions"

-- deviation: Lua only has one global object we care about, so we don't need to check different sources like with
-- upstream.

local GLOBAL_OBJ: InternalGlobal = _G
GlobalUtils.GLOBAL_OBJ = GLOBAL_OBJ

--- Returns a global singleton contained in the global `__SENTRY__` object.
---
--- If the singleton doesn't already exist in `__SENTRY__`, it will be created using the given factory
--- function and added to the `__SENTRY__` object.
---
--- @param name name of the global singleton on __SENTRY__
--- @param creator creator Factory function to create the singleton if it doesn't already exist on `__SENTRY__`
--- @param obj (Optional) The global object on which to look for `__SENTRY__`, if not `GLOBAL_OBJ`'s return value
--- @return the singleton
function GlobalUtils.getGlobalSingleton<T>(name: keyof__SENTRY__, creator: () -> T, obj: unknown?): T
    local gbl = (obj or GLOBAL_OBJ) :: InternalGlobal

    if gbl.__SENTRY__ == nil then
        gbl.__SENTRY__ = {}
    end
    local __SENTRY__ = gbl.__SENTRY__

    if __SENTRY__[name] == nil then
        __SENTRY__[name] = creator()
    end
    local singleton = __SENTRY__[name]

    return singleton
end

return GlobalUtils
