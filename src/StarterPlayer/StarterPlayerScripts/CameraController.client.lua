--[[
	CameraController.client.lua
	Handles first-person camera with FOV adjustments
	Location: StarterPlayer > StarterPlayerScripts > CameraController
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Use shared camera state
local CameraState = require(ReplicatedStorage.Modules.CameraState)

local CameraController = {}

-- Camera settings
local DEFAULT_FOV = 80
local SPRINT_FOV = 90
local AIM_FOV = 60
local FOV_TRANSITION_SPEED = 10

-- Mouse sensitivity
local MOUSE_SENSITIVITY = 0.2

-- Current camera rotation
local cameraRotationX = 0
local cameraRotationY = 0

-- Initialize camera
function CameraController.Initialize()
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()

	-- Setup camera control (once, independent of character)
	CameraController.SetupCameraControl()

	-- Wait for character parts to fully load
	local success, humanoid, rootPart = pcall(function()
		local h = character:WaitForChild("Humanoid", 10)
		local r = character:WaitForChild("HumanoidRootPart", 10)
		return h, r
	end)

	if not success or not humanoid or not rootPart or not character.Parent then
		-- Character was destroyed or timed out, skip initialization
		-- CharacterAdded will handle the next character
		return
	end

	-- Start in third-person (for Main Menu)
	CameraController.SetThirdPerson()

	-- Set camera subject
	camera.CameraSubject = humanoid

	-- Set default FOV
	camera.FieldOfView = DEFAULT_FOV

	print("[CameraController] Initialized - Third-person mode (Main Menu)")
end

-- Switch to first-person mode
function CameraController.SetFirstPerson()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5
	CameraState.IsFirstPerson = true

	-- Hide mouse cursor in first-person
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	print("[CameraController] Switched to first-person")
end

-- Switch to third-person mode
function CameraController.SetThirdPerson()
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 15
	player.CameraMinZoomDistance = 0.5
	CameraState.IsFirstPerson = false
	CameraState.IsAiming = false -- Reset aiming when switching to third person

	-- Show mouse cursor in third-person
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	print("[CameraController] Switched to third-person")
end

-- Toggle aiming mode
function CameraController.ToggleAiming()
	-- Only allow aiming in first-person mode
	if not CameraState.IsFirstPerson then
		return
	end

	CameraState.IsAiming = not CameraState.IsAiming
	print(string.format("[CameraController] Aiming: %s", CameraState.IsAiming and "ON" or "OFF"))
end

-- Setup camera control
function CameraController.SetupCameraControl()
	-- Handle camera updates
	RunService.RenderStepped:Connect(function(deltaTime)
		CameraController.UpdateCamera(deltaTime)
	end)

	-- Handle right-click for aiming
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			CameraController.ToggleAiming()
		end
	end)
end

-- Update camera
function CameraController.UpdateCamera(deltaTime)
	-- Don't control camera when menu is open
	if CameraState.MenuOpen then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Always adjust FOV (works in both first and third person)
	local targetFOV = DEFAULT_FOV

	-- Aiming takes priority over sprint
	if CameraState.IsAiming then
		targetFOV = AIM_FOV
	-- Check if sprinting (walk speed >= sprint speed)
	elseif humanoid.WalkSpeed >= 32 then
		targetFOV = SPRINT_FOV
	end

	-- Lerp FOV smoothly
	local currentFOV = camera.FieldOfView
	camera.FieldOfView = currentFOV + (targetFOV - currentFOV) * FOV_TRANSITION_SPEED * deltaTime
end

-- Handle character respawn
player.CharacterAdded:Connect(function(character)
	task.spawn(function()
		local success, humanoid = pcall(function()
			return character:WaitForChild("Humanoid", 5)
		end)

		if not success or not humanoid or not character.Parent then
			-- Character was destroyed, skip
			return
		end

		-- Reset to third-person (for Main Menu)
		CameraController.SetThirdPerson()
		camera.CameraSubject = humanoid
		camera.FieldOfView = DEFAULT_FOV

		print("[CameraController] Camera reset for new character - Third-person mode")
	end)
end)

-- Initialize on script load
CameraController.Initialize()

return CameraController
