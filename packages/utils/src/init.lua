local Utils = {}

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

Utils.Promise = require("./vendor/promise")

return Utils
