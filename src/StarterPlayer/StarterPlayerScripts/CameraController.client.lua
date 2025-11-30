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

-- Initialize camera
function CameraController.Initialize()
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Lock to first-person
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5

	-- Set camera subject
	camera.CameraSubject = humanoid

	-- Set default FOV
	camera.FieldOfView = DEFAULT_FOV

	-- Setup camera control
	CameraController.SetupCameraControl()

	print("[CameraController] Initialized - First-person mode locked")
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

-- Handle character respawn
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Relock camera
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	camera.CameraSubject = humanoid
	camera.FieldOfView = DEFAULT_FOV

	print("[CameraController] Camera reset for new character")
end)

-- Initialize on script load
CameraController.Initialize()

return CameraController
