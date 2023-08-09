-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/sessionflusher.ts

local Types = require("@packages/types")
type AggregationCounts = Types.AggregationCounts
type Client = Types.Client
type RequestSessionStatus = Types.RequestSessionStatus
type SessionAggregates = Types.SessionAggregates
type SessionFlusherLike = Types.SessionFlusherLike

local Hub = require("./hub")
local getCurrentHub = Hub.getCurrentHub

type Array<T> = { T }
type Record<K, V> = { [K]: V }

type ReleaseHealthAttributes = {
    environment: string?,
    release: string,
}

local SessionFlusher = {}
SessionFlusher.__index = SessionFlusher

function SessionFlusher.new(client: Client, attrs: ReleaseHealthAttributes)
    local self = setmetatable({}, SessionFlusher)

    self.flushTimeout = 60
    self._pendingAggregates = {} :: Record<number, AggregationCounts>
    self._sessionAttrs = attrs
    -- self._intervalId: ReturnType<typeof setInterval>;
    self._runningLoop = true
    self._isEnabled = true
    self._client = client

    task.spawn(function()
        while self._runningLoop do
            (self :: any):flush()
            task.wait(self.flushTimeout)
        end
    end)

    return self
end

export type SessionFlusher = typeof(SessionFlusher.new(...))

--- Checks if `pendingAggregates` has entries, and if it does flushes them by calling `sendSession`
function SessionFlusher.flush(self: SessionFlusher)
    local sessionAggregates = self:getSessionAggregates()
    if #sessionAggregates.aggregates == 0 then
        return
    end
    self._pendingAggregates = {}
    self._client:sendSession(sessionAggregates)
end

--- Massages the entries in `pendingAggregates` and returns aggregated sessions
function SessionFlusher.getSessionAggregates(self: SessionFlusher): SessionAggregates
    local sessionAggregates: SessionAggregates = {
        attrs = self._sessionAttrs,
        aggregates = self._pendingAggregates,
    }
    return sessionAggregates
end

function SessionFlusher.close(self: SessionFlusher)
    self._runningLoop = false
    self._isEnabled = false
    self:flush()
end

--- Wrapper function for _incrementSessionStatusCount that checks if the instance of SessionFlusher is enabled then
--- fetches the session status of the request from `Scope.getRequestSession().status` on the scope and passes them to
--- `_incrementSessionStatusCount` along with the start date
function SessionFlusher.incrementSessionStatusCount(self: SessionFlusher)
    if not self._isEnabled then
        return
    end

    local scope = getCurrentHub():getScope()
    local requestSession = scope:getRequestSession()

    if requestSession and requestSession.status then
        self:_incrementSessionStatusCount(requestSession.status)
        -- This is not entirely necessary but is added as a safe guard to indicate the bounds of a request and so in
        -- case captureRequestSession is called more than once to prevent double count
        scope:setRequestSession(nil)
    end
end

--- Increments status bucket in pendingAggregates buffer (internal state) corresponding to status of the session
--- received
function SessionFlusher._incrementSessionStatusCount(self: SessionFlusher, status: RequestSessionStatus): number
    -- Truncate minutes and seconds on Session Started attribute to have one minute bucket keys
    local currentTime = os.time()
    local sessionStartedTrunc = currentTime - (currentTime % 60)
    self._pendingAggregates[sessionStartedTrunc] = self._pendingAggregates[sessionStartedTrunc] or {} :: any

    -- corresponds to aggregated sessions in one specific minute bucket
    -- for example, {"started":"2021-03-16T08:00:00.000Z","exited":4, "errored": 1}
    local aggregationCounts: AggregationCounts = self._pendingAggregates[sessionStartedTrunc]
    if aggregationCounts.started == nil then
        aggregationCounts.started = DateTime.now():ToIsoDate()
    end

    if status == "errored" then
        aggregationCounts.errored = (aggregationCounts.errored or 0) + 1
        return aggregationCounts.errored :: number
    elseif status == "ok" then
        aggregationCounts.exited = (aggregationCounts.exited or 0) + 1
        return aggregationCounts.exited :: number
    else
        aggregationCounts.crashed = (aggregationCounts.crashed or 0) + 1
        return aggregationCounts.crashed :: number
    end
end

return SessionFlusher
