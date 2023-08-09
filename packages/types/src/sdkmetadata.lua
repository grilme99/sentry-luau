-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/sdkmetadata.ts

local SdkInfo = require("./sdkinfo")
type SdkInfo = SdkInfo.SdkInfo

export type SdkMetadata = {
    sdk: SdkInfo?,
}

return {}
