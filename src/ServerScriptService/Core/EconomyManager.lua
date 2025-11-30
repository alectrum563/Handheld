--[[
	EconomyManager.lua
	Manages player economy (Shards, Score) and kill rewards
	Location: ServerScriptService > Core > EconomyManager
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local EconomyManager = {}
EconomyManager.PlayerEconomy = {} -- Cache of player economy data
EconomyManager.MultiKillTracking = {} -- Track multi-kill streaks

-- DataStore (with fallback for Studio testing)
local EconomyStore = nil
local DataStoreEnabled = false

local success, err = pcall(function()
	EconomyStore = DataStoreService:GetDataStore("PlayerEconomy")
	DataStoreEnabled = true
end)

if not success then
	warn("[EconomyManager] DataStore not available (Studio testing mode) - using in-memory storage only")
	warn("[EconomyManager] To enable persistence, publish your game to Roblox")
else
	print("[EconomyManager] DataStore enabled - economy will persist between sessions")
end

-- Multi-kill names for notifications
local MULTIKILL_NAMES = {
	[2] = "Double Kill",
	[3] = "Triple Kill",
	[4] = "Quad Kill",
	[5] = "Penta Kill",
	[6] = "Mega Kill",
	[7] = "Ultra Kill",
	[8] = "Monster Kill",
}

-- Load player economy from DataStore
function EconomyManager.LoadEconomy(player)
	-- Default economy for new players
	local newEconomy = {
		Shards = 0,
		TotalScore = 0,
		TotalKills = 0,
	}

	-- If DataStore is not available, just return default
	if not DataStoreEnabled then
		print(string.format("[EconomyManager] Created new economy for %s [Studio Mode]", player.Name))
		return newEconomy
	end

	local success, result = pcall(function()
		return EconomyStore:GetAsync("Economy_" .. player.UserId)
	end)

	if success and result then
		print(string.format("[EconomyManager] Loaded economy for %s - Shards: %d, Score: %d", player.Name, result.Shards or 0, result.TotalScore or 0))
		return result
	else
		-- New player or error - create default economy
		print(string.format("[EconomyManager] Created new economy for %s", player.Name))
		return newEconomy
	end
end

-- Save player economy to DataStore
function EconomyManager.SaveEconomy(player)
	local economy = EconomyManager.PlayerEconomy[player.UserId]
	if not economy then
		warn("[EconomyManager] No economy to save for", player.Name)
		return false
	end

	-- If DataStore is not available, skip saving (Studio mode)
	if not DataStoreEnabled then
		-- Don't spam warnings, just silently skip in Studio mode
		return true
	end

	local success, err = pcall(function()
		EconomyStore:SetAsync("Economy_" .. player.UserId, economy)
	end)

	if success then
		print(string.format("[EconomyManager] Saved economy for %s (Shards: %d, Score: %d)", player.Name, economy.Shards, economy.TotalScore))
		return true
	else
		warn("[EconomyManager] Failed to save economy for", player.Name, ":", err)
		return false
	end
end

-- Initialize economy for player
function EconomyManager.InitializePlayer(player)
	-- Load economy
	local economy = EconomyManager.LoadEconomy(player)
	EconomyManager.PlayerEconomy[player.UserId] = economy

	-- Initialize multi-kill tracking
	EconomyManager.MultiKillTracking[player.UserId] = {
		LastKillTime = 0,
		CurrentStreak = 0,
	}

	print(string.format("[EconomyManager] Initialized economy for %s", player.Name))
end

-- Get player's economy data
function EconomyManager.GetEconomy(player)
	return EconomyManager.PlayerEconomy[player.UserId] or { Shards = 0, TotalScore = 0, TotalKills = 0 }
end

-- Calculate score for a kill
function EconomyManager.CalculateKillScore(killData)
	local score = GameConfig.BASE_KILL_SCORE

	-- Headshot bonus
	if killData.IsHeadshot then
		score = score + GameConfig.HEADSHOT_BONUS
	end

	-- Long shot bonus
	if killData.Distance and killData.Distance >= GameConfig.LONGSHOT_DISTANCE then
		score = score + GameConfig.LONGSHOT_BONUS
	end

	-- Moving kill bonus (airborne or sliding)
	if killData.IsAirborne or killData.IsSliding then
		score = score + GameConfig.MOVING_KILL_BONUS
	end

	-- Multi-kill bonus
	if killData.MultiKillLevel and killData.MultiKillLevel > 1 then
		local bonusMultiplier = killData.MultiKillLevel - 1
		score = score + (GameConfig.MULTIKILL_BONUS_PER_LEVEL * bonusMultiplier)
	end

	return score
end

-- Award kill rewards to player
function EconomyManager.AwardKill(player, killData)
	local economy = EconomyManager.GetEconomy(player)
	local multiKill = EconomyManager.MultiKillTracking[player.UserId]

	if not economy or not multiKill then
		warn("[EconomyManager] No economy data for", player.Name)
		return
	end

	-- Check for multi-kill
	local currentTime = tick()
	local timeSinceLastKill = currentTime - multiKill.LastKillTime

	if timeSinceLastKill <= GameConfig.MULTIKILL_WINDOW then
		-- Multi-kill continues
		multiKill.CurrentStreak = multiKill.CurrentStreak + 1
	else
		-- New kill streak
		multiKill.CurrentStreak = 1
	end

	multiKill.LastKillTime = currentTime

	-- Add multi-kill level to kill data
	killData.MultiKillLevel = multiKill.CurrentStreak

	-- Calculate score
	local scoreEarned = EconomyManager.CalculateKillScore(killData)

	-- Calculate shards (Score / 10, rounded down)
	local shardsEarned = math.floor(scoreEarned * GameConfig.SHARDS_PER_SCORE)

	-- Award to player
	economy.TotalScore = economy.TotalScore + scoreEarned
	economy.Shards = economy.Shards + shardsEarned
	economy.TotalKills = economy.TotalKills + 1

	-- Build reward message
	local bonusMessages = {}

	if killData.IsHeadshot then
		table.insert(bonusMessages, "Headshot")
	end

	if killData.Distance and killData.Distance >= GameConfig.LONGSHOT_DISTANCE then
		table.insert(bonusMessages, "Long Shot")
	end

	if killData.IsAirborne or killData.IsSliding then
		table.insert(bonusMessages, "Moving Kill")
	end

	if killData.MultiKillLevel > 1 then
		local multiKillName = MULTIKILL_NAMES[killData.MultiKillLevel] or (killData.MultiKillLevel .. "x Multi-Kill")
		table.insert(bonusMessages, multiKillName)
	end

	local bonusText = #bonusMessages > 0 and (" [" .. table.concat(bonusMessages, ", ") .. "]") or ""

	print(string.format(
		"[EconomyManager] %s earned +%d Score, +%d Shards%s",
		player.Name,
		scoreEarned,
		shardsEarned,
		bonusText
	))

	-- TODO: Send notification to player about rewards

	-- Auto-save every 5 kills
	if economy.TotalKills % 5 == 0 then
		EconomyManager.SaveEconomy(player)
	end

	return {
		ScoreEarned = scoreEarned,
		ShardsEarned = shardsEarned,
		TotalScore = economy.TotalScore,
		TotalShards = economy.Shards,
		Bonuses = bonusMessages,
		MultiKillLevel = killData.MultiKillLevel,
	}
end

-- Spend shards (for case opening)
function EconomyManager.SpendShards(player, amount)
	local economy = EconomyManager.GetEconomy(player)

	if economy.Shards < amount then
		warn(string.format("[EconomyManager] %s tried to spend %d Shards but only has %d",
			player.Name, amount, economy.Shards))
		return false
	end

	economy.Shards = economy.Shards - amount
	print(string.format("[EconomyManager] %s spent %d Shards (Remaining: %d)",
		player.Name, amount, economy.Shards))

	-- Save after purchase
	EconomyManager.SaveEconomy(player)

	return true
end

-- Add shards (for admin commands or rewards)
function EconomyManager.AddShards(player, amount)
	local economy = EconomyManager.GetEconomy(player)

	economy.Shards = economy.Shards + amount
	print(string.format("[EconomyManager] %s received %d Shards (Total: %d)",
		player.Name, amount, economy.Shards))

	return true
end

-- Get formatted economy data for client
function EconomyManager.GetEconomyData(player)
	local economy = EconomyManager.GetEconomy(player)

	return {
		Shards = economy.Shards,
		TotalScore = economy.TotalScore,
		TotalKills = economy.TotalKills,
	}
end

-- Cleanup player data
function EconomyManager.CleanupPlayer(player)
	-- Save economy before cleanup
	EconomyManager.SaveEconomy(player)

	-- Clear cache
	EconomyManager.PlayerEconomy[player.UserId] = nil
	EconomyManager.MultiKillTracking[player.UserId] = nil

	print(string.format("[EconomyManager] Cleaned up economy for %s", player.Name))
end

-- Reset session score (per round/session, not total)
function EconomyManager.ResetSessionScore(player)
	-- Note: This would be for per-round score, not total score
	-- Currently we track total score lifetime, but you could add SessionScore here
	print(string.format("[EconomyManager] Reset session score for %s", player.Name))
end

return EconomyManager
