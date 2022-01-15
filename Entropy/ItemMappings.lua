local Mappings = {
	["Yellow Key"] = "Wooden Door2",
	["Viridian Key"] = "Steel Door Locked",
	["Blue Key"] = "Wooden Door3",
	["Glaucous Key"] = "Lock",
	["Postit"] = "Safe",
	["Nihilism Key"] = "Wooden Door6",
	["PostitHalf1"] = "SafeHalf",
	["PostitHalf2"] = "SafeHalf2",
	["No Way Out Key"] = "LockFlood"
}

local pugs = 0

function Mappings.GetIndex(name)
	for index, model in pairs(Mappings) do
		if model == name then
			return index
		end
	end
	return nil
end

function Mappings.CollectPug()
	pugs += 1
end

function Mappings.GetNumPugs()
	return pugs
end

return Mappings
