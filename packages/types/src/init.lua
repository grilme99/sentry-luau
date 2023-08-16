-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/index.ts

local PackageRoot = script

local RecursiveModules = require(PackageRoot._recursiveModules)

local Attachment = require(PackageRoot.attachment)
export type Attachment = Attachment.Attachment

local Breadcrumb = require(PackageRoot.breadcrumb)
export type Breadcrumb = Breadcrumb.Breadcrumb
export type BreadcrumbHint = Breadcrumb.BreadcrumbHint
export type RequestBreadcrumbData = Breadcrumb.RequestBreadcrumbData
export type RequestBreadcrumbHint = Breadcrumb.RequestBreadcrumbHint

export type Client<T = BaseTransportOptions> = RecursiveModules.Client<T>

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

export type AttachmentItem = RecursiveModules.AttachmentItem
export type BaseEnvelopeHeaders = RecursiveModules.BaseEnvelopeHeaders
export type BaseEnvelopeItemHeaders = RecursiveModules.BaseEnvelopeItemHeaders
export type ClientReportEnvelope = RecursiveModules.ClientReportEnvelope
export type ClientReportItem = RecursiveModules.ClientReportItem
export type DynamicSamplingContext = RecursiveModules.DynamicSamplingContext
export type Envelope = RecursiveModules.Envelope
export type EnvelopeItemType = RecursiveModules.EnvelopeItemType
export type EnvelopeItem = RecursiveModules.EnvelopeItem
export type EventEnvelope = RecursiveModules.EventEnvelope
export type EventEnvelopeHeaders = RecursiveModules.EventEnvelopeHeaders
export type EventItem = RecursiveModules.EventItem
export type ReplayEnvelope = RecursiveModules.ReplayEnvelope
export type SessionEnvelope = RecursiveModules.SessionEnvelope
export type SessionItem = RecursiveModules.SessionItem
export type UserFeedbackItem = RecursiveModules.UserFeedbackItem
export type CheckInItem = RecursiveModules.CheckInItem
export type CheckInEnvelope = RecursiveModules.CheckInEnvelope
export type EnvelopeHeaders = RecursiveModules.EnvelopeHeaders
export type EnvelopeItems = RecursiveModules.EnvelopeItems

local Error = require(PackageRoot.error)
export type Error = Error.Error
export type ExtendedError = Error.ExtendedError

export type Event = RecursiveModules.Event
export type EventHint = RecursiveModules.EventHint
export type EventType = RecursiveModules.EventType
export type ErrorEvent = RecursiveModules.ErrorEvent
export type TransactionEvent = RecursiveModules.TransactionEvent

export type EventProcessor = RecursiveModules.EventProcessor

local Exception = require(PackageRoot.exception)
export type Exception = Exception.Exception

local Extra = require(PackageRoot.extra)
export type Extra = Extra.Extra
export type Extras = Extra.Extras

export type Hub = RecursiveModules.Hub

export type Integration = RecursiveModules.Integration
export type IntegrationClass<T> = RecursiveModules.IntegrationClass<T>

local Mechanism = require(PackageRoot.mechanism)
export type Mechanism = Mechanism.Mechanism
export type PartialMechanism = Mechanism.PartialMechanism

local Misc = require(PackageRoot.misc)
export type HttpHeaderValue = Misc.HttpHeaderValue
export type Primitive = Misc.Primitive

export type ClientOptions<T = BaseTransportOptions> = RecursiveModules.ClientOptions<T>
export type Options<T = BaseTransportOptions> = RecursiveModules.Options<T>

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

export type ReplayEvent = RecursiveModules.ReplayEvent
export type ReplayRecordingData = RecursiveModules.ReplayRecordingData
export type ReplayRecordingMode = RecursiveModules.ReplayRecordingMode

-- local Request = require(PackageRoot.request)
-- export type QueryParams = Request.QueryParams
-- export type Request = Request.Request
-- export type SanitizedRequestData = Request.SanitizedRequestData

-- local Runtime = require("./runtime")
-- export type Runtime = Runtime.Runtime

export type CaptureContext = RecursiveModules.CaptureContext
export type Scope = RecursiveModules.Scope
export type ScopeContext = RecursiveModules.ScopeContext

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

export type Span = RecursiveModules.Span
export type SpanContext = RecursiveModules.SpanContext

local StackFrame = require(PackageRoot.stackframe)
export type StackFrame = StackFrame.StackFrame

local Stacktrace = require(PackageRoot.stacktrace)
export type Stacktrace = Stacktrace.Stacktrace
export type StackParser = Stacktrace.StackParser
export type StackLineParser = Stacktrace.StackLineParser
export type StackLineParserFn = Stacktrace.StackLineParserFn

local TextEncoder = require(PackageRoot.textencoder)
export type TextEncoderInternal = TextEncoder.TextEncoderInternal

export type PropagationContext = RecursiveModules.PropagationContext
export type TracePropagationTargets = RecursiveModules.TracePropagationTargets

export type CustomSamplingContext = RecursiveModules.CustomSamplingContext
export type SamplingContext = RecursiveModules.SamplingContext
export type TraceparentData = RecursiveModules.TraceparentData
export type Transaction = RecursiveModules.Transaction
export type TransactionContext = RecursiveModules.TransactionContext
export type TransactionMetadata = RecursiveModules.TransactionMetadata
export type TransactionSource = RecursiveModules.TransactionSource

local Measurement = require(PackageRoot.measurement)
export type DurationUnit = Measurement.DurationUnit
export type InformationUnit = Measurement.InformationUnit
export type FractionUnit = Measurement.FractionUnit
export type MeasurementUnit = Measurement.MeasurementUnit
export type NoneUnit = Measurement.NoneUnit
export type Measurements = Measurement.Measurements

local Thread = require(PackageRoot.thread)
export type Thread = Thread.Thread

export type Transport = RecursiveModules.Transport
export type TransportRequest = RecursiveModules.TransportRequest
export type TransportMakeRequestResponse = RecursiveModules.TransportMakeRequestResponse
export type InternalBaseTransportOptions = RecursiveModules.InternalBaseTransportOptions
export type BaseTransportOptions = RecursiveModules.BaseTransportOptions
export type TransportRequestExecutor = RecursiveModules.TransportRequestExecutor

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
