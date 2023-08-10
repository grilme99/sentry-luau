-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/sdkinfo.ts

local Package = require("./package")
type Package = Package.Package

type Array<T> = { T }

export type SdkInfo = {
    name: string?,
    version: string?,
    integrations: Array<string>?,
    packages: Array<Package>?,
}

return {}
