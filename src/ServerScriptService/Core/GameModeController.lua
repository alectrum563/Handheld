--[[
	GameModeController.lua
	Manages the current game mode and handles mode switching
	Location: ServerScriptService > Core > GameModeController
]]

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

-- Import game modes
local GameModes = ServerScriptService.Core.GameModes
local TeamDeathmatch = require(GameModes.TeamDeathmatch)

local GameModeController = {}

-- State
GameModeController.CurrentMode = nil
GameModeController.AvailableModes = {}
GameModeController.UpdateConnection = nil

-- Initialize game mode controller
function GameModeController.Initialize()
	print("[GameModeController] Initializing...")

	-- Register available game modes
	GameModeController.RegisterModes()

	-- Setup update loop
	GameModeController.SetupUpdateLoop()

	print("[GameModeController] Initialized")
end

-- Register all available game modes
function GameModeController.RegisterModes()
	-- Register Team Deathmatch
	GameModeController.AvailableModes["TeamDeathmatch"] = TeamDeathmatch

	print(string.format("[GameModeController] Registered %d game modes",
		#GameModeController.GetAvailableModeNames()))
end

-- Setup update loop for active game mode
function GameModeController.SetupUpdateLoop()
	-- Update every heartbeat
	GameModeController.UpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if GameModeController.CurrentMode and GameModeController.CurrentMode.IsActive then
			GameModeController.CurrentMode:Update(deltaTime)
		end
	end)
end

-- Start a game mode
function GameModeController.StartMode(modeName)
	-- Stop current mode if running
	if GameModeController.CurrentMode then
		GameModeController.StopCurrentMode()
	end

	-- Check if mode exists
	local ModeClass = GameModeController.AvailableModes[modeName]
	if not ModeClass then
		warn(string.format("[GameModeController] Unknown game mode: %s", modeName))
		return false
	end

	-- Create mode instance
	local modeInstance = ModeClass.new()
	GameModeController.CurrentMode = modeInstance

	-- Initialize and start
	local initSuccess = modeInstance:Initialize()
	if not initSuccess then
		warn(string.format("[GameModeController] Failed to initialize %s", modeName))
		GameModeController.CurrentMode = nil
		return false
	end

	modeInstance:Start()

	print(string.format("[GameModeController] Started %s", modeInstance.DisplayName))
	return true
end

-- Stop the current game mode
function GameModeController.StopCurrentMode()
	if not GameModeController.CurrentMode then
		return
	end

	local modeName = GameModeController.CurrentMode.DisplayName

	-- End the mode if still active
	if GameModeController.CurrentMode.IsActive then
		GameModeController.CurrentMode:End("Stopped", nil)
	end

	-- Cleanup
	GameModeController.CurrentMode:Cleanup()

	print(string.format("[GameModeController] Stopped %s", modeName))

	GameModeController.CurrentMode = nil
end

-- Get current mode
function GameModeController.GetCurrentMode()
	return GameModeController.CurrentMode
end

-- Get current mode info
function GameModeController.GetCurrentModeInfo()
	if not GameModeController.CurrentMode then
		return nil
	end

	return GameModeController.CurrentMode:GetModeInfo()
end

-- Get available mode names
function GameModeController.GetAvailableModeNames()
	local names = {}
	for modeName, _ in pairs(GameModeController.AvailableModes) do
		table.insert(names, modeName)
	end
	return names
end

-- Handle player kill
function GameModeController.HandlePlayerKill(killer, victim)
	if GameModeController.CurrentMode and GameModeController.CurrentMode.IsActive then
		GameModeController.CurrentMode:HandlePlayerKill(killer, victim)
	end
end

-- Handle player death
function GameModeController.HandlePlayerDeath(player, killer)
	if GameModeController.CurrentMode and GameModeController.CurrentMode.IsActive then
		GameModeController.CurrentMode:HandlePlayerDeath(player, killer)
	end
end

-- Handle player spawn
function GameModeController.HandlePlayerSpawn(player)
	if GameModeController.CurrentMode and GameModeController.CurrentMode.IsActive then
		GameModeController.CurrentMode:HandlePlayerSpawn(player)
	end
end

-- Handle player leave
function GameModeController.HandlePlayerLeave(player)
	if GameModeController.CurrentMode and GameModeController.CurrentMode.IsActive then
		GameModeController.CurrentMode:HandlePlayerLeave(player)
	end
end

-- Check if mode is active
function GameModeController.IsModeActive()
	return GameModeController.CurrentMode and GameModeController.CurrentMode.IsActive
end

-- Get winner of current mode
function GameModeController.GetWinner()
	if not GameModeController.CurrentMode then
		return nil
	end

	-- Get scores
	local scores = GameModeController.CurrentMode:GetScores()

	if scores.Team1 > scores.Team2 then
		return "Team1"
	elseif scores.Team2 > scores.Team1 then
		return "Team2"
	else
		return "Draw"
	end
end

return GameModeController
