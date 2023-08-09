-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/envelope.ts

local Types = require("@packages/types")
type DsnComponents = Types.DsnComponents
type Event = Types.Event
type EventEnvelope = Types.EventEnvelope
type EventItem = Types.EventItem
type SdkInfo = Types.SdkInfo
type SdkMetadata = Types.SdkMetadata
type Session = Types.Session
type SessionAggregates = Types.SessionAggregates
type SessionEnvelope = Types.SessionEnvelope
type SessionItem = Types.SessionItem

local Utils = require("@packages/utils")
local createEnvelope = Utils.createEnvelope
local createEventEnvelopeHeaders = Utils.createEventEnvelopeHeaders
local dsnToString = Utils.dsnToString
local getSdkMetadataForEnvelopeHeader = Utils.getSdkMetadataForEnvelopeHeader
local Object = Utils.Polyfill.Object

local Envelope = {}

--- Apply SdkInfo (name, version, packages, integrations) to the corresponding event key.
--- Merge with existing data if any.
function enhanceEventWithSdkInfo(event: Event, sdkInfo: SdkInfo?): Event
    if not sdkInfo then
        return event
    end
    event.sdk = event.sdk or {}
    local sdk = event.sdk :: SdkInfo
    sdk.name = sdk.name or sdkInfo.name
    sdk.version = sdk.version or sdkInfo.version
    --   event.sdk.integrations = [...(event.sdk.integrations || []), ...(sdkInfo.integrations || [])];
    --   event.sdk.packages = [...(event.sdk.packages || []), ...(sdkInfo.packages || [])];
    return event
end

--- Creates an envelope from a Session
function Envelope.createSessionEnvelope(
    session_: Session | SessionAggregates,
    dsn: DsnComponents,
    metadata: SdkMetadata?,
    tunnel: string?
): SessionEnvelope
    local sdkInfo = getSdkMetadataForEnvelopeHeader(metadata)
    local envelopeHeaders = Object.mergeObjects(
        { sent_at = DateTime.now():ToIsoDate() },
        if sdkInfo then { sdk = sdkInfo } else {},
        if not not tunnel then { dsn = dsnToString(dsn) } else {}
    )

    -- local envelopeItem: SessionItem =
    -- 'aggregates' in session ? [{ type: 'sessions' }, session] : [{ type: 'session' }, session.toJSON()];

    local envelopeItem: SessionItem
    if (session_ :: any).aggregates then
        local session = session_ :: SessionAggregates
        envelopeItem = { headers = { type = "sessions" }, payload = session } :: any
    else
        local session = session_ :: Session
        envelopeItem = { headers = { type = "session" }, payload = session.toJSON() } :: any
    end

    return createEnvelope(envelopeHeaders, envelopeItem)
end

--- Create an Envelope from an event.
function Envelope.createEventEnvelope(
    event: Event,
    dsn: DsnComponents,
    metadata: SdkMetadata?,
    tunnel: string?
): EventEnvelope
    local sdkInfo = getSdkMetadataForEnvelopeHeader(metadata)

    -- Note: Due to Luau, event.type may be `replay_event`, theoretically.
    -- In practice, we never call `createEventEnvelope` with `replay_event` type,
    -- and we'd have to adjust a lot of types to make this work properly.
    -- We want to avoid casting this around, as that could lead to bugs (e.g. when we add another type)
    -- So the safe choice is to really guard against the replay_event type here.
    local eventType = if event.type and event.type ~= "replay_event" then event.type else "event"

    enhanceEventWithSdkInfo(event, metadata and metadata.sdk)

    local envelopeHeaders = createEventEnvelopeHeaders(event, sdkInfo, tunnel, dsn)

    -- Prevent this data (which, if it exists, was used in earlier steps in the processing pipeline) from being sent to
    -- sentry. (Note: Our use of this property comes and goes with whatever we might be debugging, whatever hacks we may
    -- have temporarily added, etc. Even if we don't happen to be using it at some point in the future, let's not get rid
    -- of this `delete`, lest we miss putting it back in the next time the property is in use.)
    event.sdkProcessingMetadata = nil

    local eventItem: EventItem = { headers = { type = eventType }, payload = event } :: any
    return createEnvelope(envelopeHeaders, eventItem)
end

return Envelope
