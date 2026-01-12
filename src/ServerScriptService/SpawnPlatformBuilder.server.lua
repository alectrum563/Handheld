--[[
	SpawnPlatformBuilder.server.lua
	Creates basic spawn platforms for testing (until maps are built)
	Location: ServerScriptService > SpawnPlatformBuilder
]]

local workspace = game:GetService("Workspace")

print("[SpawnPlatformBuilder] Building test spawn platforms...")

-- Create Team 1 spawn platform (Red Team - left side)
local team1Platform = Instance.new("Part")
team1Platform.Name = "Team1Platform"
team1Platform.Size = Vector3.new(50, 1, 50)
team1Platform.Position = Vector3.new(-50, 0, 0)
team1Platform.Anchored = true
team1Platform.Color = Color3.fromRGB(255, 100, 100) -- Red
team1Platform.Material = Enum.Material.Concrete
team1Platform.Parent = workspace

-- Create Team 2 spawn platform (Blue Team - right side)
local team2Platform = Instance.new("Part")
team2Platform.Name = "Team2Platform"
team2Platform.Size = Vector3.new(50, 1, 50)
team2Platform.Position = Vector3.new(50, 0, 0)
team2Platform.Anchored = true
team2Platform.Color = Color3.fromRGB(100, 100, 255) -- Blue
team2Platform.Material = Enum.Material.Concrete
team2Platform.Parent = workspace

-- Create center platform (neutral ground)
local centerPlatform = Instance.new("Part")
centerPlatform.Name = "CenterPlatform"
centerPlatform.Size = Vector3.new(80, 1, 80)
centerPlatform.Position = Vector3.new(0, 0, 0)
centerPlatform.Anchored = true
centerPlatform.Color = Color3.fromRGB(150, 150, 150) -- Gray
centerPlatform.Material = Enum.Material.Concrete
centerPlatform.Parent = workspace

-- Create some walls for wall-jump testing
local function createWall(name, position, size)
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Color = Color3.fromRGB(100, 100, 100)
	wall.Material = Enum.Material.Brick
	wall.Parent = workspace
end

createWall("Wall1", Vector3.new(-30, 5, 0), Vector3.new(1, 10, 20))
createWall("Wall2", Vector3.new(30, 5, 0), Vector3.new(1, 10, 20))
createWall("Wall3", Vector3.new(0, 5, 30), Vector3.new(20, 10, 1))
createWall("Wall4", Vector3.new(0, 5, -30), Vector3.new(20, 10, 1))

print("[SpawnPlatformBuilder] Test platforms created!")
print("[SpawnPlatformBuilder] - Red Team platform at (-50, 0, 0)")
print("[SpawnPlatformBuilder] - Blue Team platform at (50, 0, 0)")
print("[SpawnPlatformBuilder] - Center arena at (0, 0, 0)")
print("[SpawnPlatformBuilder] - 4 walls for wall-jump testing")
