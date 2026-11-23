--!strict
-- Builds a low-poly island valley using Roblox Terrain only.

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

-- Bright, stylised daytime lighting for the island landscape.
pcall(function()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(118, 135, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 170, 190)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.25
end)

local function fillBlock(position: Vector3, size: Vector3, material: Enum.Material)
	terrain:FillBlock(CFrame.new(position), size, material)
end

local function fillBall(position: Vector3, radius: number, material: Enum.Material)
	terrain:FillBall(position, radius, material)
end

-- A deep ocean surrounds the playable island. Land placed afterward cuts a natural coast into it.
fillBlock(Vector3.new(0, -30, 0), Vector3.new(900, 60, 900), Enum.Material.Water)

-- Build a broad, walkable grass island with a softer, varied coastline.
local islandRadius = 185
local cellSize = 12
for x = -islandRadius, islandRadius, cellSize do
	for z = -islandRadius, islandRadius, cellSize do
		local distance = math.sqrt(x * x + z * z)
		if distance < islandRadius then
			local edge = 1 - distance / islandRadius
			local noise = math.noise(x * 0.025, z * 0.025) * 4
			local height = 5 + edge * 18 + noise

			-- Keep the central area gentle enough to play on, with higher land toward the rim.
			local valley = math.exp(-((x / 78) ^ 2 + ((z - 20) / 68) ^ 2))
			height -= valley * 12
			height = math.max(height, 2)

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

-- Three large cliff formations shape the valley without adding buildings or props.
local cliffs = {
	{ Vector3.new(-88, 18, -112), 62 },
	{ Vector3.new(12, 25, -145), 72 },
	{ Vector3.new(106, 15, -96), 58 },
}
for _, cliff in cliffs do
	local position = cliff[1] :: Vector3
	local radius = cliff[2] :: number
	fillBall(position, radius, Enum.Material.Rock)
	fillBall(position + Vector3.new(0, radius * 0.58, 0), radius * 0.58, Enum.Material.Grass)
end

-- Terrain-water waterfall flowing down the central rear cliff into the valley stream.
fillBlock(Vector3.new(12, 43, -145), Vector3.new(22, 68, 4), Enum.Material.Water)
fillBlock(Vector3.new(12, 4, -75), Vector3.new(14, 5, 145), Enum.Material.Water)

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
