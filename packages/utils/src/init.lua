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

local Global = require("./global")
Utils.GLOBAL_OBJ = Global.GLOBAL_OBJ
Utils.getGlobalSingleton = Global.getGlobalSingleton

local Is = require("./is")
Utils.isPlainObject = Is.isPlainObject
Utils.isThenable = Is.isThenable

local Logger = require("./logger")
Utils.logger = Logger.logger
Utils.consoleSandbox = Logger.consoleSandbox

local MiscUtils = require("./misc")
Utils.uuid4 = MiscUtils.uuid4
Utils.arrayify = MiscUtils.arrayify

local TimeUtils = require("./time")
Utils.dateTimestampInSeconds = TimeUtils.dateTimestampInSeconds
Utils.timestampInSeconds = TimeUtils.timestampInSeconds

Utils.Polyfill = {}
Utils.Polyfill.instanceof = require("./polyfill/instanceof")
Utils.Polyfill.Error = require("./polyfill/error")
Utils.Polyfill.Object = require("./polyfill/object")

Utils.Promise = require("./vendor/promise")

return Utils
