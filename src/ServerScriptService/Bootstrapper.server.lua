--[[
	Bootstrapper.lua
	Initializes all server systems on game start
	Location: ServerScriptService > Bootstrapper
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require config
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

-- Require core modules
local Core = ServerScriptService.Core
local TeamManager = require(Core.TeamManager)
local RoundManager = require(Core.RoundManager)
local MapManager = require(Core.MapManager)
local InventoryManager = require(Core.InventoryManager)
local EconomyManager = require(Core.EconomyManager)
local HitDetection = require(Core.HitDetection)
local GameModeController = require(Core.GameModeController)

-- Get remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryEvent = Remotes:WaitForChild("GetInventory")
local GetEconomyEvent = Remotes:WaitForChild("GetEconomy")
local EquipWeaponEvent = Remotes:WaitForChild("EquipWeapon")
local SpawnPlayerEvent = Remotes:WaitForChild("SpawnPlayer")
local TogglePracticeModeEvent = Remotes:WaitForChild("TogglePracticeMode")
local PracticeModeUpdateEvent = Remotes:WaitForChild("PracticeModeUpdate")

print("==============================================")
print("         FPS Game Server Starting...         ")
print("==============================================")

-- Build weapons FIRST (before any systems try to use them)
local WeaponBuilder = require(Core.WeaponBuilder)

-- Initialize teams
TeamManager.Initialize()

-- Initialize map manager
MapManager.Initialize()

-- Initialize game mode controller
GameModeController.Initialize()

-- Initialize round manager
RoundManager.Initialize()

-- Initialize hit detection
HitDetection.Initialize()

-- Handle get inventory request
GetInventoryEvent.OnServerInvoke = function(player)
	return InventoryManager.GetInventoryData(player)
end

-- Handle get economy request
GetEconomyEvent.OnServerInvoke = function(player)
	return EconomyManager.GetEconomyData(player)
end

-- Handle equip weapon request
EquipWeaponEvent.OnServerEvent:Connect(function(player, weaponId)
	print(string.format("[Server] %s requesting to equip weapon: %s", player.Name, weaponId))

	-- Equip weapon in inventory
	local success = InventoryManager.EquipWeapon(player, weaponId)

	if success then
		print(string.format("[Server] Successfully set equipped weapon for %s", player.Name))
		-- Note: Weapon will be equipped when player spawns
	end
end)

-- Handle spawn player request
SpawnPlayerEvent.OnServerEvent:Connect(function(player)
	print(string.format("[Server] %s requesting to spawn", player.Name))

	-- Check if round is active (Intermission or Playing) OR practice mode is enabled
	local roundState = RoundManager.GetState()
	if roundState ~= "Intermission" and roundState ~= "Playing" and not GameConfig.PRACTICE_MODE then
		warn(string.format("[Server] Cannot spawn %s - round not active (state: %s)", player.Name, roundState))
		return
	end

	-- Clear any existing weapons before spawning
	if player.Character then
		for _, tool in pairs(player.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end

		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end
	end

	-- Respawn the player
	TeamManager.RespawnPlayer(player, true)

	-- Wait a moment for character to fully load, then equip weapon
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.1)

		-- Equip their selected weapon
		TeamManager.EquipWeapon(player)
	end)
end)

-- Handle practice mode toggle
TogglePracticeModeEvent.OnServerEvent:Connect(function(player, forceEnable)
	print(string.format("[Server] %s requesting practice mode", player.Name))

	-- If forceEnable is provided, set to that value; otherwise toggle
	if forceEnable ~= nil then
		GameConfig.PRACTICE_MODE = forceEnable
	else
		GameConfig.PRACTICE_MODE = not GameConfig.PRACTICE_MODE
	end

	-- Notify all clients
	PracticeModeUpdateEvent:FireAllClients(GameConfig.PRACTICE_MODE)

	print(string.format("[Server] Practice mode is now: %s", GameConfig.PRACTICE_MODE and "ON" or "OFF"))
end)

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print(string.format("[Server] Player joined: %s (UserId: %d)", player.Name, player.UserId))

	-- Initialize inventory
	InventoryManager.InitializePlayer(player)

	-- Initialize economy
	EconomyManager.InitializePlayer(player)

	-- Assign to team
	TeamManager.AssignTeam(player)

	-- Setup death handling
	TeamManager.SetupDeathHandling(player)

	-- Load character but don't spawn them in-game yet
	-- They will spawn from Main Menu when they click Play
	player:LoadCharacter()
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	print(string.format("[Server] Player left: %s", player.Name))

	-- Save and cleanup inventory
	InventoryManager.CleanupPlayer(player)

	-- Save and cleanup economy
	EconomyManager.CleanupPlayer(player)

	-- Clean up player data
	if TeamManager.PlayerData[player.UserId] then
		TeamManager.PlayerData[player.UserId] = nil
	end
end)

print("[Server] Initialization complete!")
print("==============================================")
