--!strict
-- Football game server: builds the stadium and owns all ball physics/scoring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local FIELD_LENGTH = Config.Field.Length
local FIELD_WIDTH = Config.Field.Width
local HALF_LENGTH = FIELD_LENGTH / 2
local HALF_WIDTH = FIELD_WIDTH / 2
local GOAL_WIDTH = Config.Field.GoalWidth
local GOAL_HEIGHT = Config.Field.GoalHeight

-- Every client asks the server to kick; the server validates distance, rate, and kick type.
local remoteFolder = ReplicatedStorage:FindFirstChild("FootballRemotes")
if remoteFolder then
	remoteFolder:Destroy()
end
remoteFolder = Instance.new("Folder")
remoteFolder.Name = "FootballRemotes"
remoteFolder.Parent = ReplicatedStorage

local kickBall = Instance.new("RemoteEvent")
kickBall.Name = "KickBall"
kickBall.Parent = remoteFolder

local gameEvent = Instance.new("RemoteEvent")
gameEvent.Name = "GameEvent"
gameEvent.Parent = remoteFolder

local function create(className: string, properties: { [string]: any }): Instance
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		(instance :: any)[property] = value
	end
	return instance
end

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	local part = create("Part", {
		Name = name,
		Anchored = true,
		CanCollide = canCollide,
		CanTouch = false,
		CastShadow = false,
		Color = color,
		Material = material,
		Size = size,
		CFrame = cframe,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}) :: Part
	-- Set CanQuery after CanCollide. Setting these together in an unordered property
	-- table can make Roblox reject a non-collidable line before CanCollide is applied.
	part.CanQuery = canCollide
	part.Parent = parent
	return part
end

local stadium = Workspace:FindFirstChild("FootballStadium")
if stadium then
	stadium:Destroy()
end
stadium = Instance.new("Folder")
stadium.Name = "FootballStadium"
stadium.Parent = Workspace

-- Keep the default baseplate until the pitch has been built below. If a later asset
-- has a problem, players still have a floor instead of falling into the void.
local oldBaseplate = Workspace:FindFirstChild("Baseplate")

-- FallenPartsDestroyHeight is Studio-capability protected in this project context.
-- The pitch has its own ball-reset check below, so do not set that Workspace property here.
Lighting.ClockTime = 15.2
Lighting.Brightness = 2.5
Lighting.Ambient = Color3.fromRGB(100, 110, 125)
Lighting.OutdoorAmbient = Color3.fromRGB(135, 145, 160)
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.25

-- Stadium shell and field surface.
local scenery = Instance.new("Folder")
scenery.Name = "StadiumScenery"
scenery.Parent = stadium

createPart(
	scenery,
	"StadiumFoundation",
	Vector3.new(FIELD_LENGTH + 54, 5, FIELD_WIDTH + 54),
	CFrame.new(0, -3, 0),
	Color3.fromRGB(68, 76, 82),
	Enum.Material.Concrete,
	true
)

local grass = Instance.new("Folder")
grass.Name = "Pitch"
grass.Parent = stadium

local stripeWidth = 10
for stripe = 0, math.ceil(FIELD_LENGTH / stripeWidth) - 1 do
	local width = math.min(stripeWidth, FIELD_LENGTH - stripe * stripeWidth)
	local x = -HALF_LENGTH + stripe * stripeWidth + width / 2
	createPart(
		grass,
		"MownStripe",
		Vector3.new(width, Config.Field.GrassHeight, FIELD_WIDTH),
		CFrame.new(x, -0.5, 0),
		if stripe % 2 == 0 then Color3.fromRGB(44, 138, 68) else Color3.fromRGB(50, 151, 73),
		Enum.Material.Grass,
		true
	)
end

-- The green pitch is now a safe, collidable floor, so the starter baseplate can go.
if oldBaseplate then
	oldBaseplate:Destroy()
end

local lines = Instance.new("Folder")
lines.Name = "PitchMarkings"
lines.Parent = stadium
local lineColor = Color3.fromRGB(245, 248, 245)
local LINE_THICKNESS = 0.35
local LINE_Y = 0.05

local function line(name: string, size: Vector3, position: Vector3)
	return createPart(lines, name, size, CFrame.new(position), lineColor, Enum.Material.SmoothPlastic, false)
end

-- Outer boundary and halfway line.
line("NorthTouchline", Vector3.new(FIELD_LENGTH + LINE_THICKNESS, 0.12, LINE_THICKNESS), Vector3.new(0, LINE_Y, -HALF_WIDTH))
line("SouthTouchline", Vector3.new(FIELD_LENGTH + LINE_THICKNESS, 0.12, LINE_THICKNESS), Vector3.new(0, LINE_Y, HALF_WIDTH))
line("WestGoalLine", Vector3.new(LINE_THICKNESS, 0.12, FIELD_WIDTH), Vector3.new(-HALF_LENGTH, LINE_Y, 0))
line("EastGoalLine", Vector3.new(LINE_THICKNESS, 0.12, FIELD_WIDTH), Vector3.new(HALF_LENGTH, LINE_Y, 0))
line("HalfwayLine", Vector3.new(LINE_THICKNESS, 0.12, FIELD_WIDTH), Vector3.new(0, LINE_Y, 0))

-- Centre circle built from small straight field-marking segments.
local function createCircle(name: string, centre: Vector3, radius: number)
	local segments = 40
	for index = 0, segments - 1 do
		local a = (index / segments) * math.pi * 2
		local b = ((index + 1) / segments) * math.pi * 2
		local pointA = centre + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		local pointB = centre + Vector3.new(math.cos(b) * radius, 0, math.sin(b) * radius)
		local midpoint = (pointA + pointB) / 2
		local segment = createPart(
			lines,
			name,
			Vector3.new(LINE_THICKNESS, 0.12, (pointA - pointB).Magnitude + LINE_THICKNESS),
			CFrame.lookAt(midpoint, pointB),
			lineColor,
			Enum.Material.SmoothPlastic,
			false
		)
		segment.CanQuery = false
	end
end

createCircle("CentreCircle", Vector3.new(0, LINE_Y, 0), 16)
createCircle("CentreSpot", Vector3.new(0, LINE_Y, 0), 0.9)

local function createPenaltyBox(side: number)
	local goalX = side * HALF_LENGTH
	local largeBoxX = goalX - side * 18
	local smallBoxX = goalX - side * 7

	line("PenaltyBoxBack", Vector3.new(LINE_THICKNESS, 0.12, 54), Vector3.new(largeBoxX, LINE_Y, 0))
	line("PenaltyBoxTop", Vector3.new(18, 0.12, LINE_THICKNESS), Vector3.new((goalX + largeBoxX) / 2, LINE_Y, -27))
	line("PenaltyBoxBottom", Vector3.new(18, 0.12, LINE_THICKNESS), Vector3.new((goalX + largeBoxX) / 2, LINE_Y, 27))

	line("GoalBoxBack", Vector3.new(LINE_THICKNESS, 0.12, 28), Vector3.new(smallBoxX, LINE_Y, 0))
	line("GoalBoxTop", Vector3.new(7, 0.12, LINE_THICKNESS), Vector3.new((goalX + smallBoxX) / 2, LINE_Y, -14))
	line("GoalBoxBottom", Vector3.new(7, 0.12, LINE_THICKNESS), Vector3.new((goalX + smallBoxX) / 2, LINE_Y, 14))

	createCircle("PenaltySpot", Vector3.new(goalX - side * 12, LINE_Y, 0), 0.7)
end

createPenaltyBox(-1)
createPenaltyBox(1)

-- Goals, including light netting so the scoring area is easy to read.
local goalFolder = Instance.new("Folder")
goalFolder.Name = "Goals"
goalFolder.Parent = stadium

local function createGoal(side: number)
	local goalX = side * HALF_LENGTH
	local backX = goalX + side * Config.Field.GoalDepth
	local halfGoal = GOAL_WIDTH / 2
	local postColor = Color3.fromRGB(252, 252, 252)
	local netColor = Color3.fromRGB(215, 230, 240)

	createPart(goalFolder, "GoalPost", Vector3.new(0.7, GOAL_HEIGHT, 0.7), CFrame.new(goalX, GOAL_HEIGHT / 2, -halfGoal), postColor, Enum.Material.Metal, true)
	createPart(goalFolder, "GoalPost", Vector3.new(0.7, GOAL_HEIGHT, 0.7), CFrame.new(goalX, GOAL_HEIGHT / 2, halfGoal), postColor, Enum.Material.Metal, true)
	createPart(goalFolder, "Crossbar", Vector3.new(0.7, 0.7, GOAL_WIDTH), CFrame.new(goalX, GOAL_HEIGHT, 0), postColor, Enum.Material.Metal, true)

	local backNet = createPart(goalFolder, "GoalNet", Vector3.new(0.15, GOAL_HEIGHT, GOAL_WIDTH), CFrame.new(backX, GOAL_HEIGHT / 2, 0), netColor, Enum.Material.Fabric, false)
	backNet.Transparency = 0.45
	local roofNet = createPart(goalFolder, "GoalNetRoof", Vector3.new(Config.Field.GoalDepth, 0.15, GOAL_WIDTH), CFrame.new((goalX + backX) / 2, GOAL_HEIGHT, 0), netColor, Enum.Material.Fabric, false)
	roofNet.Transparency = 0.55
	for _, z in { -halfGoal, halfGoal } do
		local sideNet = createPart(goalFolder, "GoalNetSide", Vector3.new(Config.Field.GoalDepth, GOAL_HEIGHT, 0.15), CFrame.new((goalX + backX) / 2, GOAL_HEIGHT / 2, z), netColor, Enum.Material.Fabric, false)
		sideNet.Transparency = 0.55
	end
end

createGoal(-1)
createGoal(1)

-- Tiered spectator stands run along both sidelines. The coloured tiers read as seats
-- from the pitch while the dark structure makes the stadium feel enclosed.
local standStructureColor = Color3.fromRGB(29, 39, 55)
local seatColors = {
	Color3.fromRGB(50, 121, 220),
	Color3.fromRGB(220, 74, 69),
	Color3.fromRGB(242, 195, 71),
	Color3.fromRGB(48, 171, 104),
	Color3.fromRGB(137, 96, 201),
}

local function createGrandstand(side: number)
	local standWidth = FIELD_LENGTH + 34
	for row = 0, 4 do
		local z = side * (HALF_WIDTH + 7 + row * 5.2)
		local y = 1.4 + row * 2.2
		local structure = createPart(
			scenery,
			"GrandstandStructure",
			Vector3.new(standWidth, 2.8 + row * 0.45, 5.4),
			CFrame.new(0, y, z),
			standStructureColor,
			Enum.Material.Metal,
			true
		)
		structure.CastShadow = true

		local seatTop = y + (2.8 + row * 0.45) / 2 + 0.18
		createPart(
			scenery,
			"SeatTier",
			Vector3.new(standWidth - 3, 0.35, 4.35),
			CFrame.new(0, seatTop, z),
			seatColors[row + 1],
			Enum.Material.SmoothPlastic,
			true
		)
	end

	local railZ = side * (HALF_WIDTH + 3.9)
	createPart(
		scenery,
		"PitchSideRail",
		Vector3.new(standWidth, 1.15, 0.22),
		CFrame.new(0, 2.3, railZ),
		Color3.fromRGB(218, 228, 235),
		Enum.Material.Metal,
		false
	)
	createPart(
		scenery,
		"GrandstandRoof",
		Vector3.new(standWidth + 4, 0.5, 18),
		CFrame.new(0, 14.5, side * (HALF_WIDTH + 18)),
		Color3.fromRGB(22, 29, 40),
		Enum.Material.Metal,
		true
	)
end

createGrandstand(-1)
createGrandstand(1)

for _, x in { -HALF_LENGTH - 18, HALF_LENGTH + 18 } do
	for _, z in { -HALF_WIDTH - 13, HALF_WIDTH + 13 } do
		local pole = createPart(scenery, "FloodlightPole", Vector3.new(1.2, 27, 1.2), CFrame.new(x, 13.5, z), Color3.fromRGB(85, 91, 98), Enum.Material.Metal, true)
		pole.Shape = Enum.PartType.Cylinder
		local lamp = createPart(scenery, "Floodlight", Vector3.new(6, 1.2, 2.5), CFrame.new(x, 27, z), Color3.fromRGB(255, 245, 195), Enum.Material.Neon, false)
		local light = Instance.new("PointLight")
		light.Brightness = 1.2
		light.Range = 42
		light.Color = Color3.fromRGB(255, 247, 218)
		light.Parent = lamp
	end
end

-- Spawn pads put players on opposing halves. Their Neutral setting lets everyone use either pad.
local spawns = Instance.new("Folder")
spawns.Name = "PlayerSpawns"
spawns.Parent = stadium
local spawnPositions = {
	Vector3.new(-32, Config.Player.SpawnHeight, -20),
	Vector3.new(32, Config.Player.SpawnHeight, 20),
}
for index, position in ipairs(spawnPositions) do
	local spawn = create("SpawnLocation", {
		Name = "PlayerSpawn" .. index,
		Anchored = true,
		CanCollide = true,
		Neutral = true,
		AllowTeamChangeOnTouch = false,
		Duration = 0,
		Size = Vector3.new(10, 1, 10),
		Position = position - Vector3.new(0, Config.Player.SpawnHeight - 0.5, 0),
		Color = if index == 1 then Color3.fromRGB(49, 119, 220) else Color3.fromRGB(220, 74, 69),
		Material = Enum.Material.Neon,
		Transparency = 0.28,
	}) :: SpawnLocation
	spawn.Parent = spawns
end

-- FootballPitch is a permanent, source-controlled ground under the dynamic stadium.
-- It remains in play as a fail-safe floor even if a later decorative object has a problem.

-- Physical ball. It is server-owned so each kick has the same outcome for every player.
local ball = create("Part", {
	Name = "FootballBall",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(Config.Ball.Radius * 2, Config.Ball.Radius * 2, Config.Ball.Radius * 2),
	Position = Vector3.new(0, Config.Ball.Radius + 0.2, 0),
	Anchored = false,
	CanCollide = true,
	CanTouch = true,
	CanQuery = true,
	CastShadow = true,
	Color = Color3.fromRGB(248, 248, 241),
	Material = Enum.Material.SmoothPlastic,
	CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.4, 0.5, 1, 1),
}) :: Part
ball.Parent = stadium

local highlight = Instance.new("Highlight")
highlight.Name = "BallGlow"
highlight.Adornee = ball
highlight.FillColor = Color3.fromRGB(255, 232, 113)
highlight.FillTransparency = 0.75
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.OutlineTransparency = 0.15
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Parent = ball

local trailAttachment0 = Instance.new("Attachment")
trailAttachment0.Position = Vector3.new(-0.4, 0, 0)
trailAttachment0.Parent = ball
local trailAttachment1 = Instance.new("Attachment")
trailAttachment1.Position = Vector3.new(0.4, 0, 0)
trailAttachment1.Parent = ball
local trail = Instance.new("Trail")
trail.Attachment0 = trailAttachment0
trail.Attachment1 = trailAttachment1
trail.Lifetime = 0.18
trail.MinLength = 3
trail.Color = ColorSequence.new(Color3.fromRGB(255, 250, 200), Color3.fromRGB(255, 255, 255))
trail.Transparency = NumberSequence.new(0.35, 1)
trail.Parent = ball

pcall(function()
	ball:SetNetworkOwner(nil)
end)

-- Physical scoreboard at the end of the north stand.
local scoreboard = createPart(
	scenery,
	"Scoreboard",
	Vector3.new(44, 15, 1),
	CFrame.new(0, 17, -HALF_WIDTH - 21) * CFrame.Angles(0, math.rad(180), 0),
	Color3.fromRGB(13, 20, 32),
	Enum.Material.Metal,
	true
)
local boardGui = Instance.new("SurfaceGui")
boardGui.Name = "ScoreDisplay"
boardGui.Face = Enum.NormalId.Front
boardGui.CanvasSize = Vector2.new(1000, 340)
boardGui.LightInfluence = 0
boardGui.Parent = scoreboard
local boardText = Instance.new("TextLabel")
boardText.Size = UDim2.fromScale(1, 1)
boardText.BackgroundTransparency = 1
boardText.Font = Enum.Font.GothamBlack
boardText.TextColor3 = Color3.fromRGB(245, 247, 255)
boardText.TextScaled = true
boardText.RichText = true
boardText.Parent = boardGui

local score = {
	Blue = 0,
	Red = 0,
}
local resetting = false
local lastKick: { [Player]: number } = {}

local function setScoreboard(message: string?)
	boardText.Text = string.format(
		"<font color=\"#62A8FF\">BLUE %d</font>  -  <font color=\"#FF7972\">%d RED</font>\n<font size=\"34\">%s</font>",
		score.Blue,
		score.Red,
		message or "FIRST TO THE BALL"
	)
end

local function sendScore(message: string)
	setScoreboard(message)
	gameEvent:FireAllClients("Score", score.Blue, score.Red, message)
end

local function resetBall(delay: number, message: string?)
	if resetting then
		return
	end

	resetting = true
	ball.Anchored = true
	ball.CanCollide = false
	ball.Transparency = 0.55
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero

	if message then
		gameEvent:FireAllClients("Announcement", message)
	end

	task.delay(delay, function()
		if not ball.Parent then
			return
		end
		ball.CFrame = CFrame.new(0, Config.Ball.Radius + 0.2, 0)
		ball.Transparency = 0
		ball.CanCollide = true
		ball.Anchored = false
		pcall(function()
			ball:SetNetworkOwner(nil)
		end)
		resetting = false
		gameEvent:FireAllClients("Announcement", "PLAY ON!")
	end)
end

local function scoreGoal(team: "Blue" | "Red")
	if resetting then
		return
	end

	if team == "Blue" then
		score.Blue += 1
	else
		score.Red += 1
	end
	local message = team:upper() .. " SCORES!"
	sendScore(message)
	resetBall(2.5, message)
end

setScoreboard()

kickBall.OnServerEvent:Connect(function(player: Player, kickType: unknown, requestedDirection: unknown)
	if resetting or typeof(kickType) ~= "string" then
		return
	end

	if kickType ~= "Pass" and kickType ~= "Kick" and kickType ~= "Shoot" then
		return
	end
	local kick = Config.Kicks[kickType]

	local now = os.clock()
	if now - (lastKick[player] or 0) < Config.Ball.KickCooldown then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end

	local playerToBall = ball.Position - root.Position
	if playerToBall.Magnitude > Config.Ball.ControlRadius then
		gameEvent:FireClient(player, "Feedback", "GET CLOSER TO THE BALL")
		return
	end

	local direction: Vector3
	if typeof(requestedDirection) == "Vector3" then
		direction = requestedDirection
	else
		direction = root.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.05 then
		direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	if direction.Magnitude < 0.05 then
		return
	end

	lastKick[player] = now
	local flatDirection = direction.Unit
	local desiredVelocity = flatDirection * kick.Speed + Vector3.new(0, kick.Lift, 0)
	-- Preserve a little existing momentum, but cap every client request to the configured kick speed.
	ball.AssemblyLinearVelocity = desiredVelocity + ball.AssemblyLinearVelocity * 0.12
	ball.AssemblyAngularVelocity = Vector3.new(-flatDirection.Z, 0, flatDirection.X) * 22
	pcall(function()
		ball:SetNetworkOwner(nil)
	end)

	gameEvent:FireClient(player, "Feedback", string.upper(kickType) .. "!")
end)

Players.PlayerRemoving:Connect(function(player)
	lastKick[player] = nil
end)

-- A player gets a clean spawn point instead of the old baseplate spawn.
local function moveCharacterToPitch(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if not root or not root:IsA("BasePart") then
		return
	end
	local spawnPosition = spawnPositions[(player.UserId % #spawnPositions) + 1]
	task.wait(0.15)
	if character.Parent and root.Parent then
		character:PivotTo(CFrame.new(spawnPosition) * CFrame.Angles(0, if spawnPosition.X < 0 then math.rad(90) else math.rad(-90), 0))
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		moveCharacterToPitch(player, character)
	end)
	if player.Character then
		task.spawn(moveCharacterToPitch, player, player.Character)
	end
	task.delay(1, function()
		if player.Parent then
			gameEvent:FireClient(player, "Score", score.Blue, score.Red, "GET CLOSE TO THE BALL AND PLAY")
			gameEvent:FireClient(player, "Announcement", "Q PASS  •  E KICK  •  F SHOOT")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Goal detection and a gentle out-of-bounds reset.
RunService.Heartbeat:Connect(function()
	if resetting or not ball.Parent then
		return
	end

	local position = ball.Position
	local inGoalMouth = math.abs(position.Z) < GOAL_WIDTH / 2 - 0.5 and position.Y < GOAL_HEIGHT + 1
	if inGoalMouth and position.X >= HALF_LENGTH - 0.5 then
		scoreGoal("Blue")
		return
	elseif inGoalMouth and position.X <= -HALF_LENGTH + 0.5 then
		scoreGoal("Red")
		return
	end

	if position.Y < Config.Ball.ResetHeight or math.abs(position.X) > HALF_LENGTH + 25 or math.abs(position.Z) > HALF_WIDTH + 25 then
		resetBall(Config.Ball.ResetDelay, "BALL RETURNING TO CENTRE")
	end
end)
