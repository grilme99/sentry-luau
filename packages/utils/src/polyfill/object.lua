-- note: no upstream

type Map<K, V> = { [K]: V }

local ObjectUtils = {}

function ObjectUtils.mergeObjects(...: Map<string, any>): Map<string, any>
    local result = {}

    local args = { ... }
    for _, dictionary in ipairs(args) do
        for k, v in pairs(dictionary) do
            result[k] = v
        end
    end

    return result
end

return ObjectUtils
