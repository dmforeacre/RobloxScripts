-- Services
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remotes
local useItemEvent = RepStorage.Remotes.UseItemEvent

-- References
local model = script.Parent
local plr = Players:FindFirstChildOfClass("Player") or Players:WaitForChild("TerminusEstKuldin")
local chr = plr.Character or plr.CharacterAdded:Wait()

local connection
connection = RunService.Heartbeat:Connect(function(dt)
	model.draweropening.Pitch = 1
	model.draweropening:Play()
	if (chr.PrimaryPart.Position - model.PrimaryPart.Position).Magnitude <= 10 then
		model:PivotTo(model.PrimaryPart.CFrame + Vector3.new(0,0,-dt * 15))
	end
end)
