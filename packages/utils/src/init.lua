-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/index.ts

local Utils = {}

local PackageRoot = script

local Dsn = require(PackageRoot.dsn)
Utils.dsnFromComponents = Dsn.dsnFromComponents
Utils.dsnToString = Dsn.dsnToString
Utils.makeDsn = Dsn.makeDsn

local Envelope = require(PackageRoot.envelope)
Utils.addItemToEnvelope = Envelope.addItemToEnvelope
Utils.createAttachmentEnvelopeItem = Envelope.createAttachmentEnvelopeItem
Utils.createEnvelope = Envelope.createEnvelope
Utils.createEventEnvelopeHeaders = Envelope.createEventEnvelopeHeaders
Utils.envelopeContainsItemType = Envelope.envelopeContainsItemType
Utils.envelopeItemTypeToDataCategory = Envelope.envelopeItemTypeToDataCategory
Utils.forEachEnvelopeItem = Envelope.forEachEnvelopeItem
Utils.getSdkMetadataForEnvelopeHeader = Envelope.getSdkMetadataForEnvelopeHeader
Utils.serializeEnvelope = Envelope.serializeEnvelope

local SentryError = require(PackageRoot.error)
export type SentryError = SentryError.SentryError
Utils.SentryError = SentryError

local Global = require(PackageRoot.global)
Utils.GLOBAL_OBJ = Global.GLOBAL_OBJ
Utils.getGlobalSingleton = Global.getGlobalSingleton

local Is = require(PackageRoot.is)
Utils.isError = Is.isError
Utils.isPrimitive = Is.isPrimitive
Utils.isSyntheticEvent = Is.isSyntheticEvent
Utils.isNaN = Is.isNaN
Utils.isPlainObject = Is.isPlainObject
Utils.isThenable = Is.isThenable

local Logger = require(PackageRoot.logger)
Utils.logger = Logger.logger
Utils.consoleSandbox = Logger.consoleSandbox

local Memo = require(PackageRoot.memo)
export type MemoFunc = Memo.MemoFunc
Utils.memoBuilder = Memo.memoBuilder

local MiscUtils = require(PackageRoot.misc)
Utils.uuid4 = MiscUtils.uuid4
Utils.arrayify = MiscUtils.arrayify
Utils.checkOrSetAlreadyCaught = MiscUtils.checkOrSetAlreadyCaught
Utils.addExceptionMechanism = MiscUtils.addExceptionMechanism
Utils.addExceptionTypeValue = MiscUtils.addExceptionTypeValue
Utils.getEventDescription = MiscUtils.getEventDescription
Utils.isMatchingPattern = MiscUtils.isMatchingPattern
Utils.stringMatchesSomePattern = MiscUtils.stringMatchesSomePattern

local Normalize = require(PackageRoot.normalize)
Utils.normalize = Normalize.normalize
Utils.normalizeToSize = Normalize.normalizeToSize

local Object = require(PackageRoot.object)
Utils.urlEncode = Object.urlEncode
Utils.extractExceptionKeysForMessage = Object.extractExceptionKeysForMessage

local PromiseBuffer = require(PackageRoot.promisebuffer)
export type PromiseBuffer<T> = PromiseBuffer.PromiseBuffer<T>
Utils.makePromiseBuffer = PromiseBuffer.makePromiseBuffer

local RateLimit = require(PackageRoot.ratelimit)
export type RateLimits = RateLimit.RateLimits
Utils.DEFAULT_RETRY_AFTER = RateLimit.DEFAULT_RETRY_AFTER
Utils.disabledUntil = RateLimit.disabledUntil
Utils.isRateLimited = RateLimit.isRateLimited
Utils.parseRetryAfterHeader = RateLimit.parseRetryAfterHeader
Utils.updateRateLimits = RateLimit.updateRateLimits

local Stacktrace = require(PackageRoot.stacktrace)
Utils.createStackParser = Stacktrace.createStackParser
Utils.getFunctionName = Stacktrace.getFunctionName
Utils.stackParserFromStackParserOptions = Stacktrace.stackParserFromStackParserOptions
Utils.stripSentryFramesAndReverse = Stacktrace.stripSentryFramesAndReverse

local StringUtils = require(PackageRoot.string)
Utils.truncate = StringUtils.truncate

local TimeUtils = require(PackageRoot.time)
Utils.dateTimestampInSeconds = TimeUtils.dateTimestampInSeconds
Utils.timestampInSeconds = TimeUtils.timestampInSeconds

return Utils
