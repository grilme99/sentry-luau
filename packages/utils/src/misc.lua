-- upstream: https://github.com/getsentry/sentry-javascript/blob/d3abf450b844c595dfa576f2afcfe223fb038c51/packages/utils/src/misc.ts

local ArrayUtils = require("./array")

type Array<T> = { T }

local MiscUtils = {}

--- UUID4 generator
function MiscUtils.uuid4(): string
    -- deviation: Lua has no crypto library out of the box, so the simplest option right now is to just use math.random.
    -- TODO: Should this be revisited to use a better rng implementation? Math.random shares a global seed and this may
    --  cause issues with other scripts.
    local function getRandomByte()
        math.randomseed(os.time() * os.clock())
        return math.random() * 16
    end

    -- http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/2117523#2117523
    -- Concatenating the following numbers as strings results in '10000000100040008000100000000000'
    local uuid = (`{1e7}{1e3}{4e3}{8e3}{1e11}`):gsub("[018]", function(c)
        local numC = tonumber(c) :: number
        return string.format("%x", bit32.bxor(numC, bit32.arshift(bit32.band(getRandomByte(), 15), numC / 4)))
    end)

    return uuid
end

--- Checks whether the given input is already an array, and if it isn't, wraps it in one.
---
--- @param maybeArray Input to turn into an array, if necessary
--- @return The input, if already an array, or an array with the input as the only element, if not
function MiscUtils.arrayify<T>(maybeArray: T | Array<T>): Array<T>
    return if ArrayUtils.isArray(maybeArray) then maybeArray :: Array<T> else { maybeArray :: T }
end

return MiscUtils
