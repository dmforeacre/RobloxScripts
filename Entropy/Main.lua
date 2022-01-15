-- Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RepStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local BadgeService = game:GetService("BadgeService")

-- Modules
local itemMappings = require(RepStorage.ItemMappings)
local roundHandler = require(RepStorage.RoundHandler)

-- Remotes
local screenFadeEvent = RepStorage.Remotes.ScreenFadeEvent
local pickUpEvent = RepStorage.Remotes.PickUpEvent
local useItemEvent = RepStorage.Remotes.UseItemEvent
local endGameEvent = RepStorage.Remotes.EndGameEvent

-- References
local player = nil
local character = nil
local room = workspace.RoomV1
local teleports = room.Teleports
local spawnBlock = room.SpawnLocation
local spawns = room.SpawnPoints
local objFolder = room.RoundObjects
local roomParts = room:GetDescendants()
local bgMusic = SoundService.BGMusic.level1
local rnd = Random.new(os.clock())

bgMusic:Play()

local roomPartsInitial = {}
for _, child in pairs(roomParts) do
	if child:IsA("BasePart") or child:IsA("SpawnLocation") then
		roomPartsInitial[child] = child.CFrame
	end
end

-- Round information
local rounds = {
	[1] = {
		[1] = {["Item"] = "Steel Door Normal", ["CFramePart"] = "MidRoomDoor"},
		[2] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[3] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn1"}
	},
	[2] = {
		[1] = {["Item"] = "Yellow Key", ["CFramePart"] = "Rails1"},
		[2] = {["Item"] = "Wooden Door", ["CFramePart"] = "EndRoomDoor"},
		[3] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[4] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn2"}
	},
	[3] = {
		[1] = {["Item"] = "Safe", ["CFramePart"] = "FirstRoom1"},
		[2] = {["Item"] = "Postit", ["CFramePart"] = "PostitDoor"},
		[3] = {["Item"] = "Wooden Door", ["CFramePart"] = "EndRoomDoor"},
		[4] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[5] = {["Item"] = "Tile1", ["CFramePart"] = "RailTile"},
		[6] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn3"}
	},
	[4] = {
		[1] = {["Item"] = "Sliding Puzzle", ["CFramePart"] = "MidRoom1"},
		[2] = {["Item"] = "Wooden Door Running", ["CFramePart"] = "EndRoomDoor"},
		[3] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[4] = {["Item"] = "Steel Door Locked", ["CFramePart"] = "MidRoomDoor"},
		[5] = {["Item"] = "Crate2", ["CFramePart"] = "EndHallCrate2"},
		[6] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn4"}
	},
	[5] = {
		[1] = {["Item"] = "Gate", ["CFramePart"] = "MidGate"},
		[2] = {["Item"] = "Glaucous Key", ["CFramePart"] = "Tube"},
		[3] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn5"},
		[4] = {["Item"] = "Explosion", ["CFramePart"] = "Explosion"}
	},
	[6] = {
		[1] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[2] = {["Item"] = "Wooden Door", ["CFramePart"] = "EndRoomDoor"},
		[3] = {["Item"] = "PostitHalf1", ["CFramePart"] = "PostitWall"},
		[4] = {["Item"] = "Sliding Puzzle Code", ["CFramePart"] = "FirstRoom2"},
		[5] = {["Item"] = "SafeHalf", ["CFramePart"] = "MidRoom2"},
		[6] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn6"}
	},
	[7] = {
		[1] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[2] = {["Item"] = "Sliding Puzzle Flood", ["CFramePart"] = "EndHallPuzzle"},
		[3] = {["Item"] = "Wooden Door Closed", ["CFramePart"] = "EndRoomDoor"},
		[4] = {["Item"] = "Crate", ["CFramePart"] = "EndHallCrate"},
		[5] = {["Item"] = "EndWaterDrips", ["CFramePart"] = "EndWaterDrips"},
		[6] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn7"}
	},
	[8] = {
		[1] = {["Item"] = "RightTubeBars", ["CFramePart"] = "TubeBars"},
		[2] = {["Item"] = "Steel Door Flip", ["CFramePart"] = "MidRoomDoor"},
		[3] = {["Item"] = "Pug Plush", ["CFramePart"] = "PugSpawn8"}
	},
	[9] = {
		
	}
}

-- Player information
local currentRound = 1
local inventory = {}

-- Utility functions
local function PrintInventory()
	for _, item in pairs(inventory) do
		print(item)
	end
end

local function SetRoundObjects()
	-- Adjust water drops
	local currColor = workspace.RoomV1.WaterDrips.ParticleEmitter.Color.Keypoints[1].Value
	workspace.RoomV1.WaterDrips.ParticleEmitter.Color = ColorSequence.new(Color3.new(currColor.R,currColor.G-(currentRound*4),currColor.B-(currentRound*4)))
	workspace.RoomV1.WaterDrips.ParticleEmitter.Rate += currentRound * 4
	
--[[	-- Set reverb:
	if currentRound == 1 then
		SoundService.AmbientReverb = Enum.ReverbType.Room
	elseif currentRound == 3 then
		SoundService.AmbientReverb = Enum.ReverbType.Hallway
	elseif currentRound == 5 then
		SoundService.AmbientReverb = Enum.ReverbType.StoneRoom
	elseif currentRound == 7 then
		SoundService.AmbientReverb = Enum.ReverbType.SewerPipe
	end]]
	
	if currentRound == 8 then
		workspace.RoomV1.WaterDrips.Position -= Vector3.new(0,20,0)
		workspace.RoomV1.WaterDrips.ParticleEmitter.EmissionDirection = Enum.NormalId.Top
	end
	
	
	if character then
		character.Humanoid.Health = character.Humanoid.MaxHealth
	end
	for _, asset in ipairs(rounds[currentRound]) do
		local item = ServerStorage.Parts:FindFirstChild(asset.Item):Clone()
		item:PivotTo(spawns:FindFirstChild(asset.CFramePart).CFrame)
		if item.Name == "Wooden Door" then
			item.Name = "Wooden Door"..tostring(currentRound)
		end
		item.Parent = objFolder	
	end
	roundHandler.NewRound(currentRound)
	local tweenMusicOut = TweenService:Create(bgMusic,TweenInfo.new(2),{Volume = .5})
	tweenMusicOut:Play()
	bgMusic:Stop()
	bgMusic = SoundService.BGMusic:FindFirstChild("level"..tostring(currentRound))
	bgMusic.Parent = character
	print("Playing "..bgMusic.Name)
	bgMusic.Volume = .5
	bgMusic:Play()
	local tweenMusicIn = TweenService:Create(bgMusic,TweenInfo.new(2),{Volume = 4})
	tweenMusicIn:Play()
	if not character then
		player = Players.PlayerAdded:Wait()
		character = player.CharacterAdded:Wait()
	end
	character:PivotTo(CFrame.lookAt(spawnBlock.Position, workspace.RoomV1.Lights.FrontLight.PrimaryPart.Position))
end

local function EndTween()
	character.PrimaryPart.Anchored = true	
	local tweenMusicOut = TweenService:Create(bgMusic,TweenInfo.new(2),{Volume = .5})
	tweenMusicOut:Play()
	bgMusic:Stop()
	local badge
	if itemMappings.GetNumPugs() == 8 then
		bgMusic = SoundService.BGMusic.endstart2
		bgMusic.Parent = character
		print("Playing "..bgMusic.Name)
		bgMusic.Volume = .5
		bgMusic:Play()
		local tweenMusicIn = TweenService:Create(bgMusic,TweenInfo.new(2),{Volume = 4})
		tweenMusicIn:Play()
		badge = 2124907733
		endGameEvent:FireClient(player, true)	
		print("Good ending")
	else
		badge = 2124907763
		endGameEvent:FireClient(player, false)
		print("Bad Ending")
	end
	local hasBadge
	local success, err = pcall(function()
		hasBadge = BadgeService:UserHasBadgeAsync(player.UserId, badge)
	end)
	if success then
		if not hasBadge then
			BadgeService:AwardBadge(player.UserId, badge)
		end
	else
		warn("Error while retrieving badge information: "..err)
	end	
end

-- Player added
local currentGui = {}
Players.PlayerAdded:Connect(function(plr)
	player = plr
	player.CharacterAdded:Connect(function(chr)
		if currentRound == 1 then
			bgMusic.Parent = chr
			bgMusic:Play()
		end
		character = chr
		character.Humanoid.StateChanged:Connect(function()
			if character.Humanoid:GetState() == Enum.HumanoidStateType.Swimming then
				Lighting.Blur.Size = 10
			else
				Lighting.Blur.Size = 0
			end
		end)
		character:WaitForChild("ForceField"):Destroy()
		character:PivotTo(CFrame.lookAt(character.PrimaryPart.Position, workspace.RoomV1.Lights.FrontLight.PrimaryPart.Position))
	end)
end)

-- Teleport block
local debounce = false
local t = os.clock()
for _, teleport in pairs(teleports:GetChildren()) do
	teleport.Touched:Connect(function(part)
		if debounce then return end
		if os.clock() - t <= 10 then
			print("Trying to teleport too early. "..teleport.Name)
			return
		end
		if part.Parent == character then
			debounce = true
			currentRound += 1
			screenFadeEvent:FireClient(player, 2)
			task.wait(2)
			
			-- Reset room
			if currentRound == 8 then
				SoundService.AmbientReverb = Enum.ReverbType.SewerPipe
				workspace.Terrain:FillBlock(workspace.RoomV1.WaterFill.CFrame, workspace.RoomV1.WaterFill.Size, Enum.Material.Air)
				character.heartbeatring:Stop()
			end
			for _, child in pairs(roomParts) do
				if child:IsA("BasePart") or child:IsA("SpawnLocation") then
					child.CFrame = roomPartsInitial[child]
				end
			end
			for _, child in pairs(objFolder:GetChildren()) do
				child:Destroy()
			end
			
			if currentRound == 9 then
				EndTween()
			else
				SetRoundObjects()
			end
			
			debounce = false
		end
	end)
end

-- Item pick up event
pickUpEvent.OnServerEvent:Connect(function(player, item)
	if itemMappings[item.Name] == nil then
		warn("Entry for "..item.Name.." not found.")
	else
		table.insert(inventory, item.Name)
		PrintInventory()
	end
end)

-- Use item event
useItemEvent.OnServerEvent:Connect(function(player, model)
	local item = itemMappings.GetIndex(model.Name)
	if item == nil then
		warn("Interaction for "..model.Name.." not found.")
	else
		if table.find(inventory, item) then
			print("Door opened")
			model.PrimaryPart.ProximityPrompt.Enabled = false
		else
			print("Item not aquired")
		end
	end
end)

-- Start Round 1
bgMusic:Play()
SetRoundObjects()

-- Start flicker cycle
local styles = {Enum.EasingStyle.Elastic, Enum.EasingStyle.Bounce, Enum.EasingStyle.Sine}
local function Flicker(light)
	local tweenInfo = TweenInfo.new(rnd:NextNumber(.5,2),styles[rnd:NextInteger(1,#styles)],Enum.EasingDirection.In,0,true)
	local tween = TweenService:Create(light.Light.PointLight,tweenInfo,{Brightness = rnd:NextNumber(0,4)})
	tween:Play()
end
local lights = workspace.RoomV1.Lights:GetChildren()
local nextFlicker = {}
for _, light in pairs(lights) do
	nextFlicker[light] = rnd:NextInteger((60 / currentRound), (60 / currentRound) + (30 / currentRound)) + os.clock()
end
while true do
	task.wait(1)
	for _, light in pairs(lights) do
		if nextFlicker[light] <= os.clock() then
			Flicker(light)
			nextFlicker[light] = rnd:NextInteger((50 / (currentRound * 2)), (50 / (currentRound * 2)) + (20 / (currentRound * 2))) + os.clock()
		end
	end
end
