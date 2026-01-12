--[[
	MapManager.lua
	Handles map loading, unloading, and rotation
	Location: ServerScriptService > Core > MapManager
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local MapManager = {}
MapManager.CurrentMap = nil
MapManager.CurrentMapName = nil

-- Initialize map manager
function MapManager.Initialize()
	print("[MapManager] Initialized")

	-- Ensure Maps folder exists
	if not Workspace:FindFirstChild("Maps") then
		local mapsFolder = Instance.new("Folder")
		mapsFolder.Name = "Maps"
		mapsFolder.Parent = Workspace
		print("[MapManager] Created Maps folder in Workspace")
	end
end

-- Load a map into the workspace
function MapManager.LoadMap(mapName)
	print(string.format("[MapManager] Loading map: %s", mapName))

	-- Unload current map first
	if MapManager.CurrentMap then
		MapManager.UnloadMap()
	end

	-- Find map in Workspace > Maps or ServerStorage
	local mapSource = Workspace.Maps:FindFirstChild(mapName)

	if not mapSource then
		-- Try ServerStorage as fallback
		local ServerStorage = game:GetService("ServerStorage")
		if ServerStorage:FindFirstChild("MapTemplates") then
			mapSource = ServerStorage.MapTemplates:FindFirstChild(mapName)
		end
	end

	if not mapSource then
		warn(string.format("[MapManager] Map '%s' not found!", mapName))
		return false
	end

	-- Clone map into Workspace
	local mapClone = mapSource:Clone()
	mapClone.Name = "CurrentMap"
	mapClone.Parent = Workspace

	MapManager.CurrentMap = mapClone
	MapManager.CurrentMapName = mapName

	print(string.format("[MapManager] Successfully loaded map: %s", mapName))
	return true
end

-- Unload the current map
function MapManager.UnloadMap()
	if MapManager.CurrentMap then
		print(string.format("[MapManager] Unloading map: %s", MapManager.CurrentMapName))
		MapManager.CurrentMap:Destroy()
		MapManager.CurrentMap = nil
		MapManager.CurrentMapName = nil
	end
end

-- Get spawn points for a team
function MapManager.GetTeamSpawns(teamName)
	if not MapManager.CurrentMap then
		warn("[MapManager] No map loaded!")
		return {}
	end

	-- Look for spawn locations in current map
	local spawnLocations = MapManager.CurrentMap:FindFirstChild("SpawnLocations")
	if not spawnLocations then
		warn("[MapManager] Current map has no SpawnLocations folder!")
		return {}
	end

	-- Determine which team spawns to get
	local spawnFolderName
	if teamName == GameConfig.TEAM_1_NAME then
		spawnFolderName = "Team1Spawns"
	elseif teamName == GameConfig.TEAM_2_NAME then
		spawnFolderName = "Team2Spawns"
	else
		warn(string.format("[MapManager] Unknown team name: %s", teamName))
		return {}
	end

	local teamSpawns = spawnLocations:FindFirstChild(spawnFolderName)
	if not teamSpawns then
		warn(string.format("[MapManager] No spawn folder found for %s", spawnFolderName))
		return {}
	end

	-- Collect all spawn points
	local spawns = {}
	for _, spawn in pairs(teamSpawns:GetChildren()) do
		if spawn:IsA("BasePart") or spawn:IsA("SpawnLocation") then
			table.insert(spawns, spawn)
		end
	end

	return spawns
end

-- Get a random spawn point for a team
function MapManager.GetRandomSpawn(teamName)
	local spawns = MapManager.GetTeamSpawns(teamName)

	if #spawns == 0 then
		warn(string.format("[MapManager] No spawns found for team: %s", teamName))
		return nil
	end

	-- Return random spawn
	local randomIndex = math.random(1, #spawns)
	return spawns[randomIndex]
end

-- Get game mode objects for current map
function MapManager.GetGameModeObjects(objectType)
	if not MapManager.CurrentMap then
		warn("[MapManager] No map loaded!")
		return {}
	end

	local gameModeObjects = MapManager.CurrentMap:FindFirstChild("GameModeObjects")
	if not gameModeObjects then
		warn("[MapManager] Current map has no GameModeObjects folder!")
		return {}
	end

	local objectFolder = gameModeObjects:FindFirstChild(objectType)
	if not objectFolder then
		warn(string.format("[MapManager] No %s folder found in map", objectType))
		return {}
	end

	-- Collect all objects
	local objects = {}
	for _, obj in pairs(objectFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(objects, obj)
		end
	end

	return objects
end

-- Select a random map from available maps
function MapManager.SelectRandomMap()
	local maps = GameConfig.AVAILABLE_MAPS
	if #maps == 0 then
		warn("[MapManager] No maps available in config!")
		return nil
	end

	local randomIndex = math.random(1, #maps)
	return maps[randomIndex]
end

-- Get current map name
function MapManager.GetCurrentMapName()
	return MapManager.CurrentMapName
end

-- Check if a map is loaded
function MapManager.IsMapLoaded()
	return MapManager.CurrentMap ~= nil
end

return MapManager
