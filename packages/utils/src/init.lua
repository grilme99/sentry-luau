local Utils = {}

local Dsn = require("./dsn")
Utils.dsnFromComponents = Dsn.dsnFromComponents
Utils.dsnToString = Dsn.dsnToString
Utils.makeDsn = Dsn.makeDsn

local Envelope = require("./envelope")
Utils.addItemToEnvelope = Envelope.addItemToEnvelope
Utils.createAttachmentEnvelopeItem = Envelope.createAttachmentEnvelopeItem
Utils.createEnvelope = Envelope.createEnvelope
Utils.createEventEnvelopeHeaders = Envelope.createEventEnvelopeHeaders
Utils.envelopeContainsItemType = Envelope.envelopeContainsItemType
Utils.envelopeItemTypeToDataCategory = Envelope.envelopeItemTypeToDataCategory
Utils.forEachEnvelopeItem = Envelope.forEachEnvelopeItem
Utils.getSdkMetadataForEnvelopeHeader = Envelope.getSdkMetadataForEnvelopeHeader
Utils.serializeEnvelope = Envelope.serializeEnvelope

local SentryError = require("./error")
export type SentryError = SentryError.SentryError
Utils.SentryError = SentryError

local Global = require("./global")
Utils.GLOBAL_OBJ = Global.GLOBAL_OBJ
Utils.getGlobalSingleton = Global.getGlobalSingleton

local Is = require("./is")
Utils.isPrimitive = Is.isPrimitive
Utils.isSyntheticEvent = Is.isSyntheticEvent
Utils.isNaN = Is.isNaN
Utils.isPlainObject = Is.isPlainObject
Utils.isThenable = Is.isThenable

local Logger = require("./logger")
Utils.logger = Logger.logger
Utils.consoleSandbox = Logger.consoleSandbox

local Memo = require("./memo")
export type MemoFunc = Memo.MemoFunc
Utils.memoBuilder = Memo.memoBuilder

local MiscUtils = require("./misc")
Utils.uuid4 = MiscUtils.uuid4
Utils.arrayify = MiscUtils.arrayify
Utils.checkOrSetAlreadyCaught = MiscUtils.checkOrSetAlreadyCaught

local Normalize = require("./normalize")
Utils.normalize = Normalize.normalize
Utils.normalizeToSize = Normalize.normalizeToSize

local Object = require("./object")
Utils.urlEncode = Object.urlEncode

local PromiseBuffer = require("./promisebuffer")
export type PromiseBuffer<T> = PromiseBuffer.PromiseBuffer<T>
Utils.makePromiseBuffer = PromiseBuffer.makePromiseBuffer

local RateLimit = require("./ratelimit")
export type RateLimits = RateLimit.RateLimits
Utils.DEFAULT_RETRY_AFTER = RateLimit.DEFAULT_RETRY_AFTER
Utils.disabledUntil = RateLimit.disabledUntil
Utils.isRateLimited = RateLimit.isRateLimited
Utils.parseRetryAfterHeader = RateLimit.parseRetryAfterHeader
Utils.updateRateLimits = RateLimit.updateRateLimits

local Stacktrace = require("./stacktrace")
Utils.createStackParser = Stacktrace.createStackParser
Utils.getFunctionName = Stacktrace.getFunctionName
Utils.stackParserFromStackParserOptions = Stacktrace.stackParserFromStackParserOptions
Utils.stripSentryFramesAndReverse = Stacktrace.stripSentryFramesAndReverse

local StringUtils = require("./string")
Utils.truncate = StringUtils.truncate

local TimeUtils = require("./time")
Utils.dateTimestampInSeconds = TimeUtils.dateTimestampInSeconds
Utils.timestampInSeconds = TimeUtils.timestampInSeconds

Utils.Polyfill = {}
Utils.Polyfill.instanceof = require("./polyfill/instanceof")
Utils.Polyfill.Error = require("./polyfill/error")
Utils.Polyfill.Object = require("./polyfill/object")
Utils.Polyfill.Array = require("./polyfill/array")

Utils.Promise = require("./vendor/promise")

return Utils
