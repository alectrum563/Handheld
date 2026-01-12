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
		Range = 1000,             -- Very long range - travels until hitting wall/target
		DamageFalloffStart = 40,  -- Distance where falloff begins
		MinDamage = 8,            -- Minimum damage at max range
		MagazineSize = 20,        -- Increased from 15
		ReloadTime = 1.5,

		-- Recoil (light for fast pistol)
		RecoilVertical = 0.15,    -- Vertical kick in radians
		RecoilHorizontal = 0.05,  -- Horizontal kick in radians
		BulletRadius = 0.5,       -- Spherecast radius for bullet magnetism
		BulletSpread = 0.35,      -- High spread (0-1, higher = more inaccurate) - fast fire rate = less accurate

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
		Range = 1000,             -- Very long range - travels until hitting wall/target
		DamageFalloffStart = 60,
		MinDamage = 15,
		MagazineSize = 10,
		ReloadTime = 2.0,

		-- Recoil (medium for balanced pistol)
		RecoilVertical = 0.2,     -- Vertical kick in radians
		RecoilHorizontal = 0.08,  -- Horizontal kick in radians
		BulletRadius = 0.6,       -- Spherecast radius for bullet magnetism
		BulletSpread = 0.15,      -- Medium spread - balanced fire rate = balanced accuracy

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
		Range = 1000,             -- Very long range - travels until hitting wall/target
		DamageFalloffStart = 80,
		MinDamage = 25,
		MagazineSize = 6,
		ReloadTime = 2.5,

		-- Recoil (heavy for hand cannon)
		RecoilVertical = 0.3,     -- Strong vertical kick
		RecoilHorizontal = 0.12,  -- Strong horizontal kick
		BulletRadius = 0.7,       -- Larger spherecast radius
		BulletSpread = 0.05,      -- Low spread - slow fire rate = very accurate

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
