-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/is.ts

local PackageRoot = script.Parent

local Array = require(PackageRoot.polyfill.array)
local Error = require(PackageRoot.polyfill.error)
local instanceof = require(PackageRoot.polyfill.instanceof)

local IsUtils = {}

--- Checks whether given value's type is one of a few Error or Error-like
--- @param wat A value to be checked.
--- @returns A boolean representing the result.
function IsUtils.isError(wat: unknown): boolean
    return instanceof(wat, Error)
end

--- Checks whether given value is a primitive (undefined, null, number, boolean, string, bigint, symbol)
---
--- @param wat A value to be checked.
---@returns A boolean representing the result.
function IsUtils.isPrimitive(wat: unknown): boolean
    return wat == nil or (type(wat) ~= "table" and type(wat) ~= "function")
end

--- Checks whether given value's type is an object literal
---
--- @param wat A value to be checked.
--- @returns A boolean representing the result.
function IsUtils.isPlainObject(wat: any): boolean
    -- deviation: We can't use the same tostring check as JS, so instead we'll check if the value is a table but not an
    -- array.
    return type(wat) == "table" and not Array.isArray(wat)
end

--- Checks whether given value has a then function.
--- @param wat A value to be checked.
function IsUtils.isThenable(wat: any): boolean
    return wat and wat.andThen and type(wat.andThen) == "function"
end

--- Checks whether given value's type is a SyntheticEvent
---
--- @param wat A value to be checked.
function IsUtils.isSyntheticEvent(wat: any): boolean
    return IsUtils.isPlainObject(wat)
        and type(wat) == "table"
        and wat.nativeEvent
        and wat.preventDefault
        and wat.stopPropagation
end

--- Checks whether given value is NaN
--- @param wat A value to be checked.
function IsUtils.isNaN(wat: unknown): boolean
    return type(wat) == "number" and wat ~= wat
end

return IsUtils
