-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/transports/base.ts

local PackageRoot = script.Parent.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type Envelope = Types.Envelope
type EnvelopeItem = Types.EnvelopeItem
type EnvelopeHeaders = Types.EnvelopeHeaders
type EnvelopeItemType = Types.EnvelopeItemType
type Event = Types.Event
type EventDropReason = Types.EventDropReason
type EventItem = Types.EventItem
type InternalBaseTransportOptions = Types.InternalBaseTransportOptions
type Transport = Types.Transport
type TransportMakeRequestResponse = Types.TransportMakeRequestResponse
type TransportRequestExecutor = Types.TransportRequestExecutor
type PromiseLike<T> = Types.PromiseLike<T>

local Utils = require(Packages.SentryUtils)
local createEnvelope = Utils.createEnvelope
local envelopeItemTypeToDataCategory = Utils.envelopeItemTypeToDataCategory
local forEachEnvelopeItem = Utils.forEachEnvelopeItem
local isRateLimited = Utils.isRateLimited
local logger = Utils.logger
local makePromiseBuffer = Utils.makePromiseBuffer
local SentryError = Utils.SentryError
local serializeEnvelope = Utils.serializeEnvelope
local updateRateLimits = Utils.updateRateLimits
local Array = Utils.Polyfill.Array
local Promise = Utils.Promise
local instanceof = Utils.Polyfill.instanceof
type PromiseBuffer<T> = Utils.PromiseBuffer<T>
type RateLimits = Utils.RateLimits

type Array<T> = { T }

local BaseTransport = {}

local DEFAULT_TRANSPORT_BUFFER_SIZE = 30
BaseTransport.DEFAULT_TRANSPORT_BUFFER_SIZE = DEFAULT_TRANSPORT_BUFFER_SIZE

local function getEventForEnvelopeItem(item: EnvelopeHeaders, type: EnvelopeItemType): Event?
    if type ~= "event" and type ~= "transaction" then
        return nil
    end

    return if Array.isArray(item) then ((item :: any) :: EventItem).payload else nil
end

--- Creates an instance of a Sentry `Transport`
---
--- @param options
--- @param makeRequest
function BaseTransport.createTransport(
    options: InternalBaseTransportOptions,
    makeRequest: TransportRequestExecutor,
    buffer_: PromiseBuffer<TransportMakeRequestResponse | nil>?
): Transport
    local buffer: PromiseBuffer<TransportMakeRequestResponse | nil> = buffer_
        or makePromiseBuffer(options.bufferSize or DEFAULT_TRANSPORT_BUFFER_SIZE)

    local rateLimits: RateLimits = {}
    local function flush(timeout: number?): PromiseLike<boolean>
        return buffer.drain(timeout)
    end

    local function send(envelope: Envelope): PromiseLike<TransportMakeRequestResponse | nil>
        local filteredEnvelopeItems: Array<EnvelopeItem> = {}

        -- Drop rate limited items from envelope
        forEachEnvelopeItem(envelope, function(item, type)
            local envelopeItemDataCategory = envelopeItemTypeToDataCategory(type :: any)
            if isRateLimited(rateLimits, envelopeItemDataCategory) then
                local event = getEventForEnvelopeItem(item, type :: any)
                options.recordDroppedEvent("ratelimit_backoff", envelopeItemDataCategory, event)
            else
                table.insert(filteredEnvelopeItems, item)
            end
            return nil
        end)

        -- Skip sending if envelope is empty after filtering out rate limited events
        if #filteredEnvelopeItems == 0 then
            return Promise.resolve()
        end

        local filteredEnvelope: Envelope = createEnvelope(envelope.headers, filteredEnvelopeItems :: any)

        --- Creates client report for each item in an envelope
        local function recordEnvelopeLoss(reason: EventDropReason)
            forEachEnvelopeItem(filteredEnvelope, function(item, type)
                local event = getEventForEnvelopeItem(item, type :: any)
                options.recordDroppedEvent(reason, envelopeItemTypeToDataCategory(type :: any), event)
                return nil
            end)
        end

        local function requestTask(): PromiseLike<TransportMakeRequestResponse | nil>
            return makeRequest({ body = serializeEnvelope(filteredEnvelope) }):andThen(function(response)
                -- We don't want to throw on NOK responses, but we want to at least log them
                if response.statusCode ~= nil and (response.statusCode < 200 or response.statusCode >= 300) then
                    if _G.__SENTRY_DEV__ then
                        logger.warn(
                            `Sentry responded with status code {response.statusCode} to sent event:\n`,
                            response.body
                        )
                    end
                end

                rateLimits = updateRateLimits(rateLimits, response)
                return response
            end, function(err)
                recordEnvelopeLoss("network_error")
                error(err)
            end)
        end

        return buffer.add(requestTask):andThen(function(result)
            return result
        end, function(err)
            if instanceof(err, SentryError) then
                if _G.__SENTRY_DEV__ then
                    logger.error("Skipped sending event because buffer is full.")
                end
                return Promise.resolve()
            else
                error(err)
            end
        end)
    end

    return {
        send = send,
        flush = flush,
    } :: any
end

return BaseTransport
