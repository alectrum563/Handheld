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
local CameraRecoil = require(ReplicatedStorage.Modules.CameraRecoil)
local CanDamageHumanoid = require(ReplicatedStorage.Modules.CanDamageHumanoid)
local Remotes = ReplicatedStorage.Remotes

local WeaponClient = {}

-- DEBUG MODE: Set to true to show visual indicators of bullet spread
local DEBUG_BULLET_SPREAD = false

-- Weapon state
WeaponClient.CurrentWeapon = nil
WeaponClient.EquippedWeaponName = nil
WeaponClient.Ammo = 0
WeaponClient.MaxAmmo = 0
WeaponClient.IsReloading = false
WeaponClient.IsShooting = false
WeaponClient.LastShotTime = 0
WeaponClient.SharedHUDState = nil -- Reference to WeaponHUD's state
WeaponClient.HUDReference = nil -- Reference to WeaponHUD module for hit markers

-- Helper to sync state to HUD
function WeaponClient.SyncToHUD()
	if WeaponClient.SharedHUDState then
		WeaponClient.SharedHUDState.EquippedWeaponName = WeaponClient.EquippedWeaponName
		WeaponClient.SharedHUDState.Ammo = WeaponClient.Ammo
		WeaponClient.SharedHUDState.MaxAmmo = WeaponClient.MaxAmmo
		WeaponClient.SharedHUDState.IsReloading = WeaponClient.IsReloading
	end
end

-- Input state
local mouseDown = false

-- Initialize weapon client
function WeaponClient.Initialize()
	-- Use shared state module in ReplicatedStorage
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	WeaponClient.SharedHUDState = require(ReplicatedStorage.Modules.WeaponClientState)

	-- Initialize camera recoil system
	CameraRecoil.Initialize()

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

	-- Sync to HUD
	WeaponClient.SyncToHUD()

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

	-- Sync to HUD
	WeaponClient.SyncToHUD()

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
		-- Fire rate limiting - too soon to shoot again
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
	WeaponClient.SyncToHUD()

	-- Apply camera recoil
	local verticalRecoil = weaponStats.RecoilVertical or 0.2
	local horizontalRecoil = weaponStats.RecoilHorizontal or 0.05
	-- Random horizontal direction (left or right)
	local horizontalDirection = (math.random() > 0.5) and 1 or -1
	local recoilVector = Vector2.new(horizontalRecoil * horizontalDirection, -verticalRecoil) -- Negative Y = upward kick
	CameraRecoil.ApplyRecoil(recoilVector)

	-- CRITICAL: Create ray through crosshair position (offset upward from center)
	-- Get viewport dimensions
	local viewportSize = camera.ViewportSize

	-- Calculate precise center point (floating point for sub-pixel accuracy)
	local centerX = viewportSize.X * 0.5
	local centerY = viewportSize.Y * 0.5

	-- Offset to match crosshair position (70 pixels up)
	local crosshairOffsetY = -70

	-- Create ray from camera through crosshair position
	-- Depth of 0 gives us the near plane, which is what we want for first-person
	local ray = camera:ViewportPointToRay(centerX, centerY + crosshairOffsetY, 0)

	-- Use the ray's origin (camera position) and direction
	local rayOrigin = ray.Origin
	local rayDirection = ray.Direction

	-- DEBUG: Show where center of screen ray goes (before spread)
	if DEBUG_BULLET_SPREAD then
		local debugPart = Instance.new("Part")
		debugPart.Size = Vector3.new(0.5, 0.5, 0.5)
		debugPart.Position = rayOrigin + rayDirection * 10
		debugPart.Anchored = true
		debugPart.CanCollide = false
		debugPart.Color = Color3.fromRGB(0, 255, 0) -- Green = center ray
		debugPart.Material = Enum.Material.Neon
		debugPart.Parent = workspace
		task.delay(3, function() debugPart:Destroy() end)
	end

	-- Apply bullet spread (cone of fire)
	-- BulletSpread is 0-1, where higher = more inaccurate
	local spreadAmount = weaponStats.BulletSpread or 0
	if spreadAmount > 0 then
		-- Convert spread (0-1) to degrees (0-10 degrees max)
		local maxSpreadDegrees = 10
		local spreadDegrees = spreadAmount * maxSpreadDegrees
		local spreadRadians = math.rad(spreadDegrees)

		-- Generate random offset within cone
		-- Use gaussian-like distribution for more natural spread
		local randomAngle = math.random() * math.pi * 2
		local randomRadius = (math.random() + math.random()) / 2 -- Average of two randoms = bell curve

		-- Calculate spread offset in radians
		local horizontalSpread = math.cos(randomAngle) * spreadRadians * randomRadius
		local verticalSpread = math.sin(randomAngle) * spreadRadians * randomRadius

		-- Apply spread to direction using rotation
		-- Create perpendicular vectors for the spread offset
		local right = rayDirection:Cross(Vector3.new(0, 1, 0)).Unit
		local up = rayDirection:Cross(right).Unit

		-- Apply the spread offset
		rayDirection = (rayDirection + right * horizontalSpread + up * verticalSpread).Unit

		-- DEBUG: Show where bullet goes after spread
		if DEBUG_BULLET_SPREAD then
			local debugPart = Instance.new("Part")
			debugPart.Size = Vector3.new(0.3, 0.3, 0.3)
			debugPart.Position = rayOrigin + rayDirection * 10
			debugPart.Anchored = true
			debugPart.CanCollide = false
			debugPart.Color = Color3.fromRGB(255, 255, 0) -- Yellow = spread bullet
			debugPart.Material = Enum.Material.Neon
			debugPart.Parent = workspace
			task.delay(3, function() debugPart:Destroy() end)
		end
	end

	rayDirection = rayDirection * weaponStats.Range

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.IgnoreWater = true

	-- Use team collision group to allow bullets to pass through teammates
	if player.Team and not player.Neutral then
		raycastParams.CollisionGroup = player.Team.Name
	end

	-- Use Spherecast for bullet magnetism (makes near-misses count as hits)
	-- This provides a more forgiving shooting experience
	local bulletRadius = weaponStats.BulletRadius or 0.5
	local raycastResult = workspace:Spherecast(rayOrigin, bulletRadius, rayDirection, raycastParams)

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

		-- Check if we hit a character (player or NPC)
		local hitCharacter = hitPart.Parent
		local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")

		if hitHumanoid and CanDamageHumanoid(player, hitHumanoid) then
			-- Determine if headshot
			local isHeadshot = hitPart.Name == "Head"

			-- Check if it's a player
			local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)

			if hitPlayer then
				-- Send hit data to server for player hits
				Remotes.WeaponFired:FireServer({
					WeaponName = WeaponClient.EquippedWeaponName,
					HitPlayer = hitPlayer,
					HitPart = hitPart,
					HitPosition = hitPosition,
					Distance = hitDistance,
					IsHeadshot = isHeadshot,
					Timestamp = tick()
				})
			else
				-- Hit an NPC/Dummy - apply damage directly (client-side for practice)
				local weaponStats = WeaponStats.GetWeapon(WeaponClient.EquippedWeaponName)
				if weaponStats then
					local damage = WeaponStats.CalculateDamage(WeaponClient.EquippedWeaponName, hitDistance, isHeadshot)
					hitHumanoid:TakeDamage(damage)
					print(string.format("[WeaponClient] Hit %s for %d damage (%s) - Health: %.0f/%.0f",
						hitCharacter.Name, damage, isHeadshot and "HEADSHOT" or "Body", hitHumanoid.Health, hitHumanoid.MaxHealth))

					-- Create red square on dummy hit
					WeaponClient.CreateDummyHitMarker(hitPosition, hitNormal, hitPart)
				end
			end

			-- Show hit marker for any hit (player or NPC)
			print("[WeaponClient] Calling ShowHitMarker - SharedHUDState:", WeaponClient.SharedHUDState ~= nil, "ShowHitMarker:", WeaponClient.SharedHUDState and WeaponClient.SharedHUDState.ShowHitMarker ~= nil)
			if WeaponClient.SharedHUDState and WeaponClient.SharedHUDState.ShowHitMarker then
				WeaponClient.SharedHUDState.ShowHitMarker(isHeadshot)
				print("[WeaponClient] Hit marker shown for", isHeadshot and "HEADSHOT" or "body shot")
			else
				warn("[WeaponClient] Cannot show hit marker - callback not registered!")
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

	-- Visual feedback: Faint tracer line from gun to hit point
	WeaponClient.CreateTracerLine(rayOrigin, hitPosition, weaponStats)

	-- Optional: Create brief impact flash on dummy only
	if raycastResult and hitPart and hitPart.Parent and hitPart.Parent.Name == "TargetDummy" then
		WeaponClient.CreateDummyHitMarker(hitPosition, hitNormal, hitPart)
	end
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
	WeaponClient.SyncToHUD()
	print(string.format("[WeaponClient] Reloading... (%.1fs)", weaponStats.ReloadTime))

	-- Reload after delay
	local weaponNameToReload = WeaponClient.EquippedWeaponName
	task.delay(weaponStats.ReloadTime, function()
		-- Only complete reload if still have the same weapon equipped
		if WeaponClient.EquippedWeaponName == weaponNameToReload then
			WeaponClient.Ammo = WeaponClient.MaxAmmo
			WeaponClient.IsReloading = false
			WeaponClient.SyncToHUD()
			print(string.format("[WeaponClient] Reload complete - Ammo: %d/%d", WeaponClient.Ammo, WeaponClient.MaxAmmo))
		end
	end)
end

-- Create faint tracer line using Beam (performant)
function WeaponClient.CreateTracerLine(startPos, endPos, weaponStats)
	-- Create invisible parts to hold attachments
	local startPart = Instance.new("Part")
	startPart.Transparency = 1
	startPart.Size = Vector3.new(0.1, 0.1, 0.1)
	startPart.Position = startPos
	startPart.Anchored = true
	startPart.CanCollide = false
	startPart.Parent = workspace

	local endPart = Instance.new("Part")
	endPart.Transparency = 1
	endPart.Size = Vector3.new(0.1, 0.1, 0.1)
	endPart.Position = endPos
	endPart.Anchored = true
	endPart.CanCollide = false
	endPart.Parent = workspace

	-- Create attachments for beam
	local startAttachment = Instance.new("Attachment")
	startAttachment.Parent = startPart

	local endAttachment = Instance.new("Attachment")
	endAttachment.Parent = endPart

	-- Create beam (thin, faint tracer)
	local beam = Instance.new("Beam")
	beam.Attachment0 = startAttachment
	beam.Attachment1 = endAttachment
	beam.Width0 = 0.05 -- Very thin
	beam.Width1 = 0.05
	beam.Color = ColorSequence.new(weaponStats.MuzzleFlashColor)
	beam.Transparency = NumberSequence.new(0.7) -- Very faint
	beam.FaceCamera = true
	beam.LightEmission = 0.5
	beam.Parent = startPart

	-- Destroy everything quickly (0.1 second)
	task.delay(0.1, function()
		startPart:Destroy()
		endPart:Destroy()
	end)
end

-- Create brief hit marker on dummy (lightweight)
function WeaponClient.CreateDummyHitMarker(position, normal, hitPart)
	if not hitPart or not hitPart:IsA("BasePart") then return end

	-- Create a small red marker at hit position
	local marker = Instance.new("Part")
	marker.Name = "DummyHitMarker"
	marker.Size = Vector3.new(0.25, 0.25, 0.05)
	marker.CFrame = CFrame.new(position + normal * 0.02, position + normal)
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(255, 50, 50)
	marker.Transparency = 0.3
	marker.Parent = workspace

	-- Quick fade and destroy (0.3s total)
	task.delay(0.3, function()
		if marker.Parent then
			marker:Destroy()
		end
	end)
end

-- Hit effect function removed for pure hitscan system
-- Bullet holes and impact effects disabled for better performance

-- Initialize on script load
WeaponClient.Initialize()

return WeaponClient
