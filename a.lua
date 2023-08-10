local Class = {}
Class.__index = Class

function Class.new()
	local self = setmetatable({}, Class)
	return self
end

local foo = Class.new()
print(debug.info(getmetatable(foo).new, "a"))
