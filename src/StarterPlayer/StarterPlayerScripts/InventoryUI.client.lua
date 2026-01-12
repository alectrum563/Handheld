--[[
	InventoryUI.lua
	Manages the weapon inventory UI
	Location: StarterPlayer > StarterPlayerScripts > InventoryUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryEvent = Remotes:WaitForChild("GetInventory")
local EquipWeaponEvent = Remotes:WaitForChild("EquipWeapon")

-- Get modules
local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)

local InventoryUI = {}
InventoryUI.IsOpen = false
InventoryUI.CurrentInventory = {}

-- Create inventory UI
function InventoryUI.CreateUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- Hidden by default
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Background overlay
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = background

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "WEAPON INVENTORY"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -70, 0, 20)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		InventoryUI.Close()
	end)

	-- Scrolling frame for weapons
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "WeaponList"
	scrollFrame.Size = UDim2.new(1, -40, 1, -90)
	scrollFrame.Position = UDim2.new(0, 20, 0, 70)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Update canvas size when layout changes
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	print("[InventoryUI] UI created")
	return screenGui
end

-- Create weapon card
function InventoryUI.CreateWeaponCard(weaponData, index)
	local weaponStats = WeaponStats.GetWeapon(weaponData.WeaponName)
	if not weaponStats then
		warn("[InventoryUI] Unknown weapon:", weaponData.WeaponName)
		return nil
	end

	-- Card frame
	local card = Instance.new("Frame")
	card.Name = weaponData.Id
	card.Size = UDim2.new(1, -10, 0, 100)
	card.BackgroundColor3 = weaponData.IsEquipped and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.LayoutOrder = index

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Equipped indicator
	if weaponData.IsEquipped then
		local equippedLabel = Instance.new("TextLabel")
		equippedLabel.Name = "EquippedLabel"
		equippedLabel.Size = UDim2.new(0, 100, 0, 25)
		equippedLabel.Position = UDim2.new(1, -110, 0, 10)
		equippedLabel.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		equippedLabel.Text = "EQUIPPED"
		equippedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		equippedLabel.TextSize = 12
		equippedLabel.Font = Enum.Font.GothamBold
		equippedLabel.Parent = card

		local equippedCorner = Instance.new("UICorner")
		equippedCorner.CornerRadius = UDim.new(0, 4)
		equippedCorner.Parent = equippedLabel
	end

	-- Weapon name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "WeaponName"
	nameLabel.Size = UDim2.new(0.5, -20, 0, 25)
	nameLabel.Position = UDim2.new(0, 15, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponStats.DisplayName or weaponData.WeaponName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Skin label
	local skinLabel = Instance.new("TextLabel")
	skinLabel.Name = "SkinLabel"
	skinLabel.Size = UDim2.new(0.5, -20, 0, 20)
	skinLabel.Position = UDim2.new(0, 15, 0, 35)
	skinLabel.BackgroundTransparency = 1
	skinLabel.Text = "Skin: " .. (weaponData.SkinId or "default")
	skinLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	skinLabel.TextSize = 14
	skinLabel.Font = Enum.Font.Gotham
	skinLabel.TextXAlignment = Enum.TextXAlignment.Left
	skinLabel.Parent = card

	-- Stats label
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -30, 0, 30)
	statsLabel.Position = UDim2.new(0, 15, 0, 60)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = string.format("DMG: %d | RPM: %.0f | Range: %d studs | Mag: %d",
		weaponStats.Damage,
		60 / weaponStats.FireRate,
		weaponStats.Range,
		weaponStats.MagazineSize)
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.TextSize = 12
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = card

	-- Equip button (only show if not equipped)
	if not weaponData.IsEquipped then
		local equipButton = Instance.new("TextButton")
		equipButton.Name = "EquipButton"
		equipButton.Size = UDim2.new(0, 100, 0, 35)
		equipButton.Position = UDim2.new(1, -110, 1, -45)
		equipButton.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
		equipButton.Text = "EQUIP"
		equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		equipButton.TextSize = 14
		equipButton.Font = Enum.Font.GothamBold
		equipButton.Parent = card

		local equipCorner = Instance.new("UICorner")
		equipCorner.CornerRadius = UDim.new(0, 6)
		equipCorner.Parent = equipButton

		equipButton.MouseButton1Click:Connect(function()
			InventoryUI.EquipWeapon(weaponData.Id)
		end)
	end

	return card
end

-- Refresh inventory display
function InventoryUI.RefreshInventory()
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if not inventoryUI then return end

	local mainFrame = inventoryUI.Background:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local scrollFrame = mainFrame:FindFirstChild("WeaponList")
	if not scrollFrame then return end

	-- Clear existing cards
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get inventory from server
	local success, inventory = pcall(function()
		return GetInventoryEvent:InvokeServer()
	end)

	if not success then
		warn("[InventoryUI] Failed to get inventory:", inventory)
		return
	end

	InventoryUI.CurrentInventory = inventory

	-- Create weapon cards
	for i, weaponData in ipairs(inventory) do
		local card = InventoryUI.CreateWeaponCard(weaponData, i)
		if card then
			card.Parent = scrollFrame
		end
	end

	print(string.format("[InventoryUI] Loaded %d weapons", #inventory))
end

-- Equip weapon
function InventoryUI.EquipWeapon(weaponId)
	-- Check if in main menu OR practice mode is enabled
	local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
	local mainMenuUI = playerGui:FindFirstChild("MainMenuUI")

	if not GameConfig.PRACTICE_MODE and (not mainMenuUI or not mainMenuUI.Enabled) then
		warn("[InventoryUI] Can only equip weapons in Main Menu!")

		-- Show error message
		local inventoryUI = playerGui:FindFirstChild("InventoryUI")
		if inventoryUI and inventoryUI.Enabled then
			-- Flash error message
			local mainFrame = inventoryUI.Background:FindFirstChild("MainFrame")
			if mainFrame then
				local title = mainFrame:FindFirstChild("Title")
				if title then
					local originalText = title.Text
					title.Text = "⚠ RETURN TO MAIN MENU TO CHANGE LOADOUT"
					title.TextColor3 = Color3.fromRGB(255, 100, 100)
					task.wait(2)
					title.Text = originalText
					title.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end

		return
	end

	print("[InventoryUI] Equipping weapon:", weaponId)

	-- Send equip request to server
	EquipWeaponEvent:FireServer(weaponId)

	-- Close inventory and refresh after a short delay
	task.wait(0.1)
	InventoryUI.RefreshInventory()
end

-- Open inventory
function InventoryUI.Open()
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if not inventoryUI then
		inventoryUI = InventoryUI.CreateUI()
	end

	inventoryUI.Enabled = true
	InventoryUI.IsOpen = true

	-- Refresh inventory
	InventoryUI.RefreshInventory()

	print("[InventoryUI] Opened")
end

-- Close inventory
function InventoryUI.Close()
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if inventoryUI then
		inventoryUI.Enabled = false
	end

	InventoryUI.IsOpen = false
	print("[InventoryUI] Closed")
end

-- Toggle inventory
function InventoryUI.Toggle()
	if InventoryUI.IsOpen then
		InventoryUI.Close()
	else
		InventoryUI.Open()
	end
end

-- Initialize
function InventoryUI.Initialize()
	-- Create UI
	local screenGui = InventoryUI.CreateUI()

	-- Auto-refresh inventory when the UI becomes visible
	screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if screenGui.Enabled then
			InventoryUI.RefreshInventory()
		end
	end)

	-- Bind to Tab key to toggle inventory
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Tab then
			InventoryUI.Toggle()
		end
	end)

	print("[InventoryUI] Initialized - Press TAB to open inventory")
end

-- Start
InventoryUI.Initialize()

return InventoryUI
