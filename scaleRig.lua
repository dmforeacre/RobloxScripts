-- Function to scale a model
local function scaleModel(model, scale)
	local rigType = model.Humanoid.RigType
	local oldHip = model.Humanoid.HipHeight
	local newHip = oldHip * scale
	model.Humanoid.HipHeight = newHip
	model:PivotTo(model.PrimaryPart.CFrame + Vector3.new(0, newHip - oldHip, 0))
	local primaryCFrame = model.PrimaryPart.CFrame
	local scaleVector = Vector3.new(scale, scale, scale)
	local motors = {}
	for _, v in next, model:GetDescendants() do
		if v:IsA("BasePart") then
			v.Anchored = false
			if v == model.PrimaryPart then
				v.Size *= scaleVector
				v.CFrame = primaryCFrame
			else
				local objectCFrame = primaryCFrame:inverse() * v.CFrame
				objectCFrame += (objectCFrame.Position * scale) - objectCFrame.Position
				v.Size *= scaleVector
				v.CFrame = primaryCFrame * objectCFrame
			end
		elseif v:IsA("Motor6D") and rigType == Enum.HumanoidRigType.R6 then
			table.insert(motors, {["Motor"] = v, ["Parent"] = v.Parent})
			v.Parent = nil
		elseif v:IsA("Motor6D") and rigType == Enum.HumanoidRigType.R15 then
			v:Destroy()
		end
	end
	for _, v in next, model:GetDescendants() do
		
		if v:IsA("Attachment") then
			v.Parent.Anchored = false
			local orientation = v.CFrame - v.CFrame.Position
			local newPos = (v.WorldPosition - v.Parent.Position) * scaleVector
			v.CFrame = CFrame.new(newPos) * orientation
			--v.CFrame = CFrame.new(v.Position * scale) * orientation
		end
	end
		
	if rigType == Enum.HumanoidRigType.R6 then
		model:PivotTo(model.PrimaryPart.CFrame + Vector3.new(0, model["Left Leg"].Size.Y / 2, 0))
		for i = 1, #motors do
			motors[i].Motor.Parent = motors[i].Parent
		end
	end
	if rigType == Enum.HumanoidRigType.R15 then
		model.Humanoid:BuildRigFromAttachments()
	end
	return model
end
