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
local CameraState = require(ReplicatedStorage.Modules.CameraState)

-- Camera helper functions (since CameraController is a LocalScript, not ModuleScript)
local function SetFirstPersonCamera()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5

	-- Hide cursor in first-person
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	print("[MainMenuUI] Switched to first-person")
end

local function SetThirdPersonCamera()
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 15
	player.CameraMinZoomDistance = 0.5

	-- Show cursor in third-person
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	print("[MainMenuUI] Switched to third-person")
end

local MainMenuUI = {}
MainMenuUI.IsInMenu = false
MainMenuUI.CanSpawn = false
MainMenuUI.IsDead = false
MainMenuUI.CursorForceLoop = nil -- Connection for forcing cursor visibility

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
	inventoryButton.Text = "LOADOUT (G - Toggle)"
	inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	inventoryButton.TextSize = 20
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.Parent = background

	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 10)
	invCorner.Parent = inventoryButton

	-- Practice mode button
	local practiceButton = Instance.new("TextButton")
	practiceButton.Name = "PracticeButton"
	practiceButton.Size = UDim2.new(0, 300, 0, 50)
	practiceButton.Position = UDim2.new(0.5, -150, 0.5, 135)
	practiceButton.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
	practiceButton.Text = "PRACTICE MODE"
	practiceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	practiceButton.TextSize = 20
	practiceButton.Font = Enum.Font.GothamBold
	practiceButton.Parent = background

	local practiceCorner = Instance.new("UICorner")
	practiceCorner.CornerRadius = UDim.new(0, 8)
	practiceCorner.Parent = practiceButton

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(0, 500, 0, 60)
	instructions.Position = UDim2.new(0.5, -250, 0.8, 0)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Press M anytime to return to menu • Press G to open loadout"
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
		MainMenuUI.ToggleInventory()
	end)

	-- Practice button click
	practiceButton.MouseButton1Click:Connect(function()
		MainMenuUI.StartPracticeMode()
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

	-- Close main menu
	MainMenuUI.Close()

	-- Reset death state
	MainMenuUI.IsDead = false

	-- Request spawn from server
	SpawnPlayerEvent:FireServer()

	-- Wait for character to spawn, then switch to first-person
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")

		-- Small delay to ensure camera is ready
		task.wait(0.1)

		-- Switch to first-person mode
		SetFirstPersonCamera()
	end)
end

-- Open main menu
function MainMenuUI.Open()
	local mainMenu = playerGui:FindFirstChild("MainMenuUI")
	if not mainMenu then
		mainMenu = MainMenuUI.CreateUI()
	end

	mainMenu.Enabled = true
	MainMenuUI.IsInMenu = true
	CameraState.MenuOpen = true -- Disable camera controller

	-- FORCE third-person mode and show cursor
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 15
	player.CameraMinZoomDistance = 0.5
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	-- Stop any existing cursor force loop
	if MainMenuUI.CursorForceLoop then
		MainMenuUI.CursorForceLoop:Disconnect()
	end

	-- Continuously force cursor to be visible while menu is open
	local RunService = game:GetService("RunService")
	MainMenuUI.CursorForceLoop = RunService.RenderStepped:Connect(function()
		if MainMenuUI.IsInMenu then
			UserInputService.MouseIconEnabled = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)

	-- Hide game HUD
	local gameHUD = playerGui:FindFirstChild("GameHUD")
	if gameHUD then
		gameHUD.Enabled = false
	end

	print("[MainMenuUI] Opened - Switched to third-person, forcing cursor visible")
end

-- Close main menu
function MainMenuUI.Close()
	local mainMenu = playerGui:FindFirstChild("MainMenuUI")
	if mainMenu then
		mainMenu.Enabled = false
	end

	MainMenuUI.IsInMenu = false
	CameraState.MenuOpen = false -- Re-enable camera controller

	-- Stop cursor force loop
	if MainMenuUI.CursorForceLoop then
		MainMenuUI.CursorForceLoop:Disconnect()
		MainMenuUI.CursorForceLoop = nil
	end

	-- Show game HUD
	local gameHUD = playerGui:FindFirstChild("GameHUD")
	if gameHUD then
		gameHUD.Enabled = true
	end

	print("[MainMenuUI] Closed")
end

-- Return to menu (teleport to menu position and open menu)
function MainMenuUI.ReturnToMenu()
	print("[MainMenuUI] Returning to menu...")

	-- Immediately FORCE third-person and show cursor
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 15
	player.CameraMinZoomDistance = 0.5
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	-- Teleport player to menu position (high above map)
	if player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			-- Teleport to a position high above the map
			humanoidRootPart.CFrame = CFrame.new(0, 500, 0)

			-- Set velocity to zero
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end

	-- Open menu
	MainMenuUI.Open()
end

-- Toggle inventory (only in main menu)
function MainMenuUI.ToggleInventory()
	if not MainMenuUI.IsInMenu then
		warn("[MainMenuUI] Can only change loadout in Main Menu!")
		return
	end

	-- Find InventoryUI ScreenGui and toggle it
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if inventoryUI then
		inventoryUI.Enabled = not inventoryUI.Enabled
		if inventoryUI.Enabled then
			print("[MainMenuUI] Opened inventory")
		else
			print("[MainMenuUI] Closed inventory")
		end
	else
		warn("[MainMenuUI] InventoryUI not found - make sure InventoryUI.lua is running")
	end
end

-- Start practice mode
function MainMenuUI.StartPracticeMode()
	print("[MainMenuUI] Starting practice mode...")

	-- Enable practice mode on server
	local TogglePracticeModeEvent = Remotes:FindFirstChild("TogglePracticeMode")
	if TogglePracticeModeEvent then
		TogglePracticeModeEvent:FireServer(true) -- Force enable practice mode
	end

	-- Close main menu
	MainMenuUI.Close()

	-- Reset death state
	MainMenuUI.IsDead = false

	-- Spawn player and wait for character
	SpawnPlayerEvent:FireServer()

	-- Wait for character to spawn, then switch to first-person
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")

		-- Small delay to ensure camera is ready
		task.wait(0.1)

		-- Switch to first-person mode
		SetFirstPersonCamera()
	end)
end

-- Handle round state changes
function MainMenuUI.OnRoundStateChanged(roundData)
	if roundData.State == "Waiting" then
		-- Always open menu during waiting (unless player manually closed it)
		if not MainMenuUI.IsInMenu then
			MainMenuUI.Open()
		end
		MainMenuUI.UpdatePlayButton(false, "Waiting for players...")

	elseif roundData.State == "Intermission" then
		-- In practice mode, don't auto-open menu during intermission
		if GameConfig.PRACTICE_MODE then
			-- Just update button if menu is already open
			if MainMenuUI.IsInMenu then
				MainMenuUI.UpdatePlayButton(true, "Practice Mode Active - Click PLAY to respawn")
			end
		else
			-- Open menu for intermission (unless player is in game and closed it manually)
			if not MainMenuUI.IsInMenu then
				MainMenuUI.Open()
			end
			local timeLeft = roundData.TimeRemaining or GameConfig.INTERMISSION_TIME
			MainMenuUI.UpdatePlayButton(true, string.format("Round starting in %d...", timeLeft))
		end

	elseif roundData.State == "Playing" then
		-- Don't auto-open menu during playing, just update button if menu is already open
		if MainMenuUI.IsInMenu then
			MainMenuUI.UpdatePlayButton(true, "Round in progress - Click PLAY to spawn")
		end

	elseif roundData.State == "RoundEnd" then
		-- Always open menu at round end
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

	-- Listen for practice mode updates
	local PracticeModeUpdateEvent = Remotes:FindFirstChild("PracticeModeUpdate")
	if PracticeModeUpdateEvent then
		PracticeModeUpdateEvent.OnClientEvent:Connect(function(isEnabled)
			GameConfig.PRACTICE_MODE = isEnabled
			print(string.format("[MainMenuUI] Practice mode updated: %s", isEnabled and "ON" or "OFF"))
		end)
	end

	-- Handle character spawns
	player.CharacterAdded:Connect(function(character)
		MainMenuUI.OnCharacterAdded(character)
	end)

	-- If character already exists
	if player.Character then
		MainMenuUI.OnCharacterAdded(player.Character)
	end

	-- Bind M key to return to menu (works at any time)
	-- Bind G key to open inventory (only in menu)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- M key - return to menu at any time
		if input.KeyCode == Enum.KeyCode.M then
			if not MainMenuUI.IsInMenu then
				MainMenuUI.ReturnToMenu()
			end
		end

		-- G key - toggle inventory (only in Main Menu)
		if input.KeyCode == Enum.KeyCode.G then
			if MainMenuUI.IsInMenu then
				MainMenuUI.ToggleInventory()
			end
		end
	end)

	print("[MainMenuUI] Initialized - Press M to return to menu | Press G to toggle loadout")
end

-- Start
MainMenuUI.Initialize()

return MainMenuUI
