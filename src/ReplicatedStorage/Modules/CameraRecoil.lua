--[[
	CameraRecoil.lua
	Handles camera recoil effects when shooting
	Location: ReplicatedStorage > Modules > CameraRecoil
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

local CameraRecoil = {}

-- Recoil state
local recoilVector = Vector2.new()
local zoomRecoil = 0

-- Constants
local RECOIL_RETURN_SPEED = 10 -- How fast recoil returns to zero
local ZOOM_RETURN_SPEED = 15 -- How fast FOV returns to normal
local DEFAULT_FOV = 70 -- Default field of view

-- Initialize recoil system
function CameraRecoil.Initialize()
	-- Apply recoil every frame
	RunService:BindToRenderStep("CameraRecoil", Enum.RenderPriority.Camera.Value + 2, function(deltaTime)
		CameraRecoil.Update(deltaTime)
	end)

	print("[CameraRecoil] Initialized")
end

-- Update recoil (called every frame)
function CameraRecoil.Update(deltaTime)
	-- Apply recoil rotation to camera
	camera.CFrame = camera.CFrame * CFrame.Angles(recoilVector.Y * deltaTime, recoilVector.X * deltaTime, 0)

	-- Apply FOV zoom
	camera.FieldOfView = DEFAULT_FOV + zoomRecoil

	-- Smoothly return recoil to zero
	recoilVector = recoilVector:Lerp(Vector2.zero, math.min(deltaTime * RECOIL_RETURN_SPEED, 1))

	-- Smoothly return zoom to zero
	local zoomLerpAlpha = math.min(deltaTime * ZOOM_RETURN_SPEED, 1)
	zoomRecoil = zoomRecoil + (0 - zoomRecoil) * zoomLerpAlpha
end

-- Apply recoil kick
-- recoilAmount: Vector2 where X = horizontal kick, Y = vertical kick (in radians)
function CameraRecoil.ApplyRecoil(recoilAmount)
	recoilVector = recoilVector + recoilAmount
	zoomRecoil = 1 -- Slight zoom out on shot
end

-- Cleanup
function CameraRecoil.Cleanup()
	RunService:UnbindFromRenderStep("CameraRecoil")
end

return CameraRecoil
