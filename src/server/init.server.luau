--!strict
-- Builds a soft, cartoony island valley using Roblox Terrain only.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local terrain = Workspace.Terrain

-- Remove the old football game objects and the starter baseplate.
for _, name in {
	"Baseplate",
	"FootballPitch",
	"FootballStadium",
	"FootballRemotes",
	"LandscapeSpawn",
	"CartoonTerrain",
} do
	local object = Workspace:FindFirstChild(name) or game:GetService("ReplicatedStorage"):FindFirstChild(name)
	if object then
		object:Destroy()
	end
end

terrain:Clear()

-- Keep the terrain surfaces clean and smooth, with a bright cartoon-water colour.
pcall(function()
	terrain.Decoration = false
	terrain.WaterColor = Color3.fromRGB(31, 178, 236)
	terrain.WaterTransparency = 0.2
	terrain.WaterWaveSize = 0.18
	terrain.WaterWaveSpeed = 8
end)

-- Sunny, saturated lighting gives the grass and water a softer cartoon appearance.
pcall(function()
	Lighting.ClockTime = 11.5
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(135, 154, 178)
	Lighting.OutdoorAmbient = Color3.fromRGB(166, 190, 210)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.15
end)

local function fillBlock(position: Vector3, size: Vector3, material: Enum.Material)
	terrain:FillBlock(CFrame.new(position), size, material)
end

-- A deep ocean surrounds the playable island. Land placed afterward cuts a natural coast into it.
fillBlock(Vector3.new(0, -30, 0), Vector3.new(900, 60, 900), Enum.Material.Water)

-- Build a broad, walkable grass island. Smaller terrain cells and low-frequency noise
-- keep the valley soft rather than creating the jagged, blocky ground of the first pass.
local islandRadius = 190
local cellSize = 8
for x = -islandRadius, islandRadius, cellSize do
	for z = -islandRadius, islandRadius, cellSize do
		local distance = math.sqrt(x * x + z * z)
		if distance < islandRadius then
			local edge = 1 - distance / islandRadius
			local noise = math.noise(x * 0.009, z * 0.009) * 0.7
			-- Keep the base terrain intentionally low and even. Rounded smooth-plastic
			-- mountains are layered above it below, avoiding the jagged terrain-rock walls.
			local height = 7 + (edge ^ 1.6) * 8 + noise
			height = math.max(height, 5)

			fillBlock(
				Vector3.new(x, height / 2 - 12, z),
				Vector3.new(cellSize + 1, height + 24, cellSize + 1),
				Enum.Material.Rock
			)
			fillBlock(
				Vector3.new(x, height - 1.5, z),
				Vector3.new(cellSize + 1, 4, cellSize + 1),
				if height < 6 then Enum.Material.Sand else Enum.Material.Grass
			)
		end
	end
end

-- Smooth-plastic landscape forms replace the noisy terrain-rock walls. Their rounded
-- silhouettes and flat colours give the mountains a clean, balanced cartoon look.
local cartoonTerrain = Instance.new("Folder")
cartoonTerrain.Name = "CartoonTerrain"
cartoonTerrain.Parent = Workspace

local function createLandscapePart(
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?,
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
	part.Color = color
	part.Material = material
	part.Size = size
	part.Position = position
	part.Transparency = transparency or 0
	if shape then
		part.Shape = shape
	end
	part.Parent = cartoonTerrain
	return part
end

local grassColours = {
	Color3.fromRGB(91, 190, 82),
	Color3.fromRGB(104, 204, 91),
	Color3.fromRGB(78, 177, 76),
}
local rockColour = Color3.fromRGB(74, 103, 119)

local function createCartoonMountain(index: number, position: Vector3, size: Vector3)
	-- A low smooth rock skirt grounds the mountain without the sharp Terrain rock texture.
	createLandscapePart(
		"MountainRock" .. index,
		position + Vector3.new(0, size.Y * 0.25, 0),
		Vector3.new(size.X, size.Y * 0.62, size.Z),
		rockColour,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball,
		true
	)
	-- Two overlapping green forms make a soft, rounded grassy mountain instead of a rough cliff.
	createLandscapePart(
		"MountainGrass" .. index,
		position + Vector3.new(0, size.Y * 0.53, 0),
		Vector3.new(size.X * 0.96, size.Y * 0.66, size.Z * 0.96),
		grassColours[((index - 1) % #grassColours) + 1],
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball,
		true
	)
	createLandscapePart(
		"MountainTop" .. index,
		position + Vector3.new(0, size.Y * 0.88, 0),
		Vector3.new(size.X * 0.57, size.Y * 0.42, size.Z * 0.57),
		grassColours[((index + 1) % #grassColours) + 1],
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball,
		true
	)
end

-- A balanced ring leaves a broad open valley in the middle instead of enclosing the player in walls.
local mountains = {
	{ Vector3.new(-126, 4, -110), Vector3.new(132, 92, 108) },
	{ Vector3.new(-24, 4, -162), Vector3.new(158, 112, 98) },
	{ Vector3.new(94, 4, -116), Vector3.new(132, 92, 108) },
	{ Vector3.new(-160, 4, -2), Vector3.new(98, 70, 94) },
	{ Vector3.new(160, 4, -2), Vector3.new(98, 70, 94) },
}
for index, mountain in mountains do
	createCartoonMountain(index, mountain[1] :: Vector3, mountain[2] :: Vector3)
end

-- A clean translucent waterfall and stream retain the terrain-only landscape focus.
createLandscapePart(
	"Waterfall",
	Vector3.new(-24, 51, -166),
	Vector3.new(20, 96, 2),
	Color3.fromRGB(93, 214, 255),
	Enum.Material.Glass,
	nil,
	false,
	0.2
)
fillBlock(Vector3.new(-18, 5, -82), Vector3.new(14, 6, 160), Enum.Material.Water)

-- Small smooth floating landforms keep the distant reference-inspired silhouette uncluttered.
local floatingIslands = {
	{ Vector3.new(-175, 112, -120), Vector3.new(40, 24, 34) },
	{ Vector3.new(156, 128, -80), Vector3.new(46, 28, 38) },
	{ Vector3.new(-112, 145, 132), Vector3.new(34, 21, 29) },
	{ Vector3.new(138, 106, 126), Vector3.new(38, 23, 32) },
}
for index, island in floatingIslands do
	local position = island[1] :: Vector3
	local size = island[2] :: Vector3
	createLandscapePart("FloatingRock" .. index, position, size, rockColour, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
	createLandscapePart(
		"FloatingGrass" .. index,
		position + Vector3.new(0, size.Y * 0.3, 0),
		Vector3.new(size.X * 0.82, size.Y * 0.6, size.Z * 0.82),
		grassColours[((index + 1) % #grassColours) + 1],
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball,
		false
	)
end

-- An invisible spawn marker keeps players safely above the central valley terrain.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "LandscapeSpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.AllowTeamChangeOnTouch = false
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 28, 38)
spawn.Parent = Workspace

local function placeCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if root and root:IsA("BasePart") then
		task.wait(0.15)
		if character.Parent then
			character:PivotTo(CFrame.new(0, 31, 38))
		end
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(placeCharacter)
	if player.Character then
		task.spawn(placeCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
