--[[
	WeaponBuilder.server.lua
	Programmatically creates weapon Tools in ReplicatedStorage
	This runs once at server start to build all weapon Tools
	Location: ServerScriptService > WeaponBuilder
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)

local WeaponBuilder = {}

-- Create a weapon Tool
function WeaponBuilder.CreateWeaponTool(weaponName)
	local weaponStats = WeaponStats.GetWeapon(weaponName)
	if not weaponStats then
		warn("[WeaponBuilder] Unknown weapon:", weaponName)
		return nil
	end

	-- Create Tool
	local tool = Instance.new("Tool")
	tool.Name = weaponName
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ManualActivationOnly = true -- We handle shooting in WeaponClient

	-- Create Handle (the visual part the player holds)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 0.6, 1.2) -- Pistol-like proportions
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false

	-- Color based on weapon type
	if weaponName == "FastPistol" then
		handle.Color = Color3.fromRGB(100, 150, 255) -- Blue
	elseif weaponName == "BalancedPistol" then
		handle.Color = Color3.fromRGB(150, 150, 150) -- Gray
	elseif weaponName == "SlowPistol" then
		handle.Color = Color3.fromRGB(255, 100, 100) -- Red
	end

	handle.Parent = tool

	-- Add weapon type identifier
	local weaponType = Instance.new("StringValue")
	weaponType.Name = "WeaponType"
	weaponType.Value = weaponName
	weaponType.Parent = tool

	-- Add weapon data storage (for unique weapon IDs, skins, etc.)
	local weaponData = Instance.new("Folder")
	weaponData.Name = "WeaponData"
	weaponData.Parent = tool

	-- Weapon ID (will be set by InventoryManager when equipped)
	local weaponId = Instance.new("StringValue")
	weaponId.Name = "WeaponId"
	weaponId.Value = ""
	weaponId.Parent = weaponData

	-- Skin ID (will be set by InventoryManager)
	local skinId = Instance.new("StringValue")
	skinId.Name = "SkinId"
	skinId.Value = "default"
	skinId.Parent = weaponData

	print(string.format("[WeaponBuilder] Created weapon Tool: %s (%s)", weaponStats.DisplayName, weaponName))

	return tool
end

-- Build all weapons
function WeaponBuilder.BuildAllWeapons()
	print("[WeaponBuilder] Building weapon Tools...")

	-- Ensure Weapons folder exists
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	if not weaponsFolder then
		weaponsFolder = Instance.new("Folder")
		weaponsFolder.Name = "Weapons"
		weaponsFolder.Parent = ReplicatedStorage
		print("[WeaponBuilder] Created Weapons folder in ReplicatedStorage")
	end

	-- Clear existing weapons (so we can rebuild if needed)
	for _, child in ipairs(weaponsFolder:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end

	-- Create all weapons
	local weaponNames = WeaponStats.GetAllWeaponNames()
	for _, weaponName in ipairs(weaponNames) do
		local tool = WeaponBuilder.CreateWeaponTool(weaponName)
		if tool then
			tool.Parent = weaponsFolder
		end
	end

	print(string.format("[WeaponBuilder] Built %d weapon Tools", #weaponNames))
end

-- Auto-build weapons when this module is required
WeaponBuilder.BuildAllWeapons()

return WeaponBuilder
