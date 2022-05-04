-- Services
local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local DS = game:GetService("Debris")

-- Player stuff
local player = Players.LocalPlayer
local chr = player.Character or player.CharacterAdded:Wait()

-- Constants, feel free to adjust these however you want
local NUM_SPIKES = 4
local ORBIT_DIST = 6
local SPIKE_LENGTH = 14
local DURATION = 2
local ROTATION = 64
local DELTA_LENGTH = .23

-- Object references
local storage = RepStorage.skillsEffects.Elemental.Ice
local button = script.Parent
local spike = storage.Spike
local dust = spike.Dust
local dust2 = storage.Dust2
local strike = storage.Strike

-- Temp storage folder
local folder = workspace.Effects

-- Run on button click
button.Activated:Connect(function()
	-- Freeze player
	for _, part in pairs(chr:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	
	-- Create all parts for effect
	local spheres = {}
	local colors = {}
	local model = Instance.new("Model")
	local center = Instance.new("Part")
	center.Position = chr.PrimaryPart.Position + Vector3.new(0,10,0)
	center.Transparency = 1
	center.Anchored = true
	center.CanCollide = false
	center.Parent = model
	model.PrimaryPart = center
	model.Parent = folder
	
	for i = 1, NUM_SPIKES do
		spheres[i] = Instance.new("Part")
		spheres[i].Shape = Enum.PartType.Ball
		spheres[i].Size = Vector3.new(.5,.5,.5)
		spheres[i].Material = Enum.Material.Ice
		spheres[i].Transparency = .5
		spheres[i].Anchored = true
		spheres[i].CanCollide = false
		spheres[i].Color = Color3.fromRGB(175, 221, 255)
		local newDust = dust:Clone()
		newDust.Parent = spheres[i]
		local newDust2 = dust2:Clone()
		newDust2.Parent = spheres[i]
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = spheres[i]
		weld.Part1 = center
		weld.Parent = spheres[i]
		local tempCF = chr.PrimaryPart.CFrame * CFrame.Angles(0,i * ((2 * math.pi) / NUM_SPIKES), 0)
		tempCF += tempCF.LookVector * ORBIT_DIST
		tempCF += Vector3.new(0,10,0)
		spheres[i].CFrame = tempCF		
		spheres[i].Parent = model
	end
	
	-- Render stepped connection for animation
	local connection
	local timer = 0
	connection = RS.RenderStepped:Connect(function(dt)
		timer += dt
		if timer >= DURATION then
			connection:Disconnect()
		end
		local prop = timer / DURATION
		center.CFrame = (center.CFrame * CFrame.Angles(0,math.clamp((1/prop),.01,.99) * (math.pi/ROTATION),0)) - Vector3.new(0,(prop) * DELTA_LENGTH,0)
		for i = 1, NUM_SPIKES do
			spheres[i].Transparency = math.clamp(spheres[i].Transparency - prop,0,1)
			local tempCF = center.CFrame * CFrame.Angles(0,i * ((2 * math.pi) / NUM_SPIKES), 0)
			tempCF += tempCF.LookVector * ORBIT_DIST
			spheres[i].CFrame = tempCF
		end
	end)
	task.wait(1)
	local newStrike = strike:Clone()
	newStrike.Parent = chr.Head
	DS:AddItem(newStrike, 2.5)
	task.wait(1.5)
	
	-- Create spikes
	local spikes = {}
	for i = 1, NUM_SPIKES do
		spikes[i] = spike:Clone()
		spikes[i].Size = Vector3.new(0,0,0)
		spikes[i].CFrame = CFrame.lookAt(spheres[i].Position, chr.Head.Position) * CFrame.Angles((3*math.pi)/2,0,0)
		spikes[i].Parent = folder
		local tween = TS:Create(
			spikes[i],
			TweenInfo.new(.5,Enum.EasingStyle.Exponential),
			{Size = Vector3.new(SPIKE_LENGTH/4,SPIKE_LENGTH,SPIKE_LENGTH/4),
				Position = spikes[i].Position + (spikes[i].CFrame.UpVector * (SPIKE_LENGTH / 2.7))
			}
		)
		local tween2 = TS:Create(
			spheres[i],
			TweenInfo.new(.3,Enum.EasingStyle.Exponential),
			{Transparency = 1}
		)
		tween:Play()
		tween2:Play()
	end	
	
	task.wait(2)
	
	-- Tween transparency out
	for i = 1, NUM_SPIKES do
		local tween = TS:Create(
			spikes[i],
			TweenInfo.new(1,Enum.EasingStyle.Cubic),
			{Transparency = 1}
		)
		tween:Play()
	end
	
	task.wait(1)
	
	-- Remove parts
	for i = 1, NUM_SPIKES do
		spheres[i]:Destroy()
		spikes[i]:Destroy()
	end
	
	-- Unfreeze player
	for _, part in pairs(chr:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
end)
