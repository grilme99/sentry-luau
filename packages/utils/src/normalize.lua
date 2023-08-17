-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/normalize.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Primitive = Types.Primitive

local Is = require(PackageRoot.is)
local isSyntheticEvent = Is.isSyntheticEvent
local isNaN = Is.isNaN

local Memo = require(PackageRoot.memo)
type MemoFunc = Memo.MemoFunc
local memoBuilder = Memo.memoBuilder

local Stacktrace = require(PackageRoot.stacktrace)
local getFunctionName = Stacktrace.getFunctionName

local JSON = require(PackageRoot.polyfill.json)
local String = require(PackageRoot.polyfill.string)

type ObjOrArray<T> = { [string | number]: T }

local Normalize = {}

--- Stringify the given value. Handles various known special values and types.
---
--- Not meant to be used on simple primitives which already have a string representation, as it will, for example, turn
--- the number 1231 into "[Object Number]", nor on `null`, as it will throw.
---
--- @param value The value to stringify
--- @returns A stringified representation of the given value
function stringifyValue(key: unknown, value: any): string
    local success, result = pcall(function()
        if key == "domain" and value and type(value) == "table" and value._events then
            return "[Domain]"
        end

        if key == "domainEmitter" then
            return "[DomainEmitter]"
        end

        if type(_G) == "table" and value == _G then
            return "[Global]"
        end

        if type(shared) == "table" and value == shared then
            return "[Shared]"
        end

        -- React's SyntheticEvent thingy
        if isSyntheticEvent(value) then
            return "[SyntheticEvent]"
        end

        if type(value) == "number" and value ~= value then
            return "[NaN]"
        end

        if type(value) == "function" then
            return `[Function: {getFunctionName(value)}]`
        end

        if type(value) == "userdata" then
            local userDataName = typeof(value)
            return `[UserData: {userDataName}]`
        end

        return "[object Object]"
    end)

    if success then
        return result
    else
        return `**non-serializable** ({result})`
    end
end

--- Visits a node to perform normalization on it
---
--- @param key The key corresponding to the given node
--- @param value The node to be visited
--- @param depth Optional number indicating the maximum recursion depth
--- @param maxProperties Optional maximum number of properties/elements included in any single object/array
--- @param memo Optional Memo class handling decycling
function visit(
    key: string | number,
    value: unknown,
    depth_: number?,
    maxProperties_: number?,
    memo_: MemoFunc?
): Primitive | ObjOrArray<unknown>
    local depth = depth_ or 100
    local maxProperties = maxProperties_ or math.huge
    local memo = memo_ or memoBuilder()

    local memoize, unmemoize = memo.memoize, memo.unmemoize

    -- Get the simple cases out of the way first
    if value == nil or table.find({ "number", "boolean", "string" }, type(value)) and not isNaN(value) then
        return value :: Primitive
    end

    local stringified = stringifyValue(key, value)

    -- Anything we could potentially dig into more (objects or arrays) will have come back as `"[object XXXX]"`.
    -- Everything else will have already been serialized, so if we don't see that pattern, we're done.
    if not String.startsWith(stringified, "[object ") then
        return stringified
    end

    -- Do not normalize objects that we know have already been normalized. As a general rule, the
    -- "__sentry_skip_normalization__" property should only be used sparingly and only should only be set on objects that
    -- have already been normalized.
    if (value :: ObjOrArray<unknown>)["__sentry_skip_normalization__"] then
        return value :: ObjOrArray<unknown>
    end

    -- We can set `__sentry_override_normalization_depth__` on an object to ensure that from there
    -- We keep a certain amount of depth.
    -- This should be used sparingly, e.g. we use it for the redux integration to ensure we get a certain amount of state.
    local remainingDepth = if type((value :: ObjOrArray<unknown>)["__sentry_override_normalization_depth__"])
            == "number"
        then (value :: ObjOrArray<unknown>)["__sentry_override_normalization_depth__"] :: number
        else depth

    -- We're also done if we've reached the max depth
    if remainingDepth == 0 then
        -- At this point we know `serialized` is a string of the form `"[object XXXX]"`. Clean it up so it's just `"[XXXX]"`.
        return string.gsub(stringified, "object ", "")
    end

    -- If we've already visited this branch, bail out, as it's circular reference. If not, note that we're seeing it now.
    if memoize(value) then
        return "[Circular ~]"
    end

    -- If the value has a `toJSON` method, we call it to extract more information
    local valueWithToJSON = value :: unknown & { toJSON: ((...any) -> unknown)? }
    if valueWithToJSON and type(valueWithToJSON.toJSON) == "function" then
        local success, jsonValue = pcall(valueWithToJSON.toJSON, valueWithToJSON)
        if success then
            -- We need to normalize the return value of `.toJSON()` in case it has circular references
            return visit("", jsonValue, remainingDepth - 1, maxProperties, memo)
        end
    end

    -- At this point we know we either have an object or an array, we haven't seen it before, and we're going to recurse
    -- because we haven't yet reached the max depth. Create an accumulator to hold the results of visiting each
    -- property/entry, and keep track of the number of items we add to it.
    local normalized = {} :: ObjOrArray<unknown>
    local numAdded = 0

    local visitable = value :: ObjOrArray<unknown>

    for visitKey, _ in visitable do
        if numAdded >= maxProperties then
            normalized[visitKey] = "[MaxProperties ~]"
            break
        end

        -- Recursively visit all the child nodes
        local visitValue = visitable[visitKey]
        normalized[visitKey] = visit(visitKey, visitValue, remainingDepth - 1, maxProperties, memo)

        numAdded += 1
    end

    -- Once we've visited all the branches, remove the parent from memo storage
    unmemoize(value)

    -- Return accumulated values
    return normalized
end

--- Recursively normalizes the given object.
---
--- - Creates a copy to prevent original input mutation
--- - Skips non-enumerable properties
--- - When stringifying, calls `toJSON` if implemented
--- - Removes circular references
--- - Translates non-serializable values (`undefined`/`NaN`/functions) to serializable format
--- - Translates known global objects/classes to a string representations
--- - Takes care of `Error` object serialization
--- - Optionally limits depth of final output
--- - Optionally limits number of properties/elements included in any single object/array
---
--- @param input The object to be normalized.
--- @param depth The max depth to which to normalize the object. (Anything deeper stringified whole.)
--- @param maxProperties The max number of elements or properties to be included in any single array or
--- object in the normalized output.
--- @return A normalized version of the object, or `"------non-serializable------"` if any errors are thrown during normalization.
function Normalize.normalize(input: unknown, depth_: number?, maxProperties_: number?): any
    local depth = depth_ or 100
    local maxProperties = maxProperties_ or math.huge

    local success, result = pcall(visit, "", input, depth, maxProperties)
    if success then
        return result
    else
        return { ERROR = `------non-serializable------ ({result})` }
    end
end

--- Calculates bytes size of input object
function jsonSize(value: any): number
    local size = utf8.len(JSON.stringify(value))
    return size :: number
end

function Normalize.normalizeToSize<T>(
    object: { [string]: any },
    -- Default Node.js REPL depth
    depth_: number?,
    -- 100kB, as 200kB is max payload size, so half sounds reasonable
    maxSize_: number?
): T
    local depth = depth_ or 3
    local maxSize = maxSize_ or 100 --- 1024

    local normalized = Normalize.normalize(object, depth)

    if jsonSize(normalized) > maxSize then
        return Normalize.normalizeToSize(object, depth - 1, maxSize)
    end

    return normalized
end

return Normalize
