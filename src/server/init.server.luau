--!strict
-- Builds a self-contained football stadium map with stands and a player-proof perimeter barrier.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("FootballConfig"))

-- Delete all terrain and objects from the previous island / football versions.
Workspace.Terrain:Clear()
for _, name in {
	"Baseplate",
	"LandscapeSpawn",
	"CartoonTerrain",
	"FootballPitch",
	"FootballStadium",
	"PitchMap",
} do
	local object = Workspace:FindFirstChild(name)
	if object then
		object:Destroy()
	end
end

local oldRemotes = ReplicatedStorage:FindFirstChild("FootballRemotes")
if oldRemotes then
	oldRemotes:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "FootballRemotes"
remotes.Parent = ReplicatedStorage

local ballAction = Instance.new("RemoteEvent")
ballAction.Name = "BallAction"
ballAction.Parent = remotes

local gameEvent = Instance.new("RemoteEvent")
gameEvent.Name = "GameEvent"
gameEvent.Parent = remotes

local stadium = Instance.new("Folder")
stadium.Name = "PitchMap"
stadium.Parent = Workspace

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanTouch = false
	if not canCollide then
		part.CanQuery = false
	end
	part.CastShadow = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = stadium
	return part
end

local FIELD_LENGTH = 190
local FIELD_WIDTH = 120
local HALF_LENGTH = FIELD_LENGTH / 2
local HALF_WIDTH = FIELD_WIDTH / 2
local GRASS_Y = 0.5
local LINE_Y = 1.05
local grassLight = Color3.fromRGB(60, 168, 82)
local grassDark = Color3.fromRGB(47, 145, 70)
local lineColor = Color3.fromRGB(250, 252, 250)

-- The base and striped grass pitch form the playable map floor.
createPart(
	"StadiumFoundation",
	Vector3.new(320, 6, 260),
	CFrame.new(0, -3, 0),
	Color3.fromRGB(49, 57, 68),
	Enum.Material.Concrete,
	true
)

local stripeWidth = 19
for index = 0, 9 do
	local x = -HALF_LENGTH + stripeWidth * index + stripeWidth / 2
	createPart(
		"GrassStripe",
		Vector3.new(stripeWidth + 0.1, 1, FIELD_WIDTH),
		CFrame.new(x, GRASS_Y, 0),
		if index % 2 == 0 then grassLight else grassDark,
		Enum.Material.SmoothPlastic,
		true
	)
end

local function line(name: string, size: Vector3, position: Vector3)
	return createPart(name, size, CFrame.new(position), lineColor, Enum.Material.SmoothPlastic, false)
end

-- Crisp field markings.
line("NorthTouchline", Vector3.new(FIELD_LENGTH + 0.5, 0.12, 0.35), Vector3.new(0, LINE_Y, -HALF_WIDTH))
line("SouthTouchline", Vector3.new(FIELD_LENGTH + 0.5, 0.12, 0.35), Vector3.new(0, LINE_Y, HALF_WIDTH))
line("WestGoalLine", Vector3.new(0.35, 0.12, FIELD_WIDTH), Vector3.new(-HALF_LENGTH, LINE_Y, 0))
line("EastGoalLine", Vector3.new(0.35, 0.12, FIELD_WIDTH), Vector3.new(HALF_LENGTH, LINE_Y, 0))
line("HalfwayLine", Vector3.new(0.35, 0.12, FIELD_WIDTH), Vector3.new(0, LINE_Y, 0))
line("CentreSpot", Vector3.new(2, 0.12, 2), Vector3.new(0, LINE_Y, 0))

local function penaltyBox(side: number)
	local goalX = side * HALF_LENGTH
	local backX = goalX - side * 19
	line("PenaltyBoxBack", Vector3.new(0.35, 0.12, 56), Vector3.new(backX, LINE_Y, 0))
	line("PenaltyBoxTop", Vector3.new(19, 0.12, 0.35), Vector3.new((goalX + backX) / 2, LINE_Y, -28))
	line("PenaltyBoxBottom", Vector3.new(19, 0.12, 0.35), Vector3.new((goalX + backX) / 2, LINE_Y, 28))
end
penaltyBox(-1)
penaltyBox(1)

-- Full goals with back and side nets. The translucent fabric planes plus grid strands
-- make the nets clear from both the pitch and the new end stands.
local function goal(side: number)
	local x = side * HALF_LENGTH
	local goalDepth = 8
	local backX = x + side * goalDepth
	local halfGoalWidth = 19
	local goalHeight = 14
	local netColor = Color3.fromRGB(231, 242, 249)

	for _, z in { -halfGoalWidth, halfGoalWidth } do
		createPart("GoalPost", Vector3.new(0.75, goalHeight, 0.75), CFrame.new(x, 8, z), lineColor, Enum.Material.Metal, true)
		createPart("NetSupport", Vector3.new(0.45, goalHeight, 0.45), CFrame.new(backX, 8, z), lineColor, Enum.Material.Metal, true)
	end
	createPart("GoalCrossbar", Vector3.new(0.75, 0.75, halfGoalWidth * 2), CFrame.new(x, 15, 0), lineColor, Enum.Material.Metal, true)
	createPart("NetBackBar", Vector3.new(0.45, 0.45, halfGoalWidth * 2), CFrame.new(backX, 15, 0), lineColor, Enum.Material.Metal, true)

	local backNet = createPart("GoalNetBack", Vector3.new(0.16, goalHeight, halfGoalWidth * 2), CFrame.new(backX, 8, 0), netColor, Enum.Material.Fabric, false, 0.5)
	backNet.CastShadow = false
	local roofNet = createPart("GoalNetRoof", Vector3.new(goalDepth, 0.16, halfGoalWidth * 2), CFrame.new((x + backX) / 2, 15, 0), netColor, Enum.Material.Fabric, false, 0.58)
	roofNet.CastShadow = false
	for _, z in { -halfGoalWidth, halfGoalWidth } do
		local sideNet = createPart("GoalNetSide", Vector3.new(goalDepth, goalHeight, 0.16), CFrame.new((x + backX) / 2, 8, z), netColor, Enum.Material.Fabric, false, 0.58)
		sideNet.CastShadow = false
	end

	-- Fine net grid across the rear panel.
	for z = -halfGoalWidth + 4, halfGoalWidth - 4, 4 do
		createPart("NetVertical", Vector3.new(0.24, goalHeight, 0.1), CFrame.new(backX - side * 0.12, 8, z), netColor, Enum.Material.SmoothPlastic, false, 0.22)
	end
	for y = 3, goalHeight - 1, 3 do
		createPart("NetHorizontal", Vector3.new(0.24, 0.1, halfGoalWidth * 2), CFrame.new(backX - side * 0.12, y, 0), netColor, Enum.Material.SmoothPlastic, false, 0.22)
	end
end
goal(-1)
goal(1)

-- A complete four-sided stadium: stepped concrete tiers, individual seats, rails,
-- support columns, and roofs wrap around all four edges of the pitch.
local seatColours = {
	Color3.fromRGB(45, 109, 207),
	Color3.fromRGB(204, 69, 65),
	Color3.fromRGB(238, 187, 59),
	Color3.fromRGB(55, 159, 97),
	Color3.fromRGB(122, 83, 182),
}
local standStructure = Color3.fromRGB(51, 59, 72)
local concreteColour = Color3.fromRGB(110, 119, 130)
local roofColour = Color3.fromRGB(28, 35, 48)
local railColour = Color3.fromRGB(222, 232, 240)
local STAND_ROWS = 5

local function seatColour(row: number, column: number): Color3
	return seatColours[((row + math.floor(column / 3) - 1) % #seatColours) + 1]
end

local function buildSideSeats(side: number)
	for row = 0, STAND_ROWS - 1 do
		local height = 3 + row * 1.35
		local z = side * (HALF_WIDTH + 8 + row * 5.2)
		createPart("SideStandTier", Vector3.new(FIELD_LENGTH + 24, height, 5.8), CFrame.new(0, height / 2, z), concreteColour, Enum.Material.Concrete, true)
		createPart("SideStandWalkway", Vector3.new(FIELD_LENGTH + 20, 0.35, 5), CFrame.new(0, height + 0.2, z), standStructure, Enum.Material.Metal, true)

		for column = -10, 10 do
			local x = column * 9
			createPart(
				"StadiumSeat",
				Vector3.new(7.1, 0.8, 3.1),
				CFrame.new(x, height + 0.72, z - side * 0.35),
				seatColour(row + 1, column + 11),
				Enum.Material.SmoothPlastic,
				true
			)
		end
	end

	local railZ = side * (HALF_WIDTH + 3.4)
	createPart("SideStandRail", Vector3.new(FIELD_LENGTH + 25, 1.2, 0.22), CFrame.new(0, 2.6, railZ), railColour, Enum.Material.Metal, false)
	for x = -96, 96, 32 do
		createPart("SideRoofColumn", Vector3.new(1.15, 16, 1.15), CFrame.new(x, 8, side * (HALF_WIDTH + 25)), standStructure, Enum.Material.Metal, true)
	end
	createPart("SideStandRoof", Vector3.new(FIELD_LENGTH + 30, 0.65, 19), CFrame.new(0, 16, side * (HALF_WIDTH + 20)), roofColour, Enum.Material.Metal, true)
end

local function buildEndSeats(side: number)
	local endSpan = FIELD_WIDTH + 18
	for row = 0, STAND_ROWS - 1 do
		local height = 3 + row * 1.35
		local x = side * (HALF_LENGTH + 17 + row * 5.2)
		createPart("EndStandTier", Vector3.new(5.8, height, endSpan), CFrame.new(x, height / 2, 0), concreteColour, Enum.Material.Concrete, true)
		createPart("EndStandWalkway", Vector3.new(5, 0.35, endSpan - 4), CFrame.new(x, height + 0.2, 0), standStructure, Enum.Material.Metal, true)

		for column = -7, 7 do
			local z = column * 8.5
			createPart(
				"StadiumSeat",
				Vector3.new(3.1, 0.8, 6.6),
				CFrame.new(x - side * 0.35, height + 0.72, z),
				seatColour(row + 1, column + 8),
				Enum.Material.SmoothPlastic,
				true
			)
		end
	end

	local railX = side * (HALF_LENGTH + 12.4)
	createPart("EndStandRail", Vector3.new(0.22, 1.2, endSpan + 2), CFrame.new(railX, 2.6, 0), railColour, Enum.Material.Metal, false)
	for z = -56, 56, 28 do
		createPart("EndRoofColumn", Vector3.new(1.15, 16, 1.15), CFrame.new(side * (HALF_LENGTH + 35), 8, z), standStructure, Enum.Material.Metal, true)
	end
	createPart("EndStandRoof", Vector3.new(19, 0.65, endSpan + 6), CFrame.new(side * (HALF_LENGTH + 30), 16, 0), roofColour, Enum.Material.Metal, true)
end

buildSideSeats(-1)
buildSideSeats(1)
buildEndSeats(-1)
buildEndSeats(1)

-- Inner pitch barrier: this separates the playable grass from the stands. It leaves
-- room for both goal nets, while keeping players on the pitch instead of in the seating.
local innerBarrierColor = Color3.fromRGB(200, 239, 255)
local innerBarrierHeight = 14
local innerBarrierY = innerBarrierHeight / 2
local innerHalfX = HALF_LENGTH + 11
local innerHalfZ = HALF_WIDTH + 3
createPart("InnerWestBarrier", Vector3.new(1.2, innerBarrierHeight, innerHalfZ * 2), CFrame.new(-innerHalfX, innerBarrierY, 0), innerBarrierColor, Enum.Material.Glass, true, 0.58)
createPart("InnerEastBarrier", Vector3.new(1.2, innerBarrierHeight, innerHalfZ * 2), CFrame.new(innerHalfX, innerBarrierY, 0), innerBarrierColor, Enum.Material.Glass, true, 0.58)
createPart("InnerNorthBarrier", Vector3.new(innerHalfX * 2, innerBarrierHeight, 1.2), CFrame.new(0, innerBarrierY, -innerHalfZ), innerBarrierColor, Enum.Material.Glass, true, 0.58)
createPart("InnerSouthBarrier", Vector3.new(innerHalfX * 2, innerBarrierHeight, 1.2), CFrame.new(0, innerBarrierY, innerHalfZ), innerBarrierColor, Enum.Material.Glass, true, 0.58)

-- A tall transparent barrier completely encloses the pitch and seating area.
-- It is collidable on every side, so players cannot walk or jump out of the map.
local barrierColor = Color3.fromRGB(111, 221, 255)
local barrierHeight = 38
local barrierY = barrierHeight / 2
local barrierHalfX = 150
local barrierHalfZ = 118
createPart("WestBarrier", Vector3.new(2, barrierHeight, barrierHalfZ * 2), CFrame.new(-barrierHalfX, barrierY, 0), barrierColor, Enum.Material.Glass, true, 0.48)
createPart("EastBarrier", Vector3.new(2, barrierHeight, barrierHalfZ * 2), CFrame.new(barrierHalfX, barrierY, 0), barrierColor, Enum.Material.Glass, true, 0.48)
createPart("NorthBarrier", Vector3.new(barrierHalfX * 2, barrierHeight, 2), CFrame.new(0, barrierY, -barrierHalfZ), barrierColor, Enum.Material.Glass, true, 0.48)
createPart("SouthBarrier", Vector3.new(barrierHalfX * 2, barrierHeight, 2), CFrame.new(0, barrierY, barrierHalfZ), barrierColor, Enum.Material.Glass, true, 0.48)

-- A compact black-and-white football. It uses free physics when unclaimed and a
-- responsive, non-welded AlignPosition dribble while under a player's possession.
local BALL_START = CFrame.new(0, 1 + Config.Ball.Radius + 0.06, 0)
local ball = Instance.new("Part")
ball.Name = "Football"
ball.Shape = Enum.PartType.Ball
ball.Size = Vector3.new(Config.Ball.Radius * 2, Config.Ball.Radius * 2, Config.Ball.Radius * 2)
ball.CFrame = BALL_START
ball.Anchored = false
ball.CanCollide = true
ball.CanTouch = true
ball.CanQuery = true
ball.CastShadow = true
ball.Color = Color3.fromRGB(248, 248, 242)
ball.Material = Enum.Material.SmoothPlastic
ball.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.58, 0.28, 1, 1)
ball.Parent = stadium

-- Dark panels closely match the black-and-white football reference while remaining
-- fully procedural (no external Roblox asset upload is required).
local panelOffsets = {
	Vector3.new(0, 0, -1.02),
	Vector3.new(0.9, 0.22, -0.4),
	Vector3.new(-0.9, 0.22, -0.4),
	Vector3.new(0.56, -0.72, 0.5),
	Vector3.new(-0.56, -0.72, 0.5),
	Vector3.new(0, 0.87, 0.55),
}
for index, offset in ipairs(panelOffsets) do
	local panel = Instance.new("Part")
	panel.Name = "FootballPanel" .. index
	panel.Shape = Enum.PartType.Ball
	panel.Size = Vector3.new(0.5, 0.5, 0.5)
	panel.Position = ball.Position + offset
	panel.Anchored = false
	panel.CanCollide = false
	panel.CanTouch = false
	panel.CanQuery = false
	panel.Massless = true
	panel.Color = Color3.fromRGB(22, 24, 29)
	panel.Material = Enum.Material.SmoothPlastic
	panel.Parent = stadium

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball
	weld.Part1 = panel
	weld.Parent = panel
end

local ballGlow = Instance.new("Highlight")
ballGlow.Name = "BallOutline"
ballGlow.Adornee = ball
ballGlow.FillTransparency = 1
ballGlow.OutlineColor = Color3.fromRGB(18, 22, 30)
ballGlow.OutlineTransparency = 0.08
ballGlow.Parent = ball

local ballAttachment = Instance.new("Attachment")
ballAttachment.Name = "DribbleAttachment"
ballAttachment.Parent = ball

local holder: Player? = nil
local followConstraint: AlignPosition? = nil
local lastAction: { [Player]: number } = {}
local lastTackle: { [Player]: number } = {}
local resetting = false

local function setServerOwnership()
	pcall(function()
		ball:SetNetworkOwner(nil)
	end)
end

local function getCharacterState(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return character, nil, nil
	end
	return character, humanoid, root
end

local function horizontalDirection(direction: Vector3?): Vector3?
	if not direction then
		return nil
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		return nil
	end
	return flat.Unit
end

local function notifyPossession()
	if holder then
		gameEvent:FireAllClients("Possession", holder.UserId, holder.DisplayName)
	else
		gameEvent:FireAllClients("Possession", 0, "")
	end
end

local function clearDribble(velocity: Vector3?)
	if followConstraint then
		followConstraint:Destroy()
		followConstraint = nil
	end

	ball.CanCollide = true
	ball:SetAttribute("PossessorUserId", 0)
	holder = nil
	ball.AssemblyLinearVelocity = velocity or Vector3.zero
	setServerOwnership()
	notifyPossession()
end

local function releaseBall()
	if holder or followConstraint then
		clearDribble()
	end
end

local function setDribbleTarget(root: BasePart, humanoid: Humanoid)
	if not followConstraint then
		return
	end

	local movement = horizontalDirection(humanoid.MoveDirection)
	local facing = horizontalDirection(root.CFrame.LookVector) or Vector3.new(0, 0, -1)
	local direction = movement or facing
	-- A modest extra lead while running makes turns responsive without a welded/floating look.
	local lead = Config.Ball.DribbleDistance + math.min(humanoid.MoveDirection.Magnitude * 0.35, 0.35)
	local target = root.Position + direction * lead

	-- Use the actual grass surface below the player so the ball stays at foot height
	-- instead of sinking into or hovering above uneven geometry.
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { root.Parent, ball }
	local ground = Workspace:Raycast(target + Vector3.new(0, 7, 0), Vector3.new(0, -16, 0), raycastParams)
	local targetY = if ground then ground.Position.Y + Config.Ball.Radius + 0.06 else root.Position.Y + Config.Ball.DribbleHeightOffset
	followConstraint.Position = Vector3.new(target.X, targetY, target.Z)
end

local function startDribbling(player: Player, character: Model, maxDistance: number?): boolean
	if resetting or holder then
		return false
	end

	local _, humanoid, root = getCharacterState(player)
	if not humanoid or not root then
		return false
	end
	if (ball.Position - root.Position).Magnitude > (maxDistance or Config.Ball.ControlRange) then
		return false
	end

	holder = player
	ball.CanCollide = false
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero

	followConstraint = Instance.new("AlignPosition")
	followConstraint.Name = "FootballDribbleFollow"
	followConstraint.Attachment0 = ballAttachment
	followConstraint.Mode = Enum.PositionAlignmentMode.OneAttachment
	followConstraint.ApplyAtCenterOfMass = true
	followConstraint.MaxForce = Config.Ball.DribbleMaxForce
	followConstraint.MaxVelocity = 42
	followConstraint.Responsiveness = Config.Ball.DribbleResponsiveness
	followConstraint.RigidityEnabled = false
	followConstraint.Parent = ball
	setDribbleTarget(root, humanoid)

	ball:SetAttribute("PossessorUserId", player.UserId)
	setServerOwnership()
	notifyPossession()
	humanoid.Died:Once(releaseBall)
	return true
end

local function resetBall()
	if resetting then
		return
	end
	resetting = true
	releaseBall()
	ball.Anchored = true
	ball.CanCollide = false
	ball.CFrame = BALL_START
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero
	gameEvent:FireAllClients("Reset")

	task.delay(Config.Ball.ResetDelay, function()
		if not ball.Parent then
			return
		end
		ball.CanCollide = true
		ball.Anchored = false
		resetting = false
		setServerOwnership()
	end)
end

local function validHolder(player: Player): (Humanoid?, BasePart?)
	if holder ~= player or resetting then
		return nil, nil
	end
	local _, humanoid, root = getCharacterState(player)
	if not humanoid or not root or (ball.Position - root.Position).Magnitude > Config.Ball.ControlRange + 2 then
		return nil, nil
	end
	return humanoid, root
end

local function kickBall(player: Player, kind: "Shoot" | "Pass", requestedDirection: unknown, requestedCharge: unknown)
	local humanoid, root = validHolder(player)
	if not humanoid or not root then
		gameEvent:FireClient(player, "Feedback", "GET POSSESSION FIRST")
		return
	end

	local now = os.clock()
	local cooldown = if kind == "Shoot" then Config.Shot.Cooldown else Config.Pass.Cooldown
	if now - (lastAction[player] or 0) < cooldown then
		return
	end
	lastAction[player] = now

	local direction = if typeof(requestedDirection) == "Vector3" then horizontalDirection(requestedDirection) else nil
	direction = direction or horizontalDirection(root.CFrame.LookVector)
	if not direction then
		return
	end

	local velocity: Vector3
	if kind == "Shoot" then
		local charge = if typeof(requestedCharge) == "number" then math.clamp(requestedCharge, 0, 1) else 0
		local speed = Config.Shot.MinSpeed + (Config.Shot.MaxSpeed - Config.Shot.MinSpeed) * charge
		local lift = Config.Shot.MinLift + (Config.Shot.MaxLift - Config.Shot.MinLift) * charge
		velocity = direction * speed + Vector3.new(0, lift, 0)
	else
		velocity = direction * Config.Pass.Speed + Vector3.new(0, Config.Pass.Lift, 0)
	end

	clearDribble(velocity)
	ball.AssemblyAngularVelocity = Vector3.new(-direction.Z, 0, direction.X) * (if kind == "Shoot" then 34 else 22)
	gameEvent:FireClient(player, "Feedback", if kind == "Shoot" then "SHOT!" else "PASS!")
end

local function slideTackle(player: Player, requestedDirection: unknown)
	local character, humanoid, root = getCharacterState(player)
	if not character or not humanoid or not root or resetting then
		return
	end

	local now = os.clock()
	if now - (lastTackle[player] or 0) < Config.Tackle.Cooldown then
		gameEvent:FireClient(player, "Feedback", "TACKLE RECHARGING")
		return
	end
	lastTackle[player] = now

	local direction = if typeof(requestedDirection) == "Vector3" then horizontalDirection(requestedDirection) else nil
	direction = direction or horizontalDirection(root.CFrame.LookVector)
	if not direction then
		return
	end

	-- A brief low, controlled slide. No vertical force is applied, avoiding unpredictable launches.
	local oldHipHeight = humanoid.HipHeight
	local oldAutoRotate = humanoid.AutoRotate
	humanoid.HipHeight = math.max(0, oldHipHeight - 0.85)
	humanoid.AutoRotate = false
	local slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.Name = "TackleSlide"
	slideVelocity.MaxForce = Vector3.new(70000, 0, 70000)
	slideVelocity.P = 2600
	slideVelocity.Velocity = direction * Config.Tackle.SlideSpeed
	slideVelocity.Parent = root

	task.delay(Config.Tackle.SlideDuration, function()
		if slideVelocity.Parent then
			slideVelocity:Destroy()
		end
		if humanoid.Parent then
			humanoid.HipHeight = oldHipHeight
			humanoid.AutoRotate = oldAutoRotate
		end
	end)

	if holder and holder ~= player then
		local targetCharacter, _, targetRoot = getCharacterState(holder)
		if targetCharacter and targetRoot and (targetRoot.Position - root.Position).Magnitude <= Config.Tackle.Range then
			clearDribble()
			if startDribbling(player, character, Config.Tackle.Range + 1) then
				gameEvent:FireAllClients("Tackle", player.UserId)
			end
		end
	elseif not holder and (ball.Position - root.Position).Magnitude <= Config.Tackle.Range then
		if startDribbling(player, character, Config.Tackle.Range) then
			gameEvent:FireAllClients("Tackle", player.UserId)
		end
	end
end

ball.Touched:Connect(function(otherPart: BasePart)
	if holder or resetting then
		return
	end
	local character = otherPart:FindFirstAncestorOfClass("Model")
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		startDribbling(player, character)
	end
end)

ballAction.OnServerEvent:Connect(function(player: Player, action: unknown, direction: unknown, amount: unknown)
	if action == "Shoot" then
		kickBall(player, "Shoot", direction, amount)
	elseif action == "Pass" then
		kickBall(player, "Pass", direction, nil)
	elseif action == "Tackle" then
		slideTackle(player, direction)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if holder then
		local _, humanoid, root = getCharacterState(holder)
		if not humanoid or not root then
			releaseBall()
		else
			setDribbleTarget(root, humanoid)
		end
	elseif not resetting then
		local velocity = ball.AssemblyLinearVelocity
		local flatVelocity = Vector3.new(velocity.X, 0, velocity.Z)
		if ball.Position.Y <= 2.4 and flatVelocity.Magnitude > 0.05 then
			local multiplier = Config.Ball.FreeFriction ^ (deltaTime * 60)
			flatVelocity *= multiplier
			if flatVelocity.Magnitude > Config.Ball.MaxFreeSpeed then
				flatVelocity = flatVelocity.Unit * Config.Ball.MaxFreeSpeed
			end
			ball.AssemblyLinearVelocity = Vector3.new(flatVelocity.X, velocity.Y, flatVelocity.Z)
		end
	end

	if not resetting then
		local position = ball.Position
		if position.Y < -15 or math.abs(position.X) > Config.Ball.OutOfBoundsX or math.abs(position.Z) > Config.Ball.OutOfBoundsZ then
			resetBall()
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player == holder then
		releaseBall()
	end
	lastAction[player] = nil
	lastTackle[player] = nil
end)

setServerOwnership()

-- Invisible spawn surface at midfield; players always appear on the pitch.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "PitchSpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.AllowTeamChangeOnTouch = false
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 2, 0)
spawn.Parent = stadium
