------------------------------------------------------------
-- MODIFIER SERVICE MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

local Players = game:GetService("Players")

local ModifierService = {}
local playerModifiers = {}  -- { [player] = { Speed = {...}, Jump = {...} } }

-- Modifier types
local ModifierType = {
	SPEED = "Speed",
	JUMP = "Jump",
	HEALTH = "Health",
}

------------------------------------------------------------
-- ADD/REMOVE MODIFIERS
------------------------------------------------------------

-- Add a temporary or permanent modifier
function ModifierService:AddModifier(player, modifierType, modifierId, value, duration)
	if not playerModifiers[player] then
		playerModifiers[player] = {
			Speed = {},
			Jump = {},
			Health = {},
		}
	end

	-- Add modifier
	playerModifiers[player][modifierType][modifierId] = {
		Value = value,
		Permanent = duration == nil,
	}

	-- Apply the change
	self:UpdatePlayerStats(player)

	-- Remove after duration if temporary
	if duration then
		task.delay(duration, function()
			self:RemoveModifier(player, modifierType, modifierId)
		end)
	end

	print(string.format("Added %s modifier '%s' (+%d) to %s", 
		modifierType, modifierId, value, player.Name))
end

function ModifierService:RemoveModifier(player, modifierType, modifierId)
	if not playerModifiers[player] then return end

	playerModifiers[player][modifierType][modifierId] = nil
	self:UpdatePlayerStats(player)

	print(string.format("Removed %s modifier '%s' from %s", 
		modifierType, modifierId, player.Name))
end

-- Calculate total modifier for a type
function ModifierService:GetTotalModifier(player, modifierType)
	if not playerModifiers[player] then return 0 end

	local total = 0
	for modifierId, modifier in pairs(playerModifiers[player][modifierType]) do
		total = total + modifier.Value
	end

	return total
end

-- Apply all modifiers to player
function ModifierService:UpdatePlayerStats(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Base values
	local baseSpeed = 16
	local baseJump = 7.2

	-- Calculate totals
	local speedModifier = self:GetTotalModifier(player, ModifierType.SPEED)
	local jumpModifier = self:GetTotalModifier(player, ModifierType.JUMP)

	-- Apply
	humanoid.WalkSpeed = baseSpeed + speedModifier
	humanoid.JumpHeight = baseJump + jumpModifier

	print(string.format("%s stats: Speed=%d, Jump=%.1f", 
		player.Name, humanoid.WalkSpeed, humanoid.JumpHeight))
end

-- Check if a specific modifier is active
function ModifierService:HasModifier(player, modifierType, modifierId)
	if not playerModifiers[player] then return false end
	return playerModifiers[player][modifierType][modifierId] ~= nil
end

-- Clear all modifiers (on death/round end)
function ModifierService:ClearAllModifiers(player)
	playerModifiers[player] = {
		Speed = {},
		Jump = {},
		Health = {},
	}
	self:UpdatePlayerStats(player)
end

-- Clear only temporary modifiers (keep permanent ones)
function ModifierService:ClearTemporaryModifiers(player)
	if not playerModifiers[player] then return end

	for modifierType, modifiers in pairs(playerModifiers[player]) do
		for modifierId, modifier in pairs(modifiers) do
			if not modifier.Permanent then
				modifiers[modifierId] = nil
			end
		end
	end

	self:UpdatePlayerStats(player)
end

return ModifierService