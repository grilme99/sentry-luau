-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/integrations/inboundfilters.ts

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array

local RegExp = require(Packages.RegExp)
type RegExp = RegExp.RegExp

local Types = require(Packages.SentryTypes)
type Event = Types.Event
type EventProcessor = Types.EventProcessor
type Hub = Types.Hub
type Integration = Types.Integration
type StackFrame = Types.StackFrame
type Exception = Types.Exception

local Utils = require(Packages.SentryUtils)
local getEventDescription = Utils.getEventDescription
local logger = Utils.logger
local stringMatchesSomePattern = Utils.stringMatchesSomePattern

type Array<T> = { T }

local DEFAULT_IGNORE_ERRORS: Array<RegExp> = {}
local DEFAULT_IGNORE_TRANSACTIONS: Array<RegExp> = {}

--- Options for the InboundFilters integration
type InboundFiltersOptions = {
    allowUrls: Array<string | RegExp>?,
    denyUrls: Array<string | RegExp>?,
    ignoreErrors: Array<string | RegExp>?,
    ignoreTransactions: Array<string | RegExp>?,
    ignoreInternal: boolean?,
    disableErrorDefaults: boolean?,
    disableTransactionDefaults: boolean?,
}

local function _isSentryError(event: Event): boolean
    local firstException = event.exception and event.exception.values and event.exception.values[1]
    return if firstException and type(firstException) == "table" then firstException.type == "SentryError" else false
end

local function _getPossibleEventMessages(event: Event): Array<string>
    if event.message then
        return { event.message }
    end
    if event.exception then
        local values = event.exception.values
        local exception: Exception = values and values[#values] or {}
        local type, value = exception.type or "", exception.value or ""

        return { `{value}`, `{type}: {value}` }
    end
    return {}
end

local function _getLastValidUrl(frames: Array<StackFrame>): string | nil
    for _, frame in frames do
        if frame and frame.filename ~= "<anonymous>" and frame.filename ~= "[native code]" then
            return frame.filename or nil
        end
    end

    return nil
end

local function _getEventFilterUrl(event: Event): string | nil
    local firstException = event.exception and event.exception.values and event.exception.values[1]
    local frames = firstException and firstException.stacktrace and firstException.stacktrace.frames
    return if frames then _getLastValidUrl(frames) else nil
end

local function _isIgnoredError(event: Event, ignoreErrors: Array<string | RegExp>?): boolean
    -- If event.type, this is not an error
    if event.type or not ignoreErrors or #ignoreErrors == 0 then
        return false
    end

    return Array.some(_getPossibleEventMessages(event), function(message)
        return stringMatchesSomePattern(message, ignoreErrors)
    end)
end

local function _isIgnoredTransaction(event: Event, ignoreTransactions: Array<string | RegExp>?): boolean
    if event.type ~= "transaction" or not ignoreTransactions or #ignoreTransactions == 0 then
        return false
    end

    local name = event.transaction
    return if name then stringMatchesSomePattern(name, ignoreTransactions) else false
end

local function _isDeniedUrl(event: Event, denyUrls: Array<string | RegExp>?): boolean
    -- TODO: Use Glob instead?
    if not denyUrls or #denyUrls == 0 then
        return false
    end
    local url = _getEventFilterUrl(event)
    return if not url then false else stringMatchesSomePattern(url, denyUrls)
end

local function _isAllowedUrl(event: Event, allowUrls: Array<string | RegExp>?): boolean
    -- TODO: Use Glob instead?
    if not allowUrls or #allowUrls == 0 then
        return true
    end
    local url = _getEventFilterUrl(event)
    return if not url then true else stringMatchesSomePattern(url, allowUrls)
end

local function _shouldDropEvent(event: Event, options: InboundFiltersOptions): boolean
    if options.ignoreInternal and _isSentryError(event) then
        if _G.__SENTRY_DEV__ then
            logger.warn(`Event dropped due to being internal Sentry Error.\nEvent: ${getEventDescription(event)}`)
        end
        return true
    end
    if _isIgnoredError(event, options.ignoreErrors) then
        if _G.__SENTRY_DEV__ then
            logger.warn(
                `Event dropped due to being matched by \`ignoreErrors\` option.\nEvent: ${getEventDescription(event)}`
            )
        end
        return true
    end
    if _isIgnoredTransaction(event, options.ignoreTransactions) then
        if _G.__SENTRY_DEV__ then
            logger.warn(
                `Event dropped due to being matched by \`ignoreTransactions\` option.\nEvent: ${getEventDescription(
                    event
                )}`
            )
        end
        return true
    end
    if _isDeniedUrl(event, options.denyUrls) then
        if _G.__SENTRY_DEV__ then
            logger.warn(
                `Event dropped due to being matched by \`denyUrls\` option.\nEvent: ${getEventDescription(event)}.\nUrl: ${_getEventFilterUrl(
                    event
                )}`
            )
        end
        return true
    end
    if not _isAllowedUrl(event, options.allowUrls) then
        if _G.__SENTRY_DEV__ then
            logger.warn(
                `Event dropped due to not being matched by \`allowUrls\` option.\nEvent: ${getEventDescription(event)}.\nUrl: ${_getEventFilterUrl(
                    event
                )}`
            )
        end
        return true
    end
    return false
end

local function _mergeOptions(
    internalOptions_: InboundFiltersOptions?,
    clientOptions_: InboundFiltersOptions?
): InboundFiltersOptions
    local internalOptions: InboundFiltersOptions = internalOptions_ or {}
    local clientOptions: InboundFiltersOptions = clientOptions_ or {}

    return {
        allowUrls = Array.concat(internalOptions.allowUrls or {}, clientOptions.allowUrls or {}),
        denyUrls = Array.concat(internalOptions.denyUrls or {}, clientOptions.denyUrls or {}),
        ignoreErrors = Array.concat(
            internalOptions.ignoreErrors or {},
            clientOptions.ignoreErrors or {},
            if internalOptions.disableErrorDefaults then {} else DEFAULT_IGNORE_ERRORS
        ),
        ignoreTransactions = Array.concat(
            internalOptions.ignoreTransactions or {},
            clientOptions.ignoreTransactions or {},
            if internalOptions.disableTransactionDefaults then {} else DEFAULT_IGNORE_TRANSACTIONS
        ),
        ignoreInternal = if internalOptions.ignoreInternal ~= nil then internalOptions.ignoreInternal else true,
    }
end

--- Inbound filters configurable by the user
local InboundFilters = {}
InboundFilters.id = "InboundFilters"
InboundFilters.__index = InboundFilters

export type InboundFilters = typeof(setmetatable(
    {} :: Integration & {
        _options: InboundFiltersOptions,
    },
    {} :: {
        __index: InboundFilters,
    }
))

function InboundFilters.new(options: InboundFiltersOptions?)
    local self: InboundFilters = setmetatable({}, InboundFilters) :: any
    self.name = InboundFilters.id
    self._options = options or {}
    return self
end

function InboundFilters.setupOnce(
    self: InboundFilters,
    addGlobalEventProcessor: (processor: EventProcessor) -> (),
    getCurrentHub: () -> Hub
)
    local function eventProcessor(event: Event)
        local hub = getCurrentHub()
        if hub then
            local this = hub:getIntegration(InboundFilters)
            if this then
                local client = hub:getClient()
                local clientOptions = if client then client:getOptions() else {}
                local options = _mergeOptions(this._options, clientOptions)
                return if _shouldDropEvent(event, options) then nil else event
            end
        end
        return event
    end

    addGlobalEventProcessor({
        id = self.name,
        fn = eventProcessor,
    })
end

return InboundFilters
