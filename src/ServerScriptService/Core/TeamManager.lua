--[[
	TeamManager.lua
	Handles team assignment, balancing, and respawning
	Location: ServerScriptService > Core > TeamManager
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Utilities = require(ReplicatedStorage.Modules.Utilities)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)

local TeamManager = {}
TeamManager.PlayerData = {} -- Stores player loadout and stats

-- Initialize teams
function TeamManager.Initialize()
	-- Create teams if they don't exist
	local team1 = game.Teams:FindFirstChild(GameConfig.TEAM_1_NAME)
	if not team1 then
		team1 = Instance.new("Team")
		team1.Name = GameConfig.TEAM_1_NAME
		team1.TeamColor = BrickColor.new(GameConfig.TEAM_1_COLOR)
		team1.AutoAssignable = false
		team1.Parent = game.Teams
	end

	local team2 = game.Teams:FindFirstChild(GameConfig.TEAM_2_NAME)
	if not team2 then
		team2 = Instance.new("Team")
		team2.Name = GameConfig.TEAM_2_NAME
		team2.TeamColor = BrickColor.new(GameConfig.TEAM_2_COLOR)
		team2.AutoAssignable = false
		team2.Parent = game.Teams
	end

	print("[TeamManager] Teams initialized")
	return team1, team2
end

-- Get team counts
function TeamManager.GetTeamCounts()
	local counts = {}
	for _, team in pairs(game.Teams:GetTeams()) do
		counts[team.Name] = #team:GetPlayers()
	end
	return counts
end

-- Assign player to team with fewer players
function TeamManager.AssignTeam(player)
	local team1 = game.Teams:FindFirstChild(GameConfig.TEAM_1_NAME)
	local team2 = game.Teams:FindFirstChild(GameConfig.TEAM_2_NAME)

	if not team1 or not team2 then
		warn("[TeamManager] Teams not initialized!")
		return
	end

	local team1Count = #team1:GetPlayers()
	local team2Count = #team2:GetPlayers()

	-- Assign to team with fewer players
	if team1Count <= team2Count then
		player.Team = team1
		print(string.format("[TeamManager] Assigned %s to %s", player.Name, team1.Name))
	else
		player.Team = team2
		print(string.format("[TeamManager] Assigned %s to %s", player.Name, team2.Name))
	end

	-- Initialize player data (inventory is handled by InventoryManager)
	TeamManager.PlayerData[player.UserId] = {
		Kills = 0,
		Deaths = 0,
		Score = 0,
	}
end

-- Equip weapon to player (now uses InventoryManager)
function TeamManager.EquipWeapon(player)
	local character = player.Character
	if not character then return end

	-- Get equipped weapon from InventoryManager
	local InventoryManager = require(script.Parent.InventoryManager)
	local equippedWeapon = InventoryManager.GetEquippedWeapon(player)

	if not equippedWeapon then
		warn("[TeamManager] No equipped weapon found for", player.Name)
		return
	end

	local weaponName = equippedWeapon.WeaponName
	local skinId = equippedWeapon.SkinId

	local weaponStats = WeaponStats.GetWeapon(weaponName)
	if not weaponStats then
		warn("[TeamManager] Could not find weapon stats for:", weaponName)
		return
	end

	-- Check if weapon tool exists in ReplicatedStorage
	local weaponTemplate = ReplicatedStorage.Weapons:FindFirstChild(weaponName)
	if not weaponTemplate then
		warn("[TeamManager] Weapon tool not found in ReplicatedStorage.Weapons:", weaponName)
		-- Create a placeholder tool for now
		weaponTemplate = Instance.new("Tool")
		weaponTemplate.Name = weaponName
		weaponTemplate.RequiresHandle = false

		-- Store weapon data in tool for easy access
		local weaponData = Instance.new("Folder")
		weaponData.Name = "WeaponData"
		weaponData.Parent = weaponTemplate

		-- Store weapon instance ID
		local weaponId = Instance.new("StringValue")
		weaponId.Name = "WeaponId"
		weaponId.Value = equippedWeapon.Id
		weaponId.Parent = weaponData

		-- Store skin ID
		local weaponSkin = Instance.new("StringValue")
		weaponSkin.Name = "SkinId"
		weaponSkin.Value = skinId
		weaponSkin.Parent = weaponData
	end

	-- Clone weapon to player's backpack
	local weaponClone = weaponTemplate:Clone()

	-- Update weapon data
	local weaponData = weaponClone:FindFirstChild("WeaponData")
	if weaponData then
		local weaponId = weaponData:FindFirstChild("WeaponId")
		if weaponId then
			weaponId.Value = equippedWeapon.Id
		end

		local weaponSkin = weaponData:FindFirstChild("SkinId")
		if weaponSkin then
			weaponSkin.Value = skinId
		end
	end

	weaponClone.Parent = player.Backpack
	print(string.format("[TeamManager] Weapon added to backpack for %s", player.Name))

	-- Auto-equip weapon to character's hand by parenting directly to character
	task.spawn(function()
		task.wait(0.3) -- Slightly longer delay
		if player.Character and weaponClone.Parent then
			-- Move tool from backpack to character (equips it)
			weaponClone.Parent = player.Character
			print(string.format("[TeamManager] Auto-equipped %s to %s's character", weaponName, player.Name))
		else
			warn(string.format("[TeamManager] Could not auto-equip for %s - Character exists: %s, Tool exists: %s",
				player.Name,
				tostring(player.Character ~= nil),
				tostring(weaponClone.Parent ~= nil)))
		end
	end)

	-- Notify client that weapon was equipped
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if Remotes then
		local EquipWeaponEvent = Remotes:FindFirstChild("EquipWeapon")
		if EquipWeaponEvent then
			EquipWeaponEvent:FireClient(player, weaponName)
		end
	end

	print(string.format("[TeamManager] Equipped %s (%s skin) to %s", weaponName, skinId, player.Name))
end

-- Get random spawn point for team
function TeamManager.GetTeamSpawnPoint(team)
	-- Try to use MapManager first (for dynamic map loading)
	local MapManager = require(script.Parent.MapManager)
	local spawn = MapManager.GetRandomSpawn(team.Name)

	if spawn then
		if spawn:IsA("BasePart") then
			return spawn.CFrame + Vector3.new(0, 3, 0)
		elseif spawn:IsA("Model") and spawn.PrimaryPart then
			return spawn:GetPrimaryPartCFrame() + Vector3.new(0, 3, 0)
		end
	end

	-- Fallback: Look for spawns in Workspace directly (legacy support)
	local spawnFolder = workspace:FindFirstChild("SpawnLocations")
	if not spawnFolder then
		-- No spawn folder - use VERY HIGH default positions to avoid maps
		warn("[TeamManager] No SpawnLocations folder - using default spawn position")
		if team.Name == GameConfig.TEAM_1_NAME then
			print("[TeamManager] Spawning at Y=150 (left)")
			return CFrame.new(-50, 150, 0) -- Much higher spawn
		else
			print("[TeamManager] Spawning at Y=150 (right)")
			return CFrame.new(50, 150, 0)
		end
	end

	local teamSpawnFolder
	if team.Name == GameConfig.TEAM_1_NAME then
		teamSpawnFolder = spawnFolder:FindFirstChild("Team1Spawns")
	else
		teamSpawnFolder = spawnFolder:FindFirstChild("Team2Spawns")
	end

	if not teamSpawnFolder then
		-- No team spawn folder - use VERY HIGH default positions
		warn("[TeamManager] No team spawn folder - using default spawn position")
		if team.Name == GameConfig.TEAM_1_NAME then
			print("[TeamManager] Spawning at Y=150 (left)")
			return CFrame.new(-50, 150, 0)
		else
			print("[TeamManager] Spawning at Y=150 (right)")
			return CFrame.new(50, 150, 0)
		end
	end

	local spawns = teamSpawnFolder:GetChildren()
	if #spawns == 0 then
		-- Return VERY HIGH default spawn positions based on team
		warn("[TeamManager] No spawns in team folder - using default spawn position")
		if team.Name == GameConfig.TEAM_1_NAME then
			print("[TeamManager] Spawning at Y=150 (left)")
			return CFrame.new(-50, 150, 0) -- Much higher
		else
			print("[TeamManager] Spawning at Y=150 (right)")
			return CFrame.new(50, 150, 0)
		end
	end

	-- Get random spawn
	local randomSpawn = spawns[math.random(1, #spawns)]
	if randomSpawn:IsA("BasePart") then
		return randomSpawn.CFrame + Vector3.new(0, 3, 0)
	elseif randomSpawn:IsA("Model") and randomSpawn.PrimaryPart then
		return randomSpawn:GetPrimaryPartCFrame() + Vector3.new(0, 3, 0)
	end

	print("[TeamManager] Last resort spawn at Y=150")
	return CFrame.new(0, 150, 0)
end

-- Respawn player
function TeamManager.RespawnPlayer(player, instant)
	instant = instant or true

	-- In practice mode, assign team if player doesn't have one
	if not player.Team then
		if GameConfig.PRACTICE_MODE then
			-- Assign to team 1 for practice mode
			local team1 = game.Teams:FindFirstChild(GameConfig.TEAM_1_NAME)
			if team1 then
				player.Team = team1
				print(string.format("[TeamManager] Assigned %s to %s (Practice Mode)", player.Name, team1.Name))
			else
				warn("[TeamManager] No team found for practice mode:", player.Name)
				return
			end
		else
			warn("[TeamManager] Player has no team:", player.Name)
			return
		end
	end

	-- Load character if needed
	if not player.Character then
		player:LoadCharacter()
	end

	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- Set spawn location
	local spawnCFrame = TeamManager.GetTeamSpawnPoint(player.Team)
	character:SetPrimaryPartCFrame(spawnCFrame)

	-- Reset health
	humanoid.Health = GameConfig.MAX_HEALTH
	humanoid.MaxHealth = GameConfig.MAX_HEALTH

	-- Note: Weapon equipping is now handled by the caller (Bootstrapper SpawnPlayerEvent)

	print(string.format("[TeamManager] Respawned %s at position: %s", player.Name, tostring(spawnCFrame.Position)))
end

-- Handle player death
function TeamManager.OnPlayerDeath(player, killer, killData)
	-- killData contains: IsHeadshot, Distance, IsAirborne, IsSliding, etc.
	killData = killData or {}

	-- Update stats
	if TeamManager.PlayerData[player.UserId] then
		TeamManager.PlayerData[player.UserId].Deaths = TeamManager.PlayerData[player.UserId].Deaths + 1
	end

	if killer and TeamManager.PlayerData[killer.UserId] then
		TeamManager.PlayerData[killer.UserId].Kills = TeamManager.PlayerData[killer.UserId].Kills + 1

		-- Award kill rewards via EconomyManager
		local EconomyManager = require(script.Parent.EconomyManager)
		local rewards = EconomyManager.AwardKill(killer, killData)

		-- TODO: Send reward notification to killer's client
		if rewards then
			print(string.format(
				"[TeamManager] %s killed %s - Earned %d Score, %d Shards",
				killer.Name,
				player.Name,
				rewards.ScoreEarned,
				rewards.ShardsEarned
			))
		end
	end

	-- TODO: Notify game mode of death

	-- DO NOT auto-respawn - player stays dead until they manually spawn from Main Menu
	print(string.format("[TeamManager] %s died - awaiting manual respawn", player.Name))
end

-- Setup player death handling
function TeamManager.SetupDeathHandling(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Re-equip weapon when character spawns (after death or manual spawn)
		task.spawn(function()
			character:WaitForChild("HumanoidRootPart")
			task.wait(0.5) -- Wait for character to fully load

			-- Check if player has any tools
			local hasWeapon = false
			for _, tool in pairs(player.Backpack:GetChildren()) do
				if tool:IsA("Tool") then
					hasWeapon = true
					break
				end
			end

			-- Also check character for tools
			if not hasWeapon then
				for _, tool in pairs(character:GetChildren()) do
					if tool:IsA("Tool") then
						hasWeapon = true
						break
					end
				end
			end

			if not hasWeapon and player.Character then
				-- Re-equip their weapon after respawn
				print(string.format("[TeamManager] Character respawned without weapon, re-equipping for %s", player.Name))
				TeamManager.EquipWeapon(player)
			else
				print(string.format("[TeamManager] Character already has weapon for %s", player.Name))
			end
		end)

		humanoid.Died:Connect(function()
			-- Find who killed them (if anyone)
			local killer = nil
			local lastDamager = humanoid:FindFirstChild("creator")
			if lastDamager and lastDamager.Value then
				killer = lastDamager.Value
			end

			TeamManager.OnPlayerDeath(player, killer)
		end)
	end)
end

return TeamManager
