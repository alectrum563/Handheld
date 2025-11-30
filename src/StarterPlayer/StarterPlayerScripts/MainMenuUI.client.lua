--[[
	MainMenuUI.lua
	Main menu system - spawning, loadouts, and round management
	Location: StarterPlayer > StarterPlayerScripts > MainMenuUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundStateEvent = Remotes:WaitForChild("RoundState")
local SpawnPlayerEvent = Remotes:WaitForChild("SpawnPlayer")

-- Get modules
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local MainMenuUI = {}
MainMenuUI.IsInMenu = false
MainMenuUI.CanSpawn = false
MainMenuUI.IsDead = false

-- Create main menu UI
function MainMenuUI.CreateUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	background.BackgroundTransparency = 0.2
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 600, 0, 80)
	title.Position = UDim2.new(0.5, -300, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "MAIN MENU"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 48
	title.Font = Enum.Font.GothamBold
	title.Parent = background

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0, 600, 0, 40)
	subtitle.Position = UDim2.new(0.5, -300, 0.1, 85)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Waiting for round to start..."
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 20
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = background

	-- Play button
	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.new(0, 300, 0, 70)
	playButton.Position = UDim2.new(0.5, -150, 0.5, -35)
	playButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	playButton.Text = "PLAY"
	playButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	playButton.TextSize = 32
	playButton.Font = Enum.Font.GothamBold
	playButton.AutoButtonColor = false
	playButton.Parent = background

	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0, 12)
	playCorner.Parent = playButton

	-- Inventory button
	local inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Size = UDim2.new(0, 300, 0, 60)
	inventoryButton.Position = UDim2.new(0.5, -150, 0.5, 60)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
	inventoryButton.Text = "LOADOUT (TAB)"
	inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	inventoryButton.TextSize = 24
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.Parent = background

	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 10)
	invCorner.Parent = inventoryButton

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(0, 500, 0, 60)
	instructions.Position = UDim2.new(0.5, -250, 0.8, 0)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Press M to return to menu after death"
	instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
	instructions.TextSize = 16
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.Parent = background

	-- Play button click
	playButton.MouseButton1Click:Connect(function()
		if MainMenuUI.CanSpawn then
			MainMenuUI.SpawnPlayer()
		end
	end)

	-- Inventory button click
	inventoryButton.MouseButton1Click:Connect(function()
		MainMenuUI.OpenInventory()
	end)

	print("[MainMenuUI] UI created")
	return screenGui
end

-- Update play button state
function MainMenuUI.UpdatePlayButton(canSpawn, message)
	local mainMenu = playerGui:FindFirstChild("MainMenuUI")
	if not mainMenu then return end

	local background = mainMenu:FindFirstChild("Background")
	if not background then return end

	local playButton = background:FindFirstChild("PlayButton")
	local subtitle = background:FindFirstChild("Subtitle")

	MainMenuUI.CanSpawn = canSpawn

	if playButton then
		if canSpawn then
			playButton.BackgroundColor3 = Color3.fromRGB(70, 200, 70)
			playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			playButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			playButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end

	if subtitle and message then
		subtitle.Text = message
	end
end

-- Spawn player into game
function MainMenuUI.SpawnPlayer()
	if not MainMenuUI.CanSpawn then
		warn("[MainMenuUI] Cannot spawn - round not active")
		return
	end

	print("[MainMenuUI] Spawning player...")

	-- Request spawn from server
	SpawnPlayerEvent:FireServer()

	-- Close main menu
	MainMenuUI.Close()

	-- Reset death state
	MainMenuUI.IsDead = false
end

-- Open main menu
function MainMenuUI.Open()
	local mainMenu = playerGui:FindFirstChild("MainMenuUI")
	if not mainMenu then
		mainMenu = MainMenuUI.CreateUI()
	end

	mainMenu.Enabled = true
	MainMenuUI.IsInMenu = true

	-- Hide game HUD
	local gameHUD = playerGui:FindFirstChild("GameHUD")
	if gameHUD then
		gameHUD.Enabled = false
	end

	print("[MainMenuUI] Opened")
end

-- Close main menu
function MainMenuUI.Close()
	local mainMenu = playerGui:FindFirstChild("MainMenuUI")
	if mainMenu then
		mainMenu.Enabled = false
	end

	MainMenuUI.IsInMenu = false

	-- Show game HUD
	local gameHUD = playerGui:FindFirstChild("GameHUD")
	if gameHUD then
		gameHUD.Enabled = true
	end

	print("[MainMenuUI] Closed")
end

-- Open inventory (only in main menu)
function MainMenuUI.OpenInventory()
	if not MainMenuUI.IsInMenu then
		warn("[MainMenuUI] Can only change loadout in Main Menu!")
		return
	end

	-- Find InventoryUI ScreenGui and open it
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if inventoryUI then
		inventoryUI.Enabled = true
		print("[MainMenuUI] Opened inventory")
	else
		warn("[MainMenuUI] InventoryUI not found - make sure InventoryUI.lua is running")
	end
end

-- Handle round state changes
function MainMenuUI.OnRoundStateChanged(roundData)
	if roundData.State == "Waiting" then
		MainMenuUI.Open()
		MainMenuUI.UpdatePlayButton(false, "Waiting for players...")

	elseif roundData.State == "Intermission" then
		MainMenuUI.Open()
		local timeLeft = roundData.TimeRemaining or GameConfig.INTERMISSION_TIME
		MainMenuUI.UpdatePlayButton(true, string.format("Round starting in %d...", timeLeft))

	elseif roundData.State == "Playing" then
		-- Allow spawning during gameplay (if dead)
		if MainMenuUI.IsInMenu then
			MainMenuUI.UpdatePlayButton(true, "Round in progress - Click PLAY to spawn")
		end

	elseif roundData.State == "RoundEnd" then
		MainMenuUI.Open()
		local winMessage = roundData.Message or "Round ended!"
		MainMenuUI.UpdatePlayButton(false, winMessage)
	end
end

-- Handle player death
function MainMenuUI.OnPlayerDied()
	print("[MainMenuUI] Player died")
	MainMenuUI.IsDead = true

	-- Show death screen message
	-- Player can press M to return to menu
end

-- Handle character added
function MainMenuUI.OnCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		MainMenuUI.OnPlayerDied()
	end)
end

-- Initialize
function MainMenuUI.Initialize()
	-- Create UI
	MainMenuUI.CreateUI()

	-- Open menu by default
	MainMenuUI.Open()

	-- Listen for round state updates
	RoundStateEvent.OnClientEvent:Connect(function(roundData)
		MainMenuUI.OnRoundStateChanged(roundData)
	end)

	-- Handle character spawns
	player.CharacterAdded:Connect(function(character)
		MainMenuUI.OnCharacterAdded(character)
	end)

	-- If character already exists
	if player.Character then
		MainMenuUI.OnCharacterAdded(player.Character)
	end

	-- Bind M key to open menu (only after death)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.M then
			if MainMenuUI.IsDead then
				MainMenuUI.Open()
			end
		end
	end)

	print("[MainMenuUI] Initialized - Press M to return to menu after death")
end

-- Start
MainMenuUI.Initialize()

return MainMenuUI
