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

local StringUtils = {}

function StringUtils.startsWith(value: string, substring: string, position: number?): boolean
    if string.len(substring) == 0 then
        return true
    end
    -- Luau FIXME: we have to use a tmp variable, as Luau doesn't understand the logic below narrow position to `number`
    local position_
    if position == nil or position < 1 then
        position_ = 1
    else
        position_ = position
    end

    if position_ > string.len(value) then
        return false
    end
    return value:find(substring, position_, true) == position_
end

function StringUtils.trimEnd(source: string): string
    return (source:gsub("[%s]+$", ""))
end

function StringUtils.trimStart(source: string): string
    return (source:gsub("^[%s]+", ""))
end

function StringUtils.trim(source: string): string
    return StringUtils.trimStart(StringUtils.trimEnd(source))
end

-- excluding the `+` and `*` character, since findOr tests and graphql use them explicitly
local luaPatternCharacters = "([" .. ("$%^()-[].?"):gsub("(.)", "%%%1") .. "])"

function StringUtils.includes(str: string, substring: string, position: (string | number)?): boolean
    local strLen, invalidBytePosition = utf8.len(str)
    assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))
    if strLen == 0 then
        return false
    end

    if #substring == 0 then
        return true
    end

    local startIndex = 1
    if position ~= nil then
        startIndex = tonumber(position) or 1
        if startIndex > strLen then
            return false
        end
    end

    if startIndex < 1 then
        startIndex = 1
    end

    local init = utf8.offset(str, startIndex)
    local value = substring:gsub(luaPatternCharacters, "%%%1")
    local iStart, _ = string.find(str, value, init)
    return iStart ~= nil
end

return StringUtils
