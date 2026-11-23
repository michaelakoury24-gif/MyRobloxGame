--!strict
-- Football controls and HUD. Movement is Roblox's normal WASD/thumbstick movement;
-- this script adds sprinting plus validated server-side pass, kick, and shoot actions.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local remotes = ReplicatedStorage:WaitForChild("FootballRemotes")
local kickBall = remotes:WaitForChild("KickBall") :: RemoteEvent
local gameEvent = remotes:WaitForChild("GameEvent") :: RemoteEvent

local function make(className: string, properties: { [string]: any }): Instance
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		(instance :: any)[property] = value
	end
	return instance
end

local gui = make("ScreenGui", {
	Name = "FootballHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}) :: ScreenGui
gui.Parent = player:WaitForChild("PlayerGui")

local function roundedPanel(name: string, size: UDim2, position: UDim2, anchor: Vector2): Frame
	local panel = make("Frame", {
		Name = name,
		AnchorPoint = anchor,
		Size = size,
		Position = position,
		BackgroundColor3 = Color3.fromRGB(13, 23, 39),
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
	}) :: Frame
	panel.Parent = gui
	local corner = make("UICorner", { CornerRadius = UDim.new(0, 12) })
	corner.Parent = panel
	local stroke = make("UIStroke", {
		Color = Color3.fromRGB(129, 181, 255),
		Transparency = 0.38,
		Thickness = 1.25,
	})
	stroke.Parent = panel
	return panel
end

local scorePanel = roundedPanel("ScorePanel", UDim2.fromOffset(360, 78), UDim2.new(0.5, 0, 0, 22), Vector2.new(0.5, 0))
local scoreTitle = make("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 8),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Enum.Font.GothamBold,
	Text = "FOOTBALL FREE PLAY",
	TextColor3 = Color3.fromRGB(196, 220, 255),
	TextSize = 14,
}) :: TextLabel
scoreTitle.Parent = scorePanel

local scoreText = make("TextLabel", {
	Name = "Score",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 25),
	Size = UDim2.new(1, 0, 0, 42),
	Font = Enum.Font.GothamBlack,
	RichText = true,
	Text = "<font color=\"#62A8FF\">BLUE 0</font>  <font color=\"#FFFFFF\">–</font>  <font color=\"#FF7972\">0 RED</font>",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 25,
}) :: TextLabel
scoreText.Parent = scorePanel

local helpPanel = roundedPanel("HelpPanel", UDim2.fromOffset(315, 130), UDim2.new(0, 22, 1, -22), Vector2.new(0, 1))
local helpHeader = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 12),
	Size = UDim2.new(1, -32, 0, 22),
	Font = Enum.Font.GothamBlack,
	Text = "HOW TO PLAY",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 230, 119),
	TextSize = 16,
}) :: TextLabel
helpHeader.Parent = helpPanel
local helpText = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 39),
	Size = UDim2.new(1, -32, 1, -48),
	Font = Enum.Font.GothamMedium,
	Text = "WASD / thumbstick  Move\nSHIFT  Sprint\nQ  Pass     E  Kick     F or click  Shoot\nMove within 10 studs of the ball.",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(238, 243, 252),
	TextSize = 14,
	TextWrapped = true,
}) :: TextLabel
helpText.Parent = helpPanel

local statusPanel = roundedPanel("StatusPanel", UDim2.fromOffset(370, 50), UDim2.new(0.5, 0, 1, -36), Vector2.new(0.5, 1))
local statusText = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	Text = "FIND THE BALL",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 17,
	TextWrapped = true,
}) :: TextLabel
statusText.Parent = statusPanel

local statusVersion = 0
local function showStatus(text: string, color: Color3?, duration: number?)
	statusVersion += 1
	local version = statusVersion
	statusText.Text = text
	statusText.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	if duration then
		task.delay(duration, function()
			if version == statusVersion then
				statusText.Text = "FIND THE BALL"
				statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
	end
end

local function characterHumanoid(): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local sprinting = false
local function setSprinting(enabled: boolean)
	sprinting = enabled
	local humanoid = characterHumanoid()
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = if enabled then Config.Player.SprintSpeed else Config.Player.WalkSpeed
	end
end

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.WalkSpeed = if sprinting then Config.Player.SprintSpeed else Config.Player.WalkSpeed
	end
end)

local function kickDirection(): Vector3
	local humanoid = characterHumanoid()
	if humanoid and humanoid.MoveDirection.Magnitude > 0.05 then
		return humanoid.MoveDirection.Unit
	end

	local camera = Workspace.CurrentCamera
	if camera then
		local lookVector = camera.CFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatLook.Magnitude > 0.05 then
			return flatLook.Unit
		end
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.CFrame.LookVector
	end
	return Vector3.new(0, 0, 1)
end

local function tryKick(kickType: string)
	kickBall:FireServer(kickType, kickDirection())
end

local function bindKick(actionName: string, kickType: string, key: Enum.KeyCode, title: string, position: UDim2)
	ContextActionService:BindAction(actionName, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			tryKick(kickType)
		end
		return Enum.ContextActionResult.Sink
	end, true, key)
	ContextActionService:SetTitle(actionName, title)
	ContextActionService:SetPosition(actionName, position)
end

bindKick("FootballPass", "Pass", Enum.KeyCode.Q, "PASS", UDim2.new(1, -250, 1, -185))
bindKick("FootballKick", "Kick", Enum.KeyCode.E, "KICK", UDim2.new(1, -145, 1, -185))
bindKick("FootballShoot", "Shoot", Enum.KeyCode.F, "SHOOT", UDim2.new(1, -92, 1, -265))

ContextActionService:BindAction("FootballSprint", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		setSprinting(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		setSprinting(false)
	end
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("FootballSprint", "RUN")
ContextActionService:SetPosition("FootballSprint", UDim2.new(1, -250, 1, -270))

-- Mouse shooting mirrors the F key without intercepting clicks already consumed by interface buttons.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryKick("Shoot")
	end
end)

gameEvent.OnClientEvent:Connect(function(eventType: unknown, first: unknown, second: unknown, third: unknown)
	if eventType == "Score" and typeof(first) == "number" and typeof(second) == "number" then
		scoreText.Text = string.format(
			"<font color=\"#62A8FF\">BLUE %d</font>  <font color=\"#FFFFFF\">–</font>  <font color=\"#FF7972\">%d RED</font>",
			first,
			second
		)
		if typeof(third) == "string" then
			showStatus(third, Color3.fromRGB(255, 229, 112), 2.4)
		end
	elseif eventType == "Announcement" and typeof(first) == "string" then
		showStatus(first, Color3.fromRGB(255, 255, 255), 2)
	elseif eventType == "Feedback" and typeof(first) == "string" then
		showStatus(first, Color3.fromRGB(172, 220, 255), 1.2)
	end
end)

-- A small, local proximity prompt lets a player know when a kick will be accepted.
local distanceTimer = 0
RunService.RenderStepped:Connect(function(deltaTime)
	distanceTimer += deltaTime
	if distanceTimer < 0.25 then
		return
	end
	distanceTimer = 0

	local stadium = Workspace:FindFirstChild("FootballStadium")
	local ball = stadium and stadium:FindFirstChild("FootballBall")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local isBallStatus = statusText.Text == "FIND THE BALL"
		or statusText.Text:find("^BALL DISTANCE") ~= nil
		or statusText.Text:find("^IN RANGE") ~= nil
	if ball and ball:IsA("BasePart") and root and root:IsA("BasePart") and isBallStatus then
		local distance = (ball.Position - root.Position).Magnitude
		if distance <= Config.Ball.ControlRadius then
			statusText.Text = "IN RANGE — Q PASS  •  E KICK  •  F SHOOT"
			statusText.TextColor3 = Color3.fromRGB(205, 255, 181)
		else
			statusText.Text = string.format("BALL DISTANCE  %d STUDS", math.floor(distance + 0.5))
			statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	elseif isBallStatus then
		statusText.Text = "FIND THE BALL"
	end
end)
