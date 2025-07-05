local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DevPackages = ReplicatedStorage.DevPackages
local JestGlobals = require(DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

describe("math", function()
    it("should add two numbers", function()
        expect(1 + 2).toBe(3)
    end)
end)
