-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/index.ts

local SentryLua = {}

local Sdk = require(script.sdk)
export type ClientClass = Sdk.ClientClass
SentryLua.initAndBind = Sdk.initAndBind

local Hub = require(script.hub)
export type Hub = Hub.Hub
export type AsyncContextStrategy = Hub.AsyncContextStrategy
export type Carrier = Hub.Carrier
export type Layer = Hub.Layer
export type RunWithAsyncContextOptions = Hub.RunWithAsyncContextOptions
SentryLua.getCurrentHub = Hub.getCurrentHub
SentryLua.getHubFromCarrier = Hub.getHubFromCarrier
SentryLua.Hub = Hub.Hub
SentryLua.makeMain = Hub.makeMain
SentryLua.getMainCarrier = Hub.getMainCarrier
SentryLua.runWithAsyncContext = Hub.runWithAsyncContext
SentryLua.setHubOnCarrier = Hub.setHubOnCarrier
SentryLua.ensureHubOnCarrier = Hub.ensureHubOnCarrier
SentryLua.setAsyncContextStrategy = Hub.setAsyncContextStrategy

local Exports = require(script.exports)
SentryLua.addBreadcrumb = Exports.addBreadcrumb
SentryLua.captureException = Exports.captureException
SentryLua.captureEvent = Exports.captureEvent
SentryLua.captureMessage = Exports.captureMessage
SentryLua.configureScope = Exports.configureScope
SentryLua.startTransaction = Exports.startTransaction
SentryLua.setContext = Exports.setContext
SentryLua.setExtra = Exports.setExtra
SentryLua.setExtras = Exports.setExtras
SentryLua.setTag = Exports.setTag
SentryLua.setTags = Exports.setTags
SentryLua.setUser = Exports.setUser
SentryLua.withScope = Exports.withScope
SentryLua.captureCheckIn = Exports.captureCheckIn

local Session = require(script.session)
SentryLua.makeSession = Session.makeSession
SentryLua.closeSession = Session.closeSession
SentryLua.updateSession = Session.updateSession

local SessionFlusher = require(script.sessionflusher)
export type SessionFlusher = SessionFlusher.SessionFlusher
SentryLua.SessionFlusher = SessionFlusher

local Scope = require(script.scope)
export type Scope = Scope.Scope
SentryLua.addGlobalEventProcessor = Scope.addGlobalEventProcessor
SentryLua.Scope = Scope

local Api = require(script.api)
SentryLua.getEnvelopeEndpointWithUrlEncodedAuth = Api.getEnvelopeEndpointWithUrlEncodedAuth
SentryLua.getReportDialogEndpoint = Api.getReportDialogEndpoint

local BaseClient = require(script.baseclient)
export type BaseClient<O> = BaseClient.BaseClient<O>
SentryLua.BaseClient = BaseClient

local BaseTransport = require(script.transports.base)
SentryLua.createTransport = BaseTransport.createTransport

local Version = require(script.version)
SentryLua.SDK_VERSION = Version.SDK_VERSION

local Integration = require(script.integration)
SentryLua.getIntegrationsToSetup = Integration.getIntegrationsToSetup

local PrepareEvent = require(script.utils.prepareEvent)
SentryLua.prepareEvent = PrepareEvent.prepareEvent

local CheckIn = require(script.checkin)
SentryLua.createCheckInEnvelope = CheckIn.createCheckInEnvelope

local hasTracingEnabled = require(script.utils.hasTracingEnabled)
SentryLua.hasTracingEnabled = hasTracingEnabled

local Constants = require(script.constants)
SentryLua.DEFAULT_ENVIRONMENT = Constants.DEFAULT_ENVIRONMENT

return SentryLua
