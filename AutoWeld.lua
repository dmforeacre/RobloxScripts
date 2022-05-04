-- Fill path to model here:
local model = game.Workspace.TileTest

-- First go through and remove all existing welds
for _, c in pairs(model:GetDescendants()) do
	if c:IsA("WeldConstraint") or c:IsA("Weld") then
		c:Destroy()
	end
end

-- Iterate through descendants and weld them all to primary part
if not model.PrimaryPart then
	error("Primary part must be defined for model!")
end
local prevPart = model.PrimaryPart
for _, c in pairs(model:GetDescendants()) do
	if c:IsA("BasePart") and c ~= prevPart then
		c.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = prevPart
		weld.Part1 = c
		weld.Parent = c
	end
end
