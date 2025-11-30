--[[
	WeaponHUD.client.lua
	Displays weapon information (ammo, crosshair, hit markers)
	Location: StarterPlayer > StarterPlayerScripts > WeaponHUD
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponHUD = {}

-- HUD elements
WeaponHUD.ScreenGui = nil
WeaponHUD.AmmoLabel = nil
WeaponHUD.WeaponNameLabel = nil
WeaponHUD.Crosshair = nil
WeaponHUD.HitMarker = nil

-- Initialize HUD
function WeaponHUD.Initialize()
	-- Create ScreenGui
	WeaponHUD.ScreenGui = Instance.new("ScreenGui")
	WeaponHUD.ScreenGui.Name = "WeaponHUD"
	WeaponHUD.ScreenGui.ResetOnSpawn = false
	WeaponHUD.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	WeaponHUD.ScreenGui.Parent = playerGui

	-- Create crosshair
	WeaponHUD.CreateCrosshair()

	-- Create ammo display
	WeaponHUD.CreateAmmoDisplay()

	-- Create hit marker
	WeaponHUD.CreateHitMarker()

	-- Update loop
	RunService.RenderStepped:Connect(function()
		WeaponHUD.Update()
	end)

	print("[WeaponHUD] Initialized")
end

-- Create crosshair
function WeaponHUD.CreateCrosshair()
	local crosshairFrame = Instance.new("Frame")
	crosshairFrame.Name = "Crosshair"
	crosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshairFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	crosshairFrame.Size = UDim2.new(0, 30, 0, 30)
	crosshairFrame.BackgroundTransparency = 1
	crosshairFrame.Parent = WeaponHUD.ScreenGui

	-- Center dot
	local centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerDot.Size = UDim2.new(0, 2, 0, 2)
	centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	centerDot.BorderSizePixel = 0
	centerDot.Parent = crosshairFrame

	-- Top line
	local topLine = Instance.new("Frame")
	topLine.Name = "TopLine"
	topLine.AnchorPoint = Vector2.new(0.5, 1)
	topLine.Position = UDim2.new(0.5, 0, 0.5, -5)
	topLine.Size = UDim2.new(0, 2, 0, 8)
	topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topLine.BorderSizePixel = 0
	topLine.Parent = crosshairFrame

	-- Bottom line
	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "BottomLine"
	bottomLine.AnchorPoint = Vector2.new(0.5, 0)
	bottomLine.Position = UDim2.new(0.5, 0, 0.5, 5)
	bottomLine.Size = UDim2.new(0, 2, 0, 8)
	bottomLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bottomLine.BorderSizePixel = 0
	bottomLine.Parent = crosshairFrame

	-- Left line
	local leftLine = Instance.new("Frame")
	leftLine.Name = "LeftLine"
	leftLine.AnchorPoint = Vector2.new(1, 0.5)
	leftLine.Position = UDim2.new(0.5, -5, 0.5, 0)
	leftLine.Size = UDim2.new(0, 8, 0, 2)
	leftLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	leftLine.BorderSizePixel = 0
	leftLine.Parent = crosshairFrame

	-- Right line
	local rightLine = Instance.new("Frame")
	rightLine.Name = "RightLine"
	rightLine.AnchorPoint = Vector2.new(0, 0.5)
	rightLine.Position = UDim2.new(0.5, 5, 0.5, 0)
	rightLine.Size = UDim2.new(0, 8, 0, 2)
	rightLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	rightLine.BorderSizePixel = 0
	rightLine.Parent = crosshairFrame

	WeaponHUD.Crosshair = crosshairFrame
end

-- Create ammo display
function WeaponHUD.CreateAmmoDisplay()
	-- Container frame
	local ammoFrame = Instance.new("Frame")
	ammoFrame.Name = "AmmoDisplay"
	ammoFrame.AnchorPoint = Vector2.new(1, 1)
	ammoFrame.Position = UDim2.new(1, -20, 1, -20)
	ammoFrame.Size = UDim2.new(0, 200, 0, 80)
	ammoFrame.BackgroundTransparency = 1
	ammoFrame.Parent = WeaponHUD.ScreenGui

	-- Weapon name
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Position = UDim2.new(0, 0, 0, 0)
	weaponName.Size = UDim2.new(1, 0, 0, 25)
	weaponName.BackgroundTransparency = 1
	weaponName.Font = Enum.Font.GothamBold
	weaponName.TextSize = 18
	weaponName.TextColor3 = Color3.fromRGB(255, 255, 255)
	weaponName.TextXAlignment = Enum.TextXAlignment.Right
	weaponName.TextStrokeTransparency = 0.5
	weaponName.Text = ""
	weaponName.Parent = ammoFrame

	-- Ammo count
	local ammoLabel = Instance.new("TextLabel")
	ammoLabel.Name = "AmmoCount"
	ammoLabel.Position = UDim2.new(0, 0, 0, 25)
	ammoLabel.Size = UDim2.new(1, 0, 0, 50)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.Font = Enum.Font.GothamBold
	ammoLabel.TextSize = 36
	ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
	ammoLabel.TextStrokeTransparency = 0.5
	ammoLabel.Text = ""
	ammoLabel.Parent = ammoFrame

	WeaponHUD.AmmoLabel = ammoLabel
	WeaponHUD.WeaponNameLabel = weaponName
end

-- Create hit marker
function WeaponHUD.CreateHitMarker()
	local hitMarker = Instance.new("ImageLabel")
	hitMarker.Name = "HitMarker"
	hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	hitMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
	hitMarker.Size = UDim2.new(0, 40, 0, 40)
	hitMarker.BackgroundTransparency = 1
	hitMarker.ImageColor3 = Color3.fromRGB(255, 255, 255)
	hitMarker.ImageTransparency = 1
	hitMarker.Parent = WeaponHUD.ScreenGui

	-- Create X shape with frames
	local markerFrame = Instance.new("Frame")
	markerFrame.Name = "MarkerFrame"
	markerFrame.Size = UDim2.new(1, 0, 1, 0)
	markerFrame.BackgroundTransparency = 1
	markerFrame.Parent = hitMarker

	-- Top-left to bottom-right
	local line1 = Instance.new("Frame")
	line1.Name = "Line1"
	line1.AnchorPoint = Vector2.new(0.5, 0.5)
	line1.Position = UDim2.new(0.5, 0, 0.5, 0)
	line1.Size = UDim2.new(0, 3, 1.4, 0)
	line1.Rotation = 45
	line1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line1.BorderSizePixel = 0
	line1.Parent = markerFrame

	-- Top-right to bottom-left
	local line2 = Instance.new("Frame")
	line2.Name = "Line2"
	line2.AnchorPoint = Vector2.new(0.5, 0.5)
	line2.Position = UDim2.new(0.5, 0, 0.5, 0)
	line2.Size = UDim2.new(0, 3, 1.4, 0)
	line2.Rotation = -45
	line2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line2.BorderSizePixel = 0
	line2.Parent = markerFrame

	WeaponHUD.HitMarker = hitMarker
end

-- Show hit marker
function WeaponHUD.ShowHitMarker(isHeadshot)
	if not WeaponHUD.HitMarker then return end

	-- Set color based on headshot
	local color = isHeadshot and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255)

	for _, child in pairs(WeaponHUD.HitMarker.MarkerFrame:GetChildren()) do
		if child:IsA("Frame") then
			child.BackgroundColor3 = color
		end
	end

	-- Show and fade out
	WeaponHUD.HitMarker.ImageTransparency = 0

	local startTime = tick()
	local duration = 0.2

	-- Animate fade out
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.clamp(elapsed / duration, 0, 1)

		WeaponHUD.HitMarker.ImageTransparency = alpha

		if alpha >= 1 then
			connection:Disconnect()
		end
	end)
end

-- Update HUD
function WeaponHUD.Update()
	-- Get weapon client module
	local weaponClient = require(script.Parent.WeaponClient)

	if weaponClient.EquippedWeaponName then
		local weaponStats = require(game.ReplicatedStorage.Modules.WeaponStats).GetWeapon(weaponClient.EquippedWeaponName)

		-- Update weapon name
		WeaponHUD.WeaponNameLabel.Text = weaponStats.DisplayName

		-- Update ammo display
		if weaponClient.IsReloading then
			WeaponHUD.AmmoLabel.Text = "RELOADING..."
			WeaponHUD.AmmoLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		else
			WeaponHUD.AmmoLabel.Text = string.format("%d / %d", weaponClient.Ammo, weaponClient.MaxAmmo)

			-- Change color based on ammo level
			if weaponClient.Ammo == 0 then
				WeaponHUD.AmmoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			elseif weaponClient.Ammo <= weaponStats.MagazineSize * 0.3 then
				WeaponHUD.AmmoLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			else
				WeaponHUD.AmmoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	else
		-- No weapon equipped
		WeaponHUD.WeaponNameLabel.Text = ""
		WeaponHUD.AmmoLabel.Text = ""
	end
end

-- Initialize on script load
WeaponHUD.Initialize()

return WeaponHUD
