------------------------------------------------------------
-- WINDSTORM SERVICE
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)
local MovementService = require(game.ServerScriptService.Server.Services.Player.MovementService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local windSound = SoundService.SoundEffects.Disasters.WindStorm

-- CONFIGS --
local DAMAGE_CHANCE = .15 -- 15% chance to deal damage to part
local IMPULSE_COLLISIONS = true		-- Enable/disable impulse collisions
local isActive = false


local WindStormService = {}

------------------------------------------------------------
-- WIND STORM LIFECYCLE
------------------------------------------------------------

function WindStormService:Start(duration, map)
	if isActive then return end
	isActive = true
	
	-- Pick ONE direction for the entire storm
	local windDirection = Vector3.new(
		math.random() - 0.5,
		0,
		math.random() - 0.5
	).Unit

	local baseStrength = 160 + math.random() * 300
	local endTime = tick() + duration

	-- Send windstorm effect to all players
	for _, player in Players:GetPlayers() do
		if StateService:GetState(player, StateDefinitions.PLAYING) then
			NetworkService:SendPostProcessingEffect(player, {
				Type = "WindStorm",
				Direction = windDirection,
				Toggle = true
			})
			
			-- Force all players to stand if they are sitting in chair
			MovementService:ForceStand(player)
		end
	end

	-- Play windstorm sound
	TweenerService:FadeSoundIn(windSound)
	
	-- Damage random parts over time
	task.spawn(function()
		while isActive do			
			self:DamageRandomParts(map)
			task.wait(duration / 3)
		end
	end)
	

	task.spawn(function()
		while isActive do			
			local t = math.clamp((endTime - tick()) / duration, 0, 1)
			local gust = (math.random() - 0.5) * 6 * t
			local windStrength = baseStrength + gust
			
			local rng = Random.new()
			local randomLift = rng:NextNumber(4, 8)

			for _, player in Players:GetPlayers() do
				if StateService:GetState(player, StateDefinitions.PLAYING) then
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.AssemblyLinearVelocity += windDirection * windStrength * 0.1 + Vector3.new(0, randomLift, 0)
					end
				end
			end

			task.wait(0.1)
		end
	end)
end

function WindStormService:End()
	if not isActive then return end
	isActive = false
	
	-- End the wind storm
	TweenerService:FadeSoundOut(windSound)
	
	-- Stop the windstorm effect for all players
	for _, player in Players:GetPlayers() do
		NetworkService:SendPostProcessingEffect(player, {
			Type = "WindStorm",
			Toggle = false
		})
	end
end

function WindStormService:ResetDisaster()
	self:End()
end


------------------------------------------------------------
-- DAMAGE INTERACTIONS
------------------------------------------------------------

-- Each round randomly damage parts around the map
function WindStormService:DamageRandomParts(map)
	for _, part in ipairs(map.InteractiveParts:GetDescendants()) do
		if part:IsDescendantOf(map.InteractiveParts) then
			-- small chance to be affected
			if math.random() < DAMAGE_CHANCE then
				-- Structural logic
				StructureService:Collapse(part, IMPULSE_COLLISIONS)
			end
		end
	end
end


return WindStormService
