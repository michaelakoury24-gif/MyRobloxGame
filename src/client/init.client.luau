--!strict
-- Aim, shot charging, PC/mobile actions, and a short local slide pose.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("FootballConfig"))
local remotes = ReplicatedStorage:WaitForChild("FootballRemotes")
local ballAction = remotes:WaitForChild("BallAction") :: RemoteEvent
local gameEvent = remotes:WaitForChild("GameEvent") :: RemoteEvent

local function make(className: string, properties: { [string]: any }): Instance
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		(instance :: any)[property] = value
	end
	return instance
end

local gui = make("ScreenGui", {
	Name = "FootballAim",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}) :: ScreenGui
gui.Parent = player:WaitForChild("PlayerGui")

-- The crosshair is deliberately the only persistent football UI. Camera direction
-- through its centre is sent to the server for shots and passes.
local crosshair = make("Frame", {
	Name = "ShotCrosshair",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(30, 30),
}) :: Frame
crosshair.Parent = gui

local crosshairHorizontal = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(2, 14),
	Size = UDim2.fromOffset(26, 2),
}) :: Frame
crosshairHorizontal.Parent = crosshair
local crosshairVertical = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(14, 2),
	Size = UDim2.fromOffset(2, 26),
}) :: Frame
crosshairVertical.Parent = crosshair
local crosshairDot = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 214, 93),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 12),
	Size = UDim2.fromOffset(6, 6),
}) :: Frame
crosshairDot.Parent = crosshair
local crosshairCorner = make("UICorner", { CornerRadius = UDim.new(1, 0) })
crosshairCorner.Parent = crosshairDot

-- The charge bar only appears while shooting; the old control/instruction panels are removed.
local chargeBack = make("Frame", {
	Name = "ShotCharge",
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = Color3.fromRGB(27, 34, 45),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 1, -42),
	Size = UDim2.fromOffset(250, 16),
	Visible = false,
}) :: Frame
chargeBack.Parent = gui
local chargeCorner = make("UICorner", { CornerRadius = UDim.new(0, 6) })
chargeCorner.Parent = chargeBack
local chargeFill = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 186, 62),
	BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1),
}) :: Frame
chargeFill.Parent = chargeBack
local chargeFillCorner = make("UICorner", { CornerRadius = UDim.new(0, 6) })
chargeFillCorner.Parent = chargeFill

local function aimDirection(): Vector3
	local camera = Workspace.CurrentCamera
	if camera and camera.CFrame.LookVector.Magnitude > 0.05 then
		return camera.CFrame.LookVector.Unit
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.CFrame.LookVector
	end
	return Vector3.new(0, 0, -1)
end

local chargeStartedAt: number? = nil
local function startCharging()
	if chargeStartedAt then
		return
	end
	chargeStartedAt = os.clock()
	chargeBack.Visible = true
end

local function releaseShot()
	if not chargeStartedAt then
		return
	end
	local elapsed = os.clock() - chargeStartedAt
	chargeStartedAt = nil
	chargeBack.Visible = false
	local charge = math.clamp(elapsed / Config.Shot.MaxChargeTime, 0, 1)
	ballAction:FireServer("Shoot", aimDirection(), charge)
end

ContextActionService:BindAction("FootballShoot", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		startCharging()
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		releaseShot()
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("FootballShoot", "SHOOT")
ContextActionService:SetPosition("FootballShoot", UDim2.new(1, -110, 1, -260))

ContextActionService:BindAction("FootballPass", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ballAction:FireServer("Pass", aimDirection())
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("FootballPass", "PASS")
ContextActionService:SetPosition("FootballPass", UDim2.new(1, -220, 1, -190))

ContextActionService:BindAction("FootballTackle", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ballAction:FireServer("Tackle", aimDirection())
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.E, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("FootballTackle", "TACKLE")
ContextActionService:SetPosition("FootballTackle", UDim2.new(1, -108, 1, -165))

local function playLocalSlidePose()
	local character = player.Character
	if not character then
		return
	end
	local rootJoint = character:FindFirstChild("RootJoint", true)
	if not rootJoint or not rootJoint:IsA("Motor6D") then
		return
	end

	local originalTransform = rootJoint.Transform
	local crouch = TweenService:Create(rootJoint, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transform = CFrame.Angles(math.rad(-52), 0, 0),
	})
	crouch:Play()
	task.delay(Config.Tackle.SlideDuration, function()
		if rootJoint.Parent then
			TweenService:Create(rootJoint, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transform = originalTransform,
			}):Play()
		end
	end)
end

RunService.RenderStepped:Connect(function()
	if chargeStartedAt then
		local amount = math.clamp((os.clock() - chargeStartedAt) / Config.Shot.MaxChargeTime, 0, 1)
		chargeFill.Size = UDim2.fromScale(amount, 1)
		local color = Color3.fromRGB(255, math.floor(216 - amount * 120), 70)
		crosshairHorizontal.BackgroundColor3 = color
		crosshairVertical.BackgroundColor3 = color
		crosshairDot.BackgroundColor3 = color
	else
		crosshairHorizontal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		crosshairVertical.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		crosshairDot.BackgroundColor3 = Color3.fromRGB(255, 214, 93)
	end
end)

gameEvent.OnClientEvent:Connect(function(eventType: unknown, first: unknown)
	if eventType == "Slide" and first == player.UserId then
		playLocalSlidePose()
	end
end)
