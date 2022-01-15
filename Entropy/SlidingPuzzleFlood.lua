-- Services
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Modules
local roundHandler = require(RepStorage.RoundHandler)

-- Remotes
local pictureZoomEvent = RepStorage.Remotes.PictureZoomEvent
local pictureOpenEvent = RepStorage.Remotes.PictureOpenEvent
local resetBoardEvent = RepStorage.Remotes.ResetBoardEvent

-- References
local model = script.Parent
local zero = model.Faces["0"]
local rnd = Random.new(os.clock())
local plr = nil
local contents = model.Drawer["No Way Out Key"]
local startingPoints = {}
for _, face in pairs(model.Faces:GetChildren()) do
	startingPoints[face] = face.CFrame
end

-- Variables
local isFirstView = true
local lastNum = nil
local numShuffle = 10
local moveDebounce = false
local resetDebounce = false

-- Create proximity prompt
local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "Sliding Puzzle"
prompt.ActionText = "Examine"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.RequiresLineOfSight = false
prompt.Parent = model.PrimaryPart

contents.PrimaryPart:WaitForChild("ProximityPrompt").Enabled = false

-- Functions to operate 8-puzzle
local grid = {{1, 2, 3}, {4, 0, 6}, {7, 8, 9}}
local win = {{1, 2, 3}, {4, 0, 6}, {7, 8, 9}}

local function PrintGrid()
	for i = 1, 3 do
		local str = ""
		for j = 1, 3 do
			str = str.." "..grid[i][j]
		end
		print(str)
	end
end

local function FindOnGrid(num)
	for i = 1, 3 do
		for j = 1, 3 do
			if grid[i][j] == num then
				return i, j
			end
		end
	end
	return nil
end

local function TweenBlock(duration, block, position)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Exponential)
	local tween = TweenService:Create(block, tweenInfo, {Position = position})
	tween:Play()
end

local transTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
local function TransparencyTween(target)
	local tween = TweenService:Create(zero, transTweenInfo, {Transparency = target})
	local imageTween = TweenService:Create(zero.SurfaceGui.ImageLabel, transTweenInfo, {ImageTransparency = target})
	tween:Play()
	imageTween:Play()
end

local function CheckWin()
	local same = true
	for i = 1, 3 do
		for j = 1, 3 do
			if grid[i][j] ~= win[i][j] then
				same = false
			end
		end
	end
	if same then
		local isSoundPlaying = false
		for _, child in pairs(model.Faces:GetDescendants()) do
			if child:IsA("ClickDetector") then
				child:Destroy()
			end
		end
		TransparencyTween(0)
		pictureOpenEvent:FireClient(plr, model)
		task.wait(2)
		model.Drawer.draweropening.Pitch = 1
		model.Drawer.draweropening:Play()
		for _, part in pairs(model.Drawer:GetDescendants()) do
			if part:IsA("BasePart") then
				local newCF = part.CFrame + (model.Drawer.Drawer.CFrame.LookVector * 1.5)
				local tween = TweenService:Create(part, TweenInfo.new(2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {CFrame = newCF})
				tween:Play()
			end
		end
		SoundService.AmbientReverb = Enum.ReverbType.UnderWater
		workspace.RoomV1.RoundObjects.EndWaterDrips.ParticleEmitter.Rate = 150
		contents.PrimaryPart.ProximityPrompt.Enabled = true
		local plr = Players:FindFirstChildOfClass("Player")
		local chr = plr.Character
		local t = 0
		local connection
		connection = RunService.Heartbeat:Connect(function(dt)
			t += dt
			if t >= 1 then
				if chr.Humanoid.Health >= 2 then
					chr.Humanoid.Health -= dt * 5
				end
				if not isSoundPlaying then
					SoundService.PlayerSounds.heartbeatring.Parent = chr
					SoundService.PlayerSounds.DistantThunder.Parent = chr
					chr.heartbeatring:Play()
					chr.DistantThunder:Play()
					isSoundPlaying = true
				end
			end
			workspace.RoomV1.WaterFill.Size += Vector3.new(0,dt*2,0)
			workspace.Terrain:FillBlock(workspace.RoomV1.WaterFill.CFrame,workspace.RoomV1.WaterFill.Size,Enum.Material.Water)
			if t >= 40 then
				connection:Disconnect()
			end
		end)
		prompt:Destroy()
	end
end

local function MoveBlock(num)
	local t = .75
	if isFirstView then
		t = .3
	end
	local row, col = FindOnGrid(num)
	local zeroRow, zeroCol = row, col
	if row > 1 and grid[row-1][col] == 0 then
		zeroRow = row - 1
	elseif row < 3 and grid[row+1][col] == 0 then
		zeroRow = row + 1
	elseif col > 1 and grid[row][col-1] == 0 then
		zeroCol = col - 1
	elseif col < 3 and grid[row][col+1] == 0 then
		zeroCol = col + 1
	else
		return
	end
		
	grid[zeroRow][zeroCol] = num
	grid[row][col] = 0
	local numBlock = model.Faces:FindFirstChild(tostring(num))
	TweenBlock(t, zero, numBlock.Position)
	TweenBlock(t, numBlock, zero.Position)
	lastNum = num
	model["blockslide"..tostring(rnd:NextInteger(1,2))]:Play()
	if not isFirstView then
		CheckWin()
	end
end

local function RandomMove()
	local row, col
	local zeroRow, zeroCol = FindOnGrid(0)
	local possMoves = {}
	if zeroCol - 1 > 0 then
		table.insert(possMoves, {zeroRow,zeroCol-1})
	end
	if zeroCol + 1 < 4 then
		table.insert(possMoves, {zeroRow,zeroCol+1})
	end
	if zeroRow - 1 > 0 then
		table.insert(possMoves, {zeroRow-1,zeroCol})
	end
	if zeroRow + 1 < 4 then
		table.insert(possMoves, {zeroRow+1,zeroCol})
	end
	repeat
		local nextMove = possMoves[rnd:NextInteger(1,#possMoves)]
		row, col = nextMove[1], nextMove[2]
	until grid[row][col] ~= lastNum
	MoveBlock(grid[row][col])
end

local function ShuffleBoard()
	moveDebounce = true
	numShuffle = roundHandler.GetRound() * 2
	TransparencyTween(1)
	task.wait(1.5)
	for i = 1, numShuffle do
		RandomMove()
		task.wait(.4)
	end
	isFirstView = false
	moveDebounce = false
	resetDebounce = false
end

resetBoardEvent.OnServerEvent:Connect(function(player, m)
	if model == m and not resetDebounce then
		isFirstView = true
		resetDebounce = true
		for _, face in pairs(model.Faces:GetDescendants()) do
			if face:IsA("BasePart") then
				local tween = TweenService:Create(face,TweenInfo.new(1),{Transparency=1})
				tween:Play()
			elseif face:IsA("ImageLabel") then
				local tween = TweenService:Create(face,TweenInfo.new(1),{ImageTransparency=1})
				tween:Play()
			end
		end
		task.wait(1)
		for _, face in pairs(model.Faces:GetChildren()) do
			face.CFrame = startingPoints[face]
		end
		grid = {{1, 2, 3}, {4, 0, 6}, {7, 8, 9}}
		for _, face in pairs(model.Faces:GetDescendants()) do
			if face:IsA("BasePart") then
				local tween = TweenService:Create(face,TweenInfo.new(1),{Transparency=0})
				tween:Play()
			elseif face:IsA("ImageLabel") then
				local tween = TweenService:Create(face,TweenInfo.new(1),{ImageTransparency=0})
				tween:Play()
			end
		end
		task.wait(2)
		ShuffleBoard()
	end
end)

for _, button in pairs(model.Faces:GetChildren()) do
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MouseClick:Connect(function()
		if not moveDebounce then
			moveDebounce = true
			MoveBlock(tonumber(button.Name))
			if not isFirstView then
				task.wait(.75)
			end
			moveDebounce = false
		end
	end)
	clickDetector.Parent = button
end

prompt.Triggered:Connect(function(player)
	plr = player
	moveDebounce = false
	local newCF = model.PrimaryPart.CFrame + Vector3.new(0,4,0) + (model.PrimaryPart.CFrame.LookVector * .5)
	pictureZoomEvent:FireClient(player, model, newCF.Position, isFirstView, numShuffle)
	prompt.Enabled = false
	if isFirstView then
		local floodGate = ServerStorage.Parts.GateFlood:Clone()
		floodGate:PivotTo(workspace.RoomV1.SpawnPoints.MidGateFlood.CFrame)
		floodGate.Parent = workspace.RoomV1.RoundObjects
		ShuffleBoard()
	end
end)

pictureZoomEvent.OnServerEvent:Connect(function(player, m)
	if m == model then
		prompt.Enabled = true		
	end
end)
