----------------------------------------
-- STATE SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- VARIABLES --
local playerStates = {}

local StateService = {}

-- FUNCTIONS --

-- Add temporary force field to players
function StateService:AddForceField(player)
	local character = player.Character
	if character then
		local forceField = Instance.new("ForceField")
		forceField.Visible = false
		forceField.Parent = character
	end
	
	task.delay(3, function()
		local forceField = character:FindFirstChildOfClass("ForceField")
		if forceField then
			forceField:Destroy()
		end
	end)
end


-- Change player state
function StateService:ChangeState(player, state, value)
	if not playerStates[player] then
		playerStates[player] = {}
	end
	
	playerStates[player][state] = value
	
	-- If state has a cooldown, then reset it after the cooldown
	if state.Cooldown then
		task.delay(state.Cooldown, function()
			playerStates[player][state] = state.Default
		end)
	end
end

-- Get player state
function StateService:GetState(player, state)
	if not playerStates[player] then
		playerStates[player] = {}
	end
	
	return playerStates[player][state]
end

function StateService:ResetStates(player)
	if not playerStates[player] then
		playerStates[player] = {}
	end
	
	for _, state in pairs(StateDefinitions) do
		playerStates[player][state] = state.Default
	end
end

function StateService:ResetAllStates()
	for _, player in ipairs(Players:GetPlayers()) do
		self:ResetStates(player)
		self:ResetPlayer(player)
	end
end

-- Reset player properties
function StateService:ResetPlayer(player)
	if player then
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = 100
			end
		end
	end
end

return StateService
