-- based on: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/stack-parsers.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type StackFrame = Types.StackFrame
type StackLineParser = Types.StackLineParser
type StackLineParserFn = Types.StackLineParserFn

local Utils = require(Packages.SentryUtils)
local createStackParser = Utils.createStackParser

local StackParser = {}

local robloxParser: StackLineParserFn = function(line)
    local path, lineNumber, functionName

    -- note: These pattern matches are based on another Sentry SDK for Roblox
    -- https://github.com/devSparkle/sentry-roblox/blob/429eda39bcfddc3d6065b9744193613b34fce067/src/Integrations/StackProcessor.lua#L32-L56
    if string.find(line, "^Script ") then
        path, lineNumber, functionName = string.match(line, "^Script '(.-)', Line (%d+)%s?%-?%s?(.*)$")
    elseif string.find(line, ", line") then
        path, lineNumber, functionName = string.match(line, "^(.-), line (%d+)%s?%-?%s?(.*)$")
    else
        path, lineNumber, functionName = string.match(line, "^(.-):(%d+)%s?%-?%s?(.*)$")
    end

    if functionName then
        functionName = string.gsub(functionName, "function ", "")
    end

    return {
        filename = path,
        function_ = functionName,
        lineno = tonumber(lineNumber),
    }
end

local robloxStackLineParser: StackLineParser = {
    priority = 100,
    parser = robloxParser,
}
StackParser.robloxStackLineParser = robloxStackLineParser

StackParser.defaultStackParser = createStackParser(robloxStackLineParser)

return StackParser
