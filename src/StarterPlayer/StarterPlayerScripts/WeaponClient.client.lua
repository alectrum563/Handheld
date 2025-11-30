--[[
	WeaponClient.client.lua
	Handles client-side weapon shooting, reloading, and visual feedback
	Location: StarterPlayer > StarterPlayerScripts > WeaponClient
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)
local Remotes = ReplicatedStorage.Remotes

local WeaponClient = {}

-- Weapon state
WeaponClient.CurrentWeapon = nil
WeaponClient.EquippedWeaponName = nil
WeaponClient.Ammo = 0
WeaponClient.MaxAmmo = 0
WeaponClient.IsReloading = false
WeaponClient.IsShooting = false
WeaponClient.LastShotTime = 0

-- Input state
local mouseDown = false

-- Initialize weapon client
function WeaponClient.Initialize()
	-- Listen for weapon equip events from server
	Remotes.EquipWeapon.OnClientEvent:Connect(function(weaponName)
		WeaponClient.EquipWeapon(weaponName)
	end)

	-- Setup input handling
	WeaponClient.SetupInputHandling()

	-- Setup render loop for shooting
	RunService.RenderStepped:Connect(function()
		WeaponClient.Update()
	end)

	print("[WeaponClient] Initialized")
end

-- Equip a weapon
function WeaponClient.EquipWeapon(weaponName)
	local weaponStats = WeaponStats.GetWeapon(weaponName)
	if not weaponStats then
		warn("[WeaponClient] Unknown weapon:", weaponName)
		return
	end

	-- Unequip current weapon
	if WeaponClient.CurrentWeapon then
		WeaponClient.UnequipWeapon()
	end

	-- Set new weapon
	WeaponClient.EquippedWeaponName = weaponName
	WeaponClient.Ammo = weaponStats.MagazineSize
	WeaponClient.MaxAmmo = weaponStats.MagazineSize
	WeaponClient.IsReloading = false

	print(string.format("[WeaponClient] Equipped %s (%d/%d ammo)", weaponStats.DisplayName, WeaponClient.Ammo, WeaponClient.MaxAmmo))

	-- TODO: Create weapon Tool object and equip to character
	-- For now, we'll just track the equipped weapon
end

-- Unequip current weapon
function WeaponClient.UnequipWeapon()
	if not WeaponClient.EquippedWeaponName then return end

	print(string.format("[WeaponClient] Unequipped %s", WeaponClient.EquippedWeaponName))

	WeaponClient.EquippedWeaponName = nil
	WeaponClient.Ammo = 0
	WeaponClient.IsReloading = false
	WeaponClient.IsShooting = false

	-- TODO: Destroy weapon Tool object
end

-- Setup input handling
function WeaponClient.SetupInputHandling()
	-- Mouse button down
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Left mouse button - shoot
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDown = true
		end

		-- R key - reload
		if input.KeyCode == Enum.KeyCode.R then
			WeaponClient.Reload()
		end
	end)

	-- Mouse button up
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		-- Left mouse button - stop shooting
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDown = false
			WeaponClient.IsShooting = false
		end
	end)
end

-- Update loop
function WeaponClient.Update()
	-- Check if we should shoot
	if mouseDown and WeaponClient.EquippedWeaponName and not WeaponClient.IsReloading then
		WeaponClient.TryShoot()
	end
end

-- Attempt to shoot
function WeaponClient.TryShoot()
	local weaponStats = WeaponStats.GetWeapon(WeaponClient.EquippedWeaponName)
	if not weaponStats then return end

	-- Check fire rate
	local currentTime = tick()
	local timeSinceLastShot = currentTime - WeaponClient.LastShotTime
	if timeSinceLastShot < weaponStats.FireRate then
		return
	end

	-- Check ammo
	if WeaponClient.Ammo <= 0 then
		-- Auto-reload if out of ammo
		WeaponClient.Reload()
		return
	end

	-- Perform shot
	WeaponClient.Shoot()
	WeaponClient.LastShotTime = currentTime
end

-- Perform a shot
function WeaponClient.Shoot()
	local weaponStats = WeaponStats.GetWeapon(WeaponClient.EquippedWeaponName)
	if not weaponStats then return end

	-- Consume ammo
	WeaponClient.Ammo = WeaponClient.Ammo - 1

	-- Raycast from camera
	local rayOrigin = camera.CFrame.Position
	local rayDirection = camera.CFrame.LookVector * weaponStats.Range

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	-- Process hit
	local hitPart = nil
	local hitPosition = rayOrigin + rayDirection
	local hitNormal = Vector3.new(0, 1, 0)
	local hitDistance = weaponStats.Range

	if raycastResult then
		hitPart = raycastResult.Instance
		hitPosition = raycastResult.Position
		hitNormal = raycastResult.Normal
		hitDistance = (hitPosition - rayOrigin).Magnitude

		-- Check if we hit a player
		local hitCharacter = hitPart.Parent
		if hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid") then
			local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
			if hitPlayer then
				-- Determine if headshot
				local isHeadshot = hitPart.Name == "Head"

				-- Send hit data to server for validation
				Remotes.WeaponFired:FireServer({
					WeaponName = WeaponClient.EquippedWeaponName,
					HitPlayer = hitPlayer,
					HitPart = hitPart,
					HitPosition = hitPosition,
					Distance = hitDistance,
					IsHeadshot = isHeadshot,
					Timestamp = tick()
				})

				-- Show hit marker
				local weaponHUD = require(script.Parent.WeaponHUD)
				weaponHUD.ShowHitMarker(isHeadshot)
			end
		end
	else
		-- Send miss data to server (for anti-cheat tracking)
		Remotes.WeaponFired:FireServer({
			WeaponName = WeaponClient.EquippedWeaponName,
			HitPlayer = nil,
			HitPosition = hitPosition,
			Distance = hitDistance,
			IsHeadshot = false,
			Timestamp = tick()
		})
	end

	-- Visual feedback
	WeaponClient.CreateMuzzleFlash(weaponStats)
	WeaponClient.CreateBulletTracer(rayOrigin, hitPosition, weaponStats)

	if raycastResult then
		WeaponClient.CreateHitEffect(hitPosition, hitNormal)
	end

	print(string.format("[WeaponClient] Shot fired - Ammo: %d/%d", WeaponClient.Ammo, WeaponClient.MaxAmmo))
end

-- Reload weapon
function WeaponClient.Reload()
	if WeaponClient.IsReloading then return end
	if not WeaponClient.EquippedWeaponName then return end

	local weaponStats = WeaponStats.GetWeapon(WeaponClient.EquippedWeaponName)
	if not weaponStats then return end

	-- Check if already full
	if WeaponClient.Ammo >= WeaponClient.MaxAmmo then
		print("[WeaponClient] Magazine already full")
		return
	end

	WeaponClient.IsReloading = true
	print(string.format("[WeaponClient] Reloading... (%.1fs)", weaponStats.ReloadTime))

	-- Reload after delay
	task.delay(weaponStats.ReloadTime, function()
		if WeaponClient.EquippedWeaponName == weaponStats.Name then
			WeaponClient.Ammo = WeaponClient.MaxAmmo
			WeaponClient.IsReloading = false
			print(string.format("[WeaponClient] Reload complete - Ammo: %d/%d", WeaponClient.Ammo, WeaponClient.MaxAmmo))
		end
	end)
end

-- Create muzzle flash effect
function WeaponClient.CreateMuzzleFlash(weaponStats)
	local character = player.Character
	if not character then return end

	-- Get camera position as muzzle location (first-person)
	local muzzlePosition = camera.CFrame.Position + camera.CFrame.LookVector * 2

	-- Create flash
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Size = Vector3.new(0.5, 0.5, 0.5)
	flash.Position = muzzlePosition
	flash.Anchored = true
	flash.CanCollide = false
	flash.Material = Enum.Material.Neon
	flash.Color = weaponStats.MuzzleFlashColor
	flash.Transparency = 0.3
	flash.Parent = workspace

	-- Add point light
	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Range = 10
	light.Color = weaponStats.MuzzleFlashColor
	light.Parent = flash

	-- Remove after brief moment
	task.delay(0.05, function()
		flash:Destroy()
	end)
end

-- Create bullet tracer
function WeaponClient.CreateBulletTracer(startPos, endPos, weaponStats)
	local direction = (endPos - startPos)
	local distance = direction.Magnitude
	local midPoint = startPos + direction / 2

	-- Create tracer beam
	local tracer = Instance.new("Part")
	tracer.Name = "BulletTracer"
	tracer.Size = Vector3.new(0.1, 0.1, distance)
	tracer.CFrame = CFrame.new(midPoint, endPos)
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = weaponStats.MuzzleFlashColor
	tracer.Transparency = 0.5
	tracer.Parent = workspace

	-- Fade out and remove
	task.delay(0.1, function()
		tracer:Destroy()
	end)
end

-- Create hit effect
function WeaponClient.CreateHitEffect(position, normal)
	-- Create impact particle
	local impact = Instance.new("Part")
	impact.Name = "BulletImpact"
	impact.Size = Vector3.new(0.3, 0.3, 0.3)
	impact.Position = position
	impact.Anchored = true
	impact.CanCollide = false
	impact.Material = Enum.Material.Neon
	impact.Color = Color3.fromRGB(255, 255, 100)
	impact.Transparency = 0.3
	impact.Parent = workspace

	-- Remove after brief moment
	task.delay(0.2, function()
		impact:Destroy()
	end)
end

-- Initialize on script load
WeaponClient.Initialize()

return WeaponClient
