--[[
	BaseGameMode.lua
	Base class for all game modes - provides common functionality
	Location: ServerScriptService > Core > GameModes > BaseGameMode
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local BaseGameMode = {}
BaseGameMode.__index = BaseGameMode

-- Create a new game mode instance
function BaseGameMode.new(modeConfig)
	local self = setmetatable({}, BaseGameMode)

	-- Mode configuration
	self.ModeName = modeConfig.ModeName or "Unknown"
	self.DisplayName = modeConfig.DisplayName or "Unknown Mode"
	self.Description = modeConfig.Description or ""
	self.ScoreLimit = modeConfig.ScoreLimit or 100
	self.TimeLimit = modeConfig.TimeLimit or GameConfig.ROUND_TIME
	self.RequiresObjectives = modeConfig.RequiresObjectives or false

	-- Mode state
	self.IsActive = false
	self.StartTime = 0
	self.TeamScores = {
		Team1 = 0,
		Team2 = 0
	}

	-- Event handlers (can be overridden by subclasses)
	self.OnInitialize = nil
	self.OnStart = nil
	self.OnUpdate = nil
	self.OnEnd = nil
	self.OnCleanup = nil
	self.OnPlayerKill = nil
	self.OnPlayerDeath = nil
	self.OnPlayerSpawn = nil
	self.OnPlayerLeave = nil

	return self
end

-- Initialize the game mode
function BaseGameMode:Initialize()
	print(string.format("[BaseGameMode] Initializing %s", self.DisplayName))

	-- Reset scores
	self.TeamScores.Team1 = 0
	self.TeamScores.Team2 = 0

	-- Call custom initialization if defined
	if self.OnInitialize then
		self:OnInitialize()
	end

	return true
end

-- Start the game mode
function BaseGameMode:Start()
	print(string.format("[BaseGameMode] Starting %s", self.DisplayName))

	self.IsActive = true
	self.StartTime = tick()

	-- Call custom start logic if defined
	if self.OnStart then
		self:OnStart()
	end

	-- Broadcast mode start to clients
	local Remotes = ReplicatedStorage.Remotes
	if Remotes:FindFirstChild("GameModeUpdate") then
		Remotes.GameModeUpdate:FireAllClients({
			Action = "Start",
			ModeName = self.ModeName,
			TeamScores = self.TeamScores
		})
	end
end

-- Update the game mode (called each frame or periodically)
function BaseGameMode:Update(deltaTime)
	if not self.IsActive then return end

	-- Check time limit
	local elapsed = tick() - self.StartTime
	if elapsed >= self.TimeLimit then
		self:EndByTimeLimit()
		return
	end

	-- Check victory conditions
	local winner = self:CheckVictoryCondition()
	if winner then
		self:EndByVictory(winner)
		return
	end

	-- Call custom update logic if defined
	if self.OnUpdate then
		self:OnUpdate(deltaTime)
	end
end

-- End the game mode
function BaseGameMode:End(reason, winner)
	print(string.format("[BaseGameMode] Ending %s - Reason: %s, Winner: %s", self.DisplayName, reason or "Unknown", winner or "None"))

	self.IsActive = false

	-- Call custom end logic if defined
	if self.OnEnd then
		self:OnEnd(reason, winner)
	end

	-- Broadcast mode end to clients
	local Remotes = ReplicatedStorage.Remotes
	if Remotes:FindFirstChild("GameModeUpdate") then
		Remotes.GameModeUpdate:FireAllClients({
			Action = "End",
			Reason = reason,
			Winner = winner,
			FinalScores = self.TeamScores
		})
	end

	return winner
end

-- End by time limit
function BaseGameMode:EndByTimeLimit()
	-- Determine winner by score
	local winner = "Draw"
	if self.TeamScores.Team1 > self.TeamScores.Team2 then
		winner = "Team1"
	elseif self.TeamScores.Team2 > self.TeamScores.Team1 then
		winner = "Team2"
	end

	self:End("TimeLimit", winner)
end

-- End by victory condition
function BaseGameMode:EndByVictory(winner)
	self:End("Victory", winner)
end

-- Cleanup the game mode
function BaseGameMode:Cleanup()
	print(string.format("[BaseGameMode] Cleaning up %s", self.DisplayName))

	-- Call custom cleanup logic if defined
	if self.OnCleanup then
		self:OnCleanup()
	end

	-- Reset state
	self.IsActive = false
	self.TeamScores.Team1 = 0
	self.TeamScores.Team2 = 0
end

-- Check victory condition (to be overridden by subclasses)
function BaseGameMode:CheckVictoryCondition()
	-- Default: Check if either team reached score limit
	if self.TeamScores.Team1 >= self.ScoreLimit then
		return "Team1"
	elseif self.TeamScores.Team2 >= self.ScoreLimit then
		return "Team2"
	end

	return nil
end

-- Award points to a team
function BaseGameMode:AwardPoints(teamName, points)
	if teamName == "Team1" then
		self.TeamScores.Team1 = self.TeamScores.Team1 + points
	elseif teamName == "Team2" then
		self.TeamScores.Team2 = self.TeamScores.Team2 + points
	else
		warn(string.format("[BaseGameMode] Unknown team: %s", teamName))
		return
	end

	print(string.format("[BaseGameMode] %s awarded %d points - Score: %d:%d", teamName, points, self.TeamScores.Team1, self.TeamScores.Team2))

	-- Broadcast score update to clients
	local Remotes = ReplicatedStorage.Remotes
	if Remotes:FindFirstChild("GameModeUpdate") then
		Remotes.GameModeUpdate:FireAllClients({
			Action = "ScoreUpdate",
			TeamScores = self.TeamScores
		})
	end
end

-- Handle player kill event
function BaseGameMode:HandlePlayerKill(killer, victim)
	-- Call custom kill handler if defined
	if self.OnPlayerKill then
		self:OnPlayerKill(killer, victim)
	end
end

-- Handle player death event
function BaseGameMode:HandlePlayerDeath(player, killer)
	-- Call custom death handler if defined
	if self.OnPlayerDeath then
		self:OnPlayerDeath(player, killer)
	end
end

-- Handle player spawn event
function BaseGameMode:HandlePlayerSpawn(player)
	-- Call custom spawn handler if defined
	if self.OnPlayerSpawn then
		self:OnPlayerSpawn(player)
	end
end

-- Handle player leave event
function BaseGameMode:HandlePlayerLeave(player)
	-- Call custom leave handler if defined
	if self.OnPlayerLeave then
		self:OnPlayerLeave(player)
	end
end

-- Get current scores
function BaseGameMode:GetScores()
	return {
		Team1 = self.TeamScores.Team1,
		Team2 = self.TeamScores.Team2
	}
end

-- Get time remaining
function BaseGameMode:GetTimeRemaining()
	if not self.IsActive then return 0 end

	local elapsed = tick() - self.StartTime
	return math.max(0, self.TimeLimit - elapsed)
end

-- Get mode info
function BaseGameMode:GetModeInfo()
	return {
		ModeName = self.ModeName,
		DisplayName = self.DisplayName,
		Description = self.Description,
		ScoreLimit = self.ScoreLimit,
		TimeLimit = self.TimeLimit,
		IsActive = self.IsActive,
		TeamScores = self.TeamScores,
		TimeRemaining = self:GetTimeRemaining()
	}
end

return BaseGameMode
