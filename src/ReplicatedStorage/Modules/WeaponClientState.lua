--[[
	WeaponClientState.lua
	Shared state between WeaponClient and WeaponHUD
	Location: ReplicatedStorage > Modules > WeaponClientState
]]

local WeaponClientState = {}

-- Shared weapon state (accessible by both WeaponClient and WeaponHUD)
WeaponClientState.EquippedWeaponName = nil
WeaponClientState.Ammo = 0
WeaponClientState.MaxAmmo = 0
WeaponClientState.IsReloading = false
WeaponClientState.IsFiring = false

-- Hit marker callback (set by WeaponHUD)
WeaponClientState.ShowHitMarker = nil

return WeaponClientState
