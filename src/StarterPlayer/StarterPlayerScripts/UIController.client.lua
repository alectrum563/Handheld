--[[
	UIController.lua
	Manages client-side UI (HUD, timer, scoreboard, weapon select)
	Location: StarterPlayer > StarterPlayerScripts > UIController
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundStateEvent = Remotes:WaitForChild("RoundState")
local GetEconomyEvent = Remotes:WaitForChild("GetEconomy")

-- Get modules
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local WeaponStats = require(ReplicatedStorage.Modules.WeaponStats)
local Utilities = require(ReplicatedStorage.Modules.Utilities)

local UIController = {}

-- Create main HUD
function UIController.CreateHUD()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Round Timer
	local timerFrame = Instance.new("Frame")
	timerFrame.Name = "TimerFrame"
	timerFrame.Size = UDim2.new(0, 200, 0, 60)
	timerFrame.Position = UDim2.new(0.5, -100, 0, 10)
	timerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	timerFrame.BackgroundTransparency = 0.3
	timerFrame.BorderSizePixel = 0
	timerFrame.Parent = screenGui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = timerFrame

	-- Timer text
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0.6, 0)
	timerLabel.Position = UDim2.new(0, 0, 0.4, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "10:00"
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Parent = timerFrame

	-- State label
	local stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "StateLabel"
	stateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	stateLabel.Position = UDim2.new(0, 0, 0.1, 0)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = "Waiting"
	stateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	stateLabel.TextScaled = true
	stateLabel.Font = Enum.Font.Gotham
	stateLabel.Parent = timerFrame

	-- Team Display
	local teamFrame = Instance.new("Frame")
	teamFrame.Name = "TeamFrame"
	teamFrame.Size = UDim2.new(0, 150, 0, 40)
	teamFrame.Position = UDim2.new(0, 10, 0, 10)
	teamFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	teamFrame.BackgroundTransparency = 0.3
	teamFrame.BorderSizePixel = 0
	teamFrame.Parent = screenGui

	local teamCorner = Instance.new("UICorner")
	teamCorner.CornerRadius = UDim.new(0, 8)
	teamCorner.Parent = teamFrame

	local teamLabel = Instance.new("TextLabel")
	teamLabel.Name = "TeamLabel"
	teamLabel.Size = UDim2.new(1, -10, 1, -10)
	teamLabel.Position = UDim2.new(0, 5, 0, 5)
	teamLabel.BackgroundTransparency = 1
	teamLabel.Text = player.Team and player.Team.Name or "No Team"
	teamLabel.TextColor3 = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 255, 255)
	teamLabel.TextScaled = true
	teamLabel.Font = Enum.Font.GothamBold
	teamLabel.Parent = teamFrame

	-- Economy Display (Shards and Score)
	local economyFrame = Instance.new("Frame")
	economyFrame.Name = "EconomyFrame"
	economyFrame.Size = UDim2.new(0, 200, 0, 60)
	economyFrame.Position = UDim2.new(0, 10, 0, 60)
	economyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	economyFrame.BackgroundTransparency = 0.3
	economyFrame.BorderSizePixel = 0
	economyFrame.Parent = screenGui

	local economyCorner = Instance.new("UICorner")
	economyCorner.CornerRadius = UDim.new(0, 8)
	economyCorner.Parent = economyFrame

	-- Shards display
	local shardsLabel = Instance.new("TextLabel")
	shardsLabel.Name = "ShardsLabel"
	shardsLabel.Size = UDim2.new(1, -10, 0.5, -5)
	shardsLabel.Position = UDim2.new(0, 5, 0, 5)
	shardsLabel.BackgroundTransparency = 1
	shardsLabel.Text = "💎 Shards: 0"
	shardsLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	shardsLabel.TextSize = 16
	shardsLabel.Font = Enum.Font.GothamBold
	shardsLabel.TextXAlignment = Enum.TextXAlignment.Left
	shardsLabel.Parent = economyFrame

	-- Score display
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreLabel"
	scoreLabel.Size = UDim2.new(1, -10, 0.5, -5)
	scoreLabel.Position = UDim2.new(0, 5, 0.5, 0)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "⭐ Score: 0"
	scoreLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	scoreLabel.TextSize = 16
	scoreLabel.Font = Enum.Font.GothamBold
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	scoreLabel.Parent = economyFrame

	-- Health Bar (will update later)
	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthFrame"
	healthFrame.Size = UDim2.new(0, 200, 0, 30)
	healthFrame.Position = UDim2.new(0.5, -100, 1, -40)
	healthFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	healthFrame.BackgroundTransparency = 0.5
	healthFrame.BorderSizePixel = 0
	healthFrame.Parent = screenGui

	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 8)
	healthCorner.Parent = healthFrame

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, -4, 1, -4)
	healthBar.Position = UDim2.new(0, 2, 0, 2)
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthFrame

	local healthBarCorner = Instance.new("UICorner")
	healthBarCorner.CornerRadius = UDim.new(0, 6)
	healthBarCorner.Parent = healthBar

	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = "100 HP"
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.GothamBold
	healthText.ZIndex = 2
	healthText.Parent = healthFrame

	print("[UIController] HUD created")
	return screenGui
end

-- Update round timer
function UIController.UpdateTimer(roundData)
	local hud = playerGui:FindFirstChild("GameHUD")
	if not hud then return end

	local timerFrame = hud:FindFirstChild("TimerFrame")
	if not timerFrame then return end

	local timerLabel = timerFrame:FindFirstChild("TimerLabel")
	local stateLabel = timerFrame:FindFirstChild("StateLabel")

	if roundData.State then
		if stateLabel then
			stateLabel.Text = roundData.State
		end
	end

	if roundData.TimeRemaining then
		if timerLabel then
			timerLabel.Text = Utilities.FormatTime(roundData.TimeRemaining)
		end
	end

	if roundData.Message then
		if stateLabel then
			stateLabel.Text = roundData.Message
		end
	end
end

-- Update health bar
function UIController.UpdateHealth()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local hud = playerGui:FindFirstChild("GameHUD")
	if not hud then return end

	local healthFrame = hud:FindFirstChild("HealthFrame")
	if not healthFrame then return end

	local healthBar = healthFrame:FindFirstChild("HealthBar")
	local healthText = healthFrame:FindFirstChild("HealthText")

	local healthPercent = humanoid.Health / humanoid.MaxHealth

	if healthBar then
		healthBar.Size = UDim2.new(healthPercent, -4, 1, -4)

		-- Change color based on health
		if healthPercent > 0.6 then
			healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
		elseif healthPercent > 0.3 then
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
		else
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
		end
	end

	if healthText then
		healthText.Text = math.floor(humanoid.Health) .. " HP"
	end
end

-- Update economy display
function UIController.UpdateEconomy()
	local hud = playerGui:FindFirstChild("GameHUD")
	if not hud then return end

	local economyFrame = hud:FindFirstChild("EconomyFrame")
	if not economyFrame then return end

	-- Get economy data from server
	local success, economyData = pcall(function()
		return GetEconomyEvent:InvokeServer()
	end)

	if not success then
		warn("[UIController] Failed to get economy data:", economyData)
		return
	end

	local shardsLabel = economyFrame:FindFirstChild("ShardsLabel")
	local scoreLabel = economyFrame:FindFirstChild("ScoreLabel")

	if shardsLabel then
		shardsLabel.Text = string.format("💎 Shards: %d", economyData.Shards or 0)
	end

	if scoreLabel then
		scoreLabel.Text = string.format("⭐ Score: %d", economyData.TotalScore or 0)
	end
end


-- Initialize
function UIController.Initialize()
	-- Create HUD
	UIController.CreateHUD()

	-- Listen for round state updates
	RoundStateEvent.OnClientEvent:Connect(function(roundData)
		UIController.UpdateTimer(roundData)
	end)

	-- Update health continuously
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.HealthChanged:Connect(function()
			UIController.UpdateHealth()
		end)

		UIController.UpdateHealth()
	end)

	-- Update health for current character if it exists
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.HealthChanged:Connect(function()
				UIController.UpdateHealth()
			end)
			UIController.UpdateHealth()
		end
	end

	-- Update economy display initially
	UIController.UpdateEconomy()

	-- Update economy every 2 seconds
	task.spawn(function()
		while true do
			task.wait(2)
			UIController.UpdateEconomy()
		end
	end)

	print("[UIController] Initialized")
end

-- Start UI Controller
UIController.Initialize()
