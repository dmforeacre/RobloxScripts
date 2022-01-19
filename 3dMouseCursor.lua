local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local currentCamera = workspace.CurrentCamera

-- Put whatever 3d model you want here for the camera icon
local cursor = workspace:WaitForChild("CamIcon")

UserInputService.MouseIconEnabled = false

RunService.RenderStepped:Connect(function(dt)
	local mouseLocation = UserInputService:GetMouseLocation()
	local viewportPointRay = currentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	cursor:PivotTo(CFrame.new(viewportPointRay.Origin + (viewportPointRay.Direction * 2)))
end)
