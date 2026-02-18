------------------------------------------------------------
-- EFFECT DEFINITIONS
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")

-- MODULES --
local WindService = require(script.Parent.WindService)
local AcidRainHandler = require(script.Parent.AcidRainHandler)
local RainHandler = require(script.Parent.RainHandler)

-- VARIABLES --
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Wind
local wind = nil

local EffectDefinitions = {

	-- WIND STORM
	WindStorm = {
		Start = function(data)
			-- Start the wind storm effects
			if wind then
				wind:Stop()
			end

			wind = WindService.new({
				Direction = data.Direction,
				Speed = 25,
				Amplitude = .25,
				Frequency = 4,
			})

			wind:Start()
		end,

		End = function(data)
			-- End the wind storm effects
			if wind ~= nil then
				wind:Stop()
				wind = nil
			end
		end,
	},

	-- RAINING (Flood, Lightning Storm)
	Rain = {
		Start = function(data)
			-- Start the flood effects
			RainHandler:Start()
		end,

		End = function(data)
			-- End the flood effects
			RainHandler:Stop()
		end,
	},
	

	-- ACID RAIN 
	AcidRain = {
		Start = function(data)
			-- Start the acid rain effects
			AcidRainHandler:Start()
		end,

		End = function(data)
			-- End the acid rain effects
			AcidRainHandler:Stop()
		end,

	},
}


-- Detect when players die
character:WaitForChild("Humanoid").Died:Connect(function()
	if wind then
		wind:Stop()
		wind = nil
	end
end)

return EffectDefinitions
