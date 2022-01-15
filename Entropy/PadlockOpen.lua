-- Services
local RepStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remotes
local useItemEvent = RepStorage.Remotes.UseItemEvent

-- References
local model = script.Parent

-- Create proximity prompt
local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "Gate?"
prompt.ActionText = "Let Me Out"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.RequiresLineOfSight = false
prompt.Parent = model.PrimaryPart

prompt.Triggered:Connect(function(player)
	useItemEvent:FireClient(player, model)
end)

useItemEvent.OnServerEvent:Connect(function(player, m)
	if m == model then
		local soundPlayed = false
		prompt.Enabled = false
		model.padlockunlock:Play()
		local doorOffset = model.Parent.Hinge.CFrame:Inverse() * model.Parent.Door.CFrame
		local t = 0
		local connection
		connection = RunService.Heartbeat:Connect(function(dt)
			t += dt
			
			if t < .8 then
				model.Body.CFrame += model.Body.CFrame.UpVector * -dt
			end
			
			if t >= 1 then
				model.Body.Anchored = false
				model.Latch.Anchored = false
				model.Parent.Hinge.CFrame *= CFrame.Angles(0,dt*1.3,0)
				model.Parent.Door.CFrame = model.Parent.Hinge.CFrame * doorOffset
				if not soundPlayed then
					model.padlockfall:Play()
					soundPlayed = true
				end
			end
				
			if t >= 2 then
				model.Parent.gate1:Play()
				connection:Disconnect()
			end
		end)
	end
end)

