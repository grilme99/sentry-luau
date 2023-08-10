-- note: no upstream
-- note: taken from LuauPolyfill, to avoid importing the entire package

--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

type Array<T> = { T }

local ArrayUtils = {}

local RECEIVED_OBJECT_ERROR = "Array.concat(...) only works with array-like tables but "
    .. "it received an object-like table.\nYou can avoid this error by wrapping the "
    .. "object-like table into an array. Example: `concat({1, 2}, {a = true})` should "
    .. "be `concat({1, 2}, { {a = true} }`"

function ArrayUtils.isArray(value: any): boolean
    if typeof(value) ~= "table" then
        return false
    end
    if next(value) == nil then
        -- an empty table is an empty array
        return true
    end

    local length = #value

    if length == 0 then
        return false
    end

    local count = 0
    local sum = 0
    for key in pairs(value) do
        if typeof(key) ~= "number" then
            return false
        end
        if key % 1 ~= 0 or key < 1 then
            return false
        end
        count += 1
        sum += key
    end

    return sum == (count * (count + 1) / 2)
end

function ArrayUtils.concat<T, S>(source: Array<T> | T, ...: Array<S> | S): Array<T> & Array<S>
    local array
    local elementCount = 0

    if ArrayUtils.isArray(source) then
        array = table.clone(source :: Array<T>)
        elementCount = #(source :: Array<T>)
    else
        elementCount += 1
        array = {}
        array[elementCount] = source :: T
    end

    for i = 1, select("#", ...) do
        local value = select(i, ...)
        local valueType = typeof(value)

        -- selene:allow(empty_if)
        if value == nil then
            -- do not insert nil
        elseif valueType == "table" then
            -- deviation: assume that table is an array, to avoid the expensive
            -- `isArray` check. In DEV mode, we throw if it is given an object-like
            -- table.
            
            if _G.__SENTRY_DEV__ then
                if not ArrayUtils.isArray(value) then
                    error(RECEIVED_OBJECT_ERROR)
                end
            end
            for k = 1, #value do
                elementCount += 1
                array[elementCount] = value[k]
            end
        else
            elementCount += 1
            array[elementCount] = value
        end
    end

    return (array :: any) :: Array<T> & Array<S>
end

type PredicateFunction<T> = (T, number, Array<T>) -> boolean

function ArrayUtils.findIndex<T>(array: Array<T>, predicate: PredicateFunction<T>): number
    for i = 1, #array do
        local element = array[i]
        if predicate(element, i, array) then
            return i
        end
    end
    return -1
end

-- Implements equivalent functionality to JavaScript's `array.splice`, including
-- the interface and behaviors defined at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/splice
function ArrayUtils.splice<T>(array: Array<T>, start: number, deleteCount: number?, ...: T): Array<T>
    -- Append varargs without removing anything
    if start > #array then
        local varargCount = select("#", ...)
        for i = 1, varargCount do
            local toInsert = select(i, ...)
            table.insert(array, toInsert)
        end
        return {}
    else
        local length = #array
        -- In the JS impl, a negative fromIndex means we should use length -
        -- index; with Lua, of course, this means that 0 is still valid, but
        -- refers to the end of the array the way that '-1' would in JS
        if start < 1 then
            start = math.max(length - math.abs(start), 1)
        end

        local deletedItems = {} :: Array<T>
        -- If no deleteCount was provided, we want to delete the rest of the
        -- array starting with `start`
        local deleteCount_: number = deleteCount or length
        if deleteCount_ > 0 then
            local lastIndex = math.min(length, start + math.max(0, deleteCount_ - 1))

            for _ = start, lastIndex do
                local deleted = table.remove(array, start) :: T
                table.insert(deletedItems, deleted)
            end
        end

        local varargCount = select("#", ...)
        -- Do this in reverse order so we can always insert in the same spot
        for i = varargCount, 1, -1 do
            local toInsert = select(i, ...)
            table.insert(array, start, toInsert)
        end

        return deletedItems
    end
end

-- Implements equivalent functionality to JavaScript's `array.indexOf`,
-- implementing the interface and behaviors defined at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf
--
-- This implementation is loosely based on the one described in the polyfill
-- source in the above link
function ArrayUtils.indexOf<T>(array: Array<T>, searchElement: T, fromIndex: number?): number
    local fromIndex_ = fromIndex or 1
    local length = #array

    -- In the JS impl, a negative fromIndex means we should use length - index;
    -- with Lua, of course, this means that 0 is still valid, but refers to the
    -- end of the array the way that '-1' would in JS
    if fromIndex_ < 1 then
        fromIndex_ = math.max(length - math.abs(fromIndex_), 1)
    end

    for i = fromIndex_, length do
        if array[i] == searchElement then
            return i
        end
    end

    return -1
end

return ArrayUtils
