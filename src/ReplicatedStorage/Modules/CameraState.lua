--[[
	CameraState.lua
	Shared state for camera between different client scripts
	Location: ReplicatedStorage > Modules > CameraState
]]

local CameraState = {
	IsAiming = false,
	IsFirstPerson = false,
	MenuOpen = false -- Disable camera control when menu is open
}

return CameraState
