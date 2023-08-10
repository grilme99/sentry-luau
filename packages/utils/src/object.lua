-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/object.ts

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

return ObjectUtils
