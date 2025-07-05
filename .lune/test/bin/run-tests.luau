local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local DevPackages = ReplicatedStorage.DevPackages
local Jest = require(DevPackages.Jest)

local PACKAGE_ROOTS = {
    Packages.SentryCore,
    Packages.SentryRoblox,
    Packages.SentryTypes,
    Packages.SentryUtils,
}

local status, result = Jest.runCLI(ReplicatedStorage, {
    verbose = _G.__VERBOSE__,
    ci = _G.__CI__,
    passWithNoTests = true,
}, PACKAGE_ROOTS):awaitStatus()

if status == "Rejected" then
    error(result)
end

return nil
