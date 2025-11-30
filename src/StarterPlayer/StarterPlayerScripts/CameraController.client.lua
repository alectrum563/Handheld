--[[
	CameraController.client.lua
	Handles first-person camera with FOV adjustments
	Location: StarterPlayer > StarterPlayerScripts > CameraController
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraController = {}

-- Camera settings
local DEFAULT_FOV = 80
local SPRINT_FOV = 90
local FOV_TRANSITION_SPEED = 10

-- Mouse sensitivity
local MOUSE_SENSITIVITY = 0.2

-- Current camera rotation
local cameraRotationX = 0
local cameraRotationY = 0

-- Camera state
CameraController.IsFirstPerson = false

-- Initialize camera
function CameraController.Initialize()
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Start in third-person (for Main Menu)
	CameraController.SetThirdPerson()

	-- Set camera subject
	camera.CameraSubject = humanoid

	-- Set default FOV
	camera.FieldOfView = DEFAULT_FOV

	-- Setup camera control
	CameraController.SetupCameraControl()

	print("[CameraController] Initialized - Third-person mode (Main Menu)")
end

-- Switch to first-person mode
function CameraController.SetFirstPerson()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5
	CameraController.IsFirstPerson = true
	print("[CameraController] Switched to first-person")
end

-- Switch to third-person mode
function CameraController.SetThirdPerson()
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 15
	player.CameraMinZoomDistance = 0.5
	CameraController.IsFirstPerson = false
	print("[CameraController] Switched to third-person")
end

-- Setup camera control
function CameraController.SetupCameraControl()
	-- Handle camera updates
	RunService.RenderStepped:Connect(function(deltaTime)
		CameraController.UpdateCamera(deltaTime)
	end)
end

-- Update camera
function CameraController.UpdateCamera(deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Only adjust FOV in first-person mode
	if CameraController.IsFirstPerson then
		-- Smoothly adjust FOV based on movement speed
		local targetFOV = DEFAULT_FOV

		-- Check if sprinting (walk speed > run speed threshold)
		if humanoid.WalkSpeed >= 30 then
			targetFOV = SPRINT_FOV
		end

		-- Lerp FOV
		local currentFOV = camera.FieldOfView
		camera.FieldOfView = currentFOV + (targetFOV - currentFOV) * FOV_TRANSITION_SPEED * deltaTime
	end
end

-- Handle character respawn
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Reset to third-person (for Main Menu)
	CameraController.SetThirdPerson()
	camera.CameraSubject = humanoid
	camera.FieldOfView = DEFAULT_FOV

	print("[CameraController] Camera reset for new character - Third-person mode")
end)

-- Initialize on script load
CameraController.Initialize()

return CameraController
