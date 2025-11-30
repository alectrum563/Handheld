--[[
	WeaponStats.lua
	Weapon configuration and statistics
	Location: ReplicatedStorage > Modules > WeaponStats
]]

local WeaponStats = {}

-- Weapon Configurations
WeaponStats.Weapons = {
	FastPistol = {
		Name = "Rapid Fire",
		DisplayName = "Rapid Fire",
		Damage = 20,              -- Base damage at optimal range
		HeadshotMultiplier = 2.0, -- 40 damage headshots
		FireRate = 0.1,           -- seconds between shots (10 rounds/sec)
		Range = 80,               -- Max effective range (studs)
		DamageFalloffStart = 40,  -- Distance where falloff begins
		MinDamage = 8,            -- Minimum damage at max range
		MagazineSize = 15,
		ReloadTime = 1.5,

		-- Visual/Audio
		MuzzleFlashColor = Color3.fromRGB(255, 200, 100),
		BulletSpeed = 500,        -- studs/sec for visual tracer
		SoundId = "",             -- Will add later
	},

	BalancedPistol = {
		Name = "Standard Issue",
		DisplayName = "Standard Issue",
		Damage = 35,              -- 3 body shots or 2 headshots to kill
		HeadshotMultiplier = 2.0, -- 70 damage headshots
		FireRate = 0.25,          -- 4 rounds/sec
		Range = 120,
		DamageFalloffStart = 60,
		MinDamage = 15,
		MagazineSize = 10,
		ReloadTime = 2.0,

		-- Visual/Audio
		MuzzleFlashColor = Color3.fromRGB(255, 180, 80),
		BulletSpeed = 600,
		SoundId = "",
	},

	SlowPistol = {
		Name = "Hand Cannon",
		DisplayName = "Hand Cannon",
		Damage = 50,              -- 2 body shots or 1 headshot to kill
		HeadshotMultiplier = 2.0, -- 100 damage headshots (instant kill)
		FireRate = 0.5,           -- 2 rounds/sec
		Range = 150,
		DamageFalloffStart = 80,
		MinDamage = 25,
		MagazineSize = 6,
		ReloadTime = 2.5,

		-- Visual/Audio
		MuzzleFlashColor = Color3.fromRGB(255, 150, 50),
		BulletSpeed = 700,
		SoundId = "",
	},
}

-- Get weapon stats by name
function WeaponStats.GetWeapon(weaponName)
	return WeaponStats.Weapons[weaponName]
end

-- Get all weapon names
function WeaponStats.GetAllWeaponNames()
	local names = {}
	for weaponName, _ in pairs(WeaponStats.Weapons) do
		table.insert(names, weaponName)
	end
	return names
end

-- Calculate damage based on distance and hit location
function WeaponStats.CalculateDamage(weaponName, distance, isHeadshot)
	local weapon = WeaponStats.GetWeapon(weaponName)
	if not weapon then
		warn("Unknown weapon:", weaponName)
		return 0
	end

	local damage = weapon.Damage

	-- Apply headshot multiplier
	if isHeadshot then
		damage = damage * weapon.HeadshotMultiplier
	end

	-- Apply distance falloff
	if distance > weapon.DamageFalloffStart then
		local falloffRatio = (distance - weapon.DamageFalloffStart) / (weapon.Range - weapon.DamageFalloffStart)
		falloffRatio = math.clamp(falloffRatio, 0, 1)
		damage = weapon.Damage + (weapon.MinDamage - weapon.Damage) * falloffRatio
	end

	return math.floor(damage)
end

return WeaponStats
