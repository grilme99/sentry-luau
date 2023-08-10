-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/dsn.ts

local Types = require("@packages/types")
type DsnComponents = Types.DsnComponents
type DsnLike = Types.DsnLike
type DsnProtocol = Types.DsnProtocol

local RegExp = require("./vendor/regexp")
local logger = require("./logger").logger
local console = require("./polyfill/console")

--- Regular expression used to parse a Dsn.
local DSN_REGEX = RegExp([[^(?:(\w+):)\/\/(?:(\w+)(?::(\w+)?)?@)([\w.-]+)(?::(\d+))?\/(.+)]])

local function isValidProtocol(protocol: string?): boolean
    return protocol == "http" or protocol == "https"
end

local DsnUtils = {}

--- Renders the string representation of this Dsn.
---
--- By default, this will render the public representation without the password
--- component. To get the deprecated private representation, set `withPassword`
--- to true.
---
--- @param withPassword When set to true, the password will be included.
function DsnUtils.dsnToString(dsn: DsnComponents, withPassword_: boolean?): string
    local withPassword = if withPassword_ == nil then false else withPassword_

    return (
        `{dsn.protocol}://{dsn.publicKey}{if withPassword and dsn.pass then `:{dsn.pass}` else ""}`
        .. `@{dsn.host}{if dsn.port then `:{dsn.port}` else ""}/{if dsn.path then `{dsn.path}/` else dsn.path}{dsn.projectId}`
    )
end

function DsnUtils.dsnFromComponents(components: DsnComponents): DsnComponents
    return {
        protocol = components.protocol,
        publicKey = components.publicKey or "",
        pass = components.pass or "",
        host = components.host,
        port = components.port or "",
        path = components.path or "",
        projectId = components.projectId,
    }
end

--- Parses a Dsn from a given string.
---
--- @param str A Dsn as string
--- @returns Dsn as DsnComponents or undefined if @param str is not a valid DSN string
local function dsnFromString(str: string): DsnComponents | nil
    local match = DSN_REGEX:exec(str)

    if not match then
        -- This should be logged to the console
        console.error(`Invalid Sentry Dsn: {str}`)
        return nil
    end

    local protocol, publicKey, pass_, host, port_, lastPath = match[2], match[3], match[4], match[5], match[6], match[7]
    local pass, port = pass_ or "", port_ or ""

    local path = ""
    local projectId = lastPath

    local split = string.split(projectId, "/")
    if #split > 1 then
        path = table.concat(split, "/", 1, #split - 1)
        projectId = split[#split]
    end

    if projectId then
        local projectMatch = string.match(projectId, "^%d+")
        if projectMatch then
            projectId = projectMatch
        end
    end

    return DsnUtils.dsnFromComponents({
        host = host,
        pass = pass,
        path = path,
        projectId = projectId,
        port = port,
        protocol = protocol,
        publicKey = publicKey,
    })
end

local function validateDsn(dsn: DsnComponents): boolean
    if not _G.__SENTRY_DEV__ then
        return true
    end

    local port, projectId, protocol = dsn.port, dsn.projectId, dsn.protocol

    local requiredComponents = { "protocol", "publicKey", "host", "projectId" }
    local hasMissingRequiredComponent = false

    for _, component in ipairs(requiredComponents) do
        if not dsn[component] then
            logger.error("Invalid Sentry Dsn: " .. component .. " missing")
            hasMissingRequiredComponent = true
            break
        end
    end

    if hasMissingRequiredComponent then
        return false
    end

    if not string.match(projectId, "^%d+$") then
        logger.error("Invalid Sentry Dsn: Invalid projectId " .. projectId)
        return false
    end

    if not isValidProtocol(protocol) then
        logger.error("Invalid Sentry Dsn: Invalid protocol " .. protocol)
        return false
    end

    if port and not tonumber(port) then
        logger.error("Invalid Sentry Dsn: Invalid port " .. port)
        return false
    end

    return true
end

--- Creates a valid Sentry Dsn object, identifying a Sentry instance and project.
--- @returns a valid DsnComponents object or `undefined` if @param from is an invalid DSN source
function DsnUtils.makeDsn(from: DsnLike): DsnComponents | nil
    local components = if type(from) == "string" then dsnFromString(from) else DsnUtils.dsnFromComponents(from)
    if not components or not validateDsn(components) then
        return nil
    end
    return components
end

return DsnUtils
