local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jest = require(Packages._Workspace.TestPlace.Jest)

local status, result = Jest.runCLI(ReplicatedStorage, {
	verbose = _G.__VERBOSE__,
	ci = _G.__CI__,
}, { ReplicatedStorage.TestRunner }):awaitStatus()

if status == "Rejected" then
	error(result)
end

return nil
