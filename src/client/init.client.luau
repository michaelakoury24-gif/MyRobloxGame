--!strict
-- Client input, mobile controls, charge UI, and football control guide.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
	Name = "FootballControls",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}) :: ScreenGui
gui.Parent = player:WaitForChild("PlayerGui")

local function createPanel(name: string, size: UDim2, position: UDim2, anchor: Vector2): Frame
	local panel = make("Frame", {
		Name = name,
		AnchorPoint = anchor,
		Size = size,
		Position = position,
		BackgroundColor3 = Color3.fromRGB(13, 23, 39),
		BackgroundTransparency = 0.14,
		BorderSizePixel = 0,
	}) :: Frame
	panel.Parent = gui
	local corner = make("UICorner", { CornerRadius = UDim.new(0, 12) })
	corner.Parent = panel
	local stroke = make("UIStroke", {
		Color = Color3.fromRGB(138, 199, 255),
		Transparency = 0.38,
		Thickness = 1.2,
	})
	stroke.Parent = panel
	return panel
end

local controlsPanel = createPanel("ControlsPanel", UDim2.fromOffset(335, 136), UDim2.new(0, 22, 1, -22), Vector2.new(0, 1))
local controlsTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 12),
	Size = UDim2.new(1, -32, 0, 22),
	Font = Enum.Font.GothamBlack,
	Text = "FOOTBALL CONTROLS",
	TextColor3 = Color3.fromRGB(255, 226, 114),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
}) :: TextLabel
controlsTitle.Parent = controlsPanel

local controlsText = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 39),
	Size = UDim2.new(1, -32, 1, -48),
	Font = Enum.Font.GothamMedium,
	Text = "Touch the ball to dribble\nHold CLICK or F  Charge shot\nQ  Ground pass\nE  Slide tackle\nMobile: use the on-screen buttons",
	TextColor3 = Color3.fromRGB(240, 245, 252),
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
}) :: TextLabel
controlsText.Parent = controlsPanel

local statusPanel = createPanel("StatusPanel", UDim2.fromOffset(390, 50), UDim2.new(0.5, 0, 1, -36), Vector2.new(0.5, 1))
local statusText = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	Text = "TOUCH THE BALL TO DRIBBLE",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	TextWrapped = true,
}) :: TextLabel
statusText.Parent = statusPanel

local chargePanel = createPanel("ChargePanel", UDim2.fromOffset(280, 42), UDim2.new(0.5, 0, 1, -96), Vector2.new(0.5, 1))
chargePanel.Visible = false
local chargeBack = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(33, 44, 58),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 12),
	Size = UDim2.new(1, -24, 0, 18),
}) :: Frame
chargeBack.Parent = chargePanel
local chargeFill = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 188, 63),
	BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1),
}) :: Frame
chargeFill.Parent = chargeBack
local chargeLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, -21),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Enum.Font.GothamBold,
	Text = "SHOT POWER",
	TextColor3 = Color3.fromRGB(255, 245, 215),
	TextSize = 13,
}) :: TextLabel
chargeLabel.Parent = chargePanel

local statusNonce = 0
local function showStatus(text: string, color: Color3?, duration: number?)
	statusNonce += 1
	local nonce = statusNonce
	statusText.Text = text
	statusText.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	if duration then
		task.delay(duration, function()
			if nonce == statusNonce then
				statusText.Text = "TOUCH THE BALL TO DRIBBLE"
				statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
	end
end

local function aimDirection(): Vector3
	local camera = Workspace.CurrentCamera
	if camera then
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.05 then
			return flat.Unit
		end
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if flat.Magnitude > 0.05 then
			return flat.Unit
		end
	end
	return Vector3.new(0, 0, -1)
end

local chargeStartedAt: number? = nil
local function startCharging()
	if chargeStartedAt then
		return
	end
	chargeStartedAt = os.clock()
	chargePanel.Visible = true
end

local function releaseShot()
	if not chargeStartedAt then
		return
	end
	local elapsed = os.clock() - chargeStartedAt
	chargeStartedAt = nil
	chargePanel.Visible = false
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

RunService.RenderStepped:Connect(function()
	if chargeStartedAt then
		local amount = math.clamp((os.clock() - chargeStartedAt) / Config.Shot.MaxChargeTime, 0, 1)
		chargeFill.Size = UDim2.fromScale(amount, 1)
		chargeLabel.Text = string.format("SHOT POWER  %d%%", math.floor(amount * 100))
	end
end)

gameEvent.OnClientEvent:Connect(function(eventType: unknown, first: unknown, second: unknown)
	if eventType == "Possession" then
		if first == player.UserId then
			showStatus("YOU HAVE THE BALL", Color3.fromRGB(188, 255, 170), 1.5)
		elseif typeof(second) == "string" then
			showStatus(second .. " HAS POSSESSION", Color3.fromRGB(215, 228, 245), 1.5)
		end
	elseif eventType == "Feedback" and typeof(first) == "string" then
		showStatus(first, Color3.fromRGB(255, 225, 126), 1.2)
	elseif eventType == "Tackle" and first == player.UserId then
		showStatus("TACKLE WON!", Color3.fromRGB(188, 255, 170), 1.2)
	elseif eventType == "Reset" then
		showStatus("BALL RESET TO CENTRE", Color3.fromRGB(210, 235, 255), 1.5)
	end
end)
