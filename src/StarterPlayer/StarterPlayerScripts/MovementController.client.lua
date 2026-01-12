--[[
	MovementController.client.lua
	Handles custom character movement (walk, run, sprint, wall jump)
	Location: StarterPlayer > StarterPlayerScripts > MovementController
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local CameraState = require(ReplicatedStorage.Modules.CameraState)

local MovementController = {}

-- Movement state
MovementController.CurrentState = "Walk" -- Walk, Run, Sprint, Slide
MovementController.IsWallJumping = false
MovementController.IsSliding = false
MovementController.LastWPressed = 0
MovementController.ShiftHoldTime = 0

-- Movement speeds (from GameConfig)
local WALK_SPEED = GameConfig.DEFAULT_WALKSPEED
local RUN_SPEED = GameConfig.RUN_SPEED
local SPRINT_SPEED = GameConfig.SPRINT_SPEED

-- Wall jump settings
local WALL_JUMP_COOLDOWN = 0.8 -- Increased cooldown for super jump
local WALL_JUMP_FORCE = GameConfig.WALL_JUMP_POWER
local WALL_DETECT_DISTANCE = 3
local lastWallJumpTime = 0

-- Slide settings
local SLIDE_DURATION = 0.8 -- seconds (shorter, snappier slide)
local SLIDE_SPEED = 45 -- studs/second (faster than sprint)
local SLIDE_COOLDOWN = 0.5 -- cooldown after slide ends
local SLIDE_CAMERA_OFFSET = -2 -- lower camera by 2 studs during slide
local lastSlideTime = 0

-- Sprint activation
local DOUBLE_TAP_TIME = 0.3 -- Time window for double-tap W
local SHIFT_HOLD_TIME_FOR_SPRINT = 0.5 -- Hold Shift this long to sprint

-- Initialize movement
function MovementController.Initialize()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- Set default walk speed
	humanoid.WalkSpeed = WALK_SPEED

	-- Handle input for movement states
	MovementController.SetupInputHandling()

	-- Handle wall jump detection
	MovementController.SetupWallJumpDetection()

	print("[MovementController] Initialized")
end

-- Setup input handling for run/sprint
function MovementController.SetupInputHandling()
	local shiftPressed = false
	local shiftPressTime = 0

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- Shift key for running/sprinting
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			-- Don't allow sprint while aiming
			if CameraState.IsAiming then
				return
			end

			shiftPressed = true
			shiftPressTime = tick()
			MovementController.CurrentState = "Run"
			humanoid.WalkSpeed = RUN_SPEED
		end

		-- W key for double-tap sprint
		if input.KeyCode == Enum.KeyCode.W then
			local currentTime = tick()
			local timeSinceLastW = currentTime - MovementController.LastWPressed

			-- Double-tap W to sprint (not while aiming)
			if timeSinceLastW < DOUBLE_TAP_TIME and not CameraState.IsAiming then
				MovementController.CurrentState = "Sprint"
				humanoid.WalkSpeed = SPRINT_SPEED
				print("[MovementController] Sprint activated (double-tap W)")
			end

			MovementController.LastWPressed = currentTime
		end

		-- Space for wall jump
		if input.KeyCode == Enum.KeyCode.Space then
			MovementController.AttemptWallJump()
		end

		-- C key for slide (while sprinting)
		if input.KeyCode == Enum.KeyCode.C then
			MovementController.AttemptSlide()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- Release Shift - return to walk
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			shiftPressed = false

			-- Check if we should enter sprint mode (held Shift long enough)
			local holdDuration = tick() - shiftPressTime
			if holdDuration >= SHIFT_HOLD_TIME_FOR_SPRINT then
				-- Continue sprinting until W is released or player stops moving
				-- We'll handle this in the update loop
			else
				MovementController.CurrentState = "Walk"
				humanoid.WalkSpeed = WALK_SPEED
			end
		end
	end)

	-- Update loop for sprint hold detection
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- Don't interfere with sliding
		if MovementController.IsSliding then return end

		-- If aiming, force return to walk
		if CameraState.IsAiming and MovementController.CurrentState ~= "Walk" then
			MovementController.CurrentState = "Walk"
			humanoid.WalkSpeed = WALK_SPEED
			return
		end

		-- Check if holding Shift for long enough to sprint (but not while aiming)
		if shiftPressed and not CameraState.IsAiming then
			local holdDuration = tick() - shiftPressTime
			if holdDuration >= SHIFT_HOLD_TIME_FOR_SPRINT and MovementController.CurrentState == "Run" then
				MovementController.CurrentState = "Sprint"
				humanoid.WalkSpeed = SPRINT_SPEED
				print("[MovementController] Sprint activated (held Shift)")
			end
		end

		-- Auto-return to walk if not moving
		if humanoid.MoveDirection.Magnitude == 0 and MovementController.CurrentState ~= "Walk" then
			MovementController.CurrentState = "Walk"
			humanoid.WalkSpeed = WALK_SPEED
		end
	end)
end

-- Setup wall jump detection
function MovementController.SetupWallJumpDetection()
	-- Wall jump detection will run in the update loop
	print("[MovementController] Wall jump detection enabled")
end

-- Attempt wall jump
function MovementController.AttemptWallJump()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Check cooldown
	local currentTime = tick()
	if currentTime - lastWallJumpTime < WALL_JUMP_COOLDOWN then
		return
	end

	-- Only wall jump if airborne
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end

	-- Detect wall
	local wallNormal = MovementController.DetectWall()
	if not wallNormal then
		return
	end

	-- Perform wall jump
	MovementController.PerformWallJump(wallNormal)
	lastWallJumpTime = currentTime
end

-- Detect if player is near a wall
function MovementController.DetectWall()
	local character = player.Character
	if not character then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	-- Raycast in all horizontal directions to find a wall
	local directions = {
		Vector3.new(1, 0, 0),   -- Right
		Vector3.new(-1, 0, 0),  -- Left
		Vector3.new(0, 0, 1),   -- Forward
		Vector3.new(0, 0, -1),  -- Back
	}

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	for _, direction in ipairs(directions) do
		local ray = workspace:Raycast(
			rootPart.Position,
			direction * WALL_DETECT_DISTANCE,
			raycastParams
		)

		if ray and ray.Instance then
			-- Check if it's a wall (vertical surface)
			local normal = ray.Normal
			local angle = math.abs(math.deg(math.acos(normal:Dot(Vector3.new(0, 1, 0)))))

			-- If angle is close to 90 degrees, it's a wall
			if angle > 80 and angle < 100 then
				return normal
			end
		end
	end

	return nil
end

-- Perform wall jump
function MovementController.PerformWallJump(wallNormal)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end

	-- Calculate jump direction with strong horizontal push off wall
	-- More horizontal (wall push) + lower vertical (jump height)
	local horizontalPush = wallNormal * 2.0 -- Double the horizontal component
	local verticalPush = Vector3.new(0, 3.5, 0) -- Reduced to 3.5 studs for lower jump
	local jumpDirection = (horizontalPush + verticalPush).Unit

	-- Apply force with strong velocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = jumpDirection * WALL_JUMP_FORCE * 1.9 -- 1.9x force multiplier (reduced for lower jump)
	bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
	bodyVelocity.Parent = rootPart

	-- Keep force active for good momentum
	task.delay(0.3, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)

	MovementController.IsWallJumping = true
	print("[MovementController] Wall jump performed!")

	-- Reset flag after landing
	task.delay(0.8, function()
		MovementController.IsWallJumping = false
	end)
end

-- Attempt to slide
function MovementController.AttemptSlide()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Check if already sliding
	if MovementController.IsSliding then return end

	-- Check cooldown
	local currentTime = tick()
	if currentTime - lastSlideTime < SLIDE_COOLDOWN then
		return
	end

	-- Must be sprinting to slide
	if MovementController.CurrentState ~= "Sprint" then
		return
	end

	-- Must be moving to slide
	if humanoid.MoveDirection.Magnitude < 0.1 then
		return
	end

	-- Perform the slide
	MovementController.PerformSlide()
	lastSlideTime = currentTime
end

-- Perform slide
function MovementController.PerformSlide()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Get current movement direction
	local slideDirection = humanoid.MoveDirection
	if slideDirection.Magnitude < 0.1 then return end

	-- Start slide
	MovementController.IsSliding = true
	MovementController.CurrentState = "Slide"

	-- Disable player control by setting WalkSpeed to 0
	humanoid.WalkSpeed = 0

	-- Store original camera offset
	local originalCameraOffset = humanoid.CameraOffset

	-- Smoothly lower camera
	local cameraLowerTween = TweenService:Create(
		humanoid,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CameraOffset = Vector3.new(0, SLIDE_CAMERA_OFFSET, 0)}
	)
	cameraLowerTween:Play()

	-- Apply slide velocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "SlideVelocity"
	bodyVelocity.Velocity = slideDirection * SLIDE_SPEED
	bodyVelocity.MaxForce = Vector3.new(10000, 0, 10000) -- Only horizontal force
	bodyVelocity.Parent = rootPart

	-- End slide after duration
	task.delay(SLIDE_DURATION, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end

		if humanoid and humanoid.Parent then
			-- Smoothly restore camera offset
			local cameraRaiseTween = TweenService:Create(
				humanoid,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{CameraOffset = originalCameraOffset}
			)
			cameraRaiseTween:Play()

			-- Return to walk speed
			MovementController.IsSliding = false
			MovementController.CurrentState = "Walk"
			humanoid.WalkSpeed = WALK_SPEED
		end
	end)
end

-- Handle character respawn
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Reset to walk speed
	humanoid.WalkSpeed = WALK_SPEED
	MovementController.CurrentState = "Walk"
	MovementController.IsSliding = false

	-- Re-setup input handling
	task.wait(0.1)
	-- Input handling is global, no need to re-setup
end)

-- Initialize on script load
MovementController.Initialize()

return MovementController
