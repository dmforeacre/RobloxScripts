-- Services
local RepStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Modules
local roundHandler = require(RepStorage.RoundHandler)

-- Remotes
local safeZoomEvent = RepStorage.Remotes.SafeZoomEvent
local safeOpenEvent = RepStorage.Remotes.SafeOpenEvent
local useItemEvent = RepStorage.Remotes.UseItemEvent

-- Variables
local currentRound = 0
local codeLength = 0
local safeCode = ""

-- References
local model = script.Parent
local contents = model["Blue Key"]
local keypad = RepStorage.Keypad
local postit = workspace.RoomV1.RoundObjects:WaitForChild("Postit")
local rnd = Random.new(os.clock())
local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}

-- Create proximity prompt
local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "Safe"
prompt.ActionText = "Examine"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.RequiresLineOfSight = false
prompt.Parent = model.PrimaryPart

contents.PrimaryPart:WaitForChild("ProximityPrompt").Enabled = false

local function GetCode()
	currentRound = roundHandler.GetRound()
	if currentRound <= 4 then
		codeLength = 3
	elseif currentRound <= 8 then
		codeLength = 4
	else
		codeLength = 5
	end
	local displayCode = ""
	for i = 1, codeLength do
		local num = keys[rnd:NextInteger(1, #keys)]
		safeCode = safeCode..num
		displayCode = displayCode.." "..num
	end
	displayCode = string.sub(displayCode, 1)
	postit.Face.SurfaceGui.TextLabel.Text = displayCode
	print(safeCode)
end

GetCode()

prompt.Triggered:Connect(function(player)
	local keypadCopy = keypad:Clone()
	keypadCopy.Parent = model
	local offset = (model.Code.CFrame.LookVector * -.007)+(model.Code.CFrame.RightVector * -.06)+(model.Code.CFrame.UpVector * .011)
	keypadCopy:PivotTo(model.Code.CFrame + offset)

	local newCF = model.PrimaryPart.CFrame + (-model.PrimaryPart.CFrame.RightVector * 3)
	safeZoomEvent:FireClient(player, model, safeCode, newCF.Position)
	prompt.Enabled = false
end)

safeZoomEvent.OnServerEvent:Connect(function(player, m)
	if m == model then
		prompt.Enabled = true		
	end
end)

local itemUseTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.In, 0, true)
safeOpenEvent.OnServerEvent:Connect(function(player, m)
	if m == model then
		contents.PrimaryPart.ProximityPrompt.Enabled = true
		local offsetSpindle = model.Door.CFrame:Inverse() * model.Spindle.CFrame
		local offsetDoor = model.Hinge.CFrame:Inverse() * model.Door.CFrame
		local offsetKeypad = model.Door.CFrame:Inverse() * model.Code.CFrame
		local offsetSpin = model.Spindle.CFrame:Inverse() * model["Spinny Boi"].CFrame
		
		useItemEvent:FireClient(player, model)
		
		local connection
		local t = 0
		connection = RunService.Heartbeat:Connect(function(dt)
			t += dt
			model.Hinge.CFrame = model.Hinge.CFrame * CFrame.Angles(0,-math.pi/(9216*dt),0)
			model.Door.CFrame = model.Hinge.CFrame * offsetDoor
			model.Code.CFrame = model.Door.CFrame * offsetKeypad
			model.Spindle.CFrame = model.Door.CFrame * offsetSpindle
			model.Spindle.CFrame = model.Spindle.CFrame * CFrame.Angles(math.pi/t,0,0)
			model["Spinny Boi"].CFrame = model.Spindle.CFrame * offsetSpin
			if t >= 2.5 then
				connection:Disconnect()
			end
		end)
	end
end)
