--[[
	HitDetection.lua
	Server-side hit validation and damage application
	Location: ServerScriptService > Core > HitDetection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local HitDetection = {}

-- Anti-cheat settings
local MAX_SHOT_DISTANCE_BUFFER = 10 -- Allow 10 studs over weapon range for latency
local MAX_HEADSHOT_ANGLE = 45 -- Maximum angle from look vector to headshot (degrees)
local SHOT_VALIDATION_TIMEOUT = 1.0 -- Shots older than this are rejected (seconds)

-- Player shot history for anti-cheat
HitDetection.ShotHistory = {}

-- Initialize hit detection
function HitDetection.Initialize()
	local Remotes = ReplicatedStorage.Remotes

	-- Listen for weapon fire events
	Remotes.WeaponFired.OnServerEvent:Connect(function(player, shotData)
		HitDetection.ProcessShot(player, shotData)
	end)

	print("[HitDetection] Initialized")
end

-- Process a shot from a player
function HitDetection.ProcessShot(player, shotData)
	-- Validate shot data
	if not HitDetection.ValidateShot(player, shotData) then
		warn(string.format("[HitDetection] Invalid shot from %s", player.Name))
		return
	end

	-- If shot hit a player, apply damage
	if shotData.HitPlayer and shotData.HitPlayer ~= player then
		HitDetection.ApplyDamage(player, shotData)
	end

	-- Track shot for anti-cheat
	HitDetection.RecordShot(player, shotData)
end

-- Validate a shot
function HitDetection.ValidateShot(player, shotData)
	-- Check required fields
	if not shotData.WeaponName or not shotData.HitPosition or not shotData.Distance or not shotData.Timestamp then
		return false
	end

	-- Check weapon exists
	local weaponStats = WeaponStats.GetWeapon(shotData.WeaponName)
	if not weaponStats then
		return false
	end

	-- Check shot age (prevent replay attacks)
	local shotAge = tick() - shotData.Timestamp
	if shotAge > SHOT_VALIDATION_TIMEOUT or shotAge < 0 then
		warn(string.format("[HitDetection] Shot too old or in future from %s (age: %.3fs)", player.Name, shotAge))
		return false
	end

	-- Validate distance
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local playerPos = character.HumanoidRootPart.Position
	local distanceToHit = (shotData.HitPosition - playerPos).Magnitude

	-- Allow some buffer for latency
	if distanceToHit > weaponStats.Range + MAX_SHOT_DISTANCE_BUFFER then
		warn(string.format("[HitDetection] Shot too far from %s (distance: %.1f, max: %.1f)", player.Name, distanceToHit, weaponStats.Range))
		return false
	end

	-- If headshot claimed, validate it's reasonable
	if shotData.IsHeadshot and shotData.HitPlayer then
		if not HitDetection.ValidateHeadshot(player, shotData) then
			warn(string.format("[HitDetection] Suspicious headshot from %s", player.Name))
			-- Still allow the shot, just not as headshot
			shotData.IsHeadshot = false
		end
	end

	return true
end

-- Validate headshot claim
function HitDetection.ValidateHeadshot(player, shotData)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local targetCharacter = shotData.HitPlayer.Character
	if not targetCharacter or not targetCharacter:FindFirstChild("Head") then
		return false
	end

	-- Check if hit part is actually the head
	if shotData.HitPart and shotData.HitPart.Name ~= "Head" then
		return false
	end

	-- Check if player was looking at the head (within reason)
	local playerPos = character.HumanoidRootPart.Position
	local headPos = targetCharacter.Head.Position
	local directionToHead = (headPos - playerPos).Unit

	-- Get player's look direction (approximate from HitPosition)
	local lookDirection = (shotData.HitPosition - playerPos).Unit

	-- Calculate angle
	local dotProduct = directionToHead:Dot(lookDirection)
	local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))

	-- If angle is too large, headshot is suspicious
	if angle > MAX_HEADSHOT_ANGLE then
		return false
	end

	return true
end

-- Apply damage to a player
function HitDetection.ApplyDamage(shooter, shotData)
	local victim = shotData.HitPlayer
	if not victim or not victim.Character then return end

	local humanoid = victim.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Calculate damage
	local damage = WeaponStats.CalculateDamage(
		shotData.WeaponName,
		shotData.Distance,
		shotData.IsHeadshot
	)

	-- Apply damage
	local oldHealth = humanoid.Health
	humanoid.Health = math.max(0, humanoid.Health - damage)
	local newHealth = humanoid.Health

	print(string.format(
		"[HitDetection] %s hit %s for %d damage (%s, %.1f studs) - HP: %.0f -> %.0f",
		shooter.Name,
		victim.Name,
		damage,
		shotData.IsHeadshot and "HEADSHOT" or "body",
		shotData.Distance,
		oldHealth,
		newHealth
	))

	-- Check if killed
	if newHealth <= 0 and oldHealth > 0 then
		HitDetection.HandleKill(shooter, victim, shotData)
	end
end

-- Handle a kill
function HitDetection.HandleKill(killer, victim, shotData)
	print(string.format("[HitDetection] %s killed %s", killer.Name, victim.Name))

	-- Notify game mode about the kill
	local GameModeController = require(script.Parent.GameModeController)
	GameModeController.HandlePlayerKill(killer, victim)

	-- Award kill credit to the killer
	local EconomyManager = require(script.Parent.EconomyManager)

	-- Prepare kill data for economy system
	local killData = {
		IsHeadshot = shotData.IsHeadshot,
		Distance = shotData.Distance,
		IsAirborne = HitDetection.IsPlayerAirborne(killer),
		WeaponUsed = shotData.WeaponName
	}

	-- Award kill rewards
	EconomyManager.AwardKill(killer, killData)

	-- Send damage event to client for death handling
	local Remotes = ReplicatedStorage.Remotes
	Remotes.DamagePlayer:FireClient(victim, {
		Attacker = killer,
		Damage = 0, -- Already dead
		IsKilled = true
	})
end

-- Check if player is airborne
function HitDetection.IsPlayerAirborne(player)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Flying
end

-- Record shot for anti-cheat analysis
function HitDetection.RecordShot(player, shotData)
	local userId = player.UserId
	if not HitDetection.ShotHistory[userId] then
		HitDetection.ShotHistory[userId] = {
			TotalShots = 0,
			Headshots = 0,
			Hits = 0,
			LastShotTime = 0
		}
	end

	local history = HitDetection.ShotHistory[userId]
	history.TotalShots = history.TotalShots + 1
	history.LastShotTime = tick()

	if shotData.HitPlayer then
		history.Hits = history.Hits + 1
		if shotData.IsHeadshot then
			history.Headshots = history.Headshots + 1
		end
	end

	-- Simple anti-cheat check: headshot rate
	if history.TotalShots > 20 then
		local headshotRate = history.Headshots / history.TotalShots
		if headshotRate > 0.8 then
			warn(string.format("[HitDetection] Suspicious headshot rate from %s: %.1f%%", player.Name, headshotRate * 100))
		end
	end
end

return HitDetection
