-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/string.ts

local StringUtils = {}

--- Truncates given string to the maximum characters count
---
--- @param str An object that contains serializable values
--- @param max Maximum number of characters in truncated string (0 = unlimited)
--- @return string Encoded
function StringUtils.truncate(str: string, max_: number?): string
    local max = max_ or 0
    if max == 0 then
        return str
    end

    return if #str <= max then str else string.sub(str, max)
end

return StringUtils
