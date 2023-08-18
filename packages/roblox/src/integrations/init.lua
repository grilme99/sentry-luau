-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/integrations/index.ts

local Integrations = {}

Integrations.GlobalHandlers = require(script.globalhandlers)
Integrations.InApp = require(script.inapp)
Integrations.Dedupe = require(script.dedupe)

return Integrations
