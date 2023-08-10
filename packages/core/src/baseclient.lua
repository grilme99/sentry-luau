-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/baseclient.ts

local Types = require("@packages/types")
type Breadcrumb = Types.Breadcrumb
type BreadcrumbHint = Types.BreadcrumbHint
type Client = Types.Client
type ClientOptions = Types.ClientOptions
type DataCategory = Types.DataCategory
type DsnComponents = Types.DsnComponents
type DynamicSamplingContext = Types.DynamicSamplingContext
type Envelope = Types.Envelope
type ErrorEvent = Types.ErrorEvent
type Event = Types.Event
type EventDropReason = Types.EventDropReason
type EventHint = Types.EventHint
type Integration = Types.Integration
type IntegrationClass<T> = Types.IntegrationClass<T>
type Outcome = Types.Outcome
type PropagationContext = Types.PropagationContext
type SdkMetadata = Types.SdkMetadata
type Session = Types.Session
type SessionAggregates = Types.SessionAggregates
type SeverityLevel = Types.SeverityLevel
type Transaction = Types.Transaction
type TransactionEvent = Types.TransactionEvent
type Transport = Types.Transport
type TransportMakeRequestResponse = Types.TransportMakeRequestResponse

local Utils = require("@packages/utils")
local addItemToEnvelope = Utils.addItemToEnvelope
local checkOrSetAlreadyCaught = Utils.checkOrSetAlreadyCaught
local createAttachmentEnvelopeItem = Utils.createAttachmentEnvelopeItem
local isPlainObject = Utils.isPlainObject
local isPrimitive = Utils.isPrimitive
local isThenable = Utils.isThenable
local logger = Utils.logger
local makeDsn = Utils.makeDsn
local SentryError = Utils.SentryError
local Promise = Utils.Promise

local Api = require("./api")
