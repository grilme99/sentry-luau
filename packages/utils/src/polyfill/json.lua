-- note: no upstream

local JsonPolyfill = {}

-- Polyfill for encoding an object as json in different lua environments
function JsonPolyfill.stringify(value: any): string
    local isRoblox = game ~= nil
    if isRoblox then
        return game:GetService("HttpService"):JSONEncode(value)
    end

    local success, luneSerde = pcall(require, "@lune/serde")
    if success then
        luneSerde.encode("json", value)
    end

    error("This environment doesn't support encoding JSON")
end

return JsonPolyfill
