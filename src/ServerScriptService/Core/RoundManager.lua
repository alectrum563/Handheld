--[[
	RoundManager.lua
	Manages round states, timing, and win conditions
	Location: ServerScriptService > Core > RoundManager
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local RoundManager = {}
RoundManager.State = "Waiting" -- Waiting, Intermission, Playing, RoundEnd
RoundManager.TimeRemaining = 0
RoundManager.CurrentGameMode = nil
RoundManager.CurrentMap = nil

-- Remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundStateEvent

-- Initialize round manager
function RoundManager.Initialize()
	-- Wait for remote events
	RoundStateEvent = Remotes:WaitForChild("RoundState")

	print("[RoundManager] Initialized")

	-- Start the round loop
	task.spawn(function()
		RoundManager.RoundLoop()
	end)
end

-- Main round loop
function RoundManager.RoundLoop()
	while true do
		-- Wait for players
		RoundManager.SetState("Waiting")
		RoundManager.WaitForPlayers()

		-- Intermission
		RoundManager.SetState("Intermission")
		RoundManager.TimeRemaining = GameConfig.INTERMISSION_TIME
		RoundManager.Countdown(GameConfig.INTERMISSION_TIME)

		-- Start round
		RoundManager.StartRound()

		-- Play round
		RoundManager.SetState("Playing")
		RoundManager.PlayRound()

		-- End round
		RoundManager.EndRound(RoundManager.WinningTeam)

		-- Show results
		RoundManager.SetState("RoundEnd")
		task.wait(10)
	end
end

-- Wait for minimum players
function RoundManager.WaitForPlayers()
	print("[RoundManager] Waiting for players...")

	RoundStateEvent:FireAllClients({
		State = "Waiting",
		Message = string.format("Waiting for %d players...", GameConfig.MIN_PLAYERS)
	})

	while #Players:GetPlayers() < GameConfig.MIN_PLAYERS do
		task.wait(1)
	end

	print(string.format("[RoundManager] %d players found, starting intermission", #Players:GetPlayers()))
end

-- Countdown timer
function RoundManager.Countdown(duration)
	for i = duration, 1, -1 do
		RoundManager.TimeRemaining = i
		RoundStateEvent:FireAllClients({
			State = "Intermission",
			TimeRemaining = i,
			Message = string.format("Round starting in %d...", i)
		})
		task.wait(1)
	end
end

-- Start a new round
function RoundManager.StartRound()
	print("[RoundManager] Starting round...")

	-- TODO: Select game mode and map
	-- For now, we'll use TeamDeathmatch on a default map

	-- Respawn all players
	local TeamManager = require(script.Parent.TeamManager)
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team then
			TeamManager.RespawnPlayer(player, true)
		end
	end

	RoundManager.TimeRemaining = GameConfig.ROUND_TIME
	RoundManager.WinningTeam = nil

	print("[RoundManager] Round started!")
end

-- Play the round
function RoundManager.PlayRound()
	local startTime = tick()
	local endTime = startTime + GameConfig.ROUND_TIME

	while tick() < endTime do
		local timeLeft = math.ceil(endTime - tick())
		RoundManager.TimeRemaining = timeLeft

		-- Update clients
		RoundStateEvent:FireAllClients({
			State = "Playing",
			TimeRemaining = timeLeft,
		})

		-- Check win conditions
		local winner = RoundManager.CheckWinConditions()
		if winner then
			RoundManager.WinningTeam = winner
			print(string.format("[RoundManager] %s wins!", winner.Name))
			break
		end

		task.wait(1)
	end

	-- Time ran out
	if not RoundManager.WinningTeam then
		print("[RoundManager] Round ended - Time limit reached")
		-- TODO: Determine winner by score
	end
end

-- Check win conditions (delegates to game mode)
function RoundManager.CheckWinConditions()
	-- TODO: Ask current game mode if someone has won
	-- For now, return nil (no winner)
	return nil
end

-- End the round
function RoundManager.EndRound(winningTeam)
	print("[RoundManager] Ending round...")

	-- Notify clients
	RoundStateEvent:FireAllClients({
		State = "RoundEnd",
		WinningTeam = winningTeam and winningTeam.Name or "Draw",
		Message = winningTeam and (winningTeam.Name .. " wins!") or "Draw!"
	})

	-- TODO: Show scoreboard, stats, etc.
end

-- Set round state
function RoundManager.SetState(newState)
	if RoundManager.State ~= newState then
		print(string.format("[RoundManager] State changed: %s -> %s", RoundManager.State, newState))
		RoundManager.State = newState
	end
end

-- Get current state
function RoundManager.GetState()
	return RoundManager.State
end

-- Get time remaining
function RoundManager.GetTimeRemaining()
	return RoundManager.TimeRemaining
end

return RoundManager
