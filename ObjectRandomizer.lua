--[[
	Object Placement Randomizer v 2.41
	Plugin for Roblox Studio
	Written by Daniel Foreacre (BahamutFierce)
	
  NOTE! This plugin requires the plugingui modules from https://github.com/Roblox/StudioWidgets

	This plugin is designed to create a user-friendly way to copy an object
	and place it over a wide area. Features numerous ways to customize the
	copies, including:
		- Customize size and position of placement area 
		- Place objects on terrain or parts
		- Ability to limit placements to specific materials
		- Can set starting orientations perpendicular to surface
		- Clustering into groups of different sizes and densities
		- Randomization of scale, rotation, orientation and depth
]]

-- Services
local WorkspaceService = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Toolbar Icon
local toolbar = plugin:CreateToolbar("Generation")
local scriptButton = toolbar:CreateButton("Object Placement Randomizer", "Randomly place objects in an area", "rbxassetid://6551643745")

-- Get main plugin folder
local folder = script.Parent

-- Required modules
local CollapsibleTitledSection = require(folder.CollapsibleTitledSection)
local LabeledTextInput = require(folder.LabeledTextInput)
local GuiUtilities = require(folder.GuiUtilities)
local CustomTextButton = require(folder.CustomTextButton)
local ImageButtonWithText = require(folder.ImageButtonWithText)
local LabeledSlider = require(folder.LabeledSlider)
local LabeledCheckbox = require(folder.LabeledCheckbox)
local VerticallyScalingListFrame = require(folder.VerticallyScalingListFrame)
local VerticalScrollingFrame = require(folder.VerticalScrollingFrame)

local isGuiActive = false

-- Make sure we're in studio
if RunService:IsEdit() then
	-- Get theme colors
	local textColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	local borderColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Border)
	local backgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)

	local rng = Random.new(tick())
	
	-- Constants
	local GUI_X_SIZE_MIN = 350
	local GUI_Y_SIZE_MIN = 400
	local GUI_X_SIZE = 350
	local GUI_Y_SIZE = 500
	local DEFAULT_AREA_POSITION = Vector3.new(0,0,0)
	local DEFAULT_AREA_SIZE = Vector3.new(500,1,500)

	-- Variables
	local area = nil
	local areaPosition = DEFAULT_AREA_POSITION
	local areaSize = DEFAULT_AREA_SIZE
	local areaConnection = nil
	local objectName = ""
	local number = 20
	local setScale = 1
	local scaleRange = 0
	local maxRotation = 0
	local maxInclination = 0
	local depth = .50
	local clusterSize = 5
	local density = 25
	local perpendicular = false
	local onParts = false
	
	-- Create table of enum materials
	local materials = {}
	local materialValid = {}
	for _, i in pairs(Enum.Material:GetEnumItems()) do
		if i ~= Enum.Material.Air and i ~= Enum.Material.ForceField and i ~= Enum.Material.Water then
			materials[i.Name] = i
			materialValid[i.Name]= true
		end
	end
	
	local blacklist = {}
	local components = {}
	local instructions = nil

	-- Create Gui window
	local guiInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		GUI_X_SIZE,
		GUI_Y_SIZE,
		GUI_X_SIZE_MIN,
		GUI_Y_SIZE_MIN
	)

	local gui = plugin:CreateDockWidgetPluginGui("ObjectPlacementRandomizer", guiInfo)
	gui.Title = "Object Placement Randomizer"
	
	local progressFrame
	local progressBackground
	local progressBorder
	local progressBar
	local percentBox
	local cancelButton
	local cancelled = false
	
	-- Check if gui already exists
	local pluginGui = CoreGui:FindFirstChild("RandomizerGui")
	if pluginGui then
		pluginGui:Destroy()
	end
	
	-- Create gui for progress bar
	pluginGui = Instance.new("ScreenGui")
	pluginGui.Name = "RandomizerGui"
	pluginGui.Parent = CoreGui
	
	progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(.5, 0, 0, 25)
	progressFrame.AnchorPoint = Vector2.new(.5, .5)
	progressFrame.Position = UDim2.new(.5, 0, 1, -15)
	progressFrame.BackgroundTransparency = 1
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = pluginGui
	
	progressBackground = Instance.new("Frame")
	progressBackground.Name = "ProgressBackground"
	progressBackground.Size = UDim2.new(1, 0, 1, 0)
	progressBackground.AnchorPoint = Vector2.new(.5, .5)
	progressBackground.Position = UDim2.new(.5, 0, .5, 0)
	progressBackground.BackgroundColor3 = backgroundColor
	progressBackground.ZIndex = 1
	progressBackground.Parent = progressFrame
	
	progressBorder = progressBackground:Clone()
	progressBorder.Name = "ProgressBorder"
	progressBorder.BorderColor3 = borderColor
	progressBorder.BackgroundTransparency = 1
	progressBorder.ZIndex = 10
	progressBorder.Parent = progressFrame
	
	progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.AnchorPoint = Vector2.new(0, .5)
	progressBar.Position = UDim2.new(0, 0, .5, 0)
	progressBar.BorderColor3 = Color3.new(0.117647, 0.6, 0.109804)
	progressBar.BackgroundColor3 = Color3.new(0.392157, 1, 0.254902)
	progressBar.ZIndex = 5
	progressBar.Parent = progressFrame
	
	percentBox = Instance.new("TextLabel")
	percentBox.Name = "PercentBox"
	percentBox.Size = UDim2.new(0, 50, 0, 20)
	percentBox.AnchorPoint = Vector2.new(.5, .5)
	percentBox.Position = UDim2.new(.5, 0, .5, 0)
	percentBox.BackgroundTransparency = 1
	percentBox.Text = ""
	percentBox.TextColor3 = textColor
	percentBox.ZIndex = 10
	percentBox.Parent = progressFrame
	
	cancelButton = Instance.new("TextButton")
	cancelButton.Name = "Cancel"
	cancelButton.Size = UDim2.new(0, 70, 0, 25)
	cancelButton.AnchorPoint = Vector2.new(.5, .5)
	cancelButton.Position = UDim2.new(.5, 0, 0, -30)
	cancelButton.TextColor3 = textColor
	cancelButton.BackgroundColor3 = borderColor
	cancelButton.Text = "Cancel"
	cancelButton.Parent = progressFrame
	
	cancelButton.Activated:Connect(function()
		warn("Generation cancelled by user.")
		cancelled = true
	end)
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.Parent = progressBackground
	uiCorner = uiCorner:Clone()
	uiCorner.Parent = progressBorder
	uiCorner = uiCorner:Clone()
	uiCorner.Parent = progressBar
	uiCorner = uiCorner:Clone()
	uiCorner.Parent = cancelButton
	
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0, 0.333333, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0))
	}
	uiGradient.Parent = progressBar
	pluginGui.Enabled = false
	
	-- Create scrolling frames for gui
	local scrollFrame = VerticalScrollingFrame.new("Main")
	scrollFrame:GetSectionFrame().BackgroundColor3 = backgroundColor
	scrollFrame:GetSectionFrame().BackgroundTransparency = 0
	local listFrame = VerticallyScalingListFrame.new("Main")
		
	-- Create collapsable section for instructions
	local instructionsSection = CollapsibleTitledSection.new(
		"instructions", -- name suffix of the gui object
		"Instructions", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		true -- minimized by default?
	)
	
	local instructionsFrame = GuiUtilities:MakeFrame("InstructionsFrame")
	instructionsFrame.Size = UDim2.new(1,0,0,600)

	local instructionsText = [[-- Area to Fill
					NOTE: Area must be *above* the region you want to fill.
					    The plugin works by raycasting straight down.
					
					Area Position: The center position in the workspace 
					    where you want your objects. Must be ABOVE terrain!
					Area Size: Size of the area you want covered in studs,
					    on X and Z axes only. Recommended Y of 1.
					
					-- Object to Copy
					Name: Name of the object in the workspace to copy.
					Copies: Number of copies of the object to make. Supports
						up to 9999, but go above 1000 at your own risk!
					Place on Parts: Check this box to allow placement on 
					    parts as well as terrain. Does not have a filter!
					
					-- Terrain
					Checking any of the boxes will allow the plugin to place
					    objects on that terrain. It will not place on
					    unchecked terrain types. If the randomizer cannot
					    find a suitable position to place, it will skip and
					    move onto the next copy.
					
					-- Orientation
					Perpendicular: Check this box if you want objects
					    aligned	perpendicular to the surface.
					Set Scale: Amount to scale copies by, before applying
						randomized scale.
					Scale: Maximum amount to scale parts by. Will scale
					    each copy randomly between ± the specified %.
					Max Rotation: Maximum amount it will rotate each copy.
					Max Inclination: Maximum amount it will incline the
					    copy from upright.
					Depth: Amount to sink copies below the surface, as a
					    percent of half the length of the primary part.
					
					-- Clustering
					Max Size: Maximum number of copies that will be put in
					    a cluster.
					Density: Maximum distance each member of the cluster
					    will be from the center in studs.
					
					Created by TerminusEstKuldin/BahamutFierce]]
	instructions = GuiUtilities.MakeStandardPropertyLabel(instructionsText)
	instructions.Parent = instructionsFrame
	instructionsFrame.Parent = instructionsSection:GetContentsFrame()
	
	-- Add Instructions section to components
	components[#components+1] = instructionsSection:GetSectionFrame()
	
	local function stringToVector(str)
		local tokens = string.split(str, ',')
		for i = 1, 3 do
			tokens[i] = tonumber(tokens[i])
			if tokens[i] == "0" or tokens[i] == nil then
				tokens[i] = 0
			end
		end
		return Vector3.new(tokens[1],tokens[2],tokens[3])
	end
	
	-- Create Area section
	local areaSection = CollapsibleTitledSection.new(
		"area", -- name suffix of the gui object
		"Area to Fill", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		false -- minimized by default?
	)	
	
	-- Create Area position input
	local inputAreaPosition = LabeledTextInput.new(
		"areaPosition", -- name suffix of gui object
		"Area Position", -- title text of the multi choice
		--string.format("%.2f, %.2f, %.2f" , areaPosition.X, areaPosition.Y, areaPosition.Z)
		tostring(areaPosition) -- default value
	)
	inputAreaPosition:SetMaxGraphemes(35)
	inputAreaPosition:SetValueChangedFunction(function(newObj)
		areaPosition = stringToVector(newObj)
	end)
	inputAreaPosition:GetFrame().Wrapper.Size = UDim2.new(0, 200, .6, 0)
	inputAreaPosition:GetFrame().Parent = areaSection:GetContentsFrame()
	
	-- Create Area size input
	local inputAreaSize = LabeledTextInput.new(
		"areaSize", -- name suffix of gui object
		"Area Size", -- title text of the multi choice
		--string.format("%.2f, %.2f, %.2f" , areaSize.X, areaSize.Y, areaSize.Z)
		tostring(areaSize) -- default value
	)
	inputAreaSize:SetMaxGraphemes(35)
	inputAreaSize:SetValueChangedFunction(function(newObj)
		areaSize = stringToVector(newObj)
	end)
	inputAreaSize:GetFrame().Wrapper.Size = UDim2.new(0, 200, .6, 0)
	inputAreaSize:GetFrame().Parent = areaSection:GetContentsFrame()
	
	-- Create Area generation button
	local areaCreateFrame = GuiUtilities:MakeStandardFixedHeightFrame("areaCreateFrame")
	local areaCreateObject = CustomTextButton.new(
		"createAreaButton",
		"Set Area"
	)
	local areaRemoveObject = CustomTextButton.new(
		"removeAreaButton",
		"Remove Area"
	)
	areaCreateButton = areaCreateObject:GetButton()
	areaCreateButton.AnchorPoint = Vector2.new(.5,.5)
	areaCreateButton.Size = UDim2.new(0,80,0,25)
	areaCreateButton.Position = UDim2.new(.33,0,.5,0)
	areaCreateObject:GetButton().Parent = areaCreateFrame
	areaRemoveButton = areaRemoveObject:GetButton()
	areaRemoveButton.AnchorPoint = Vector2.new(.5,.5)
	areaRemoveButton.Size = UDim2.new(0,80,0,25)
	areaRemoveButton.Position = UDim2.new(.66,0,.5,0)
	areaCreateObject:GetButton().Parent = areaCreateFrame 
	areaRemoveObject:GetButton().Parent = areaCreateFrame
	areaCreateFrame.Parent = areaSection:GetContentsFrame()
	
	-- Function to update area if it changes
	local function updateArea()
		areaPosition = area.Position
		areaSize = area.Size
		inputAreaPosition:GetFrame().Wrapper.TextBox.Text = tostring(areaPosition)
		inputAreaSize:GetFrame().Wrapper.TextBox.Text = tostring(areaSize)
	end

	-- Check if Area part exists in workspace
	area = WorkspaceService:FindFirstChild("Area")
	if area then
		areaPosition = area.Position
		areaSize = area.Size
		inputAreaPosition:GetFrame().Wrapper.TextBox.Text = tostring(areaPosition)
		inputAreaSize:GetFrame().Wrapper.TextBox.Text = tostring(areaSize)
		print("Area already exists. Size and position loaded in.")
				
		if areaConnection then
			areaConnection:Disconnect()
		end
		areaConnection = area.Changed:Connect(updateArea)
	end
	
	-- Connect function to Area Create button
	areaCreateButton.Activated:Connect(function()
		if not areaPosition then
			warn("Error! Area Position must be a valid Vector3.")
		else
			if not areaSize then
				warn("Error! Area Size must be a valid Vector3.")
			else
				if not area then 
					area = Instance.new("Part")
					area.Name = "Area"
					area.Position = areaPosition
					area.Size = areaSize
					area.Transparency = .8
					area.Anchored = true
					area.CanCollide = false
					area.Massless = true
					area.CastShadow = false
					area.Parent = WorkspaceService
					print("Area set. You can adjust size and position in the workspace.")
				else
					area.Position = areaPosition
					area.Size = areaSize
					print("Area already exists. Size and position updated.")
				end
				if areaConnection then
					areaConnection:Disconnect()
				end
				areaConnection = area.Changed:Connect(updateArea)
			end
		end
	end)
	
	-- Connect function to Area Remove Button
	areaRemoveButton.Activated:Connect(function()
		area = WorkspaceService:FindFirstChild("Area")
		if not area then
			warn("Error! Area not defined yet.")
		else
			areaPosition = DEFAULT_AREA_POSITION
			areaSize = DEFAULT_AREA_SIZE
			
			inputAreaPosition:SetValue(tostring(areaPosition))
			inputAreaSize:SetValue(tostring(areaSize))
			
			if areaConnection then
				areaConnection:Disconnect()
			end
			area:Destroy()
			area = nil
			print("Area removed!")
		end
	end)
	
	-- Add Area section to components
	components[#components+1] = areaSection:GetSectionFrame()
	
	-- Create Object section
	local objectSection = CollapsibleTitledSection.new(
		"object", -- name suffix of the gui object
		"Object to Copy", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		false -- minimized by default?
	)
	
	-- Create object input box
	local inputObject = LabeledTextInput.new(
		"object", -- name suffix of gui object
		"Name", -- title text of the multi choice
		objectName -- default value
	)
	inputObject:SetMaxGraphemes(30)
	inputObject:SetValueChangedFunction(function(newObj)
		objectName = newObj
	end)
	inputObject:GetFrame().Parent = objectSection:GetContentsFrame()

	-- Create number input box
	local inputNumber = LabeledTextInput.new(
		"number", -- name suffix of gui object
		"Copies", -- title text of the multi choice
		number -- default value
	)
	inputNumber:SetMaxGraphemes(4)
	inputNumber:SetValueChangedFunction(function(newObj)
		number = tonumber(newObj)
		if number == nil then
			number = 0
		end
	end)
	inputNumber:GetFrame().Parent = objectSection:GetContentsFrame()
	
	-- Create perpendicular checkbox
	local partsCheckBox = LabeledCheckbox.new(
		"parts", -- name suffix of gui object
		"Place on Parts", -- text beside the checkbox
		false, -- initial value
		false -- initially disabled?
	)
	partsCheckBox:SetValueChangedFunction(function(newValue)
		onParts = newValue
	end)
	partsCheckBox:GetFrame().Parent = objectSection:GetContentsFrame()
	
	-- Add Object section to components
	components[#components+1] = objectSection:GetSectionFrame()
	
	-- Create Materials section
	local materialSection = CollapsibleTitledSection.new(
		"material", -- name suffix of the gui object
		"Materials", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		true -- minimized by default?
	)
	
	local checkCount = 0
	local checkBox = {}
	for _, i in pairs(materials) do
		-- Create material checkbox
		checkCount += 1
		checkBox[checkCount] = LabeledCheckbox.new(
			i.Name, -- name suffix of gui object
			i.Name, -- text beside the checkbox
			true, -- initial value
			false -- initially disabled?
		)
		checkBox[checkCount]:SetValueChangedFunction(function(newValue)
			materialValid[i.Name] = newValue
		end)
		checkBox[checkCount]:GetFrame().Parent = materialSection:GetContentsFrame()
	end
	
	-- Create material buttons
	local matButtonFrame = GuiUtilities:MakeStandardFixedHeightFrame("areaCreateFrame")
	local matClear = CustomTextButton.new(
		"matClearButton",
		"Clear All"
	)
	local matFill = CustomTextButton.new(
		"matFillButton",
		"Select All"
	)
	matClearButton = matClear:GetButton()
	matClearButton.AnchorPoint = Vector2.new(.5,.5)
	matClearButton.Size = UDim2.new(0,80,0,25)
	matClearButton.Position = UDim2.new(.33,0,.5,0)
	matClear:GetButton().Parent = matButtonFrame
	matFillButton = matFill:GetButton()
	matFillButton.AnchorPoint = Vector2.new(.5,.5)
	matFillButton.Size = UDim2.new(0,80,0,25)
	matFillButton.Position = UDim2.new(.66,0,.5,0)
	matFill:GetButton().Parent = matButtonFrame 
	matButtonFrame.Parent = materialSection:GetContentsFrame()
	
	matClearButton.Activated:Connect(function()
		for i = 1, #checkBox do
			checkBox[i]:SetValue(false)
		end
	end)
	
	matFillButton.Activated:Connect(function()
		for i = 1, #checkBox do
			checkBox[i]:SetValue(true)
		end
	end)
	
	-- Add Materials section to components
	components[#components+1] = materialSection:GetSectionFrame()
	
	-- Create Scale section
	local scaleSection = CollapsibleTitledSection.new(
		"scale", -- name suffix of the gui object
		"Scale", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		true -- minimized by default?
	)
	
	-- Create set scale input box
	local inputSetScale = LabeledTextInput.new(
		"setScale", -- name suffix of gui object
		"Set Scale", -- title text of the multi choice
		setScale -- default value
	)
	inputSetScale:SetMaxGraphemes(3)
	inputSetScale:SetValueChangedFunction(function(newObj)
		setScale = tonumber(newObj)
		if setScale == nil then
			setScale = 1
		end
		if setScale <= 0 then
			warn("Error! Scale cannot be less than or equal to 0.")
			setScale = 1
		end
	end)
	inputSetScale:GetFrame().Parent = scaleSection:GetContentsFrame()
	
	-- Create scale slider
	local sliderScale = LabeledSlider.new(
		"scale", -- name suffix of gui object
		"Random Scale", -- title text of the multi choice
		50, -- how many intervals to split the slider into
		2 -- the starting value of the slider
	)
	local sliderScaleDisplay = GuiUtilities.MakeStandardPropertyLabel("± 1 %")
	sliderScaleDisplay.TextXAlignment = Enum.TextXAlignment.Right
	sliderScaleDisplay.Position = UDim2.new(0.6, 0, 0.5, -3)
	sliderScaleDisplay.Parent = sliderScale:GetFrame()

	sliderScale:SetValueChangedFunction(function(newValue)
		sliderScaleDisplay.Text = "± "..newValue.." %"
		scaleRange = (newValue / 100)
	end)	
	sliderScale:GetFrame().Parent = scaleSection:GetContentsFrame()
	
	-- Add Scale section to components
	components[#components+1] = scaleSection:GetSectionFrame()
	
	
	-- Create Orientation section
	local orientSection = CollapsibleTitledSection.new(
		"orient", -- name suffix of the gui object
		"Orientation", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		true -- minimized by default?
	)
	
	-- Create perpendicular checkbox
	local perpCheckBox = LabeledCheckbox.new(
		"Perpendicular", -- name suffix of gui object
		"Perpendicular", -- text beside the checkbox
		false, -- initial value
		false -- initially disabled?
	)
	perpCheckBox:SetValueChangedFunction(function(newValue)
		perpendicular = newValue
	end)
	perpCheckBox:GetFrame().Parent = orientSection:GetContentsFrame()
	
	-- Create max rotation slider
	local sliderMaxRot = LabeledSlider.new(
		"maxRotation", -- name suffix of gui object
		"Max Rotation", -- title text of the multi choice
		360, -- how many intervals to split the slider into
		2 -- the starting value of the slider
	)
	local sliderMaxRotDisplay = GuiUtilities.MakeStandardPropertyLabel("1 °")
	sliderMaxRotDisplay.TextXAlignment = Enum.TextXAlignment.Right
	sliderMaxRotDisplay.Position = UDim2.new(0.6, 0, 0.5, -3)
	sliderMaxRotDisplay.Parent = sliderMaxRot:GetFrame()
	
	sliderMaxRot:SetValueChangedFunction(function(newValue)
		sliderMaxRotDisplay.Text = newValue.." °"
		maxRotation = math.rad(newValue)
	end)
	sliderMaxRot:GetFrame().Parent = orientSection:GetContentsFrame()

	-- Create max inclination slider
	local sliderMaxInc = LabeledSlider.new(
		"maxInclination", -- name suffix of gui object
		"Max Inclination", -- title text of the multi choice
		90, -- how many intervals to split the slider into
		2 -- the starting value of the slider
	)
	local sliderMaxIncDisplay = GuiUtilities.MakeStandardPropertyLabel("1 °")
	sliderMaxIncDisplay.TextXAlignment = Enum.TextXAlignment.Right
	sliderMaxIncDisplay.Position = UDim2.new(0.6, 0, 0.5, -3)
	sliderMaxIncDisplay.Parent = sliderMaxInc:GetFrame()	
	
	sliderMaxInc:SetValueChangedFunction(function(newValue)
		sliderMaxIncDisplay.Text = newValue.." °"
		maxInclination = math.rad(newValue)
	end)
	sliderMaxInc:GetFrame().Parent = orientSection:GetContentsFrame()

	-- Create depth slider
	local sliderDepth = LabeledSlider.new(
		"depth", -- name suffix of gui object
		"Depth", -- title text of the multi choice
		100, -- how many intervals to split the slider into
		50 -- the starting value of the slider
	)
	local sliderDepthDisplay = GuiUtilities.MakeStandardPropertyLabel("50 %")
	sliderDepthDisplay.TextXAlignment = Enum.TextXAlignment.Right
	sliderDepthDisplay.Position = UDim2.new(0.6, 0, 0.5, -3)
	sliderDepthDisplay.Parent = sliderDepth:GetFrame()
	
	sliderDepth:SetValueChangedFunction(function(newValue)
		sliderDepthDisplay.Text = newValue.." %"
		depth = (newValue / 100)
	end)
	sliderDepth:GetFrame().Parent = orientSection:GetContentsFrame()
	
	-- Add Orientation section to components
	components[#components+1] = orientSection:GetSectionFrame()
	
	-- Create Cluster section
	local clusterSection = CollapsibleTitledSection.new(
		"cluster", -- name suffix of the gui object
		"Clustering", -- the text displayed beside the collapsible arrow
		true, -- have the content frame auto-update its size?
		true, -- minimizable?
		true -- minimized by default?
	)
	
	-- Create clumpSize input box
	local inputClusterSize = LabeledTextInput.new(
		"clustersize", -- name suffix of gui object
		"Max Size", -- title text of the multi choice
		"5" -- default value
	)
	inputClusterSize:SetMaxGraphemes(3)
	inputClusterSize:SetValueChangedFunction(function(newObj)
		clusterSize = tonumber(newObj)
		if clusterSize == nil then
			clusterSize = 0
		end
	end)
	inputClusterSize:GetFrame().Parent = clusterSection:GetContentsFrame()

	-- Create density slider
	local sliderDensity = LabeledSlider.new(
		"density", -- name suffix of gui object
		"Density", -- title text of the multi choice
		50, -- how many intervals to split the slider into
		25 -- the starting value of the slider
	)
	local sliderDensityDisplay = GuiUtilities.MakeStandardPropertyLabel("35 studs away")
	sliderDensityDisplay.TextXAlignment = Enum.TextXAlignment.Right
	sliderDensityDisplay.Position = UDim2.new(0.7, 0, 0.5, -3)
	sliderDensityDisplay.Parent = sliderDensity:GetFrame()
	
	sliderDensity:SetValueChangedFunction(function(newValue)
		density = 60 - newValue
		sliderDensityDisplay.Text = density.." studs away"
	end)
	sliderDensity:GetFrame().Parent = clusterSection:GetContentsFrame()
	
	-- Add Clustering section to components
	components[#components+1] = clusterSection:GetSectionFrame()
	
	-- Create confirmation button
	local confirmObject = CustomTextButton.new(
		"confirmButton",
		"Generate"
	)
	local confirmButton = confirmObject:GetButton()
	confirmButton.Size = UDim2.new(0,80,0,25)
	confirmButton.AnchorPoint = Vector2.new(.5,.5)
	confirmButton.Position = UDim2.new(.33,0,.5,0)
	local undoObject = CustomTextButton.new(
		"undoButton",
		"Undo"
	)
	local undoButton = undoObject:GetButton()
	undoButton.Size = UDim2.new(0,80,0,25)
	undoButton.AnchorPoint = Vector2.new(.5,.5)
	undoButton.Position = UDim2.new(.66,0,.5,0)
	local buttonFrame = GuiUtilities:MakeStandardFixedHeightFrame("areaCreateFrame")
	confirmButton.Parent = buttonFrame
	undoButton.Parent = buttonFrame
	components[#components+1] = buttonFrame
	
	undoActive = false
	undoButton.Activated:Connect(function()
		if not undoActive then
			undoActive = true
			if ChangeHistoryService:GetCanUndo() then
				ChangeHistoryService:Undo()
				print("Last generation undone!")
			else
				warn("Error: Nothing to undo!")
			end
			undoActive = false
			pluginGui.Enabled = false
		end
	end)
	
	-- Add frames to main frame
	for _, frame in ipairs(components) do
		listFrame:AddChild(frame)
	end
	
	--listFrame:AddBottomPadding()
	listFrame:GetFrame().Parent = scrollFrame:GetContentsFrame()
	
	scrollFrame:GetSectionFrame().Parent = gui
	
	game.Selection.SelectionChanged:Connect(function()
		-- Check if object selected
		local selection = game.Selection:Get()[1]
		if selection and selection.Name ~= "Area" then
			objectName = selection.Name
			inputObject:GetFrame().Wrapper.TextBox.Text = objectName
		end
	end)	

	-- Function to set a part's CFrame. Returns the CFrame of the part
	local function setPartCFrame(part, newCFrame)
		part.CFrame = newCFrame
		return part.CFrame
	end

	-- Function to return an objects CFrame based on type
	local function getCFrame(object)
		if object:IsA("Model") then
			return object.PrimaryPart.CFrame
		else
			return object.CFrame
		end
	end

	-- Function to get CFrame of object adjusted to normal of surface
	local function getNewCFrame(object, normal)
		local cf = getCFrame(object)
		local rightVec = cf.UpVector:Cross(normal)
		return CFrame.fromMatrix(object.Position, rightVec, normal)			
	end

	-- Function to set a model's CFrame. Returns the CFrame of the primary part of the model.
	-- Written by @Thedagz on Discord
	local ModelOffsetsRegistry = {} -- Part = Offset
	local function CFrameModel(Model,CF)
		local Registry = ModelOffsetsRegistry[Model]
		if Registry then
			for Part,Offset in pairs(Registry) do
				Part.CFrame = CF*Offset
			end
		else
			Registry = {}

			local InversePrimaryPartCF = Model.PrimaryPart.CFrame:Inverse()
			local c = Model:GetDescendants()
			for i=1,#c do
				if c[i]:IsA("BasePart") then
					Registry[c[i]] = InversePrimaryPartCF*c[i].CFrame
				end
			end

			local ParentConnection; ParentConnection = Model:GetPropertyChangedSignal("Parent"):Connect(function(NewParent)
				if NewParent == nil then
					ModelOffsetsRegistry[Model] = nil
					ParentConnection:Disconnect()
				end
			end)

			ModelOffsetsRegistry[Model] = Registry
			CFrameModel(Model,CF)
		end
		return Model.PrimaryPart.CFrame
	end	
	
	-- Function to scale a model
	-- Written with help from Kohl on RCS Discord Server
	local function scaleModel(model, scale)		
		local primaryCFrame = model.PrimaryPart.CFrame
		local scaleVector = Vector3.new(scale, scale, scale)
		for _, v in next, model:GetDescendants() do
			if v:IsA("BasePart") then
				if v == model.PrimaryPart then
					v.Size *= scaleVector
					v.CFrame = primaryCFrame
				else
					local objectCFrame = primaryCFrame:inverse() * v.CFrame
					objectCFrame += (objectCFrame.Position * scale) - objectCFrame.Position
					v.Size *= scaleVector
					v.CFrame = primaryCFrame * objectCFrame
				end
			end
		end
		
		return model
	end
	
	-- Create Objects folder if it's not already there
	local objectsFolder = WorkspaceService:FindFirstChild("RandomizerObjects")
	if not objectsFolder then
		objectsFolder = Instance.new("Folder")
		objectsFolder.Name = "RandomizerObjects"
		objectsFolder.Parent = WorkspaceService
	end
	
	local clicked = false
	-- Event to run placement when button pressed
	confirmButton.Activated:Connect(function()
		if not clicked then
			clicked = true
			
			-- Enable progress bar
			pluginGui.Enabled = true
			
			-- Add any parts in the Objects folder to blacklist
			if onParts then
				blacklist = {WorkspaceService.Area}
				for _, part in pairs(objectsFolder:GetDescendants()) do
					if part:IsA("BasePart") then
						blacklist[#blacklist+1] = part
					end
				end
			end
			
			-- Set undo history waypoint
			ChangeHistoryService:SetWaypoint("GuiActive")
			-- Flag to monitor if the placement can run
			local canRun = true

			-- Check if object exists
			local setCFrame
			local midpoint
			local object = game.Workspace:FindFirstChild(objectName)
			if not object then
				warn("Error! Object not found in Workspace!")
				canRun = false
			else
				local objType = object.ClassName
				if object:IsA("Model") then
					setCFrame = CFrameModel
					if not object.PrimaryPart then
						warn("Error! Model must have PrimaryPart set!")
						canRun = false
					else
						midpoint = object.PrimaryPart.Size.Y / 2

					end
				elseif object:IsA("BasePart") then
					setCFrame = setPartCFrame
					midpoint = object.Size.Y / 2
				else
					warn("Error! "..tostring(object).." is not a valid model or part!")
					canRun = false			
				end
			end

			local raycastParams = RaycastParams.new()
			if onParts then
				-- Set up raycast to blacklist placed objects so it can place on other parts
				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				raycastParams.FilterDescendantsInstances = {WorkspaceService.Area, objectsFolder:GetDescendants()}
			else
				-- Set up raycast to only detect terrain
				raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
				raycastParams.FilterDescendantsInstances = {WorkspaceService.Terrain}
			end

			-- Check if Area exists
			local area = game.Workspace:FindFirstChild("Area")
			if not area then
				warn("Error! Area not found in Workspace!")
				canRun = false
			end

			-- Check if cluster size is bigger than number of objects
			if number < clusterSize then
				warn("Error! Cluster size cannot be larger than total number!")
				canRun = false
			end

			-- Loop to place objects
			local count = 0
			local failures = 0
			if canRun then
				gui.Enabled = false
				print("Placing "..number.." objects.")
				while (count <= number and failures <= number) and not cancelled do
					local obj = object:Clone()
					local posOffset
					local orientOffset
					local rotatedCF
					local scale
					local newCF
					local rayResults
					local loop = 0
					
					-- Update blacklist if placing on parts
					if onParts then
						raycastParams.FilterDescendantsInstances = blacklist
					end
					-- Get random location on Area part and raycast down
					repeat
						posOffset = Vector3.new(rng:NextNumber(-area.Size.X/2,area.Size.X/2), 0, rng:NextNumber(-area.Size.Z/2,area.Size.Z/2))
						rayResults = WorkspaceService:Raycast(area.Position + posOffset, Vector3.new(0, -200, 0), raycastParams)
						loop += 1
						RunService.RenderStepped:Wait()
					until (rayResults and materialValid[rayResults.Material.Name]==true) or loop >= 100
					count += 1
					if not rayResults or materialValid[rayResults.Material.Name]==false then
						warn("Raycasting didn't get results. Do you have Area positioned correctly?")
						if loop >= 100 then
							obj:Destroy()
							warn("Raycasting timeout reached. Does the specified material exist here?")
						end
						failures += 1
					else
						-- First scale by set scale amount, then by random scale
						scale = rng:NextNumber(1 - scaleRange, 1 + scaleRange)
						if obj:IsA("BasePart") then
							orientOffset = obj.Orientation
							obj.Size *= Vector3.new(setScale, setScale, setScale)
							obj.Size *= Vector3.new(scale, scale, scale)
							-- Add to blacklist if onParts set
							if onParts then
								blacklist[#blacklist+1] = obj
							end
						elseif obj:IsA("Model") then
							orientOffset = obj.PrimaryPart.Orientation
							obj = scaleModel(obj, setScale)
							obj = scaleModel(obj, scale)
							if onParts then
								for _, part in pairs(obj:GetDescendants()) do
									if part:IsA("BasePart") then
										blacklist[#blacklist+1] = part
									end
								end
							end
						end
						
						rotatedCF = CFrame.new(getCFrame(object).Position)
						rotatedCF = CFrame.fromAxisAngle(rotatedCF.UpVector, math.rad(orientOffset.Y))
						rotatedCF = CFrame.fromAxisAngle(rotatedCF.RightVector, math.rad(orientOffset.X))
						rotatedCF = CFrame.fromAxisAngle(-rotatedCF.LookVector, math.rad(orientOffset.Z))
						rotatedCF = rotatedCF - rotatedCF.Position
						
						-- Set CFrame if perpendicular is checked
						if perpendicular and not onParts then
							local cf = getCFrame(object)
							local rightVec = cf.UpVector:Cross(rayResults.Normal)
							newCF = setCFrame(obj, CFrame.fromMatrix(rayResults.Position + Vector3.new(0, midpoint - (depth * midpoint), 0), rightVec, rayResults.Normal))
						else						
							newCF = setCFrame(obj, CFrame.new(rayResults.Position + Vector3.new(0, midpoint - (depth * midpoint), 0)))
						end
						-- Adjust for original orientation
						newCF = setCFrame(obj, newCF * rotatedCF)
						newCF = setCFrame(obj, newCF * CFrame.fromAxisAngle(newCF.UpVector, rng:NextNumber(0, maxRotation)))
						newCF = setCFrame(obj, newCF * CFrame.fromAxisAngle(newCF.RightVector, rng:NextNumber(0, maxInclination)))
						newCF = setCFrame(obj, newCF * CFrame.fromAxisAngle(-newCF.LookVector, rng:NextNumber(0, maxInclination)))
						
						-- Delay for parenting
						RunService.RenderStepped:Wait()
						obj.Parent = objectsFolder
						-- Calculate cluster size
						local cluster = rng:NextInteger(clusterSize / 2, clusterSize)
						-- Set position based on original part
						local pos
						if obj:IsA("BasePart") then
							pos = obj.Position
						else
							pos = obj.PrimaryPart.Position
						end
						-- Loop through for cluster
						for i = 2, cluster do
							-- Clone new object from original one
							local obj2 = obj:Clone()
							loop = 0
							-- Update blacklist if placing on parts
							if onParts then
								raycastParams.FilterDescendantsInstances = blacklist
							end
							-- Get random distance from original part and raycast down
							repeat
								posOffset = Vector3.new(rng:NextNumber(5, density), 50, rng:NextNumber(5, density))
								rayResults = WorkspaceService:Raycast(pos + posOffset, Vector3.new(0, -200, 0), raycastParams)
								loop += 1
								RunService.RenderStepped:Wait()
							until (rayResults and materialValid[rayResults.Material.Name]==true) or loop >= 100
							count += 1
							if not rayResults then
								warn("Raycasting didn't get results. Do you have Area positioned correctly?")
								if loop >= 100 then
									obj2:Destroy()
									warn("Raycasting timeout reached. Does the specified material exist here?")
								end
								failures += 1
							else
								-- First scale by set scale amount, then by random scale
								scale = rng:NextNumber(1 - scaleRange, 1 + scaleRange)
								if obj2:IsA("BasePart") then
									obj2.Size *= Vector3.new(setScale, setScale, setScale)
									obj2.Size *= Vector3.new(scale, scale, scale)
									-- Add to blacklist if onParts set
									if onParts then
										blacklist[#blacklist+1] = obj2
									end
								elseif obj2:IsA("Model") then
									obj2 = scaleModel(obj2, setScale)
									obj2 = scaleModel(obj2, scale)
									if onParts then
										for _, part in pairs(obj2:GetDescendants()) do
											if part:IsA("BasePart") then
												blacklist[#blacklist+1] = part
											end
										end
									end
								end
																
								-- Set CFrame if perpendicular is checked
								if perpendicular and not onParts then
									local cf = getCFrame(object)
									local rightVec = cf.UpVector:Cross(rayResults.Normal)
									newCF = setCFrame(obj2, CFrame.fromMatrix(rayResults.Position + Vector3.new(0, midpoint - (depth * midpoint), 0), rightVec, rayResults.Normal))
								else						
									newCF = setCFrame(obj2, CFrame.new(rayResults.Position + Vector3.new(0, midpoint - (depth * midpoint), 0)))
								end
								-- Adjust for original orientation
								newCF = setCFrame(obj2, newCF * rotatedCF)
								newCF = setCFrame(obj2, newCF * CFrame.fromAxisAngle(newCF.UpVector, rng:NextNumber(0, maxRotation)))
								newCF = setCFrame(obj2, newCF * CFrame.fromAxisAngle(newCF.RightVector, rng:NextNumber(0, maxInclination)))
								newCF = setCFrame(obj2, newCF * CFrame.fromAxisAngle(-newCF.LookVector, rng:NextNumber(0, maxInclination)))
								
								-- Delay for parenting
								RunService.RenderStepped:Wait()
								obj2.Parent = objectsFolder
								-- Update progress bar
								progressBar.Size = UDim2.new((count/number), 0, 1, 0)
								percentBox.Text = string.format("%.1f %%", (count / number) * 100)
								if (count / number) > .5 then
									percentBox.TextColor3 = backgroundColor
								end
								-- Break inner loop if needed
								-- count may be larger than number due to clumping
								if count > number or cancelled then break end
							end
						end
					end
					-- Update progress bar
					progressBar.Size = UDim2.new((count/number), 0, 1, 0)
					percentBox.Text = string.format("%.1f %%", (count / number) * 100)
					if (count / number) > .5 then
						percentBox.TextColor3 = backgroundColor
					end
				end
				
				if failures > number then
					warn("Generation was unable to place any copies. Check your area position and materials")
				end
				
				-- Reset cancellation button
				cancelled = false
				
				-- Set waypoint after generation complete and reset gui
				ChangeHistoryService:SetWaypoint("Generation")
				progressBar.Size = UDim2.new(0, 0, 1, 0)
				percentBox.TextColor3 = textColor
				percentBox.Text = ""
				pluginGui.Enabled = false
				print("Generation complete!")
			end
			
			clicked = false
			gui.Enabled = true
		end
	end)
	-- Connection for toolbar button
	scriptButton.Click:Connect(function()
		-- Show/hide gui window
		gui.Enabled = not gui.Enabled		
	end)	
end
