--[[
	Utilities.lua
	Helper functions used across the game
	Location: ReplicatedStorage > Modules > Utilities
]]

local Utilities = {}

-- Get player from a character part
function Utilities.GetPlayerFromPart(part)
	if not part or not part:IsA("BasePart") then
		return nil
	end

	local character = part:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	return game.Players:GetPlayerFromCharacter(character)
end

-- Get character from player
function Utilities.GetCharacter(player)
	return player.Character
end

-- Check if character is alive
function Utilities.IsAlive(player)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	return humanoid.Health > 0
end

-- Get humanoid from player
function Utilities.GetHumanoid(player)
	local character = player.Character
	if not character then return nil end

	return character:FindFirstChildOfClass("Humanoid")
end

-- Format time as MM:SS
function Utilities.FormatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", minutes, secs)
end

-- Deep copy a table
function Utilities.DeepCopy(original)
	local copy
	if type(original) == "table" then
		copy = {}
		for key, value in pairs(original) do
			copy[Utilities.DeepCopy(key)] = Utilities.DeepCopy(value)
		end
	else
		copy = original
	end
	return copy
end

-- Wait for child with timeout
function Utilities.WaitForChild(parent, childName, timeout)
	timeout = timeout or 5
	local startTime = tick()
	while not parent:FindFirstChild(childName) do
		if tick() - startTime > timeout then
			warn(string.format("Timeout waiting for child '%s' in %s", childName, parent:GetFullName()))
			return nil
		end
		task.wait(0.1)
	end
	return parent:FindFirstChild(childName)
end

return Utilities
