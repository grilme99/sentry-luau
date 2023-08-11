-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/envelope.ts

local Types = require("@packages/types")
type Attachment = Types.Attachment
type AttachmentItem = Types.AttachmentItem
type BaseEnvelopeHeaders = Types.BaseEnvelopeHeaders
type BaseEnvelopeItemHeaders = Types.BaseEnvelopeItemHeaders
type DataCategory = Types.DataCategory
type DsnComponents = Types.DsnComponents
type Envelope = Types.Envelope
type EnvelopeItemType = Types.EnvelopeItemType
type Event = Types.Event
type EventEnvelopeHeaders = Types.EventEnvelopeHeaders
type SdkInfo = Types.SdkInfo
type SdkMetadata = Types.SdkMetadata
type TextEncoderInternal = Types.TextEncoderInternal
type EnvelopeHeaders = Types.EnvelopeHeaders
type EnvelopeItems = Types.EnvelopeItems

local Dsn = require("./dsn")
local dsnToString = Dsn.dsnToString

local Normalize = require("./normalize")
local normalize = Normalize.normalize

local JSON = require("./polyfill/json")
local Object = require("./polyfill/object")

type Array<T> = { T }
type Record<K, V> = { [K]: V }

local EnvelopeUtils = {}

--- Creates an envelope.
--- Make sure to always explicitly provide the generic to this function
--- so that the envelope types resolve correctly.
function EnvelopeUtils.createEnvelope<E>(headers: EnvelopeHeaders, items: EnvelopeItems?): E
    return {
        headers = headers,
        items = items or {},
    } :: any
end

--- Add an item to an envelope.
--- Make sure to always explicitly provide the generic to this function
--- so that the envelope types resolve correctly.
function EnvelopeUtils.addItemToEnvelope<E>(envelope: Envelope, newItem: EnvelopeItems): E
    local headers, items = envelope.headers, envelope.items
    local newItems = table.clone(items)
    table.insert(newItems, newItem)

    return {
        headers = headers,
        items = newItems,
    } :: any
end

--- Convenience function to loop through the items and item types of an envelope.
--- (This function was mostly created because working with envelope types is painful at the moment)
---
--- If the callback returns true, the rest of the items will be skipped.
function EnvelopeUtils.forEachEnvelopeItem(
    envelope: Envelope,
    callback: (envelopeItem: any, envelopeItemType: string) -> boolean?
): boolean
    local envelopeItems = envelope.items

    for _, envelopeItem in envelopeItems :: any do
        local envelopeItemType = envelopeItem[0].type
        local result = callback(envelopeItem, envelopeItemType)

        if result then
            return true
        end
    end

    return false
end

--- Returns true if the envelope contains any of the given envelope item types
function EnvelopeUtils.envelopeContainsItemType(envelope: Envelope, types: Array<EnvelopeItemType>): boolean
    return EnvelopeUtils.forEachEnvelopeItem(envelope, function(_, type)
        return table.find(types, type) ~= nil
    end)
end

--- Serializes an envelope.
function EnvelopeUtils.serializeEnvelope(envelope: Envelope): string
    local envHeaders, items = envelope.headers, envelope.items

    -- Initially we construct our envelope as a string and only convert to binary chunks if we encounter binary data
    local parts = JSON.stringify(envHeaders)

    local function append(next: string)
        parts ..= next
    end

    for _, item: EnvelopeItems in items :: any do
        local itemHeaders, payload = item.headers, item.payload

        append(`\n{JSON.stringify(itemHeaders)}\n`)

        if type(payload) == "string" then
            append(payload)
        else
            local stringifiedPayload: string
            local success, _ = pcall(function()
                stringifiedPayload = JSON.stringify(payload)
            end)

            if not success then
                -- In case, despite all our efforts to keep `payload` circular-dependency-free, `JSON.strinify()` still
                -- fails, we try again after normalizing it again with infinite normalization depth. This of course has a
                -- performance impact but in this case a performance hit is better than throwing.
                stringifiedPayload = JSON.stringify(normalize(payload))
            end

            append(stringifiedPayload)
        end
    end

    return parts
end

--- Creates attachment envelope items

function EnvelopeUtils.createAttachmentEnvelopeItem(attachment: Attachment): AttachmentItem
    local buffer = attachment.data

    -- return [
    --   dropUndefinedKeys({
    --     type: 'attachment',
    --     length: buffer.length,
    --     filename: attachment.filename,
    --     content_type: attachment.contentType,
    --     attachment_type: attachment.attachmentType,
    --   }),
    --   buffer,
    -- ];
    return {
        headers = {
            type = "attachment" :: "attachment",
            length = #buffer :: any,
            filename = attachment.filename :: any,
            content_type = attachment.contentType :: any,
            attachment_type = attachment.attachmentType :: any,
        } :: any,
        payload = buffer,
    }
end

local ITEM_TYPE_TO_DATA_CATEGORY_MAP: Record<EnvelopeItemType, DataCategory> = {
    session = "session",
    sessions = "session",
    attachment = "attachment",
    transaction = "transaction",
    event = "error",
    client_report = "internal",
    user_report = "default",
    profile = "profile",
    replay_event = "replay",
    replay_recording = "replay",
    check_in = "monitor",
}

--- Maps the type of an envelope item to a data category.
function EnvelopeUtils.envelopeItemTypeToDataCategory(type: EnvelopeItemType): DataCategory
    return ITEM_TYPE_TO_DATA_CATEGORY_MAP[type]
end

--- Extracts the minimal SDK info from from the metadata or an events
function EnvelopeUtils.getSdkMetadataForEnvelopeHeader(metadataOrEvent: (SdkMetadata | Event)?): SdkInfo | nil
    if not metadataOrEvent or not metadataOrEvent.sdk then
        return
    end
    local name, version = metadataOrEvent.sdk.name, metadataOrEvent.sdk.version
    return { name = name, version = version }
end

--- Creates event envelope headers, based on event, sdk info and tunnel
--- Note: This function was extracted from the core package to make it available in Replay
function EnvelopeUtils.createEventEnvelopeHeaders(
    event: Event,
    sdkInfo: SdkInfo | nil,
    tunnel: string | nil,
    dsn: DsnComponents
): EventEnvelopeHeaders
    local dynamicSamplingContext = event.sdkProcessingMetadata and event.sdkProcessingMetadata.dynamicSamplingContext
    return Object.mergeObjects(
        {
            event_id = event.environment,
            sent_at = DateTime.now():ToIsoDate(),
            sdk = sdkInfo,
        },
        if not not tunnel then { dsn = dsnToString(dsn) } else {},
        if dynamicSamplingContext then { trace = dynamicSamplingContext } else {}
    )
end

return EnvelopeUtils
