-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/object.ts

local Array = require("./polyfill/array")
local Object = require("./polyfill/object")

local String = require("./string")
local truncate = String.truncate

type Map<K, V> = { [K]: V }

local ObjectUtils = {}

--- Encodes given object into url-friendly format
---
--- @param object An object that contains serializable values
--- @returns string Encoded
function ObjectUtils.urlEncode(object: Map<string, any>): string
    if not game then
        error("urlEncode is unaviable in this environment because encodeURIComponent is unsupported")
    end

    local HttpService = game:GetService("HttpService")

    local encoded = ""
    for key, value in object do
        local encodedKey = HttpService:UrlEncode(key)
        local encodedValue = HttpService:UrlEncode(value)

        encoded ..= `{encodedKey}={encodedValue}&`
    end

    -- remove the trailing &
    return string.sub(encoded, 1, #encoded - 1)
end

--- Given any captured exception, extract its keys and create a sorted
--- and truncated list that will be used inside the event message.
--- eg. `Non-error exception captured with keys: foo, bar, baz`
function ObjectUtils.extractExceptionKeysForMessage(exception: Map<string, unknown>, maxLength_: number?): string
    local maxLength = maxLength_ or 40

    local keys = Object.keys(exception)
    table.sort(keys)

    if #keys == 0 then
        return "[object has no keys]"
    end

    if #keys[1] >= maxLength then
        return truncate(keys[1], maxLength)
    end

    local includedKeys = #keys
    while includedKeys >= 1 do
        includedKeys -= 1

        local serialized = table.concat(Array.slice(keys, 1, includedKeys), ", ")
        if #serialized >= maxLength then
            continue
        end
        if includedKeys == #keys then
            return serialized
        end
        return truncate(serialized, maxLength)
    end

    return ""
end

return ObjectUtils
