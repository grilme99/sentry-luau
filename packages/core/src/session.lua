local Types = require("@packages/types")
type SerializedSession = Types.SerializedSession
type Session = Types.Session
type SessionContext = Types.SessionContext
type SessionStatus = Types.SessionStatus

local Utils = require("@packages/utils")
local timestampInSeconds, uuid4 = Utils.timestampInSeconds, Utils.uuid4

local Session = {}

--- Serializes a passed session object to a JSON object with a slightly different structure.
--- This is necessary because the Sentry backend requires a slightly different schema of a session
--- than the one the Lua SDKs use internally.
---
--- @param session the session to be converted
---
--- @returns a JSON object of the passed session
local function sessionToJSON(_session: Session): SerializedSession
    error("sessionToJSON unimplemented")

    -- return {
    --     sid = `${session.sid}`,
    --     init = session.init,
    --     -- Make sure that sec is converted to ms for date constructor
    --     -- TODO: Implement ISO string conversion
    --     -- started = Date.new(session.started * 1000).toISOString(),
    --     -- timestamp = Date.new(session.timestamp * 1000).toISOString(),
    --     status = session.status,
    --     errors = session.errors,
    --     did = if type(session.did) == "number" or type(session.did) == "string" then `${session.did}` else nil,
    --     duration = session.duration,
    --     attrs = {
    --         release = session.release,
    --         environment = session.environment,
    --         ip_address = session.ipAddress,
    --         user_agent = session.userAgent,
        -- },
    -- }
end

--- Creates a new `Session` object by setting certain default parameters. If optional @param context
--- is passed, the passed properties are applied to the session object.
---
--- @param context (optional) additional properties to be applied to the returned session object
---
--- @return a new `Session` object
function Session.makeSession(context: SessionContext): Session
    -- Both timestamp and started are in seconds since the UNIX epoch.
    local startingTime = timestampInSeconds()

    local session: Session
    session = {
        sid = uuid4(),
        init = true,
        timestamp = startingTime,
        started = startingTime,
        duration = 0,
        status = "ok",
        errors = 0,
        ignoreDuration = false,
        toJSON = function()
            return sessionToJSON(session)
        end,
    }

    if context then
        Session.updateSession(session, context)
    end

    return session
end

--- Updates a session object with the properties passed in the context.
---
--- Note that this function mutates the passed object and returns void.
--- (Had to do this instead of returning a new and updated session because closing and sending a session
--- makes an update to the session after it was passed to the sending logic.
--- @see BaseClient.captureSession )
---
--- @param session the `Session` to update
--- @param context the `SessionContext` holding the properties that should be updated in @param session
function Session.updateSession(session: Session, context_: SessionContext?)
    local context: SessionContext = context_ or {} :: any

    if context.user then
        if not session.ipAddress and context.user.ip_address then
            session.ipAddress = context.user.ip_address
        end

        if not session.did and not context.did then
            session.did = context.user.id or context.user.email or context.user.username
        end
    end

    session.timestamp = context.timestamp or timestampInSeconds()

    if context.ignoreDuration then
        session.ignoreDuration = context.ignoreDuration
    end
    if context.sid then
        -- Good enough uuid validation. — Kamil
        session.sid = if #context.sid == 32 then context.sid else uuid4()
    end
    if context.init ~= nil then
        session.init = context.init
    end
    if not session.did and context.did then
        session.did = tostring(context.did)
    end
    if type(context.started) == "number" then
        session.started = context.started
    end
    if session.ignoreDuration then
        session.duration = nil
    elseif type(context.duration) == "number" then
        session.duration = context.duration
    else
        local duration = session.timestamp - session.started
        session.duration = if duration >= 0 then duration else 0
    end
    if context.release then
        session.release = context.release
    end
    if context.environment then
        session.environment = context.environment
    end
    if not session.ipAddress and context.ipAddress then
        session.ipAddress = context.ipAddress
    end
    if not session.userAgent and context.userAgent then
        session.userAgent = context.userAgent
    end
    if type(context.errors) == "number" then
        session.errors = context.errors
    end
    if context.status then
        session.status = context.status
    end
end

--- Closes a session by setting its status and updating the session object with it.
--- Internally calls `updateSession` to update the passed session object.
---
--- Note that this function mutates the passed session (@see updateSession for explanation).
---
--- @param session the `Session` object to be closed
--- @param status the `SessionStatus` with which the session was closed. If you don't pass a status,
---               this function will keep the previously set status, unless it was `'ok'` in which case
---               it is changed to `'exited'`.
function Session.closeSession(session: Session, status: SessionStatus?)
    local context = {}
    if status then
        context = { status = status }
    elseif session.status == "ok" then
        context = { status = "exited" :: SessionStatus }
    end

    Session.updateSession(session, context)
end

return Session
