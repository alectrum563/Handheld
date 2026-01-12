--[[
	Domination.lua
	Domination game mode - Control zones to earn points
	Location: ServerScriptService > Core > GameModes > Domination
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local BaseGameMode = require(script.Parent.BaseGameMode)

local Domination = {}
Domination.__index = Domination
setmetatable(Domination, BaseGameMode)

-- Configuration
local CAPTURE_TIME = 5 -- Seconds to capture a zone
local POINTS_PER_SECOND_PER_ZONE = 1 -- Points earned per second per controlled zone
local CAPTURE_RADIUS = 15 -- Studs radius for capturing
local UPDATE_INTERVAL = 1 -- Update every second

-- Create new Domination instance
function Domination.new()
	local self = BaseGameMode.new({
		ModeName = "Domination",
		DisplayName = "Domination",
		Description = "Capture and hold zones to earn points!",
		ScoreLimit = GameConfig.DOM_SCORE_LIMIT or 200,
		TimeLimit = GameConfig.ROUND_TIME,
		RequiresObjectives = true
	})

	setmetatable(self, Domination)

	-- Zone tracking
	self.Zones = {} -- {zone = part, owner = "Team1"/"Team2"/"Neutral", capturers = {player list}}
	self.CaptureProgress = {} -- {zoneId = {Team1 = 0, Team2 = 0}}
	self.LastScoreTime = 0

	-- Setup event handlers
	self:SetupEventHandlers()

	return self
end

-- Setup event handlers
function Domination:SetupEventHandlers()
	-- Initialize
	self.OnInitialize = function(self)
		print("[Domination] Mode initialized")

		-- Find domination zones in map
		self:FindZones()
	end

	-- Start
	self.OnStart = function(self)
		print(string.format("[Domination] Match started - Capture zones to earn points! First to %d wins!", self.ScoreLimit))

		-- Start monitoring zones
		self:StartZoneMonitoring()
	end

	-- Update
	self.OnUpdate = function(self, deltaTime)
		-- Award points based on controlled zones
		local currentTime = tick()
		if currentTime - self.LastScoreTime >= UPDATE_INTERVAL then
			self:AwardZonePoints()
			self.LastScoreTime = currentTime
		end

		-- Update capture progress for all zones
		self:UpdateCaptures(deltaTime)
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
			"[Domination] Match ended - %s | Winner: %s | Final Score: %d:%d",
			reason,
			winnerName,
			self.TeamScores.Team1,
			self.TeamScores.Team2
		))

		-- Stop zone monitoring
		self:StopZoneMonitoring()
	end

	-- Player spawn
	self.OnPlayerSpawn = function(self, player)
		-- Could show zone status on spawn
	end

	-- Cleanup
	self.OnCleanup = function(self)
		print("[Domination] Cleaning up mode")

		-- Clear zones
		self:ClearZones()
	end
end

-- Find domination zones in the current map
function Domination:FindZones()
	local MapManager = require(script.Parent.Parent.MapManager)
	local zones = MapManager.GetGameModeObjects("DominationZones")

	if #zones == 0 then
		warn("[Domination] No domination zones found in map!")
		return
	end

	-- Setup zones
	for i, zonePart in ipairs(zones) do
		local zoneId = "Zone_" .. i
		self.Zones[zoneId] = {
			Part = zonePart,
			Owner = "Neutral",
			Capturers = {},
			CaptureProgress = {
				Team1 = 0,
				Team2 = 0
			}
		}

		-- Visual setup
		zonePart.BrickColor = BrickColor.new("Medium stone grey")
		zonePart.Transparency = 0.7
		zonePart.CanCollide = false

		print(string.format("[Domination] Setup zone: %s at %s", zoneId, tostring(zonePart.Position)))
	end

	print(string.format("[Domination] Found and setup %d zones", #zones))
end

-- Start monitoring zones for players
function Domination:StartZoneMonitoring()
	-- Monitoring happens in Update function
	self.LastScoreTime = tick()
end

-- Stop monitoring zones
function Domination:StopZoneMonitoring()
	-- Reset zones
	for zoneId, zone in pairs(self.Zones) do
		zone.Owner = "Neutral"
		zone.Capturers = {}
		zone.CaptureProgress.Team1 = 0
		zone.CaptureProgress.Team2 = 0

		-- Reset visual
		if zone.Part then
			zone.Part.BrickColor = BrickColor.new("Medium stone grey")
		end
	end
end

-- Update capture progress for all zones
function Domination:UpdateCaptures(deltaTime)
	local Players = game:GetService("Players")

	for zoneId, zone in pairs(self.Zones) do
		if not zone.Part then continue end

		-- Find all players in zone
		local playersInZone = {
			Team1 = {},
			Team2 = {}
		}

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Team then
				local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
				local humanoid = player.Character:FindFirstChild("Humanoid")

				if humanoidRootPart and humanoid and humanoid.Health > 0 then
					-- Check if in zone
					local distance = (humanoidRootPart.Position - zone.Part.Position).Magnitude
					if distance <= CAPTURE_RADIUS then
						-- Determine team
						local teamKey = nil
						if player.Team.Name == GameConfig.TEAM_1_NAME then
							teamKey = "Team1"
						elseif player.Team.Name == GameConfig.TEAM_2_NAME then
							teamKey = "Team2"
						end

						if teamKey then
							table.insert(playersInZone[teamKey], player)
						end
					end
				end
			end
		end

		-- Update capture progress
		self:ProcessZoneCapture(zoneId, zone, playersInZone, deltaTime)
	end
end

-- Process capture progress for a single zone
function Domination:ProcessZoneCapture(zoneId, zone, playersInZone, deltaTime)
	local team1Count = #playersInZone.Team1
	local team2Count = #playersInZone.Team2

	-- Contested zone (both teams present)
	if team1Count > 0 and team2Count > 0 then
		-- Zone is contested, no progress
		return
	end

	-- Team 1 capturing
	if team1Count > 0 and team2Count == 0 then
		self:CaptureZone(zoneId, zone, "Team1", team1Count, deltaTime)
	-- Team 2 capturing
	elseif team2Count > 0 and team1Count == 0 then
		self:CaptureZone(zoneId, zone, "Team2", team2Count, deltaTime)
	else
		-- No one in zone, slowly decay progress
		if zone.Owner == "Neutral" then
			zone.CaptureProgress.Team1 = math.max(0, zone.CaptureProgress.Team1 - deltaTime * 0.2)
			zone.CaptureProgress.Team2 = math.max(0, zone.CaptureProgress.Team2 - deltaTime * 0.2)
		end
	end
end

-- Capture zone for a team
function Domination:CaptureZone(zoneId, zone, capturingTeam, playerCount, deltaTime)
	local opposingTeam = capturingTeam == "Team1" and "Team2" or "Team1"

	-- If zone owned by opposing team, reduce their progress first
	if zone.Owner == opposingTeam then
		zone.CaptureProgress[opposingTeam] = zone.CaptureProgress[opposingTeam] - deltaTime

		if zone.CaptureProgress[opposingTeam] <= 0 then
			zone.CaptureProgress[opposingTeam] = 0
			zone.Owner = "Neutral"
			zone.Part.BrickColor = BrickColor.new("Medium stone grey")
			print(string.format("[Domination] %s neutralized by %s", zoneId, capturingTeam))
		end
		return
	end

	-- Increase capture progress (faster with more players, cap at 2x speed)
	local captureRate = math.min(playerCount, 2)
	zone.CaptureProgress[capturingTeam] = zone.CaptureProgress[capturingTeam] + (deltaTime * captureRate)

	-- Check if captured
	if zone.CaptureProgress[capturingTeam] >= CAPTURE_TIME then
		zone.Owner = capturingTeam
		zone.CaptureProgress[capturingTeam] = CAPTURE_TIME
		zone.CaptureProgress[opposingTeam] = 0

		-- Update visual
		if capturingTeam == "Team1" then
			zone.Part.BrickColor = BrickColor.new("Bright blue")
		else
			zone.Part.BrickColor = BrickColor.new("Bright red")
		end

		print(string.format("[Domination] %s captured by %s", zoneId, capturingTeam))
	else
		-- Capturing in progress
		zone.Part.BrickColor = BrickColor.new(capturingTeam == "Team1" and "Cyan" or "Pink")
	end
end

-- Award points based on controlled zones
function Domination:AwardZonePoints()
	local controlCounts = {
		Team1 = 0,
		Team2 = 0
	}

	-- Count zones controlled by each team
	for _, zone in pairs(self.Zones) do
		if zone.Owner == "Team1" then
			controlCounts.Team1 = controlCounts.Team1 + 1
		elseif zone.Owner == "Team2" then
			controlCounts.Team2 = controlCounts.Team2 + 1
		end
	end

	-- Award points
	if controlCounts.Team1 > 0 then
		self:AwardPoints("Team1", controlCounts.Team1 * POINTS_PER_SECOND_PER_ZONE)
	end

	if controlCounts.Team2 > 0 then
		self:AwardPoints("Team2", controlCounts.Team2 * POINTS_PER_SECOND_PER_ZONE)
	end
end

-- Clear zones
function Domination:ClearZones()
	for zoneId, zone in pairs(self.Zones) do
		if zone.Part then
			zone.Part.BrickColor = BrickColor.new("Medium stone grey")
		end
	end

	self.Zones = {}
end

-- Get mode-specific stats
function Domination:GetStats()
	local controlCounts = {
		Team1 = 0,
		Team2 = 0,
		Neutral = 0
	}

	for _, zone in pairs(self.Zones) do
		if zone.Owner == "Team1" then
			controlCounts.Team1 = controlCounts.Team1 + 1
		elseif zone.Owner == "Team2" then
			controlCounts.Team2 = controlCounts.Team2 + 1
		else
			controlCounts.Neutral = controlCounts.Neutral + 1
		end
	end

	return {
		Team1Score = self.TeamScores.Team1,
		Team2Score = self.TeamScores.Team2,
		Team1Zones = controlCounts.Team1,
		Team2Zones = controlCounts.Team2,
		NeutralZones = controlCounts.Neutral,
		TotalZones = controlCounts.Team1 + controlCounts.Team2 + controlCounts.Neutral,
		ScoreToWin = self.ScoreLimit
	}
end

return Domination
