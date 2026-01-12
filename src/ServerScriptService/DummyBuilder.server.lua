--[[
	DummyBuilder.server.lua
	Creates target dummies for shooting practice
	Location: ServerScriptService > DummyBuilder
]]

local workspace = game:GetService("Workspace")

print("[DummyBuilder] Creating target dummy...")

-- Create dummy model
local dummy = Instance.new("Model")
dummy.Name = "TargetDummy"

-- Store original positions for respawn
local originalPositions = {}

-- Create humanoid root part
local rootPart = Instance.new("Part")
rootPart.Name = "HumanoidRootPart"
rootPart.Size = Vector3.new(2, 2, 1)
rootPart.Position = Vector3.new(0, 6, -15) -- In front of center spawn
rootPart.Anchored = true
rootPart.Color = Color3.fromRGB(150, 150, 150)
rootPart.Material = Enum.Material.SmoothPlastic
rootPart.Parent = dummy
originalPositions[rootPart] = rootPart.CFrame

-- Create head
local head = Instance.new("Part")
head.Name = "Head"
head.Size = Vector3.new(1.5, 1.5, 1.5)
head.Position = Vector3.new(0, 8, -15)
head.Anchored = true
head.Color = Color3.fromRGB(255, 200, 150) -- Skin tone
head.Material = Enum.Material.SmoothPlastic
head.Parent = dummy
originalPositions[head] = head.CFrame

-- Create torso
local torso = Instance.new("Part")
torso.Name = "Torso"
torso.Size = Vector3.new(2, 2, 1)
torso.Position = Vector3.new(0, 6, -15)
torso.Anchored = true
torso.Color = Color3.fromRGB(100, 100, 255) -- Blue shirt
torso.Material = Enum.Material.SmoothPlastic
torso.Parent = dummy
originalPositions[torso] = torso.CFrame

-- Create humanoid
local humanoid = Instance.new("Humanoid")
humanoid.MaxHealth = 100
humanoid.Health = 100
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
humanoid.Parent = dummy

-- Handle dummy death and respawn
humanoid.Died:Connect(function()
	print("[DummyBuilder] Target dummy died! Applying ragdoll effect...")

	-- Unanchor all parts to allow physics
	for _, part in pairs(dummy:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	-- Apply backward velocity to torso for ragdoll effect
	if torso then
		torso.AssemblyLinearVelocity = Vector3.new(0, 10, 30) -- Fly backwards and up
		torso.AssemblyAngularVelocity = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5)) -- Random spin
	end

	-- Wait 3 seconds, then respawn
	task.wait(3)

	-- Reset all parts to original positions and re-anchor
	for part, originalCFrame in pairs(originalPositions) do
		if part and part.Parent then
			part.CFrame = originalCFrame
			part.Anchored = true
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end

	-- Reset health
	humanoid.Health = humanoid.MaxHealth
	print("[DummyBuilder] Target dummy respawned with full health")
end)

-- Set primary part
dummy.PrimaryPart = rootPart

-- Parent to workspace
dummy.Parent = workspace

print("[DummyBuilder] Target dummy created at (0, 6, -15)")
print("[DummyBuilder] Dummy has 100 health and will regenerate after death")
