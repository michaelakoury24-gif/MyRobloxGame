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

local function fillBall(position: Vector3, radius: number, material: Enum.Material)
	terrain:FillBall(position, radius, material)
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
			local noise = math.noise(x * 0.011, z * 0.011) * 1.8
			local height = 10 + (edge ^ 1.45) * 20 + noise

			-- A wide, gentle valley stays clear for the player while the rim becomes soft foothills.
			local valley = math.exp(-((x / 88) ^ 2 + ((z - 24) / 78) ^ 2))
			height -= valley * 15
			height = math.max(height, 4)

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

-- Rounded, layered mountains give the skyline a clean cartoon silhouette. Most of each
-- mountain is grass, with only a small rock skirt showing near the base.
local mountains = {
	{ Vector3.new(-118, 18, -112), 76 },
	{ Vector3.new(-22, 24, -156), 86 },
	{ Vector3.new(94, 18, -121), 72 },
	{ Vector3.new(142, 12, -18), 58 },
	{ Vector3.new(-150, 12, -12), 56 },
}
for _, mountain in mountains do
	local position = mountain[1] :: Vector3
	local radius = mountain[2] :: number
	fillBall(position, radius, Enum.Material.Rock)
	fillBall(position + Vector3.new(0, radius * 0.34, 0), radius * 0.82, Enum.Material.Grass)
	fillBall(position + Vector3.new(0, radius * 0.94, 0), radius * 0.42, Enum.Material.Grass)
end

-- Terrain-water waterfall flowing from the tallest rear mountain into the valley stream.
fillBlock(Vector3.new(-22, 52, -156), Vector3.new(23, 104, 5), Enum.Material.Water)
fillBlock(Vector3.new(-12, 5, -77), Vector3.new(16, 6, 160), Enum.Material.Water)

-- A few terrain-only floating islands echo the distant sky islands in the reference.
local floatingIslands = {
	{ Vector3.new(-175, 112, -120), 21 },
	{ Vector3.new(156, 128, -80), 25 },
	{ Vector3.new(-112, 145, 132), 17 },
	{ Vector3.new(138, 106, 126), 19 },
}
for _, island in floatingIslands do
	local position = island[1] :: Vector3
	local radius = island[2] :: number
	fillBall(position, radius, Enum.Material.Rock)
	fillBall(position + Vector3.new(0, radius * 0.5, 0), radius * 0.58, Enum.Material.Grass)
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
