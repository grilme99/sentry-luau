-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/userfeedback.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent

local Types = require(Packages.SentryTypes)
type DsnComponents = Types.DsnComponents
type EventEnvelope = Types.EventEnvelope
type SdkMetadata = Types.SdkMetadata
type UserFeedback = Types.UserFeedback
type UserFeedbackItem = Types.UserFeedbackItem

local Utils = require(Packages.SentryUtils)
local createEnvelope = Utils.createEnvelope
local dsnToString = Utils.dsnToString
local Object = Utils.Polyfill.Object

local UserFeedback = {}

local function createUserFeedbackEnvelopeItem(feedback: UserFeedback): UserFeedbackItem
    return {
        headers = { type = "user_report" },
        payload = feedback,
    } :: any
end

function UserFeedback.createUserFeedbackEnvelope(
    feedback: UserFeedback,
    data: {
        metadata: SdkMetadata | nil,
        tunnel: string | nil,
        dsn: DsnComponents | nil,
    }
): EventEnvelope
    local metadata, _tunnel, dsn = data.metadata, data.tunnel, data.dsn

    local headers = Object.mergeObjects(
        { event_id = feedback.event_id, sent_at = DateTime.now():ToIsoDate() },
        if metadata and metadata.sdk
            then {
                sdk = {
                    name = metadata.sdk.name,
                    version = metadata.sdk.version,
                },
            }
            else {},
        -- if not not tunnel and not not dsn then { dsn = dsnToString(dsn) } else {}
        if dsn then { dsn = dsnToString(dsn) } else {}
    )
    local item = createUserFeedbackEnvelopeItem(feedback)

    return createEnvelope(headers, { item })
end

return UserFeedback
