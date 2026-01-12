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
WeaponHUD.ScreenCorners = {}
WeaponHUD.GlitchElements = {} -- Elements that glitch/shimmer

-- Animation state
WeaponHUD.AnimTime = 0
WeaponHUD.NextGlitchTime = 0

-- Initialize HUD
function WeaponHUD.Initialize()
	-- Create ScreenGui
	WeaponHUD.ScreenGui = Instance.new("ScreenGui")
	WeaponHUD.ScreenGui.Name = "WeaponHUD"
	WeaponHUD.ScreenGui.ResetOnSpawn = false
	WeaponHUD.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	WeaponHUD.ScreenGui.Parent = playerGui

	-- Create holographic screen corners
	WeaponHUD.CreateScreenCorners()

	-- Create crosshair
	WeaponHUD.CreateCrosshair()

	-- Create ammo display
	WeaponHUD.CreateAmmoDisplay()

	-- Create hit marker
	WeaponHUD.CreateHitMarker()

	-- Update loop with deltaTime for smooth animations
	RunService.RenderStepped:Connect(function(deltaTime)
		WeaponHUD.Update(deltaTime)
	end)

	print("[WeaponHUD] Initialized")
end

-- Create holographic screen corners
function WeaponHUD.CreateScreenCorners()
	local hologramColor = Color3.fromRGB(0, 255, 255) -- Cyan
	local hologramGlow = Color3.fromRGB(100, 255, 255) -- Light cyan

	local function createScreenCorner(name, anchorPoint, position)
		local cornerFrame = Instance.new("Frame")
		cornerFrame.Name = name
		cornerFrame.AnchorPoint = anchorPoint
		cornerFrame.Position = position
		cornerFrame.Size = UDim2.new(0, 80, 0, 80)
		cornerFrame.BackgroundTransparency = 1
		cornerFrame.Parent = WeaponHUD.ScreenGui

		-- Horizontal line
		local hLine = Instance.new("Frame")
		hLine.Name = "HLine"
		hLine.Size = UDim2.new(0, 50, 0, 2)
		hLine.BackgroundColor3 = hologramColor
		hLine.BackgroundTransparency = 0.2
		hLine.BorderSizePixel = 0
		hLine.Parent = cornerFrame

		-- Vertical line
		local vLine = Instance.new("Frame")
		vLine.Name = "VLine"
		vLine.Size = UDim2.new(0, 2, 0, 50)
		vLine.BackgroundColor3 = hologramColor
		vLine.BackgroundTransparency = 0.2
		vLine.BorderSizePixel = 0
		vLine.Parent = cornerFrame

		-- Add glow to lines
		local hStroke = Instance.new("UIStroke")
		hStroke.Color = hologramGlow
		hStroke.Thickness = 1
		hStroke.Transparency = 0.5
		hStroke.Parent = hLine

		local vStroke = Instance.new("UIStroke")
		vStroke.Color = hologramGlow
		vStroke.Thickness = 1
		vStroke.Transparency = 0.5
		vStroke.Parent = vLine

		-- Position lines based on corner
		if name == "TopLeft" then
			hLine.Position = UDim2.new(0, 0, 0, 0)
			vLine.Position = UDim2.new(0, 0, 0, 0)
		elseif name == "TopRight" then
			hLine.AnchorPoint = Vector2.new(1, 0)
			hLine.Position = UDim2.new(1, 0, 0, 0)
			vLine.AnchorPoint = Vector2.new(1, 0)
			vLine.Position = UDim2.new(1, 0, 0, 0)
		elseif name == "BottomLeft" then
			hLine.AnchorPoint = Vector2.new(0, 1)
			hLine.Position = UDim2.new(0, 0, 1, 0)
			vLine.AnchorPoint = Vector2.new(0, 1)
			vLine.Position = UDim2.new(0, 0, 1, 0)
		else -- BottomRight
			hLine.AnchorPoint = Vector2.new(1, 1)
			hLine.Position = UDim2.new(1, 0, 1, 0)
			vLine.AnchorPoint = Vector2.new(1, 1)
			vLine.Position = UDim2.new(1, 0, 1, 0)
		end

		-- Small accent dot in corner
		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.Size = UDim2.new(0, 4, 0, 4)
		dot.BackgroundColor3 = hologramGlow
		dot.BackgroundTransparency = 0
		dot.BorderSizePixel = 0
		dot.Parent = cornerFrame

		if name == "TopLeft" then
			dot.Position = UDim2.new(0, -1, 0, -1)
		elseif name == "TopRight" then
			dot.AnchorPoint = Vector2.new(1, 0)
			dot.Position = UDim2.new(1, 1, 0, -1)
		elseif name == "BottomLeft" then
			dot.AnchorPoint = Vector2.new(0, 1)
			dot.Position = UDim2.new(0, -1, 1, 1)
		else -- BottomRight
			dot.AnchorPoint = Vector2.new(1, 1)
			dot.Position = UDim2.new(1, 1, 1, 1)
		end

		return cornerFrame
	end

	-- Create all four corners and store for glitch animation
	WeaponHUD.ScreenCorners.TopLeft = createScreenCorner("TopLeft", Vector2.new(0, 0), UDim2.new(0, 20, 0, 20))
	WeaponHUD.ScreenCorners.TopRight = createScreenCorner("TopRight", Vector2.new(1, 0), UDim2.new(1, -20, 0, 20))
	WeaponHUD.ScreenCorners.BottomLeft = createScreenCorner("BottomLeft", Vector2.new(0, 1), UDim2.new(0, 20, 1, -20))
	WeaponHUD.ScreenCorners.BottomRight = createScreenCorner("BottomRight", Vector2.new(1, 1), UDim2.new(1, -20, 1, -20))

	-- Add corners to glitch elements list
	for _, corner in pairs(WeaponHUD.ScreenCorners) do
		table.insert(WeaponHUD.GlitchElements, corner)
	end
end

-- Create simple crosshair (original design)
function WeaponHUD.CreateCrosshair()
	local crosshairFrame = Instance.new("Frame")
	crosshairFrame.Name = "Crosshair"
	crosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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

-- Create futuristic ammo display
function WeaponHUD.CreateAmmoDisplay()
	local hologramColor = Color3.fromRGB(0, 255, 255) -- Cyan
	local hologramGlow = Color3.fromRGB(100, 255, 255) -- Light cyan

	-- Container frame with holographic panel
	local ammoFrame = Instance.new("Frame")
	ammoFrame.Name = "AmmoDisplay"
	ammoFrame.AnchorPoint = Vector2.new(1, 1)
	ammoFrame.Position = UDim2.new(1, -30, 1, -30)
	ammoFrame.Size = UDim2.new(0, 250, 0, 120)
	ammoFrame.BackgroundColor3 = Color3.fromRGB(0, 10, 15)
	ammoFrame.BackgroundTransparency = 0.6
	ammoFrame.BorderSizePixel = 0
	ammoFrame.Parent = WeaponHUD.ScreenGui

	-- Add holographic border glow
	local ammoStroke = Instance.new("UIStroke")
	ammoStroke.Color = hologramColor
	ammoStroke.Thickness = 2
	ammoStroke.Transparency = 0.3
	ammoStroke.Parent = ammoFrame

	-- Corner decorations
	local function createCornerBracket(name, anchorPoint, position, rotation)
		local bracket = Instance.new("Frame")
		bracket.Name = name
		bracket.AnchorPoint = anchorPoint
		bracket.Position = position
		bracket.Size = UDim2.new(0, 20, 0, 2)
		bracket.BackgroundColor3 = hologramGlow
		bracket.BackgroundTransparency = 0.1
		bracket.BorderSizePixel = 0
		bracket.Rotation = rotation
		bracket.Parent = ammoFrame

		-- Add glow stroke
		local stroke = Instance.new("UIStroke")
		stroke.Color = hologramColor
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = bracket

		return bracket
	end

	-- Top-left corner
	createCornerBracket("TopLeftH", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), 0)
	createCornerBracket("TopLeftV", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), 90)

	-- Top-right corner
	createCornerBracket("TopRightH", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), 0)
	createCornerBracket("TopRightV", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), 90)

	-- Bottom-left corner
	createCornerBracket("BottomLeftH", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), 0)
	createCornerBracket("BottomLeftV", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), 90)

	-- Bottom-right corner
	createCornerBracket("BottomRightH", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), 0)
	createCornerBracket("BottomRightV", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), 90)

	-- Weapon name with holographic effect
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Position = UDim2.new(0, 15, 0, 10)
	weaponName.Size = UDim2.new(1, -30, 0, 30)
	weaponName.BackgroundTransparency = 1
	weaponName.Font = Enum.Font.Code -- Monospace for tech look
	weaponName.TextSize = 16
	weaponName.TextColor3 = hologramGlow
	weaponName.TextXAlignment = Enum.TextXAlignment.Left
	weaponName.TextStrokeTransparency = 0
	weaponName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	weaponName.Text = ""
	weaponName.Parent = ammoFrame

	-- Ammo count with large holographic numbers
	local ammoLabel = Instance.new("TextLabel")
	ammoLabel.Name = "AmmoCount"
	ammoLabel.Position = UDim2.new(0, 15, 0, 45)
	ammoLabel.Size = UDim2.new(1, -30, 0, 60)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.Font = Enum.Font.Code
	ammoLabel.TextSize = 48
	ammoLabel.TextColor3 = hologramColor
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
	ammoLabel.TextStrokeTransparency = 0
	ammoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	ammoLabel.Text = ""
	ammoLabel.Parent = ammoFrame

	-- Ammo bar background
	local ammoBarBG = Instance.new("Frame")
	ammoBarBG.Name = "AmmoBarBG"
	ammoBarBG.Position = UDim2.new(0, 15, 1, -15)
	ammoBarBG.Size = UDim2.new(1, -30, 0, 4)
	ammoBarBG.AnchorPoint = Vector2.new(0, 1)
	ammoBarBG.BackgroundColor3 = Color3.fromRGB(0, 50, 60)
	ammoBarBG.BackgroundTransparency = 0.3
	ammoBarBG.BorderSizePixel = 0
	ammoBarBG.Parent = ammoFrame

	-- Ammo bar fill
	local ammoBar = Instance.new("Frame")
	ammoBar.Name = "AmmoBar"
	ammoBar.Size = UDim2.new(1, 0, 1, 0)
	ammoBar.BackgroundColor3 = hologramColor
	ammoBar.BackgroundTransparency = 0.1
	ammoBar.BorderSizePixel = 0
	ammoBar.Parent = ammoBarBG

	-- Add glow to ammo bar
	local barStroke = Instance.new("UIStroke")
	barStroke.Color = hologramGlow
	barStroke.Thickness = 1
	barStroke.Transparency = 0.3
	barStroke.Parent = ammoBar

	-- Cell shading details - translucent lines for depth
	local cellShadingContainer = Instance.new("Frame")
	cellShadingContainer.Name = "CellShading"
	cellShadingContainer.Size = UDim2.new(1, 0, 1, 0)
	cellShadingContainer.BackgroundTransparency = 1
	cellShadingContainer.Parent = ammoFrame

	-- Diagonal lines for cell shading effect
	for i = 1, 8 do
		local line = Instance.new("Frame")
		line.Name = "ShadeLine" .. i
		line.Size = UDim2.new(0, 1, 1.5, 0)
		line.Position = UDim2.new(0, i * 30, 0, 0)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = hologramColor
		line.BackgroundTransparency = 0.85 -- Very translucent
		line.BorderSizePixel = 0
		line.Rotation = 15 -- Slight diagonal
		line.Parent = cellShadingContainer
	end

	-- Horizontal detail lines
	for i = 1, 3 do
		local hLine = Instance.new("Frame")
		hLine.Name = "DetailLine" .. i
		hLine.Size = UDim2.new(1, 0, 0, 1)
		hLine.Position = UDim2.new(0, 0, 0.25 * i, 0)
		hLine.BackgroundColor3 = hologramGlow
		hLine.BackgroundTransparency = 0.9 -- Very subtle
		hLine.BorderSizePixel = 0
		hLine.Parent = cellShadingContainer
	end

	WeaponHUD.AmmoLabel = ammoLabel
	WeaponHUD.WeaponNameLabel = weaponName
	WeaponHUD.AmmoBar = ammoBar
	WeaponHUD.AmmoFrame = ammoFrame
	WeaponHUD.CellShading = cellShadingContainer

	-- Add ammo frame to glitch elements
	table.insert(WeaponHUD.GlitchElements, ammoFrame)
end

-- Create futuristic hit marker
function WeaponHUD.CreateHitMarker()
	local hologramColor = Color3.fromRGB(0, 255, 255) -- Cyan
	local hitColor = Color3.fromRGB(255, 100, 100) -- Red-pink for hits
	local headshotColor = Color3.fromRGB(255, 50, 50) -- Brighter red for headshots

	local hitMarker = Instance.new("Frame")
	hitMarker.Name = "HitMarker"
	hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Position will be updated dynamically to match viewport center
	hitMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
	hitMarker.Size = UDim2.new(0, 60, 0, 60)
	hitMarker.BackgroundTransparency = 1
	hitMarker.Parent = WeaponHUD.ScreenGui

	-- Create hexagonal hit marker
	local markerFrame = Instance.new("Frame")
	markerFrame.Name = "MarkerFrame"
	markerFrame.Size = UDim2.new(1, 0, 1, 0)
	markerFrame.BackgroundTransparency = 1
	markerFrame.Visible = false -- Start hidden
	markerFrame.Parent = hitMarker

	-- Center pulse circle
	local pulseCircle = Instance.new("ImageLabel")
	pulseCircle.Name = "PulseCircle"
	pulseCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	pulseCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
	pulseCircle.Size = UDim2.new(0, 30, 0, 30)
	pulseCircle.BackgroundTransparency = 1
	pulseCircle.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	pulseCircle.ImageColor3 = hitColor
	pulseCircle.ImageTransparency = 0.3
	pulseCircle.Parent = markerFrame

	-- Four corner brackets (diamond shape)
	local function createHitBracket(name, rotation, position)
		local bracket = Instance.new("Frame")
		bracket.Name = name
		bracket.AnchorPoint = Vector2.new(0.5, 0.5)
		bracket.Position = position
		bracket.Size = UDim2.new(0, 12, 0, 3)
		bracket.BackgroundColor3 = hitColor
		bracket.BackgroundTransparency = 0
		bracket.BorderSizePixel = 0
		bracket.Rotation = rotation
		bracket.Parent = markerFrame

		-- Add glow effect
		local stroke = Instance.new("UIStroke")
		stroke.Color = hitColor
		stroke.Thickness = 2
		stroke.Transparency = 0.3
		stroke.Parent = bracket

		return bracket
	end

	-- Create diamond pattern brackets
	createHitBracket("TopBracket", 0, UDim2.new(0.5, 0, 0.5, -20))
	createHitBracket("RightBracket", 90, UDim2.new(0.5, 20, 0.5, 0))
	createHitBracket("BottomBracket", 0, UDim2.new(0.5, 0, 0.5, 20))
	createHitBracket("LeftBracket", 90, UDim2.new(0.5, -20, 0.5, 0))

	-- Small corner accents
	for i = 0, 3 do
		local angle = i * 90
		local radians = math.rad(angle + 45) -- Offset by 45 degrees for corners
		local distance = 18

		local accent = Instance.new("Frame")
		accent.Name = "Accent" .. i
		accent.AnchorPoint = Vector2.new(0.5, 0.5)
		accent.Position = UDim2.new(0.5, math.cos(radians) * distance, 0.5, math.sin(radians) * distance)
		accent.Size = UDim2.new(0, 4, 0, 4)
		accent.BackgroundColor3 = hitColor
		accent.BackgroundTransparency = 0
		accent.BorderSizePixel = 0
		accent.Parent = markerFrame
	end

	WeaponHUD.HitMarker = hitMarker
	WeaponHUD.HitMarkerFrame = markerFrame
	WeaponHUD.PulseCircle = pulseCircle
end

-- Show futuristic hit marker with animations
function WeaponHUD.ShowHitMarker(isHeadshot)
	if not WeaponHUD.HitMarkerFrame or not WeaponHUD.PulseCircle then return end

	local markerFrame = WeaponHUD.HitMarkerFrame

	-- Show the marker
	markerFrame.Visible = true

	-- Set color (brighter red for headshots, lighter for normal hits)
	local color = isHeadshot and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 100, 100)

	-- Update all bracket colors
	for _, child in pairs(markerFrame:GetChildren()) do
		if child:IsA("Frame") then
			child.BackgroundColor3 = color
			-- Update stroke color too
			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = color
			end
		end
	end

	-- Update pulse circle color
	if WeaponHUD.PulseCircle then
		WeaponHUD.PulseCircle.ImageColor3 = color
	end

	local startTime = tick()
	local duration = 0.5 -- Faster fade for more responsive feel
	local initialSize = isHeadshot and 40 or 30
	local expandSize = isHeadshot and 50 or 40

	-- Animate expansion and fade out
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = elapsed / duration

		if elapsed >= duration then
			markerFrame.Visible = false
			-- Reset size
			if WeaponHUD.PulseCircle then
				WeaponHUD.PulseCircle.Size = UDim2.new(0, 30, 0, 30)
			end
			connection:Disconnect()
		else
			-- Expand pulse circle
			if WeaponHUD.PulseCircle then
				local currentSize = initialSize + (expandSize - initialSize) * progress
				WeaponHUD.PulseCircle.Size = UDim2.new(0, currentSize, 0, currentSize)
				WeaponHUD.PulseCircle.ImageTransparency = 0.3 + (0.7 * progress) -- Fade out
			end

			-- Fade out brackets
			for _, child in pairs(markerFrame:GetChildren()) do
				if child:IsA("Frame") then
					child.BackgroundTransparency = progress
					local stroke = child:FindFirstChildOfClass("UIStroke")
					if stroke then
						stroke.Transparency = 0.3 + (0.7 * progress)
					end
				end
			end
		end
	end)
end

-- Use shared weapon state from ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
WeaponHUD.WeaponState = require(ReplicatedStorage.Modules.WeaponClientState)

-- Register hit marker function so WeaponClient can call it
WeaponHUD.WeaponState.ShowHitMarker = function(isHeadshot)
	WeaponHUD.ShowHitMarker(isHeadshot)
end

-- Apply holographic shimmer effect
function WeaponHUD.ApplyShimmer(deltaTime)
	WeaponHUD.AnimTime = WeaponHUD.AnimTime + deltaTime

	-- Shimmer all UI strokes with sine wave
	local shimmerIntensity = 0.5 + math.sin(WeaponHUD.AnimTime * 3) * 0.2

	-- Shimmer corner brackets
	for _, corner in pairs(WeaponHUD.ScreenCorners) do
		if corner then
			for _, child in pairs(corner:GetChildren()) do
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Transparency = 0.3 + (shimmerIntensity * 0.2)
				end
			end
		end
	end

	-- Shimmer ammo frame border
	if WeaponHUD.AmmoFrame then
		local ammoStroke = WeaponHUD.AmmoFrame:FindFirstChildOfClass("UIStroke")
		if ammoStroke then
			ammoStroke.Transparency = 0.2 + (shimmerIntensity * 0.15)
		end
	end

	-- Shimmer cell shading lines
	if WeaponHUD.CellShading then
		for _, line in pairs(WeaponHUD.CellShading:GetChildren()) do
			if line.Name:find("ShadeLine") then
				line.BackgroundTransparency = 0.85 + (math.sin(WeaponHUD.AnimTime * 2 + tonumber(line.Name:match("%d+")) * 0.3) * 0.05)
			end
		end
	end
end

-- Apply random glitch effect
function WeaponHUD.ApplyGlitch()
	-- Random chance to glitch (very rare)
	if math.random() > 0.98 then -- 2% chance per frame
		local glitchDuration = 0.05 -- Very brief
		local glitchElement = WeaponHUD.GlitchElements[math.random(1, #WeaponHUD.GlitchElements)]

		if glitchElement and glitchElement:IsA("GuiObject") then
			-- Store original position
			local originalPos = glitchElement.Position

			-- Random glitch offset
			local glitchOffset = UDim2.new(0, math.random(-3, 3), 0, math.random(-2, 2))

			-- Apply glitch
			glitchElement.Position = originalPos + glitchOffset

			-- Quick transparency flicker
			local originalTransparency = glitchElement.BackgroundTransparency
			glitchElement.BackgroundTransparency = math.min(1, originalTransparency + 0.3)

			-- Reset after brief moment
			task.delay(glitchDuration, function()
				if glitchElement and glitchElement.Parent then
					glitchElement.Position = originalPos
					glitchElement.BackgroundTransparency = originalTransparency
				end
			end)
		end
	end
end

-- Update HUD
function WeaponHUD.Update(deltaTime)
	-- Check if menu is open (from CameraState)
	local CameraState = require(game.ReplicatedStorage.Modules.CameraState)
	local isMenuOpen = CameraState.MenuOpen

	-- Hide crosshair and ammo when menu is open
	if WeaponHUD.Crosshair then
		WeaponHUD.Crosshair.Visible = not isMenuOpen
	end
	if WeaponHUD.AmmoFrame then
		WeaponHUD.AmmoFrame.Visible = not isMenuOpen
	end

	-- Apply holographic effects
	WeaponHUD.ApplyShimmer(deltaTime or 0.016) -- Default to ~60fps if no deltaTime
	WeaponHUD.ApplyGlitch()

	-- CRITICAL: Position crosshair and hit marker at EXACT viewport center where bullets actually go
	if WeaponHUD.Crosshair or WeaponHUD.HitMarker then
		local camera = workspace.CurrentCamera
		local viewportSize = camera.ViewportSize

		-- Calculate precise viewport center (exact same calculation as bullet trajectory in WeaponClient)
		local centerX = viewportSize.X * 0.5
		local centerY = viewportSize.Y * 0.5

		-- Offset crosshair upward from center (70 pixels up for better visibility)
		local crosshairOffsetY = -70

		-- Use absolute positioning to match exact pixel where bullet goes
		if WeaponHUD.Crosshair then
			WeaponHUD.Crosshair.Position = UDim2.new(0, centerX, 0, centerY + crosshairOffsetY)
		end
		if WeaponHUD.HitMarker then
			WeaponHUD.HitMarker.Position = UDim2.new(0, centerX, 0, centerY + crosshairOffsetY)
		end
	end

	-- Use shared weapon state
	if WeaponHUD.WeaponState.EquippedWeaponName then
		local weaponStats = require(game.ReplicatedStorage.Modules.WeaponStats).GetWeapon(WeaponHUD.WeaponState.EquippedWeaponName)

		-- Holographic colors
		local hologramColor = Color3.fromRGB(0, 255, 255) -- Cyan
		local warningColor = Color3.fromRGB(255, 200, 100) -- Orange
		local criticalColor = Color3.fromRGB(255, 100, 100) -- Red

		-- Update weapon name with holographic glow
		WeaponHUD.WeaponNameLabel.Text = "[ " .. weaponStats.DisplayName:upper() .. " ]"

		-- Update ammo display with futuristic formatting
		if WeaponHUD.WeaponState.IsReloading then
			WeaponHUD.AmmoLabel.Text = "// RELOADING //"
			WeaponHUD.AmmoLabel.TextColor3 = warningColor

			-- Pulse ammo bar during reload
			if WeaponHUD.AmmoBar then
				WeaponHUD.AmmoBar.Size = UDim2.new(0.5, 0, 1, 0) -- Mid-fill during reload
				WeaponHUD.AmmoBar.BackgroundColor3 = warningColor
			end
		else
			-- Show ammo with separator
			WeaponHUD.AmmoLabel.Text = string.format("%02d | %02d", WeaponHUD.WeaponState.Ammo, WeaponHUD.WeaponState.MaxAmmo)

			-- Calculate ammo percentage for bar
			local ammoPercent = WeaponHUD.WeaponState.Ammo / WeaponHUD.WeaponState.MaxAmmo

			-- Update ammo bar
			if WeaponHUD.AmmoBar then
				WeaponHUD.AmmoBar.Size = UDim2.new(ammoPercent, 0, 1, 0)
			end

			-- Change color based on ammo level (holographic theme)
			if WeaponHUD.WeaponState.Ammo == 0 then
				WeaponHUD.AmmoLabel.TextColor3 = criticalColor
				if WeaponHUD.AmmoBar then
					WeaponHUD.AmmoBar.BackgroundColor3 = criticalColor
				end
			elseif WeaponHUD.WeaponState.Ammo <= weaponStats.MagazineSize * 0.3 then
				WeaponHUD.AmmoLabel.TextColor3 = warningColor
				if WeaponHUD.AmmoBar then
					WeaponHUD.AmmoBar.BackgroundColor3 = warningColor
				end
			else
				WeaponHUD.AmmoLabel.TextColor3 = hologramColor
				if WeaponHUD.AmmoBar then
					WeaponHUD.AmmoBar.BackgroundColor3 = hologramColor
				end
			end
		end

		-- Show ammo frame
		if WeaponHUD.AmmoFrame then
			WeaponHUD.AmmoFrame.Visible = true
		end
	else
		-- No weapon equipped - hide ammo display
		WeaponHUD.WeaponNameLabel.Text = ""
		WeaponHUD.AmmoLabel.Text = ""
		if WeaponHUD.AmmoFrame then
			WeaponHUD.AmmoFrame.Visible = false
		end
	end
end

-- Initialize on script load
WeaponHUD.Initialize()

return WeaponHUD
