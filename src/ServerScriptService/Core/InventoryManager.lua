--[[
	InventoryManager.lua
	Manages player weapon inventories with DataStore persistence
	Location: ServerScriptService > Core > InventoryManager
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)

local InventoryManager = {}
InventoryManager.PlayerInventories = {} -- Cache of loaded inventories
InventoryManager.EquippedWeapons = {} -- Currently equipped weapon per player

-- DataStore (with fallback for Studio testing)
local InventoryStore = nil
local DataStoreEnabled = false

local success, err = pcall(function()
	InventoryStore = DataStoreService:GetDataStore("PlayerInventories")
	DataStoreEnabled = true
end)

if not success then
	warn("[InventoryManager] DataStore not available (Studio testing mode) - using in-memory storage only")
	warn("[InventoryManager] To enable persistence, publish your game to Roblox")
else
	print("[InventoryManager] DataStore enabled - inventory will persist between sessions")
end

-- Default starter weapons (all players get these)
local STARTER_WEAPONS = {
	{WeaponName = "FastPistol", SkinId = "default"},
	{WeaponName = "BalancedPistol", SkinId = "default"},
	{WeaponName = "SlowPistol", SkinId = "default"},
}

-- Generate unique ID for weapon instance
local function GenerateWeaponId()
	return HttpService:GenerateGUID(false)
end

-- Create default inventory for new players
function InventoryManager.CreateDefaultInventory()
	local inventory = {}

	for _, weaponData in ipairs(STARTER_WEAPONS) do
		table.insert(inventory, {
			Id = GenerateWeaponId(),
			WeaponName = weaponData.WeaponName,
			SkinId = weaponData.SkinId,
			UnlockedAt = os.time(),
		})
	end

	return inventory
end

-- Load player inventory from DataStore
function InventoryManager.LoadInventory(player)
	-- If DataStore is not available, just create default inventory
	if not DataStoreEnabled then
		local newInventory = InventoryManager.CreateDefaultInventory()
		print(string.format("[InventoryManager] Created new inventory for %s (%d weapons) [Studio Mode]", player.Name, #newInventory))
		return newInventory
	end

	local success, result = pcall(function()
		return InventoryStore:GetAsync("Inventory_" .. player.UserId)
	end)

	if success then
		if result then
			-- Player has existing inventory
			print(string.format("[InventoryManager] Loaded inventory for %s (%d weapons)", player.Name, #result))
			return result
		else
			-- New player - create default inventory
			local newInventory = InventoryManager.CreateDefaultInventory()
			print(string.format("[InventoryManager] Created new inventory for %s (%d weapons)", player.Name, #newInventory))
			return newInventory
		end
	else
		warn("[InventoryManager] Failed to load inventory for", player.Name, ":", result)
		-- Return default inventory as fallback
		return InventoryManager.CreateDefaultInventory()
	end
end

-- Save player inventory to DataStore
function InventoryManager.SaveInventory(player)
	local inventory = InventoryManager.PlayerInventories[player.UserId]
	if not inventory then
		warn("[InventoryManager] No inventory to save for", player.Name)
		return false
	end

	-- If DataStore is not available, skip saving (Studio mode)
	if not DataStoreEnabled then
		-- Don't spam warnings, just silently skip in Studio mode
		return true
	end

	local success, err = pcall(function()
		InventoryStore:SetAsync("Inventory_" .. player.UserId, inventory)
	end)

	if success then
		print(string.format("[InventoryManager] Saved inventory for %s (%d weapons)", player.Name, #inventory))
		return true
	else
		warn("[InventoryManager] Failed to save inventory for", player.Name, ":", err)
		return false
	end
end

-- Initialize inventory for player
function InventoryManager.InitializePlayer(player)
	-- Load inventory
	local inventory = InventoryManager.LoadInventory(player)
	InventoryManager.PlayerInventories[player.UserId] = inventory

	-- Set default equipped weapon (first weapon in inventory)
	if #inventory > 0 then
		InventoryManager.EquippedWeapons[player.UserId] = inventory[1].Id
		print(string.format("[InventoryManager] %s equipped: %s", player.Name, inventory[1].WeaponName))
	else
		warn("[InventoryManager] Player has empty inventory:", player.Name)
	end
end

-- Get player's inventory
function InventoryManager.GetInventory(player)
	return InventoryManager.PlayerInventories[player.UserId] or {}
end

-- Get player's equipped weapon
function InventoryManager.GetEquippedWeapon(player)
	local equippedId = InventoryManager.EquippedWeapons[player.UserId]
	if not equippedId then
		return nil
	end

	local inventory = InventoryManager.GetInventory(player)
	for _, weapon in ipairs(inventory) do
		if weapon.Id == equippedId then
			return weapon
		end
	end

	return nil
end

-- Equip a weapon from inventory
function InventoryManager.EquipWeapon(player, weaponId)
	local inventory = InventoryManager.GetInventory(player)

	-- Check if player owns this weapon
	local hasWeapon = false
	for _, weapon in ipairs(inventory) do
		if weapon.Id == weaponId then
			hasWeapon = true
			break
		end
	end

	if not hasWeapon then
		warn(string.format("[InventoryManager] %s tried to equip weapon they don't own: %s", player.Name, weaponId))
		return false
	end

	-- Equip the weapon
	InventoryManager.EquippedWeapons[player.UserId] = weaponId
	print(string.format("[InventoryManager] %s equipped weapon: %s", player.Name, weaponId))

	return true
end

-- Add weapon to player's inventory (for future case opening)
function InventoryManager.AddWeapon(player, weaponName, skinId)
	skinId = skinId or "default"

	-- Verify weapon exists
	local weaponStats = WeaponStats.GetWeapon(weaponName)
	if not weaponStats then
		warn("[InventoryManager] Tried to add invalid weapon:", weaponName)
		return false
	end

	local inventory = InventoryManager.GetInventory(player)

	-- Create new weapon instance
	local newWeapon = {
		Id = GenerateWeaponId(),
		WeaponName = weaponName,
		SkinId = skinId,
		UnlockedAt = os.time(),
	}

	table.insert(inventory, newWeapon)
	print(string.format("[InventoryManager] Added %s (%s skin) to %s's inventory", weaponName, skinId, player.Name))

	-- Save inventory
	InventoryManager.SaveInventory(player)

	return newWeapon.Id
end

-- Remove weapon from inventory (optional - for trading/selling)
function InventoryManager.RemoveWeapon(player, weaponId)
	local inventory = InventoryManager.GetInventory(player)

	-- Don't allow removing if it's the only weapon
	if #inventory <= 1 then
		warn("[InventoryManager] Cannot remove last weapon from inventory")
		return false
	end

	-- Find and remove weapon
	for i, weapon in ipairs(inventory) do
		if weapon.Id == weaponId then
			-- If this was equipped, equip something else
			if InventoryManager.EquippedWeapons[player.UserId] == weaponId then
				-- Equip first available weapon
				if i > 1 then
					InventoryManager.EquippedWeapons[player.UserId] = inventory[1].Id
				else
					InventoryManager.EquippedWeapons[player.UserId] = inventory[2].Id
				end
			end

			table.remove(inventory, i)
			print(string.format("[InventoryManager] Removed weapon %s from %s's inventory", weaponId, player.Name))

			-- Save inventory
			InventoryManager.SaveInventory(player)
			return true
		end
	end

	warn("[InventoryManager] Weapon not found in inventory:", weaponId)
	return false
end

-- Cleanup player data
function InventoryManager.CleanupPlayer(player)
	-- Save inventory before cleanup
	InventoryManager.SaveInventory(player)

	-- Clear cache
	InventoryManager.PlayerInventories[player.UserId] = nil
	InventoryManager.EquippedWeapons[player.UserId] = nil

	print(string.format("[InventoryManager] Cleaned up inventory for %s", player.Name))
end

-- Get formatted inventory data for client
function InventoryManager.GetInventoryData(player)
	local inventory = InventoryManager.GetInventory(player)
	local equippedId = InventoryManager.EquippedWeapons[player.UserId]

	local inventoryData = {}
	for _, weapon in ipairs(inventory) do
		table.insert(inventoryData, {
			Id = weapon.Id,
			WeaponName = weapon.WeaponName,
			SkinId = weapon.SkinId,
			IsEquipped = (weapon.Id == equippedId),
			UnlockedAt = weapon.UnlockedAt,
		})
	end

	return inventoryData
end

return InventoryManager
