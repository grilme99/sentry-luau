-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/object.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

local String = require(PackageRoot.string)
local truncate = String.truncate

local Is = require(PackageRoot.is)
local isPlainObject = Is.isPlainObject

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

local function _dropUndefinedKeys<K, V>(inputValue: Map<K, V>, memoizationMap: Map<unknown, unknown>): Map<K, V>
    if isPlainObject(inputValue) then
        -- If this node has already been visited due to a circular reference, return the object it was mapped to in the
        -- new object
        local memoVal = memoizationMap[inputValue]
        if memoVal then
            return memoVal :: any
        end

        local returnValue = {}
        -- Store the mapping of this value in case we visit it again, in case of circular data
        memoizationMap[inputValue] = returnValue

        for key, value in inputValue do
            if type(value) ~= "nil" then
                returnValue[key] = _dropUndefinedKeys(value :: any, memoizationMap)
            end
        end

        return returnValue :: any
    end

    if Array.isArray(inputValue) then
        -- If this node has already been visited due to a circular reference, return the array it was mapped to in the new object
        local memoVal = memoizationMap[inputValue]
        if memoVal then
            return memoVal :: any
        end

        local returnValue: { unknown } = {}
        -- Store the mapping of this value in case we visit it again, in case of circular data
        memoizationMap[inputValue] = returnValue

        for _, item in inputValue do
            table.insert(returnValue, _dropUndefinedKeys(item :: any, memoizationMap))
        end

        return returnValue :: any
    end

    return inputValue
end

--- Given any object, return a new object having removed all fields whose value was `undefined`.
--- Works recursively on objects and arrays.
---
--- Attention: This function keeps circular references in the returned object.
function ObjectUtils.dropUndefinedKeys<K, V>(inputValue: Map<K, V>): Map<K, V>
    -- This map keeps track of what already visited nodes map to.
    -- Our Set - based memoBuilder doesn't work here because we want to the output object to have the same circular
    -- references as the input object.
    local memoizationMap: Map<unknown, unknown> = {}

    -- This function just proxies `_dropUndefinedKeys` to keep the `memoBuilder` out of this function's API
    return _dropUndefinedKeys(inputValue, memoizationMap)
end

return ObjectUtils
