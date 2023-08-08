-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/is.ts

local Array = require("./polyfill/array")

local IsUtils = {}

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

return IsUtils
