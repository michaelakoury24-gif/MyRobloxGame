--!strict
-- Builds a self-contained football stadium map with stands and a player-proof perimeter barrier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
	Vector3.new(240, 6, 190),
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

-- Goals stay inside the perimeter and use simple bright white posts.
local function goal(side: number)
	local x = side * HALF_LENGTH
	local halfGoalWidth = 19
	for _, z in { -halfGoalWidth, halfGoalWidth } do
		createPart("GoalPost", Vector3.new(0.75, 14, 0.75), CFrame.new(x, 8, z), lineColor, Enum.Material.Metal, true)
	end
	createPart("GoalCrossbar", Vector3.new(0.75, 0.75, halfGoalWidth * 2), CFrame.new(x, 15, 0), lineColor, Enum.Material.Metal, true)
end
goal(-1)
goal(1)

-- Five stepped seating tiers on each sideline create two full grandstands.
local seatColours = {
	Color3.fromRGB(52, 119, 214),
	Color3.fromRGB(220, 76, 74),
	Color3.fromRGB(241, 194, 75),
	Color3.fromRGB(69, 172, 110),
	Color3.fromRGB(132, 94, 196),
}
local standStructure = Color3.fromRGB(36, 46, 61)

local function grandstand(side: number)
	for row = 0, 4 do
		local height = 3 + row * 1.25
		local y = height / 2
		local z = side * (HALF_WIDTH + 8 + row * 5)
		createPart(
			"StandStructure",
			Vector3.new(FIELD_LENGTH + 22, height, 5.5),
			CFrame.new(0, y, z),
			standStructure,
			Enum.Material.Metal,
			true
		)
		createPart(
			"SeatTier",
			Vector3.new(FIELD_LENGTH + 17, 0.45, 4.4),
			CFrame.new(0, height + 0.25, z),
			seatColours[row + 1],
			Enum.Material.SmoothPlastic,
			true
		)
	end

	local railZ = side * (HALF_WIDTH + 3.5)
	createPart("StandRail", Vector3.new(FIELD_LENGTH + 24, 1.1, 0.22), CFrame.new(0, 2.6, railZ), Color3.fromRGB(218, 228, 238), Enum.Material.Metal, false)
	createPart(
		"StandRoof",
		Vector3.new(FIELD_LENGTH + 28, 0.6, 17),
		CFrame.new(0, 15.5, side * (HALF_WIDTH + 19)),
		Color3.fromRGB(28, 35, 48),
		Enum.Material.Metal,
		true
	)
end
grandstand(-1)
grandstand(1)

-- A tall transparent barrier completely encloses the pitch and seating area.
-- It is collidable on every side, so players cannot walk or jump out of the map.
local barrierColor = Color3.fromRGB(111, 221, 255)
local barrierHeight = 28
local barrierY = barrierHeight / 2
local barrierHalfX = 113
local barrierHalfZ = 88
createPart("WestBarrier", Vector3.new(2, barrierHeight, barrierHalfZ * 2), CFrame.new(-barrierHalfX, barrierY, 0), barrierColor, Enum.Material.Glass, true, 0.48)
createPart("EastBarrier", Vector3.new(2, barrierHeight, barrierHalfZ * 2), CFrame.new(barrierHalfX, barrierY, 0), barrierColor, Enum.Material.Glass, true, 0.48)
createPart("NorthBarrier", Vector3.new(barrierHalfX * 2, barrierHeight, 2), CFrame.new(0, barrierY, -barrierHalfZ), barrierColor, Enum.Material.Glass, true, 0.48)
createPart("SouthBarrier", Vector3.new(barrierHalfX * 2, barrierHeight, 2), CFrame.new(0, barrierY, barrierHalfZ), barrierColor, Enum.Material.Glass, true, 0.48)

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
