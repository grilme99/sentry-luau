-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/ratelimit.ts

local Types = require("@packages/types")
type TransportMakeRequestResponse = Types.TransportMakeRequestResponse

local Is = require("./is")
local isNaN = Is.isNaN

local String = require("./polyfill/string")

type Record<K, V> = { [K]: V }

-- Intentionally keeping the key broad, as we don't know for sure what rate limit headers get returned from backend
export type RateLimits = Record<string, number>

local RateLimit = {}

local DEFAULT_RETRY_AFTER = 60 -- 60 seconds
RateLimit.DEFAULT_RETRY_AFTER = DEFAULT_RETRY_AFTER

--- Extracts Retry-After value from the request header or returns default value
--- @param header string representation of 'Retry-After' header
--- @param now current unix timestamp
function RateLimit.parseRetryAfterHeader(header: string, now_: number?): number
    local now = now_ or os.time()
    local headerDelay = tonumber(`{header}`, 10)
    if headerDelay and not isNaN(headerDelay) then
        return headerDelay
    end

    local success, headerDate = pcall(DateTime.fromIsoDate, `{header}`)
    if success then
        return headerDate.UnixTimestamp - now
    end

    return DEFAULT_RETRY_AFTER
end

--- Gets the time that the given category is disabled until for rate limiting.
--- In case no category-specific limit is set but a general rate limit across all categories is active,
--- that time is returned.
---
--- @return the time in ms that the category is disabled until or 0 if there's no active rate limit.
function RateLimit.disabledUntil(limits: RateLimits, category: string): number
    return limits[category] or limits.all or 0
end

--- Checks if a category is rate limited
function RateLimit.isRateLimited(limits: RateLimits, category: string, now_: number?): boolean
    local now = now_ or os.time()
    return RateLimit.disabledUntil(limits, category) > now
end

--- Update ratelimits from incoming headers.
---
--- @return the updated RateLimits object.
function RateLimit.updateRateLimits(
    limits: RateLimits,
    response: TransportMakeRequestResponse,
    now_: number?
): RateLimits
    local statusCode, headers = response.statusCode, response.headers
    local now = now_ or os.time()

    local updatedRateLimits: RateLimits = table.clone(limits)

    -- "The name is case-insensitive."
    -- https://developer.mozilla.org/en-US/docs/Web/API/Headers/get
    local rateLimitHeader = headers and headers["x-sentry-rate-limits"]
    local retryAfterHeader = headers and headers["retry-after"]

    if rateLimitHeader then
        --[[
            rate limit headers are of the form
                <header>,<header>,..
            where each <header> is of the form
                <retry_after>: <categories>: <scope>: <reason_code>
            where
                <retry_after> is a delay in seconds
                <categories> is the event type(s) (error, transaction, etc) being rate limited and is of the form
                    <category>;<category>;...
                <scope> is what's being limited (org, project, or key) - ignored by SDK
                <reason_code> is an arbitrary string like "org_quota" - ignored by SDK
        ]]

        for _, limit in string.split(String.trim(rateLimitHeader), ",") do
            local limitSplit = string.split(limit, ":")
            local retryAfter, categories = limitSplit[1], limitSplit[2]

            local headerDelay = tonumber(retryAfter, 10)
            local delay = if headerDelay then headerDelay else 60 -- 60 second default

            if not categories then
                updatedRateLimits.all = now + delay
            else
                for _, category in string.split(categories, ",") do
                    updatedRateLimits[category] = now + delay
                end
            end
        end
    elseif retryAfterHeader then
        updatedRateLimits.all = now + RateLimit.parseRetryAfterHeader(retryAfterHeader, now)
    elseif statusCode == 429 then
        updatedRateLimits.all = now + 60
    end

    return updatedRateLimits
end

return RateLimit
