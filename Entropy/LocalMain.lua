-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RepStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")

-- Modules
local itemMappings = require(RepStorage.ItemMappings)
local roundHandler = require(RepStorage.RoundHandler)

-- References
local plr = Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local camera = workspace.CurrentCamera
local mouse = plr:GetMouse()
local playerGui = plr:WaitForChild("PlayerGui")
local remotes = RepStorage:WaitForChild("Remotes")

-- Remotes
local screenFadeEvent = remotes.ScreenFadeEvent
local safeZoomEvent = remotes.SafeZoomEvent
local pictureZoomEvent = remotes.PictureZoomEvent
local pickUpEvent = remotes.PickUpEvent
local useItemEvent = remotes.UseItemEvent
local safeOpenEvent = remotes.SafeOpenEvent
local pictureOpenEvent = remotes.PictureOpenEvent
local resetBoardEvent = remotes.ResetBoardEvent
local endGameEvent = remotes.EndGameEvent

-- Assets
local logos = {
	["bahaLogo"] = {"rbxassetid://8452855390", UDim2.new(.9,0,.9,0)},
	["rscLogo"] = {"rbxassetid://8434977525", UDim2.new(0,512,0,512)}
}
local assets = {
	["vignette"] = "rbxassetid://8435010394",
	["defaultMouseIcon"] = "rbxassetid://8437762911"	
}

-- Create asset list for preload
local assetList = {}
-- Add asset links to assetList
for _, child in pairs(assets) do
	table.insert(assetList, child)
end
-- Add worksplace instances to assetList
for _, child in pairs(workspace:GetChildren()) do
	if child:IsA("BasePart") or child:IsA("Model") then
		table.insert(assetList, child)
	end
end
-- Add Replicated Storage instances to assetList
for _, child in pairs(RepStorage:GetChildren()) do
	if child:IsA("Instance") then
		table.insert(assetList, child)
	end
end

-- Constants
local LOGO_LENGTH = 2

-- Variables
local testing = false
local isMobile = false
local debounce = false
local hasCode = false
local hasCodeHalf1 = false
local hasCodeHalf2 = false
local iconSize = 100
local zoomOutMsg = "Press 'E' to go back."

-- Set core GUI
StarterGui:SetCore("TopbarEnabled", false)

-- Set camera
plr.CameraMode = Enum.CameraMode.LockFirstPerson
camera.CameraType = Enum.CameraType.Scriptable

-- Set mouse
mouse.Icon = assets.defaultMouseIcon
UIS.MouseIconEnabled = false

-- Check platform player is on
if UIS.TouchEnabled and not UIS.KeyboardEnabled then
	print("Mobile user detected")
	isMobile = true
	iconSize = 50
	zoomOutMsg = "Double tap to zoom out."
end

-- Create gui
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui

-- Create intro background
local introFrame = Instance.new("Frame")
introFrame.Size = UDim2.new(1,0,1,36)
introFrame.Position = UDim2.new(0,0,0,-36)
introFrame.BackgroundColor3 = Color3.new(0.0470588, 0.0470588, 0.0470588)
introFrame.BackgroundTransparency = 0
introFrame.Visible = true
introFrame.Parent = screenGui
local introImage = Instance.new("ImageLabel")
introImage.AnchorPoint = Vector2.new(.5,.5)
introImage.Position = UDim2.new(.5,0,.5,0)
introImage.BackgroundTransparency = 1
introImage.ImageTransparency = 1
introImage.Parent = introFrame

-- Create loading bar
local loadingBar = Instance.new("Frame")
loadingBar.AnchorPoint = Vector2.new(0,.5)
loadingBar.Position = UDim2.new(.2,0,1,-20)
loadingBar.Parent = introFrame
local barCorners = Instance.new("UICorner")
barCorners.Parent = loadingBar
local barGradient = Instance.new("UIGradient")
barGradient.Color = ColorSequence.new(Color3.new(0.847059, 0.847059, 0.847059),Color3.new(0.956863, 0.956863, 0.956863))
barGradient.Parent = loadingBar

-- Create zoom out message gui
local zoomFrame = Instance.new("Frame")
zoomFrame.Size = UDim2.new(.35,0,0,iconSize)
zoomFrame.AnchorPoint = Vector2.new(1,1)
zoomFrame.Position = UDim2.new(1,-10,1,-10)
zoomFrame.BackgroundTransparency = 1
zoomFrame.Parent = screenGui
local zoomLabel = Instance.new("TextLabel")
zoomLabel.Text = zoomOutMsg
zoomLabel.Size = UDim2.new(1,0,1,0)
zoomLabel.TextScaled = true
zoomLabel.Font = Enum.Font.Garamond
zoomLabel.TextColor3 = Color3.new(0.898039, 0.898039, 0.898039)
zoomLabel.TextTransparency = 1
zoomLabel.TextStrokeColor3 = Color3.new(0.196078, 0.196078, 0.196078)
zoomLabel.TextStrokeTransparency = 1
zoomLabel.BackgroundTransparency = 1
zoomLabel.Parent = zoomFrame

-- Create fade gui
local fadeFrame = Instance.new("Frame")
fadeFrame.Size = UDim2.new(1,0,1,36)
fadeFrame.Position = UDim2.new(0,0,0,-36)
fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
fadeFrame.BackgroundTransparency = 1
fadeFrame.Visible = true
fadeFrame.Parent = screenGui
local fadeImage = Instance.new("ImageLabel")
fadeImage.Size = UDim2.new(1,0,1,0)
fadeImage.BackgroundTransparency = 1
fadeImage.Image = assets.vignette
fadeImage.ImageTransparency = 0
fadeImage.Parent = fadeFrame

-- Create item viewport
local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.AnchorPoint = Vector2.new(.5,.5)
viewportFrame.Position = UDim2.new(.5,0,.5,0)
viewportFrame.Size = UDim2.new(0,600,0,600)
viewportFrame.BackgroundTransparency = 1
viewportFrame.BorderSizePixel = 0
viewportFrame.Visible = false
viewportFrame.Parent = screenGui
local viewportCamera = Instance.new("Camera")
viewportFrame.CurrentCamera = viewportCamera
viewportCamera.FieldOfView = 30
viewportCamera.Parent = viewportFrame

-- Create viewport frame for code postit
local postitView = Instance.new("Frame")
postitView.Size = UDim2.new(0.15,0,0.15,0)
postitView.Position = UDim2.new(.8,0,0,10)
postitView.BackgroundTransparency = 1
postitView.BorderSizePixel = 0
postitView.Visible = false
postitView.Parent = screenGui
local postitText = Instance.new("TextLabel")
postitText.Size = UDim2.new(1,0,1,0)
postitText.BackgroundTransparency = 1
postitText.TextTransparency = 1
postitText.Text = ""
postitText.TextSize = 64
postitText.Font = Enum.Font.IndieFlower
postitText.Parent = postitView
local postitCorners = Instance.new("UICorner")
postitCorners.CornerRadius = UDim.new(0,15)
postitCorners.Parent = postitView
local postitGradient = Instance.new("UIGradient")
postitGradient.Color = ColorSequence.new(Color3.new(0.709804, 0.764706, 0.109804),Color3.new(0.635294, 0.619608, 0.184314))
postitGradient.Parent = postitView

-- Create inventory frame
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.AnchorPoint = Vector2.new(1,.5)
inventoryFrame.Position = UDim2.new(1, -20, .5, 0)
inventoryFrame.Size = UDim2.new(0, iconSize, .8, 0)
inventoryFrame.BackgroundTransparency = 1
inventoryFrame.Parent = screenGui
local listLayout = Instance.new("UIListLayout")
listLayout.Parent = inventoryFrame
local itemUseTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.In, 1)

-- Create puzzle reset button
local resetBtn = Instance.new("TextButton")
resetBtn.Text = "RESET"
resetBtn.TextScaled = true
resetBtn.Font = Enum.Font.Garamond
resetBtn.TextColor3 = Color3.new(0.898039, 0.898039, 0.898039)
resetBtn.TextTransparency = 0
resetBtn.TextStrokeColor3 = Color3.new(0.196078, 0.196078, 0.196078)
resetBtn.TextStrokeTransparency = .75
resetBtn.BackgroundTransparency = .3
resetBtn.Size = UDim2.new(0,120,0,80)
resetBtn.Position = UDim2.new(0,25,0,100)
resetBtn.Visible = false
resetBtn.Parent = screenGui
local resetCorner = Instance.new("UICorner")
resetCorner.Parent = resetBtn
local resetGradient = Instance.new("UIGradient")
resetGradient.Color = ColorSequence.new(Color3.new(0.294118, 0.294118, 0.294118), Color3.new(0.494118, 0.494118, 0.494118))
resetGradient.Parent = resetBtn

-- Wait for game to load assets
--local function TweenLogo(logo, target)
local logoTweenInInfo = TweenInfo.new(LOGO_LENGTH, Enum.EasingStyle.Cubic)
local logoTweenIn = TweenService:Create(introImage, logoTweenInInfo, {ImageTransparency = 0})
local function TweenLogoIn(logo)
	introImage.Image = logo[1]
	if isMobile and logo[1] == "rbxassetid://8434977525" then
		introImage.Size = UDim2.new(.8,0,.9,0)
	else
		introImage.Size = logo[2]
	end
	logoTweenIn:Play()
end
local logoTweenOutInfo = TweenInfo.new(LOGO_LENGTH, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local logoTweenOut = TweenService:Create(introImage, logoTweenOutInfo, {ImageTransparency = 1})
local function TweenLogoOut()
	logoTweenOut:Play()
end
local startTime = os.clock()
for i = 1, #assetList do
	ContentProvider:PreloadAsync({assetList[i]})
	loadingBar.Size = UDim2.new(.6 * (i / #assetList), 0, 0, 20)
	if i == 1 then
		TweenLogoIn(logos.bahaLogo)
	end
end
TweenLogoOut()
-- Fade out loading bar
local barTween = TweenService:Create(loadingBar, TweenInfo.new(3), {BackgroundTransparency = 1})
barTween:Play()

-- Check if in testing mode
local headphones
if not testing then
	-- Lock player movement
	chr:WaitForChild("Humanoid").WalkSpeed = 0
	
	-- Play logos
	task.wait(1)
	TweenLogoIn(logos.rscLogo)
	task.wait(2)
	TweenLogoOut()
	task.wait(1)
	headphones = Instance.new("TextLabel")
	headphones.Font = Enum.Font.Garamond
	headphones.TextColor3 = Color3.new(0.909804, 0.909804, 0.909804)
	if isMobile then
		headphones.TextSize = 42
		headphones.Text = [[For best experience,
		wear headphones.]]
	else
		headphones.TextSize = 58
		headphones.Text = "For best experience, wear headphones."
	end
	headphones.BackgroundTransparency = 1
	headphones.TextTransparency = 1
	headphones.Size = UDim2.new(.8,0,0,100)
	headphones.AnchorPoint = Vector2.new(.5,.5)
	headphones.Position = UDim2.new(.5,0,.5,0)
	headphones.Parent = screenGui
	local headphoneTween = TweenService:Create(headphones,TweenInfo.new(2),{TextTransparency=0})
	headphoneTween:Play()
	task.wait(2)
	local headphoneTweenOut = TweenService:Create(headphones,TweenInfo.new(2),{TextTransparency=1})
	headphoneTweenOut:Play()
	task.wait(2)
else
	UIS.MouseIconEnabled = true
	chr.Humanoid.WalkSpeed = 14
	camera.CameraType = Enum.CameraType.Custom
end

-- Toggle zoom message
local function ToggleZoomMsg()
	local target = 1
	local strokeTarget = 1
	if zoomLabel.TextTransparency == 1 then
		target = 0
		strokeTarget = .75
	end
	local tween = TweenService:Create(zoomLabel, TweenInfo.new(1), {TextTransparency = target, TextStrokeTransparency = strokeTarget})
	tween:Play()
end

local function FadeInOut(duration)
	local fadeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 0, true)
	local fadeTween = TweenService:Create(fadeImage, fadeTweenInfo, {ImageTransparency = 0})
	local fadeTweenBG = TweenService:Create(fadeFrame, fadeTweenInfo, {BackgroundTransparency = 0})
	fadeFrame.Visible = true
	fadeTween:Play()
	fadeTweenBG:Play()
	fadeTween.Completed:Wait()
	fadeFrame.Visible = false
end

local function TweenCodeIn()
	local tweenInBG = TweenService:Create(postitView,TweenInfo.new(2),{BackgroundTransparency = .2})
	local tweenInText = TweenService:Create(postitText,TweenInfo.new(2),{TextTransparency = 0})
	tweenInBG:Play()
	tweenInText:Play()	
end

local function TweenCodeOut()
	local tweenInBG = TweenService:Create(postitView,TweenInfo.new(2),{BackgroundTransparency = 1})
	local tweenInText = TweenService:Create(postitText,TweenInfo.new(2),{TextTransparency = 1})
	tweenInBG:Play()
	tweenInText:Play()	
end

-- Connect screen fade event
screenFadeEvent.OnClientEvent:Connect(function(duration)
	FadeInOut(duration)
end)

-- Connect safe interaction event
local zoomTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
safeZoomEvent.OnClientEvent:Connect(function(model, code, position)
	if debounce then return end
	debounce = true	
	
	local returnCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	chr.Humanoid.WalkSpeed = 0
	local fov
	if isMobile then
		fov = 8
	else
		fov = 20
	end
	local zoomTween = TweenService:Create(camera, zoomTweenInfo, {CFrame = CFrame.lookAt(position, model.PrimaryPart.Position), FieldOfView = fov})
	zoomTween:Play()
	
	if hasCode then	
		postitView.Visible = true
		postitText.Text = code
		TweenCodeIn()
	end
	if hasCodeHalf1 and hasCodeHalf2 then
		postitView.Visible = true
		postitText.Text = code
		TweenCodeIn()
	elseif hasCodeHalf1 then
		postitView.Visible = true
		print("Half1: "..string.sub(code, 1, 2))
		postitText.Text = string.sub(code, 1, 2)
		TweenCodeIn()
	elseif hasCodeHalf2 then
		postitView.Visible = true
		print("Half2: "..string.sub(code, 3, #code))
		postitText.Text = string.sub(code, 3, #code)
		TweenCodeIn()	
	end
	
	local buttonsDebounce = false
	-- Keypad blink tween
	local function BlinkKeys(color)
		for _, button in pairs(model.Keypad:GetChildren()) do
			if button:IsA("BasePart") then
				button.Transparency = .5
				local codeTween = TweenService:Create(button, TweenInfo.new(.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.In,1,true), {Color = color})
				codeTween:Play()
			end
		end
		task.wait(1)
		for _, button in pairs(model.Keypad:GetChildren()) do
			if button:IsA("BasePart") then
				button.Transparency = 1
			end
		end
		buttonsDebounce = false
	end
	local enteredCode = ""
	local solved = false
	for _, button in pairs(model.Keypad:GetChildren()) do
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MouseHoverEnter:Connect(function()
			if not buttonsDebounce then
				button.Transparency = .5
			end
		end)
		clickDetector.MouseHoverLeave:Connect(function()
			if not buttonsDebounce then
				button.Transparency = 1
			end
		end)
		clickDetector.MouseClick:Connect(function()
			model.Keypad.beep1:Play()
			enteredCode = enteredCode..button.Name
			if #enteredCode == #code and not buttonsDebounce then
				buttonsDebounce = true
				if enteredCode == code then
					TweenCodeOut()
					model.Accessgranted:Play()
					BlinkKeys(Color3.new(0.0705882, 0.776471, 0.188235))
					safeOpenEvent:FireServer(model)
					local newCF = CFrame.new(position + Vector3.new(0,1,0) + (model.PrimaryPart.CFrame.LookVector * -2) + (model.PrimaryPart.CFrame.RightVector * -1))--Vector3.new(1,1,-2)
					zoomTween = TweenService:Create(camera, zoomTweenInfo, {CFrame = CFrame.lookAt(newCF.Position, model["Spinny Boi"].Position), FieldOfView = 20})
					zoomTween:Play()
					hasCode = false
					solved = true
				else
					model.Accessdenied:Play()
					BlinkKeys(Color3.new(1, 0.164706, 0.176471))
					enteredCode = ""
				end
			end
		end)
		clickDetector.Parent = button
	end

	zoomTween.Completed:Wait()
	debounce = false
	ToggleZoomMsg()
	
	local function SafeZoomOut()
		if hasCode or hasCodeHalf1 or hasCodeHalf2 then	
			TweenCodeOut()
		end
		ToggleZoomMsg()
		local zoomOutTween = TweenService:Create(camera, zoomTweenInfo, {CFrame = returnCFrame, FieldOfView = 70})
		zoomOutTween:Play()
		zoomOutTween.Completed:Wait()
		chr.Humanoid.WalkSpeed = 16
		camera.CameraType = Enum.CameraType.Custom
		debounce = false
		safeZoomEvent:FireServer(model)
		if solved then
			model.PrimaryPart.ProximityPrompt:Destroy()
		end
	end
	local connection
	local lastTap = os.clock()
	if isMobile then
		connection = UIS.TouchTap:Connect(function(touch, gameProcessed)
			if gameProcessed then return end
			if os.clock() - lastTap <= .3 then
				SafeZoomOut()
				model.Keypad:Destroy()
				connection:Disconnect()
			end
			lastTap = os.clock()
		end)
	else
		connection = UIS.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
				SafeZoomOut()
				model.Keypad:Destroy()
				connection:Disconnect()
			end
		end)
	end
end)

-- Connect sliding puzzle zoom event
pictureZoomEvent.OnClientEvent:Connect(function(model, position, isFirstView, numShuffle)

	if debounce then return end
	debounce = true
	local returnCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	chr.Humanoid.WalkSpeed = 0
	local zoomTween = TweenService:Create(camera, zoomTweenInfo, {CFrame = CFrame.lookAt(position, model.PrimaryPart.Position), FieldOfView = 25})
	zoomTween:Play()
	zoomTween.Completed:Wait()
	if isFirstView then
		task.wait(numShuffle * .4)
	end
	debounce = false
	ToggleZoomMsg()
	
	resetBtn.Visible = true
	resetBtn.Activated:Connect(function()
		resetBoardEvent:FireServer(model)
	end)
	
	local function PictureZoomOut()
		ToggleZoomMsg()
		resetBtn.Visible = false
		local zoomOutTween = TweenService:Create(camera, zoomTweenInfo, {CFrame = returnCFrame, FieldOfView = 70})
		zoomOutTween:Play()
		zoomOutTween.Completed:Wait()
		chr.Humanoid.WalkSpeed = 16
		camera.CameraType = Enum.CameraType.Custom
		pictureZoomEvent:FireServer(model)
		debounce = false
	end
	local connection
	local lastTap = os.clock()
	if isMobile then
		connection = UIS.TouchTap:Connect(function(touch, gameProcessed)
			if gameProcessed then return end
			if os.clock() - lastTap <= .3 then
				PictureZoomOut()
				connection:Disconnect()
			end
			lastTap = os.clock()
		end)
	else
		connection = UIS.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
				PictureZoomOut()
				connection:Disconnect()
			end
		end)
	end
end)

-- Connect sliding puzzle drawer open event
pictureOpenEvent.OnClientEvent:Connect(function(model)
	resetBtn.Visible = false
	task.wait(.5)
	local newPos = (camera.CFrame + (model.PrimaryPart.CFrame.LookVector * 6) + Vector3.new(0,2,0)).Position
	local tween = TweenService:Create(camera, zoomTweenInfo, {CFrame = CFrame.lookAt(newPos, model.Drawer.PrimaryPart.Position)})
	tween:Play()
	
end)

-- Connect item pickup event
pickUpEvent.OnClientEvent:Connect(function(model)
	if model.Name == "Postit" then
		hasCode = true
	elseif model.Name == "PostitHalf1" then
		hasCodeHalf1 = true
	elseif model.Name == "PostitHalf2" then
		hasCodeHalf2 = true
	end
	viewportFrame.Visible = true
	model.Parent = viewportFrame
	local newPos = (camera.CFrame + (model.PrimaryPart.CFrame.RightVector * 2)).Position
	viewportCamera.CFrame = CFrame.lookAt(newPos + Vector3.new(0,4,0), model.PrimaryPart.Position)
	--model:PivotTo(CFrame.lookAt(model.PrimaryPart.Position,viewportCamera.CFrame.Position))
	pickUpEvent:FireServer(model)
	local t = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		t += dt
		model:PivotTo(model.PrimaryPart.CFrame * CFrame.Angles(0,math.pi/64,0))
		if t >= 2 then
			viewportFrame.Visible = false
			local inventoryViewport = Instance.new("ViewportFrame")
			inventoryViewport.Name = model.Name
			inventoryViewport.Size = UDim2.new(0,iconSize,0,iconSize)
			inventoryViewport.BackgroundTransparency = 1
			inventoryViewport.BorderSizePixel = 0
			inventoryViewport.Parent = inventoryFrame
			local invViewCamera = Instance.new("Camera")
			inventoryViewport.CurrentCamera = invViewCamera
			invViewCamera.Parent = inventoryViewport
			local invViewCorner = Instance.new("UICorner")
			invViewCorner.CornerRadius = UDim.new(0,15)
			invViewCorner.Parent = inventoryViewport
			model.Parent = inventoryViewport
			invViewCamera.CFrame = CFrame.lookAt(model.PrimaryPart.Position + Vector3.new(0, 1, 2), model.PrimaryPart.Position)
			model:PivotTo(CFrame.lookAt(model.PrimaryPart.Position,invViewCamera.CFrame.Position)*CFrame.Angles(math.pi/4,math.pi/2,0))
			connection:Disconnect()
		end
	end)
end)

-- Connect use item event
useItemEvent.OnClientEvent:Connect(function(model)
	print("Looking for "..model.Name)
	local viewport = inventoryFrame:FindFirstChild(itemMappings.GetIndex(model.Name))
	if viewport == nil then
		if string.sub(model.Name, 1, #model.Name - 1) == "Wooden Door" then
			model.lockeddoor2:Play()
		end
		warn("Item not found for "..model.Name)
	else
		if string.sub(model.Name, 1, #model.Name - 1) == "Wooden Door" then
			model.lockeddoor1:Play()
		end		
		local itemUseTween = TweenService:Create(viewport, itemUseTweenInfo, {BackgroundTransparency = 0})
		itemUseTween:Play()
		if model.Name ~= "Safe" then
			useItemEvent:FireServer(model)
		end
		itemUseTween.Completed:Wait()
		viewport:Destroy()
		if model.Name == "SafeHalf" then
			local viewport = inventoryFrame:FindFirstChild("PostitHalf2")
			local itemUseTween = TweenService:Create(viewport, itemUseTweenInfo, {BackgroundTransparency = 0})
			itemUseTween:Play()
			if model.Name ~= "Safe" then
				useItemEvent:FireServer(model)
			end
			itemUseTween.Completed:Wait()
			viewport:Destroy()
		end
	end
end)

UIS.MouseIconEnabled = true
camera.CameraType = Enum.CameraType.Scriptable
local menuGui = Instance.new("Frame")
menuGui.Size = UDim2.new(1,0,1,36)
menuGui.Position = UDim2.new(0,0,0,-36)
menuGui.BackgroundTransparency = 1
menuGui.Parent = screenGui
local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0,200,0,90)
playBtn.AnchorPoint = Vector2.new(.5,.5)
playBtn.Position = UDim2.new(.5,0,.8,0)
playBtn.BackgroundTransparency = 1
playBtn.Text = "PLAY"
playBtn.Font = Enum.Font.Garamond
playBtn.TextSize = 82
playBtn.TextStrokeColor3 = Color3.new(0.588235, 0.588235, 0.588235)
playBtn.TextStrokeTransparency = 0
playBtn.Parent = menuGui
local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new(Color3.new(0.854902, 0.854902, 0.854902), Color3.new(0.494118, 0.494118, 0.494118))
btnGradient.Parent = playBtn
local titleImage = Instance.new("ImageLabel")
titleImage.Size = UDim2.new(.8,0,.5,0)
titleImage.AnchorPoint = Vector2.new(.5,.5)
titleImage.Position = UDim2.new(.5,0,.4,0)
titleImage.BackgroundTransparency = 1
titleImage.Image = "rbxassetid://8518360143"
titleImage.ImageTransparency = 1
titleImage.Parent = menuGui
local studio = headphones:Clone()
studio.TextSize = 28
studio.Position = UDim2.new(.5,0,1,-20)
studio.Text = "© Bahamut Fierce Studios 2022"
studio.Parent = menuGui

-- Tween in menu
local titleTween = TweenService:Create(titleImage,TweenInfo.new(1),{ImageTransparency=0})
titleTween:Play()
for _, txt in pairs({playBtn,studio}) do 
	local buttonTween = TweenService:Create(txt,TweenInfo.new(1),{TextTransparency=0})
	local strokeTween = TweenService:Create(txt,TweenInfo.new(1),{TextStrokeTransparency=.3})
	buttonTween:Play()
	strokeTween:Play()
end

local playDebounce = false
playBtn.Activated:Connect(function()
	if playDebounce then return end
	playDebounce = true
	UIS.MouseIconEnabled = false
	local startSound = SoundService.PlayerSounds.startgui:Clone()
	startSound.Parent = chr
	startSound:Play()
	-- Fade out introFrame to begin game
	local imgTween = TweenService:Create(titleImage,TweenInfo.new(2),{ImageTransparency = 1})
	imgTween:Play()
	for _, txt in pairs({playBtn,studio}) do 
		local buttonTween = TweenService:Create(txt,TweenInfo.new(1),{TextTransparency=1})
		local strokeTween = TweenService:Create(txt,TweenInfo.new(1),{TextStrokeTransparency=1})
		buttonTween:Play()
		strokeTween:Play()
	end
	local introFrameTween = TweenService:Create(introFrame, TweenInfo.new(4), {BackgroundTransparency = 1})
	local vignetteTween = TweenService:Create(fadeImage, TweenInfo.new(12), {ImageTransparency = 1})
	introFrameTween:Play()
	vignetteTween:Play()
	introFrameTween.Completed:Wait()
	menuGui.Visible = false
	introFrame.Visible = false
	fadeFrame.Visible = false
	local vo = SoundService.PlayerSounds.whereamisample2:Clone()
	vo.Parent = chr
	vo:Play()
	
	-- Re-enable mouse & camera
	if not testing then
		UIS.MouseIconEnabled = true
		chr.Humanoid.JumpHeight = 3
		chr.Humanoid.WalkSpeed = 14
		camera.CameraType = Enum.CameraType.Custom
	end	
end)

local gameEnd = false
endGameEvent.OnClientEvent:Connect(function(goodEnding)
	gameEnd = true
	UIS.MouseIconEnabled = false
	camera.CameraType = Enum.CameraType.Scriptable
	introFrame.BackgroundTransparency = 1
	introFrame.Visible = true
	local msg = Instance.new("TextLabel")
	msg.Position = UDim2.new(.5,0,.5,0)
	msg.AnchorPoint = Vector2.new(.5,.5)
	msg.Size = UDim2.new()
	msg.Font = Enum.Font.Garamond
	msg.TextColor3 = Color3.new(0.494118, 0.494118, 0.494118)
	msg.TextStrokeColor3 = Color3.new(0.494118, 0.494118, 0.494118)
	msg.TextSize = 58
	msg.BackgroundTransparency = 1
	msg.TextTransparency = 1
	msg.Size = UDim2.new(.8,0,0,100)
	local color
	local voice
	if goodEnding then
		msg.Text = "Maybe there's a way out after all?"
		color = Color3.new(0.917647, 0.917647, 0.917647)
		voice = SoundService.PlayerSounds.wayoutfinal
	else
		msg.Text = "Is there nothing left...?"
		color = Color3.new(0.0156863, 0.0156863, 0.0156863)
		voice = SoundService.PlayerSounds.nothingleftfinal
	end
	voice.Parent = chr
	msg.Parent = introFrame
	local tween = TweenService:Create(introFrame,TweenInfo.new(10),{BackgroundColor3 = color, BackgroundTransparency = 0})
	tween:Play()
	task.wait(5)
	local msgTween = TweenService:Create(msg,TweenInfo.new(1),{TextTransparency = 0, TextStrokeTransparency = .3})
	msgTween:Play()
	print("Playing "..voice.Name)
	voice:Play()
	task.wait(5)
	local moveMsgTween = TweenService:Create(msg,TweenInfo.new(5),{Position = UDim2.new(.5,0,-.5,0)})
	moveMsgTween:Play()
	task.wait(5)
	local credits = msg:Clone()
	credits.Size = UDim2.new(1,0,1,0)
	credits.Position = UDim2.new(.5,0,1.5,0)
	credits.TextSize = 48
	credits.Text = [[Models by 2Tye and BahamutFierce

Sounds and music by PugAddictVivi
* Subway horn from https://www.freesoundslibrary.com
* Subway train from https://www.freesoundslibrary.com
* Thunderstorm from https://soundbible.com

Images by BahamutFierce
* Subway image from https://www.wallpaperflare.com
* Clock image from https://www.shutterstock.com
* Ship image from https://commons.wikimedia.org

Scripting by BahamutFierce


Thanks for playing!]]
	credits.Parent = introFrame
	local creditsTween = TweenService:Create(credits,TweenInfo.new(20),{Position = UDim2.new(.5,0,-.5,0)})
	creditsTween:Play()
end)

--[[local nextBlur = Random.new(os.clock()):NextNumber(1,60) + os.clock()
local nextFoV = Random.new(os.clock()):NextNumber(1,60) + os.clock()
while not gameEnd do
	task.wait(1)
	local round = roundHandler.GetRound()
	if os.clock() >= nextBlur then
		nextBlur = Random.new(os.clock()):NextNumber(1, 60 / round) + os.clock()
		print("Random blur at"..os.clock().." next at "..nextBlur)
		local blurTween = TweenService:Create(Lighting.Blur,TweenInfo.new(round/2,Enum.EasingStyle.Exponential,Enum.EasingDirection.In,0,true),{Size=(round/2)})
		blurTween:Play()
	end
	if os.clock() >= nextFoV then
		print("Random DoF")
		nextFoV = Random.new(os.clock()):NextNumber(1,60 / round) + os.clock()
		local dofTween = TweenService:Create(camera,TweenInfo.new(round/2,Enum.EasingStyle.Exponential,Enum.EasingDirection.In,0,true),{FieldOfView=70+(round*5)})
		dofTween:Play()
	end
end]]
