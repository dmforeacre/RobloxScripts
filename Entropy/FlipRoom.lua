-- Services
local RepStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remotes

-- References
local model = script.Parent
local room = workspace.RoomV1

-- Create proximity prompt
local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "Steel Door"
prompt.ActionText = "Open"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.Parent = model.PrimaryPart

prompt.Triggered:Connect(function(player)
	prompt.Enabled = false
	local roomParts = room:GetDescendants()
	local roomPartsInitial = {}
	for _, child in pairs(roomParts) do
		if child:IsA("BasePart") or child:IsA("SpawnLocation") then
			roomPartsInitial[child] = child.CFrame
		end
	end
	local roomPartsOffsets = {}
	for _, child in pairs(roomParts) do
		if child:IsA("BasePart") or child:IsA("SpawnLocation") then
			roomPartsOffsets[child] = model.Handle.CFrame:Inverse() * child.CFrame
		end
	end
	local turnSoundPlayed = false
	player.Character.PrimaryPart.Anchored = true
	local connection
	local t = 0
	connection = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t <= 2 then
			if not turnSoundPlayed then
				turnSoundPlayed = true
				model.shipdoortest2:Play()
			end
			model.Handle:PivotTo(model.Handle.CFrame * CFrame.Angles(dt * (math.pi / 2),0,0))
			for _, child in pairs(roomParts) do
				if child:IsA("BasePart") or child:IsA("SpawnLocation") then
					child.CFrame = model.Handle.CFrame * roomPartsOffsets[child]
				end
			end
		end
		if t >= 2 then
			model.shipdoortest2:Stop()
			player.Character.PrimaryPart.Anchored = false
			connection:Disconnect()
		end
	end)
end)
