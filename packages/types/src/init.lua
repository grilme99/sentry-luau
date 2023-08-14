-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/index.ts

local PackageRoot = script

local Attachment = require(PackageRoot.attachment)
export type Attachment = Attachment.Attachment

local Breadcrumb = require(PackageRoot.breadcrumb)
export type Breadcrumb = Breadcrumb.Breadcrumb
export type BreadcrumbHint = Breadcrumb.BreadcrumbHint
export type RequestBreadcrumbData = Breadcrumb.RequestBreadcrumbData
export type RequestBreadcrumbHint = Breadcrumb.RequestBreadcrumbHint

local Client = require(PackageRoot.client)
export type Client<T = ClientOptions> = Client.Client<T>

local ClientReport = require(PackageRoot.clientreport)
export type ClientReport = ClientReport.ClientReport
export type Outcome = ClientReport.Outcome
export type EventDropReason = ClientReport.EventDropReason

local Context = require(PackageRoot.context)
export type Context = Context.Context
export type Contexts = Context.Contexts
export type DeviceContext = Context.DeviceContext
export type OsContext = Context.OsContext
export type AppContext = Context.AppContext
export type CultureContext = Context.CultureContext
export type TraceContext = Context.TraceContext

local DataCategory = require(PackageRoot.datacategory)
export type DataCategory = DataCategory.DataCategory

local Dsn = require(PackageRoot.dsn)
export type DsnComponents = Dsn.DsnComponents
export type DsnLike = Dsn.DsnLike
export type DsnProtocol = Dsn.DsnProtocol

local DebugMeta = require(PackageRoot.debugMeta)
export type DebugImage = DebugMeta.DebugImage
export type DebugMeta = DebugMeta.DebugMeta

local Envelope = require(PackageRoot.envelope)
export type AttachmentItem = Envelope.AttachmentItem
export type BaseEnvelopeHeaders = Envelope.BaseEnvelopeHeaders
export type BaseEnvelopeItemHeaders = Envelope.BaseEnvelopeItemHeaders
export type ClientReportEnvelope = Envelope.ClientReportEnvelope
export type ClientReportItem = Envelope.ClientReportItem
export type DynamicSamplingContext = Envelope.DynamicSamplingContext
export type Envelope = Envelope.Envelope
export type EnvelopeItemType = Envelope.EnvelopeItemType
export type EnvelopeItem = Envelope.EnvelopeItem
export type EventEnvelope = Envelope.EventEnvelope
export type EventEnvelopeHeaders = Envelope.EventEnvelopeHeaders
export type EventItem = Envelope.EventItem
export type ReplayEnvelope = Envelope.ReplayEnvelope
export type SessionEnvelope = Envelope.SessionEnvelope
export type SessionItem = Envelope.SessionItem
export type UserFeedbackItem = Envelope.UserFeedbackItem
export type CheckInItem = Envelope.CheckInItem
export type CheckInEnvelope = Envelope.CheckInEnvelope
export type EnvelopeHeaders = Envelope.EnvelopeHeaders
export type EnvelopeItems = Envelope.EnvelopeItems

local Error = require(PackageRoot.error)
export type Error = Error.Error
export type ExtendedError = Error.ExtendedError

local Event = require(PackageRoot.event)
export type Event = Event.Event
export type EventHint = Event.EventHint
export type EventType = Event.EventType
export type ErrorEvent = Event.ErrorEvent
export type TransactionEvent = Event.TransactionEvent

local EventProcessor = require(PackageRoot.eventprocessor)
export type EventProcessor = EventProcessor.EventProcessor

local Exception = require(PackageRoot.exception)
export type Exception = Exception.Exception

local Extra = require(PackageRoot.extra)
export type Extra = Extra.Extra
export type Extras = Extra.Extras

local Hub = require(PackageRoot.hub)
export type Hub = Hub.Hub

local Integration = require(PackageRoot.integration)
export type Integration = Integration.Integration
export type IntegrationClass<T> = Integration.IntegrationClass<T>

local Mechanism = require(PackageRoot.mechanism)
export type Mechanism = Mechanism.Mechanism
export type PartialMechanism = Mechanism.PartialMechanism

local Misc = require(PackageRoot.misc)
export type HttpHeaderValue = Misc.HttpHeaderValue
export type Primitive = Misc.Primitive

local Options = require(PackageRoot.options)
export type ClientOptions<T = BaseTransportOptions> = Options.ClientOptions<T>
export type Options<T = BaseTransportOptions> = Options.Options<T>

local Package = require(PackageRoot.package)
export type Package = Package.Package

-- local Polymorphic = require("./polymorphics")
-- export type PolymorphicEvent = Polymorphic.PolymorphicEvent
-- export type PolymorphicRequest = Polymorphic.PolymorphicRequest

-- local Profiling = require("./profiling")
-- export type ThreadId = Profiling.ThreadId
-- export type FrameId = Profiling.FrameId
-- export type StackId = Profiling.StackId
-- export type ThreadCpuSample = Profiling.ThreadCpuSample
-- export type ThreadCpuStack = Profiling.ThreadCpuStack
-- export type ThreadCpuFrame = Profiling.ThreadCpuFrame
-- export type ThreadCpuProfile = Profiling.ThreadCpuProfile
-- export type Profile = Profiling.Profile

-- local Replay = require(PackageRoot.replay)
-- export type ReplayEvent = Replay.ReplayEvent
-- export type ReplayRecordingData = Replay.ReplayRecordingData
-- export type ReplayRecordingMode = Replay.ReplayRecordingMode

-- local Request = require(PackageRoot.request)
-- export type QueryParams = Request.QueryParams
-- export type Request = Request.Request
-- export type SanitizedRequestData = Request.SanitizedRequestData

-- local Runtime = require("./runtime")
-- export type Runtime = Runtime.Runtime

local Scope = require(PackageRoot.scope)
export type CaptureContext = Scope.CaptureContext
export type Scope = Scope.Scope
export type ScopeContext = Scope.ScopeContext

local SdkInfo = require(PackageRoot.sdkinfo)
export type SdkInfo = SdkInfo.SdkInfo

local SdkMetadata = require(PackageRoot.sdkmetadata)
export type SdkMetadata = SdkMetadata.SdkMetadata

local Session = require(PackageRoot.session)
export type SessionAggregates = Session.SessionAggregates
export type AggregationCounts = Session.AggregationCounts
export type Session = Session.Session
export type SessionContext = Session.SessionContext
export type SessionStatus = Session.SessionStatus
export type RequestSession = Session.RequestSession
export type RequestSessionStatus = Session.RequestSessionStatus
export type SessionFlusherLike = Session.SessionFlusherLike
export type SerializedSession = Session.SerializedSession

local Severity = require(PackageRoot.severity)
export type SeverityLevel = Severity.SeverityLevel

local Span = require(PackageRoot.span)
export type Span = Span.Span
export type SpanContext = Span.SpanContext

local StackFrame = require(PackageRoot.stackframe)
export type StackFrame = StackFrame.StackFrame

local Stacktrace = require(PackageRoot.stacktrace)
export type Stacktrace = Stacktrace.Stacktrace
export type StackParser = Stacktrace.StackParser
export type StackLineParser = Stacktrace.StackLineParser
export type StackLineParserFn = Stacktrace.StackLineParserFn

local TextEncoder = require(PackageRoot.textencoder)
export type TextEncoderInternal = TextEncoder.TextEncoderInternal

local Tracing = require(PackageRoot.tracing)
export type PropagationContext = Tracing.PropagationContext
export type TracePropagationTargets = Tracing.TracePropagationTargets

local Transaction = require(PackageRoot.transaction)
export type CustomSamplingContext = Transaction.CustomSamplingContext
export type SamplingContext = Transaction.SamplingContext
export type TraceparentData = Transaction.TraceparentData
export type Transaction = Transaction.Transaction
export type TransactionContext = Transaction.TransactionContext
export type TransactionMetadata = Transaction.TransactionMetadata
export type TransactionSource = Transaction.TransactionSource

local Measurement = require(PackageRoot.measurement)
export type DurationUnit = Measurement.DurationUnit
export type InformationUnit = Measurement.InformationUnit
export type FractionUnit = Measurement.FractionUnit
export type MeasurementUnit = Measurement.MeasurementUnit
export type NoneUnit = Measurement.NoneUnit
export type Measurements = Measurement.Measurements

-- local Thread = require(PackageRoot.thread)
-- export type Thread = Thread.Thread

local Transport = require(PackageRoot.transport)
export type Transport = Transport.Transport
export type TransportRequest = Transport.TransportRequest
export type TransportMakeRequestResponse = Transport.TransportMakeRequestResponse
export type InternalBaseTransportOptions = Transport.InternalBaseTransportOptions
export type BaseTransportOptions = Transport.BaseTransportOptions
export type TransportRequestExecutor = Transport.TransportRequestExecutor

local User = require(PackageRoot.user)
export type User = User.User
export type UserFeedback = User.UserFeedback

-- local WrappedFunction = require("./wrappedfunction")
-- export type WrappedFunction = WrappedFunction.WrappedFunction

local Instrumenter = require(PackageRoot.instrumenter)
export type Instrumenter = Instrumenter.Instrumenter

local HandlerData = require(PackageRoot.instrument)
export type HandlerDataFetch = HandlerData.HandlerDataFetch
-- export type HandlerDataXhr = HandlerData.HandlerDataXhr
-- export type SentryXhrData = HandlerData.SentryXhrData
-- export type SentryWrappedXMLHttpRequest = HandlerData.SentryWrappedXMLHttpRequest

-- local BrowserOptions = require("./browseroptions")
-- export type BrowserClientReplayOptions = BrowserOptions.BrowserClientReplayOptions
-- export type BrowserClientProfilingOptions = BrowserOptions.BrowserClientProfilingOptions

local CheckIn = require(PackageRoot.checkin)
export type CheckIn = CheckIn.CheckIn
export type MonitorConfig = CheckIn.MonitorConfig
export type SerializedCheckIn = CheckIn.SerializedCheckIn

local Promise = require(PackageRoot.promise)
export type Promise<T> = Promise.Promise<T>
export type PromiseLike<T> = Promise.PromiseLike<T>

return {}
