--[[
	FixEverything.server.lua
	ONE-TIME FIX: Creates remotes and gives you all 3 weapons
	Location: ServerScriptService > FixEverything

	DELETE THIS SCRIPT after it runs successfully
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("======================================================")
print("           FIXING EVERYTHING - PLEASE WAIT")
print("======================================================")

task.wait(1) -- Wait for game to initialize

-- ===== STEP 1: CREATE ALL REMOTES =====
print("[FixEverything] Step 1: Creating Remotes...")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
	print("[FixEverything] ✓ Created Remotes folder")
end

-- Create RemoteFunctions
local remoteFunctionsToCreate = {"GetInventory", "GetEconomy"}
for _, name in ipairs(remoteFunctionsToCreate) do
	if not Remotes:FindFirstChild(name) then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = Remotes
		print(string.format("[FixEverything] ✓ Created RemoteFunction: %s", name))
	end
end

-- Create RemoteEvents
local remoteEventsToCreate = {
	"EquipWeapon", "SpawnPlayer", "TogglePracticeMode",
	"PracticeModeUpdate", "RoundState", "WeaponFired",
	"DamagePlayer", "GameModeUpdate"
}
for _, name in ipairs(remoteEventsToCreate) do
	if not Remotes:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = Remotes
		print(string.format("[FixEverything] ✓ Created RemoteEvent: %s", name))
	end
end

print("[FixEverything] ✓ Step 1 Complete: All remotes created")

-- ===== STEP 2: VERIFY INVENTORY MANAGER =====
print("[FixEverything] Step 2: Checking InventoryManager...")

local ServerScriptService = game:GetService("ServerScriptService")
local Core = ServerScriptService:WaitForChild("Core", 5)
if not Core then
	warn("[FixEverything] ✗ Core folder not found!")
	return
end

local InventoryManager = require(Core.InventoryManager)
print("[FixEverything] ✓ InventoryManager loaded")

-- ===== STEP 3: RESET ALL PLAYER INVENTORIES =====
print("[FixEverything] Step 3: Resetting player inventories...")

task.wait(1) -- Wait for players to fully initialize

for _, player in ipairs(Players:GetPlayers()) do
	-- Clear and reinitialize
	if InventoryManager.PlayerInventories[player.UserId] then
		InventoryManager.PlayerInventories[player.UserId] = nil
		print(string.format("[FixEverything] Cleared cached inventory for %s", player.Name))
	end

	InventoryManager.InitializePlayer(player)

	local inventory = InventoryManager.GetInventory(player)
	print(string.format("[FixEverything] ✓ %s now has %d weapons:", player.Name, #inventory))

	for i, weapon in ipairs(inventory) do
		print(string.format("    %d. %s (ID: %s)", i, weapon.WeaponName, weapon.Id))
	end
end

print("======================================================")
print("           FIX COMPLETE!")
print("  1. STOP the game")
print("  2. SAVE the place (Ctrl+S)")
print("  3. DELETE this FixEverything script")
print("  4. DELETE BuildRemotes and ResetInventory scripts")
print("  5. RUN the game again")
print("  6. Press G to open inventory - you should see all 3 weapons!")
print("======================================================")
