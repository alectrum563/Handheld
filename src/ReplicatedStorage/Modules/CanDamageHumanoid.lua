--[[
	CanDamageHumanoid.lua
	Validates if a player can damage a humanoid (prevents friendly fire)
	Location: ReplicatedStorage > Modules > CanDamageHumanoid
]]

local Players = game:GetService("Players")

local function canDamageHumanoid(player, targetHumanoid)
	-- Check if humanoid is already dead
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	local targetCharacter = targetHumanoid.Parent
	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

	-- If the target is not a player (NPC/Dummy), allow damage
	if not targetPlayer then
		return true
	end

	-- If either player is neutral (not on a team), allow damage
	if player.Neutral or targetPlayer.Neutral then
		return true
	end

	-- Only allow damage if players are on different teams (prevent friendly fire)
	return player.Team ~= targetPlayer.Team
end

return canDamageHumanoid
