-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/event.ts

local PackageRoot = script.Parent

local Attachment = require(PackageRoot.attachment)
type Attachment = Attachment.Attachment

local Breadcrumb = require(PackageRoot.breadcrumb)
type Breadcrumb = Breadcrumb.Breadcrumb

local Contexts = require(PackageRoot.context)
type Contexts = Contexts.Contexts

local DebugMeta = require(PackageRoot.debugMeta)
type DebugMeta = DebugMeta.DebugMeta

local Exception = require(PackageRoot.exception)
type Exception = Exception.Exception

local Extras = require(PackageRoot.extra)
type Extras = Extras.Extras

local Measurements = require(PackageRoot.measurement)
type Measurements = Measurements.Measurements

local Primitive = require(PackageRoot.misc)
type Primitive = Primitive.Primitive

local Scope = require(PackageRoot.scope)
type CaptureContext = Scope.CaptureContext

local SdkInfo = require(PackageRoot.sdkinfo)
type SdkInfo = SdkInfo.SdkInfo

local Severity = require(PackageRoot.severity)
type SeverityLevel = Severity.SeverityLevel

local Span = require(PackageRoot.span)
type Span = Span.Span

local Thread = require(PackageRoot.thread)
type Thread = Thread.Thread

local TransactionSource = require(PackageRoot.transaction)
type TransactionSource = TransactionSource.TransactionSource

local User = require(PackageRoot.user)
type User = User.User

local Error = require(PackageRoot.error)
type Error = Error.Error

type Array<T> = { T }
type Map<K, V> = { [K]: V }

export type Event = {
    event_id: string?,
    message: string?,
    timestamp: number?,
    start_timestamp: number?,
    level: SeverityLevel?,
    platform: string?,
    logger: string?,
    server_name: string?,
    release: string?,
    dist: string?,
    environment: string?,
    sdk: SdkInfo?,
    -- request: Request?,
    transaction: string?,
    modules: Map<string, string>?,
    fingerprint: Array<string>?,
    exception: {
        values: Array<Exception>?,
    }?,
    breadcrumbs: Array<Breadcrumb>?,
    contexts: Contexts?,
    tags: Map<string, Primitive>?,
    extra: Extras?,
    user: User?,
    type: EventType?,
    spans: Array<Span>?,
    measurements: Measurements?,
    debug_meta: DebugMeta?,
    -- A place to stash data which is needed at some point in the SDK's event processing pipeline but which shouldn't get sent to Sentry
    sdkProcessingMetadata: Map<string, any>?,
    transaction_info: {
        source: TransactionSource,
    }?,
    threads: {
        values: Array<Thread>,
    }?,
}

--- The type of an `Event`.
--- Note that `ErrorEvent`s do not have a type (hence its undefined),
--- while all other events are required to have one.
export type EventType = "transaction" | "profile" | "replay_event" | nil

export type ErrorEvent = Event & {
    type: nil,
}
export type TransactionEvent = Event & {
    type: "transaction",
}

export type EventHint = {
    event_id: string?,
    captureContext: CaptureContext?,
    syntheticException: (Error | nil)?,
    originalException: unknown?,
    attachments: Array<Attachment>?,
    data: any?,
    integrations: Array<string>?,
}

return {}
