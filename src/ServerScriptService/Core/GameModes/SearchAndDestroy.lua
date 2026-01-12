--[[
	SearchAndDestroy.lua
	Search & Destroy game mode - Round-based bomb planting/defusing
	Location: ServerScriptService > Core > GameModes > SearchAndDestroy
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local BaseGameMode = require(script.Parent.BaseGameMode)

local SearchAndDestroy = {}
SearchAndDestroy.__index = SearchAndDestroy
setmetatable(SearchAndDestroy, BaseGameMode)

-- Configuration
local PLANT_TIME = 5 -- Seconds to plant bomb
local DEFUSE_TIME = 7 -- Seconds to defuse bomb
local EXPLOSION_TIME = 30 -- Seconds until bomb explodes after plant
local ROUNDS_TO_WIN = 6 -- First to 6 rounds wins
local PLANT_RADIUS = 10 -- Distance to plant bomb
local DEFUSE_RADIUS = 5 -- Distance to defuse bomb

-- Create new SearchAndDestroy instance
function SearchAndDestroy.new()
	local self = BaseGameMode.new({
		ModeName = "SearchAndDestroy",
		DisplayName = "Search & Destroy",
		Description = "Plant or defuse the bomb! No respawns!",
		ScoreLimit = ROUNDS_TO_WIN,
		TimeLimit = 120, -- 2 minutes per round
		RequiresObjectives = true
	})

	setmetatable(self, SearchAndDestroy)

	-- Round state
	self.CurrentRound = 0
	self.RoundsWon = {
		Team1 = 0,
		Team2 = 0
	}

	-- Bomb state
	self.BombSites = {} -- {A = part, B = part}
	self.BombState = "NotPlanted" -- NotPlanted, Planting, Planted, Defusing, Defused, Exploded
	self.BombCarrier = nil
	self.PlantedSite = nil
	self.PlantProgress = 0
	self.DefuseProgress = 0
	self.ExplosionTimer = 0
	self.CurrentPlanter = nil
	self.CurrentDefuser = nil

	-- Setup event handlers
	self:SetupEventHandlers()

	return self
end

-- Setup event handlers
function SearchAndDestroy:SetupEventHandlers()
	-- Initialize
	self.OnInitialize = function(self)
		print("[SearchAndDestroy] Mode initialized")

		-- Find bomb sites
		self:FindBombSites()

		-- Reset round counter
		self.CurrentRound = 0
		self.RoundsWon.Team1 = 0
		self.RoundsWon.Team2 = 0
	end

	-- Start
	self.OnStart = function(self)
		self.CurrentRound = 1
		self:StartNewRound()
	end

	-- Update
	self.OnUpdate = function(self, deltaTime)
		-- Update bomb timers
		self:UpdateBombState(deltaTime)

		-- Check round end conditions
		self:CheckRoundEnd()
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
			"[SearchAndDestroy] Match ended - %s | Winner: %s | Rounds: %d:%d",
			reason,
			winnerName,
			self.RoundsWon.Team1,
			self.RoundsWon.Team2
		))
	end

	-- Player death - no respawn in S&D
	self.OnPlayerDeath = function(self, player, killer)
		print(string.format("[SearchAndDestroy] %s eliminated", player.Name))

		-- If bomb carrier dies, drop bomb
		if self.BombCarrier == player then
			self:DropBomb(player)
		end

		-- If planter/defuser dies, cancel action
		if self.CurrentPlanter == player then
			self:CancelPlant()
		elseif self.CurrentDefuser == player then
			self:CancelDefuse()
		end
	end

	-- Player spawn - assign bomb carrier
	self.OnPlayerSpawn = function(self, player)
		-- In S&D, players only spawn at start of round
		-- This is handled by StartNewRound
	end

	-- Player leave
	self.OnPlayerLeave = function(self, player)
		if self.BombCarrier == player then
			self:DropBomb(player)
		end
	end

	-- Cleanup
	self.OnCleanup = function(self)
		print("[SearchAndDestroy] Cleaning up mode")
		self:ClearBombSites()
	end
end

-- Find bomb sites in the map
function SearchAndDestroy:FindBombSites()
	local MapManager = require(script.Parent.Parent.MapManager)
	local sites = MapManager.GetGameModeObjects("BombSites")

	if #sites < 2 then
		warn("[SearchAndDestroy] Need at least 2 bomb sites (A and B)!")
		return
	end

	-- Assign sites
	self.BombSites.A = sites[1]
	self.BombSites.B = sites[2]

	-- Visual setup
	for name, site in pairs(self.BombSites) do
		site.BrickColor = BrickColor.new("Bright yellow")
		site.Transparency = 0.8
		site.CanCollide = false

		print(string.format("[SearchAndDestroy] Setup bomb site %s at %s", name, tostring(site.Position)))
	end
end

-- Start a new round
function SearchAndDestroy:StartNewRound()
	print(string.format("[SearchAndDestroy] Starting Round %d - Best of %d", self.CurrentRound, ROUNDS_TO_WIN * 2 - 1))

	-- Reset bomb state
	self.BombState = "NotPlanted"
	self.PlantProgress = 0
	self.DefuseProgress = 0
	self.ExplosionTimer = 0
	self.PlantedSite = nil
	self.CurrentPlanter = nil
	self.CurrentDefuser = nil

	-- Assign bomb carrier (random attacker)
	self:AssignBombCarrier()

	-- Reset round timer
	self.StartTime = tick()

	print(string.format("[SearchAndDestroy] Round started - Attackers: Plant the bomb! Defenders: Stop them!"))
end

-- Assign bomb carrier to random attacking player
function SearchAndDestroy:AssignBombCarrier()
	-- Determine attacking team (alternate each round)
	local attackingTeam = (self.CurrentRound % 2 == 1) and GameConfig.TEAM_1_NAME or GameConfig.TEAM_2_NAME

	-- Find players on attacking team
	local attackers = {}
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == attackingTeam then
			table.insert(attackers, player)
		end
	end

	-- Assign random carrier
	if #attackers > 0 then
		self.BombCarrier = attackers[math.random(1, #attackers)]
		print(string.format("[SearchAndDestroy] %s is carrying the bomb!", self.BombCarrier.Name))
	else
		warn("[SearchAndDestroy] No attackers found to carry bomb!")
	end
end

-- Update bomb state
function SearchAndDestroy:UpdateBombState(deltaTime)
	if self.BombState == "Planting" then
		self:UpdatePlanting(deltaTime)
	elseif self.BombState == "Planted" then
		self:UpdateExplosionTimer(deltaTime)
	elseif self.BombState == "Defusing" then
		self:UpdateDefusing(deltaTime)
	end
end

-- Update planting progress
function SearchAndDestroy:UpdatePlanting(deltaTime)
	if not self.CurrentPlanter or not self.CurrentPlanter.Character then
		self:CancelPlant()
		return
	end

	-- Check if still in range
	local humanoidRootPart = self.CurrentPlanter.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		self:CancelPlant()
		return
	end

	-- Find closest site
	local closestSite, closestDist = self:GetClosestBombSite(humanoidRootPart.Position)
	if not closestSite or closestDist > PLANT_RADIUS then
		self:CancelPlant()
		return
	end

	-- Increase progress
	self.PlantProgress = self.PlantProgress + deltaTime

	-- Check if planted
	if self.PlantProgress >= PLANT_TIME then
		self:PlantBomb(closestSite)
	end
end

-- Update explosion timer
function SearchAndDestroy:UpdateExplosionTimer(deltaTime)
	self.ExplosionTimer = self.ExplosionTimer + deltaTime

	-- Check if exploded
	if self.ExplosionTimer >= EXPLOSION_TIME then
		self:ExplodeBomb()
	end
end

-- Update defusing progress
function SearchAndDestroy:UpdateDefusing(deltaTime)
	if not self.CurrentDefuser or not self.CurrentDefuser.Character then
		self:CancelDefuse()
		return
	end

	-- Check if still in range of planted site
	local humanoidRootPart = self.CurrentDefuser.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart or not self.PlantedSite then
		self:CancelDefuse()
		return
	end

	local distance = (humanoidRootPart.Position - self.PlantedSite.Position).Magnitude
	if distance > DEFUSE_RADIUS then
		self:CancelDefuse()
		return
	end

	-- Increase progress
	self.DefuseProgress = self.DefuseProgress + deltaTime

	-- Check if defused
	if self.DefuseProgress >= DEFUSE_TIME then
		self:DefuseBomb()
	end
end

-- Plant bomb
function SearchAndDestroy:PlantBomb(site)
	self.BombState = "Planted"
	self.PlantedSite = site
	self.ExplosionTimer = 0

	-- Visual feedback
	site.BrickColor = BrickColor.new("Bright red")

	print(string.format("[SearchAndDestroy] Bomb planted at site %s by %s!", self:GetSiteName(site), self.CurrentPlanter.Name))

	self.CurrentPlanter = nil
	self.PlantProgress = 0
end

-- Defuse bomb
function SearchAndDestroy:DefuseBomb()
	self.BombState = "Defused"

	-- Visual feedback
	if self.PlantedSite then
		self.PlantedSite.BrickColor = BrickColor.new("Bright green")
	end

	print(string.format("[SearchAndDestroy] Bomb defused by %s!", self.CurrentDefuser.Name))

	-- End round - defenders win
	self:EndRound("Defused")
end

-- Explode bomb
function SearchAndDestroy:ExplodeBomb()
	self.BombState = "Exploded"

	-- Visual feedback
	if self.PlantedSite then
		self.PlantedSite.BrickColor = BrickColor.new("Really red")

		-- Create explosion effect
		local explosion = Instance.new("Explosion")
		explosion.Position = self.PlantedSite.Position
		explosion.BlastRadius = 30
		explosion.BlastPressure = 0 -- Don't kill players
		explosion.Parent = workspace
	end

	print("[SearchAndDestroy] Bomb exploded!")

	-- End round - attackers win
	self:EndRound("Exploded")
end

-- Cancel plant
function SearchAndDestroy:CancelPlant()
	if self.BombState == "Planting" then
		self.BombState = "NotPlanted"
		self.PlantProgress = 0
		self.CurrentPlanter = nil
		print("[SearchAndDestroy] Plant cancelled")
	end
end

-- Cancel defuse
function SearchAndDestroy:CancelDefuse()
	if self.BombState == "Defusing" then
		self.BombState = "Planted"
		self.DefuseProgress = 0
		self.CurrentDefuser = nil
		print("[SearchAndDestroy] Defuse cancelled")
	end
end

-- Drop bomb (when carrier dies)
function SearchAndDestroy:DropBomb(player)
	print(string.format("[SearchAndDestroy] %s dropped the bomb!", player.Name))
	-- TODO: Could spawn a pickup for another attacker
	self.BombCarrier = nil
end

-- Get closest bomb site
function SearchAndDestroy:GetClosestBombSite(position)
	local closest = nil
	local closestDist = math.huge

	for name, site in pairs(self.BombSites) do
		local dist = (site.Position - position).Magnitude
		if dist < closestDist then
			closest = site
			closestDist = dist
		end
	end

	return closest, closestDist
end

-- Get site name
function SearchAndDestroy:GetSiteName(site)
	for name, s in pairs(self.BombSites) do
		if s == site then
			return name
		end
	end
	return "Unknown"
end

-- Check round end conditions
function SearchAndDestroy:CheckRoundEnd()
	-- Count alive players per team
	local alivePlayers = {
		Team1 = 0,
		Team2 = 0
	}

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Team then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				if player.Team.Name == GameConfig.TEAM_1_NAME then
					alivePlayers.Team1 = alivePlayers.Team1 + 1
				elseif player.Team.Name == GameConfig.TEAM_2_NAME then
					alivePlayers.Team2 = alivePlayers.Team2 + 1
				end
			end
		end
	end

	-- Team elimination check
	if alivePlayers.Team1 == 0 and alivePlayers.Team2 > 0 then
		self:EndRound("Team1Eliminated")
	elseif alivePlayers.Team2 == 0 and alivePlayers.Team1 > 0 then
		self:EndRound("Team2Eliminated")
	end
end

-- End current round
function SearchAndDestroy:EndRound(reason)
	-- Determine winner of round
	local roundWinner = nil

	if reason == "Exploded" or reason == "Team2Eliminated" then
		-- Attackers win (alternate each round)
		roundWinner = (self.CurrentRound % 2 == 1) and "Team1" or "Team2"
	elseif reason == "Defused" or reason == "Team1Eliminated" or reason == "TimeLimit" then
		-- Defenders win
		roundWinner = (self.CurrentRound % 2 == 1) and "Team2" or "Team1"
	end

	-- Award round
	if roundWinner then
		self.RoundsWon[roundWinner] = self.RoundsWon[roundWinner] + 1
		self:AwardPoints(roundWinner, 1)
		print(string.format("[SearchAndDestroy] Round won by %s - Rounds: %d:%d", roundWinner, self.RoundsWon.Team1, self.RoundsWon.Team2))
	end

	-- Check if match is over
	if self.RoundsWon.Team1 >= ROUNDS_TO_WIN or self.RoundsWon.Team2 >= ROUNDS_TO_WIN then
		-- Match over
		return
	end

	-- Start next round
	task.wait(5) -- Brief delay between rounds
	self.CurrentRound = self.CurrentRound + 1
	self:StartNewRound()
end

-- Clear bomb sites
function SearchAndDestroy:ClearBombSites()
	for name, site in pairs(self.BombSites) do
		site.BrickColor = BrickColor.new("Bright yellow")
	end

	self.BombSites = {}
end

-- Override victory check
function SearchAndDestroy:CheckVictoryCondition()
	if self.RoundsWon.Team1 >= ROUNDS_TO_WIN then
		return "Team1"
	elseif self.RoundsWon.Team2 >= ROUNDS_TO_WIN then
		return "Team2"
	end

	return nil
end

-- Get mode-specific stats
function SearchAndDestroy:GetStats()
	return {
		CurrentRound = self.CurrentRound,
		Team1Rounds = self.RoundsWon.Team1,
		Team2Rounds = self.RoundsWon.Team2,
		RoundsToWin = ROUNDS_TO_WIN,
		BombState = self.BombState,
		BombCarrier = self.BombCarrier and self.BombCarrier.Name or "None",
		ExplosionTimer = self.ExplosionTimer,
		PlantProgress = self.PlantProgress,
		DefuseProgress = self.DefuseProgress
	}
end

return SearchAndDestroy
