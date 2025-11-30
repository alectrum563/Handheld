--[[
	TeamDeathmatch.lua
	Team Deathmatch game mode - First team to kill limit wins
	Location: ServerScriptService > Core > GameModes > TeamDeathmatch
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local BaseGameMode = require(script.Parent.BaseGameMode)

local TeamDeathmatch = {}
TeamDeathmatch.__index = TeamDeathmatch
setmetatable(TeamDeathmatch, BaseGameMode)

-- Create new TeamDeathmatch instance
function TeamDeathmatch.new()
	local self = BaseGameMode.new({
		ModeName = "TeamDeathmatch",
		DisplayName = "Team Deathmatch",
		Description = "First team to reach the kill limit wins!",
		ScoreLimit = GameConfig.TDM_KILL_LIMIT,
		TimeLimit = GameConfig.ROUND_TIME,
		RequiresObjectives = false
	})

	setmetatable(self, TeamDeathmatch)

	-- Kill tracking
	self.TeamKills = {
		Team1 = 0,
		Team2 = 0
	}

	-- Setup event handlers
	self:SetupEventHandlers()

	return self
end

-- Setup event handlers
function TeamDeathmatch:SetupEventHandlers()
	-- Initialize
	self.OnInitialize = function(self)
		print("[TeamDeathmatch] Mode initialized")

		-- Reset kill counts
		self.TeamKills.Team1 = 0
		self.TeamKills.Team2 = 0
	end

	-- Start
	self.OnStart = function(self)
		print(string.format("[TeamDeathmatch] Match started - First to %d kills wins!", self.ScoreLimit))
	end

	-- Update (called periodically)
	self.OnUpdate = function(self, deltaTime)
		-- TeamDeathmatch doesn't need periodic updates
		-- Victory is checked automatically by base class
	end

	-- End
	self.OnEnd = function(self, reason, winner)
		local winnerName = "Draw"
		if winner == "Team1" then
			winnerName = GameConfig.TEAM_1_NAME
		elseif winner == "Team2" then
			winnerName = GameConfig.TEAM_2_NAME
		end

		print(string.format(
			"[TeamDeathmatch] Match ended - %s | Winner: %s | Final Score: %d:%d",
			reason,
			winnerName,
			self.TeamKills.Team1,
			self.TeamKills.Team2
		))
	end

	-- Player kill
	self.OnPlayerKill = function(self, killer, victim)
		-- Determine killer's team
		local killerTeam = nil
		if killer.Team then
			if killer.Team.Name == GameConfig.TEAM_1_NAME then
				killerTeam = "Team1"
			elseif killer.Team.Name == GameConfig.TEAM_2_NAME then
				killerTeam = "Team2"
			end
		end

		-- Award kill to team
		if killerTeam then
			self.TeamKills[killerTeam] = self.TeamKills[killerTeam] + 1
			self:AwardPoints(killerTeam, 1)

			print(string.format(
				"[TeamDeathmatch] %s killed %s - %s: %d, %s: %d",
				killer.Name,
				victim.Name,
				GameConfig.TEAM_1_NAME,
				self.TeamKills.Team1,
				GameConfig.TEAM_2_NAME,
				self.TeamKills.Team2
			))
		end
	end

	-- Player death (not used in TDM, but available)
	self.OnPlayerDeath = function(self, player, killer)
		-- Could track deaths here if needed
	end

	-- Player spawn (not used in TDM, but available)
	self.OnPlayerSpawn = function(self, player)
		-- Could give spawn bonuses or messages here
	end

	-- Player leave
	self.OnPlayerLeave = function(self, player)
		-- TDM doesn't need special handling for players leaving
	end

	-- Cleanup
	self.OnCleanup = function(self)
		print("[TeamDeathmatch] Cleaning up mode")

		-- Reset kill counts
		self.TeamKills.Team1 = 0
		self.TeamKills.Team2 = 0
	end
end

-- Check victory condition (override base class)
function TeamDeathmatch:CheckVictoryCondition()
	-- Check if either team reached kill limit
	if self.TeamKills.Team1 >= self.ScoreLimit then
		return "Team1"
	elseif self.TeamKills.Team2 >= self.ScoreLimit then
		return "Team2"
	end

	return nil
end

-- Get mode-specific stats
function TeamDeathmatch:GetStats()
	return {
		Team1Kills = self.TeamKills.Team1,
		Team2Kills = self.TeamKills.Team2,
		KillsToWin = self.ScoreLimit,
		Team1Progress = (self.TeamKills.Team1 / self.ScoreLimit) * 100,
		Team2Progress = (self.TeamKills.Team2 / self.ScoreLimit) * 100
	}
end

return TeamDeathmatch
