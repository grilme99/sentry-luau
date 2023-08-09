-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/envelope.ts

-- Based on: https://develop.sentry.dev/sdk/envelopes/

local CheckIn = require("./checkin")
type SerializedCheckIn = CheckIn.SerializedCheckIn

local ClientReport = require("./clientreport")
type ClientReport = ClientReport.ClientReport

local Dsn = require("./dsn")
type DsnComponents = Dsn.DsnComponents

local Event = require("./event")
type Event = Event.Event

local Replay = require("./replay")
type ReplayEvent = Replay.ReplayEvent
type ReplayRecordingData = Replay.ReplayRecordingData

local SdkInfo = require("./sdkinfo")
type SdkInfo = SdkInfo.SdkInfo

local Session = require("./session")
type SerializedSession = Session.SerializedSession
type Session = Session.Session
type SessionAggregates = Session.SessionAggregates

local Transaction = require("./transaction")
type Transaction = Transaction.Transaction

local User = require("./user")
type UserFeedback = User.UserFeedback

type Map<K, V> = { [K]: V }
type Array<T> = { T }

--- Based on https://github.com/getsentry/relay/blob/b23b8d3b2360a54aaa4d19ecae0231201f31df5e/relay-sampling/src/lib.rs#L685-L707
export type DynamicSamplingContext = {
    trace_id: string,
    public_key: string,
    sample_rate: string?,
    release: string?,
    environment: string?,
    transaction: string?,
    user_segment: string?,
    replay_id: string?,
    sampled: string?,
}

export type EnvelopeItemType =
    "client_report"
    | "user_report"
    | "session"
    | "sessions"
    | "transaction"
    | "attachment"
    | "event"
    | "profile"
    | "replay_event"
    | "replay_recording"
    | "check_in"

export type BaseEnvelopeHeaders = Map<string, unknown> & {
    dsn: string?,
    sdk: SdkInfo?,
}

export type BaseEnvelopeItemHeaders = Map<string, unknown> & {
    type: EnvelopeItemType,
    length: number?,
}

-- deviation: This is a tuple in Typescript, but there is no equivalent in Luau. Tables are the most obvious
--  alternative.
type BaseEnvelopeItem<ItemHeaders, Payload> = {
    headers: ItemHeaders & BaseEnvelopeItemHeaders,
    payload: Payload,
}

-- deviation: This is a tuple in Typescript, but there is no equivalent in Luau. Tables are the most obvious
--  alternative.
type BaseEnvelope<EnvelopeHeaders, Item> = {
    headers: EnvelopeHeaders & BaseEnvelopeHeaders,
    items: Array<Item & BaseEnvelopeItem<BaseEnvelopeItemHeaders, unknown>>,
}

type EventItemHeaders = {
    type: "event" | "transaction" | "profile",
}
type AttachmentItemHeaders = {
    type: "attachment",
    length: number,
    filename: string,
    content_type: string?,
    attachment_type: string?,
}
type UserFeedbackItemHeaders = { type: "user_report" }
type SessionItemHeaders = { type: "session" }
type SessionAggregatesItemHeaders = { type: "sessions" }
type ClientReportItemHeaders = { type: "client_report" }
type ReplayEventItemHeaders = { type: "replay_event" }
type ReplayRecordingItemHeaders = { type: "replay_recording", length: number }
type CheckInItemHeaders = { type: "check_in" }

export type EventItem = BaseEnvelopeItem<EventItemHeaders, Event>
export type AttachmentItem = BaseEnvelopeItem<AttachmentItemHeaders, string>
export type UserFeedbackItem = BaseEnvelopeItem<UserFeedbackItemHeaders, UserFeedback>
export type SessionItem =
    -- TODO(v8): Only allow serialized session here (as opposed to Session or SerializedSesison)
    BaseEnvelopeItem<
        SessionItemHeaders,
        Session | SerializedSession
    > | BaseEnvelopeItem<SessionAggregatesItemHeaders, SessionAggregates>
export type ClientReportItem = BaseEnvelopeItem<ClientReportItemHeaders, ClientReport>
export type CheckInItem = BaseEnvelopeItem<CheckInItemHeaders, SerializedCheckIn>
type ReplayEventItem = BaseEnvelopeItem<ReplayEventItemHeaders, ReplayEvent>
type ReplayRecordingItem = BaseEnvelopeItem<ReplayRecordingItemHeaders, ReplayRecordingData>

export type EventEnvelopeHeaders = { event_id: string, sent_at: string, trace: DynamicSamplingContext? }
type SessionEnvelopeHeaders = { sent_at: string }
type CheckInEnvelopeHeaders = { trace: DynamicSamplingContext? }
type ClientReportEnvelopeHeaders = BaseEnvelopeHeaders
type ReplayEnvelopeHeaders = BaseEnvelopeHeaders

export type EventEnvelope = BaseEnvelope<EventEnvelopeHeaders, EventItem | AttachmentItem | UserFeedbackItem>
export type SessionEnvelope = BaseEnvelope<SessionEnvelopeHeaders, SessionItem>
export type ClientReportEnvelope = BaseEnvelope<ClientReportEnvelopeHeaders, ClientReportItem>
-- deviation: This is a tuple in Typescript, but there is no equivalent in Luau. Tables are the most obvious
--  alternative.
export type ReplayEnvelope = {
    headers: ReplayEnvelopeHeaders,
    items: {
        eventItem: ReplayEventItem,
        recordingItem: ReplayRecordingItem,
    },
}

export type CheckInEnvelope = BaseEnvelope<CheckInEnvelopeHeaders, CheckInItem>

export type Envelope = EventEnvelope | SessionEnvelope | ClientReportEnvelope | ReplayEnvelope | CheckInEnvelope
-- export type EnvelopeItem = Envelope[1][number];

export type EnvelopeHeaders =
    EventEnvelopeHeaders
    | SessionEnvelopeHeaders
    | ClientReportEnvelopeHeaders
    | ReplayEnvelopeHeaders
    | CheckInEnvelopeHeaders

export type EnvelopeItems =
    EventItem
    | AttachmentItem
    | UserFeedbackItem
    | SessionItem
    | ClientReportItem
    | ReplayEventItem
    | ReplayRecordingItem
    | CheckInItem

return {}
