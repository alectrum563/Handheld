--[[
	Hardpoint.lua
	Hardpoint game mode - Rotating King of the Hill
	Location: ServerScriptService > Core > GameModes > Hardpoint
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local BaseGameMode = require(script.Parent.BaseGameMode)

local Hardpoint = {}
Hardpoint.__index = Hardpoint
setmetatable(Hardpoint, BaseGameMode)

-- Configuration
local HARDPOINT_DURATION = 60 -- Seconds each hardpoint stays active
local ROTATION_DELAY = 5 -- Seconds between hardpoints
local CAPTURE_RADIUS = 15 -- Studs radius for capturing
local POINTS_PER_SECOND = 1 -- Points earned per second in hardpoint
local UPDATE_INTERVAL = 0.5 -- Update twice per second

-- Create new Hardpoint instance
function Hardpoint.new()
	local self = BaseGameMode.new({
		ModeName = "Hardpoint",
		DisplayName = "Hardpoint",
		Description = "Control the rotating hardpoint to earn points!",
		ScoreLimit = GameConfig.HP_SCORE_LIMIT or 250,
		TimeLimit = GameConfig.ROUND_TIME,
		RequiresObjectives = true
	})

	setmetatable(self, Hardpoint)

	-- Hardpoint state
	self.HardpointLocations = {} -- All possible hardpoint locations
	self.CurrentHardpoint = nil -- Currently active hardpoint
	self.HardpointIndex = 0 -- Index of current hardpoint
	self.HardpointTimer = 0 -- Time current hardpoint has been active
	self.RotationTimer = 0 -- Time since last rotation
	self.IsRotating = false -- Whether we're between hardpoints
	self.LastScoreTime = 0
	self.ControllingTeam = nil -- Which team is currently controlling

	-- Setup event handlers
	self:SetupEventHandlers()

	return self
end

-- Setup event handlers
function Hardpoint:SetupEventHandlers()
	-- Initialize
	self.OnInitialize = function(self)
		print("[Hardpoint] Mode initialized")

		-- Find hardpoint locations
		self:FindHardpointLocations()
	end

	-- Start
	self.OnStart = function(self)
		print(string.format("[Hardpoint] Match started - Control the hardpoint! First to %d wins!", self.ScoreLimit))

		-- Activate first hardpoint
		self:ActivateNextHardpoint()
		self.LastScoreTime = tick()
	end

	-- Update
	self.OnUpdate = function(self, deltaTime)
		-- Handle rotation
		if self.IsRotating then
			self:UpdateRotation(deltaTime)
			return
		end

		-- Update hardpoint timer
		self.HardpointTimer = self.HardpointTimer + deltaTime

		-- Check if time to rotate
		if self.HardpointTimer >= HARDPOINT_DURATION then
			self:StartRotation()
			return
		end

		-- Update control and award points
		local currentTime = tick()
		if currentTime - self.LastScoreTime >= UPDATE_INTERVAL then
			self:UpdateControl()
			self:AwardHardpointPoints()
			self.LastScoreTime = currentTime
		end
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
			"[Hardpoint] Match ended - %s | Winner: %s | Final Score: %d:%d",
			reason,
			winnerName,
			self.TeamScores.Team1,
			self.TeamScores.Team2
		))

		-- Deactivate hardpoint
		self:DeactivateHardpoint()
	end

	-- Player spawn
	self.OnPlayerSpawn = function(self, player)
		-- Could show hardpoint location on spawn
	end

	-- Cleanup
	self.OnCleanup = function(self)
		print("[Hardpoint] Cleaning up mode")
		self:ClearHardpoints()
	end
end

-- Find hardpoint locations in the map
function Hardpoint:FindHardpointLocations()
	local MapManager = require(script.Parent.Parent.MapManager)
	local locations = MapManager.GetGameModeObjects("HardpointLocations")

	if #locations == 0 then
		warn("[Hardpoint] No hardpoint locations found in map!")
		return
	end

	-- Store locations
	self.HardpointLocations = locations

	-- Setup visuals (all invisible initially)
	for i, location in ipairs(locations) do
		location.BrickColor = BrickColor.new("White")
		location.Transparency = 1 -- Hidden initially
		location.CanCollide = false

		print(string.format("[Hardpoint] Setup location %d at %s", i, tostring(location.Position)))
	end

	print(string.format("[Hardpoint] Found %d hardpoint locations", #locations))
end

-- Activate next hardpoint
function Hardpoint:ActivateNextHardpoint()
	-- Deactivate current if any
	if self.CurrentHardpoint then
		self:DeactivateHardpoint()
	end

	-- Move to next location (cycle through)
	self.HardpointIndex = (self.HardpointIndex % #self.HardpointLocations) + 1
	self.CurrentHardpoint = self.HardpointLocations[self.HardpointIndex]
	self.HardpointTimer = 0
	self.IsRotating = false
	self.ControllingTeam = nil

	-- Activate visual
	if self.CurrentHardpoint then
		self.CurrentHardpoint.Transparency = 0.7
		self.CurrentHardpoint.BrickColor = BrickColor.new("White")

		print(string.format("[Hardpoint] Hardpoint %d activated at %s", self.HardpointIndex, tostring(self.CurrentHardpoint.Position)))
	end
end

-- Deactivate current hardpoint
function Hardpoint:DeactivateHardpoint()
	if self.CurrentHardpoint then
		self.CurrentHardpoint.Transparency = 1
		print(string.format("[Hardpoint] Hardpoint %d deactivated", self.HardpointIndex))
	end

	self.CurrentHardpoint = nil
	self.ControllingTeam = nil
end

-- Start rotation to next hardpoint
function Hardpoint:StartRotation()
	print("[Hardpoint] Starting rotation...")
	self:DeactivateHardpoint()
	self.IsRotating = true
	self.RotationTimer = 0
end

-- Update rotation timer
function Hardpoint:UpdateRotation(deltaTime)
	self.RotationTimer = self.RotationTimer + deltaTime

	if self.RotationTimer >= ROTATION_DELAY then
		self:ActivateNextHardpoint()
	end
end

-- Update hardpoint control
function Hardpoint:UpdateControl()
	if not self.CurrentHardpoint or self.IsRotating then
		return
	end

	-- Count players in hardpoint per team
	local playersInZone = {
		Team1 = 0,
		Team2 = 0
	}

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Team then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character:FindFirstChild("Humanoid")

			if humanoidRootPart and humanoid and humanoid.Health > 0 then
				-- Check if in hardpoint
				local distance = (humanoidRootPart.Position - self.CurrentHardpoint.Position).Magnitude

				if distance <= CAPTURE_RADIUS then
					-- Determine team
					if player.Team.Name == GameConfig.TEAM_1_NAME then
						playersInZone.Team1 = playersInZone.Team1 + 1
					elseif player.Team.Name == GameConfig.TEAM_2_NAME then
						playersInZone.Team2 = playersInZone.Team2 + 1
					end
				end
			end
		end
	end

	-- Determine control
	local newControllingTeam = nil

	if playersInZone.Team1 > 0 and playersInZone.Team2 == 0 then
		newControllingTeam = "Team1"
	elseif playersInZone.Team2 > 0 and playersInZone.Team1 == 0 then
		newControllingTeam = "Team2"
	elseif playersInZone.Team1 > 0 and playersInZone.Team2 > 0 then
		-- Contested - no control
		newControllingTeam = nil
	else
		-- No one in zone
		newControllingTeam = nil
	end

	-- Update visual if control changed
	if newControllingTeam ~= self.ControllingTeam then
		self.ControllingTeam = newControllingTeam

		if newControllingTeam == "Team1" then
			self.CurrentHardpoint.BrickColor = BrickColor.new("Bright blue")
			print("[Hardpoint] Team 1 is controlling the hardpoint")
		elseif newControllingTeam == "Team2" then
			self.CurrentHardpoint.BrickColor = BrickColor.new("Bright red")
			print("[Hardpoint] Team 2 is controlling the hardpoint")
		else
			self.CurrentHardpoint.BrickColor = BrickColor.new("White")
			-- Contested or neutral
		end
	end
end

-- Award points based on hardpoint control
function Hardpoint:AwardHardpointPoints()
	if not self.ControllingTeam or self.IsRotating then
		return
	end

	-- Award points to controlling team
	local pointsToAward = POINTS_PER_SECOND * UPDATE_INTERVAL

	self:AwardPoints(self.ControllingTeam, pointsToAward)
end

-- Clear hardpoints
function Hardpoint:ClearHardpoints()
	-- Hide all hardpoints
	for _, location in ipairs(self.HardpointLocations) do
		location.Transparency = 1
	end

	self.HardpointLocations = {}
	self.CurrentHardpoint = nil
end

-- Get mode-specific stats
function Hardpoint:GetStats()
	return {
		Team1Score = self.TeamScores.Team1,
		Team2Score = self.TeamScores.Team2,
		ControllingTeam = self.ControllingTeam,
		CurrentHardpointIndex = self.HardpointIndex,
		TotalHardpoints = #self.HardpointLocations,
		HardpointTimeRemaining = HARDPOINT_DURATION - self.HardpointTimer,
		IsRotating = self.IsRotating,
		RotationTimeRemaining = self.IsRotating and (ROTATION_DELAY - self.RotationTimer) or 0,
		ScoreToWin = self.ScoreLimit
	}
end

return Hardpoint
