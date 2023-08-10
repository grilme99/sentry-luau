-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/checkin.ts

local Types = require("@packages/types")
type CheckInEnvelope = Types.CheckInEnvelope
type CheckInItem = Types.CheckInItem
type DsnComponents = Types.DsnComponents
type DynamicSamplingContext = Types.DynamicSamplingContext
type SdkMetadata = Types.SdkMetadata
type SerializedCheckIn = Types.SerializedCheckIn

local Utils = require("@packages/utils")
local createEnvelope = Utils.createEnvelope
local dsnToString = Utils.dsnToString

local CheckIn = {}

local function createCheckInEnvelopeItem(checkIn: SerializedCheckIn): CheckInItem
    local checkInHeaders = {
        type = "check_in",
    }
    return { headers = checkInHeaders, payload = checkIn } :: any
end

--- Create envelope from check in item.
function CheckIn.createCheckInEnvelope(
    checkIn: SerializedCheckIn,
    dynamicSamplingContext: DynamicSamplingContext?,
    metadata: SdkMetadata?,
    tunnel: string?,
    dsn: DsnComponents?
): CheckInEnvelope
    local headers = {
        sent_at = DateTime.now():ToIsoDate(),
    }

    if metadata and metadata.sdk then
        headers.sdk = {
            name = metadata.sdk.name,
            version = metadata.sdk.version,
        }
    end

    if not not tunnel and not not dsn then
        headers.dsn = dsnToString(dsn)
    end

    if dynamicSamplingContext then
        headers.trace = dynamicSamplingContext
    end

    local item = createCheckInEnvelopeItem(checkIn)
    return createEnvelope(headers, item)
end

return CheckIn
