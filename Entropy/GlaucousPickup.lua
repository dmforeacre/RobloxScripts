-- Services
local RepStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Remotes
local pickUpEvent = RepStorage.Remotes.PickUpEvent

-- References
local model = script.Parent
local trainLight = ServerStorage.Parts.TrainLight
local waypoints = workspace.RoomV1.TrainTrail

-- Create proximity prompt
local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = model.Name
prompt.ActionText = "Pick Up"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.Parent = model.PrimaryPart

prompt.Triggered:Connect(function(player)
	model.keyjangle:Play()
	pickUpEvent:FireClient(player, model)
	local newLight = trainLight:Clone()
	newLight.CFrame = waypoints["0"].CFrame
	newLight.Parent = workspace.RoomV1.RoundObjects
	newLight["subway-sounds"]:Play()
	newLight["loud-train-horn-sound"]:Play()
	for i = 1, 4 do
		local tween = TweenService:Create(newLight,TweenInfo.new(3-(i/2)),{CFrame = waypoints[tostring(i)].CFrame})
		tween:Play()
		tween.Completed:Wait()
	end
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = 10
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Position = workspace.RoomV1.SpawnPoints.Explosion.Position
	explosion.Parent = workspace.RoomV1.RoundObjects.Explosion
	newLight:Destroy()
end)

