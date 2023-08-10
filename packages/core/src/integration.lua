-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/core/src/integration.ts

local Types = require("@packages/types")
type Integration_ = Types.Integration
type Options = Types.Options

local Utils = require("@packages/utils")
local Array = Utils.Polyfill.Array
local arrayify = Utils.arrayify
local logger = Utils.logger

local Hub = require("./hub")
local getCurrentHub = Hub.getCurrentHub

local Scope = require("./scope")
local addGlobalEventProcessor = Scope.addGlobalEventProcessor

type Array<T> = { T }
type Map<K, V> = { [K]: V }

type Integration = Integration_ & {
    isDefaultInstance: boolean?,
}

local Integration = {}

local installedIntegrations: Array<string> = {}
Integration.installedIntegrations = installedIntegrations

export type IntegrationIndex = Map<string, Integration>

--- Remove duplicates from the given array, preferring the last instance of any duplicate. Not guaranteed to preserve
--- the order of integrations in the array.
---
--- @private
local function filterDuplicates(integrations: Array<Integration>): Array<Integration>
    local integrationsByName: Map<string, Integration> = {}

    for _, currentInstance in integrations do
        local name = currentInstance.name

        local existingInstance = integrationsByName[name]

        -- We want integrations later in the array to overwrite earlier ones of the same type, except that we never want
        -- a default instance to overwrite an existing user instance
        if existingInstance and not existingInstance.isDefaultInstance and currentInstance.isDefaultInstance then
            continue
        end

        integrationsByName[name] = currentInstance
    end

    local filteredIntegrations = {}
    for _, integration in integrationsByName do
        table.insert(filteredIntegrations, integration)
    end
    return filteredIntegrations
end

--- Gets integrations to install
function Integration.getIntegrationsToSetup(options: Options): Array<Integration>
    local defaultIntegrations: Array<Integration> = options.defaultIntegrations or {}
    local userIntegrations: Array<Integration> = options.integrations

    -- We flag default instances, so that later we can tell them apart from any user-created instances of the same class
    for _, integration in defaultIntegrations do
        integration.isDefaultInstance = true
    end

    local integrations: Array<Integration>

    if Array.isArray(userIntegrations) then
        -- integrations = [...defaultIntegrations, ...userIntegrations];
        integrations = Array.concat(defaultIntegrations, userIntegrations)
    elseif type(userIntegrations) == "function" then
        integrations = arrayify(userIntegrations(defaultIntegrations))
    else
        integrations = defaultIntegrations
    end

    local finalIntegrations = filterDuplicates(integrations)

    -- The `Debug` integration prints copies of the `event` and `hint` which will be passed to `beforeSend` or
    -- `beforeSendTransaction`. It therefore has to run after all other integrations, so that the changes of all event
    -- processors will be reflected in the printed values. For lack of a more elegant way to guarantee that, we
    -- therefore locate it and, assuming it exists, pop it out of its current spot and shove it onto the end of the
    -- array.
    local debugIndex = Array.findIndex(finalIntegrations, function(integration)
        return integration.name == "Debug"
    end)
    if debugIndex ~= -1 then
        local debugInstance = Array.splice(finalIntegrations, debugIndex, 1)[1]
        table.insert(finalIntegrations, debugInstance)
    end

    return finalIntegrations
end

--- Given a list of integration instances this installs them all. When `withDefaults` is set to `true` then all default
--- integrations are added unless they were already provided before.
--- @param integrations array of integration instances
--- @param withDefault should enable default integrations
function Integration.setupIntegrations(integrations: Array<Integration>): IntegrationIndex
    local integrationIndex: IntegrationIndex = {}

    for _, integration in integrations do
        -- guard against empty provided integrations
        if integration then
            Integration.setupIntegration(integration, integrationIndex)
        end
    end

    return integrationIndex
end

--- Setup a single integration.
function Integration.setupIntegration(integration: Integration, integrationIndex: IntegrationIndex)
    integrationIndex[integration.name] = integration

    if Array.indexOf(installedIntegrations, integration.name) == -1 then
        integration.setupOnce(addGlobalEventProcessor, getCurrentHub)
        table.insert(installedIntegrations, integration.name)
        if _G.__SENTRY_DEV__ then
            logger.log(`Integration installed: {integration.name}`)
        end
    end
end

return Integration
