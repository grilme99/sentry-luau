-- upstream: https://github.com/getsentry/sentry-javascript/blob/d3abf450b844c595dfa576f2afcfe223fb038c51/packages/utils/src/time.ts#L122

local TimeUtils = {}

--- Returns a timestamp in seconds since the UNIX epoch.
function TimeUtils.timestampInSeconds()
    -- deviation: In JS, this util switches its source of truth based on the availability of the JS Performance API. Lua
    --  doesn't have this problem, so we can just use a single API.
    return os.time()
end

--- deviation: We don't need a distinction between the time APIs in Lua
TimeUtils.dateTimestampInSeconds = TimeUtils.timestampInSeconds

return TimeUtils
