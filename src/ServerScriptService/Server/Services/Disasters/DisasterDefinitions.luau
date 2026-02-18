------------------------------------------------------------
-- DISASTER DEFINITIONS
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local WindStormService = require(game.ServerScriptService.Server.Services.Disasters.WindStormService)
local FloodService = require(game.ServerScriptService.Server.Services.Disasters.FloodService)
local MeteorStrikeService = require(game.ServerScriptService.Server.Services.Disasters.MeteorStrikeService)
local PlagueService = require(game.ServerScriptService.Server.Services.Disasters.PlagueService)
local FireService = require(game.ServerScriptService.Server.Services.Disasters.FireService)
local AcidRainService = require(game.ServerScriptService.Server.Services.Disasters.AcidRainService)
local TsunamiService = require(game.ServerScriptService.Server.Services.Disasters.TsunamiService)
local LightningStormService = require(game.ServerScriptService.Server.Services.Disasters.LightningStormService)
local BlackholeService = require(game.ServerScriptService.Server.Services.Disasters.BlackholeService)
local TornadoService = require(game.ServerScriptService.Server.Services.Disasters.TornadoService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)


------------------------------------------------------------
-- DISASTER DEFINITIONS
------------------------------------------------------------

local DisasterDefinitions = {
	
	-- WIND STORM
	WindStorm = {
		Name = "Wind Storm",
		Description = "A strong gust pushes players to the side.",
		Duration = 5,
		MinPlayers = 0,
		
		Initialize = function(map)
		end,
		
		Start = function(duration, map)
			WindStormService:Start(duration, map)
		end,
		
		End = function(map)
			-- End the wind storm
			WindStormService:End(map)
		end,
		
		ResetDisaster = function(map)
			-- Reset the wind storm
			WindStormService:ResetDisaster(map)
		end,
	},
	
	-- FLOOD
	Flood = {
		Name = "Flood",
		Description = "A flood rises, pushing players to the surface.",
		Duration = 10,
		MinPlayers = 0,
		
		Initialize = function(map)
			-- Initialize the flood
			FloodService:Initialize(map)
		end,
		
		Start = function(duration, map)
			-- Start the flood
			FloodService:Start(duration, map)
		end,
		
		End = function(map)
			-- End the flood
			FloodService:End(map)
		end,
		
		ResetDisaster = function(map)
			-- Reset the flood
			FloodService:ResetDisaster(map)
		end,
	},
	
	-- METEOR STRIKE
	MeteorStrike = {
		Name = "Meteor Strike",
		Description = "A giant rock is hurdling towards you.",
		Duration = 10,
		MinPlayers = 0,
		
		Initialize = function(map)
			-- Initialize the meteor strike
			MeteorStrikeService:Initialize(map)
		end,

		Start = function(duration, map)
			-- Start the meteor strike
			MeteorStrikeService:Start(duration, map)
		end,
		
		End = function(map)
			-- End the meteor strike
			MeteorStrikeService:End(map)
		end,
		
		ResetDisaster = function(map)
			-- Reset the meteor strike
			MeteorStrikeService:ResetDisaster(map)
		end,
	},
	
	
	-- PLAGUE 
	Plague = {
		Name = "Plague",
		Description = "A plague breaks out, infecting players.",
		Duration = 10,
		MinPlayers = 3,
		
		Initialize = function(map)
			-- Initialize the plague
		end,
		
		Start = function(duration, map)
			-- Start the plague
			PlagueService:Start(duration, map)
		end,
		
		End = function(map)
			-- End the plague
			PlagueService:End(map)
		end,
		
		ResetDisaster = function(map)
			-- Reset the plague
			PlagueService:ResetDisaster(map)
		end,
	},
	
	-- FIRE 
	Fire = {
		Name = "Fire",
		Description = "A fire breaks lose",
		Duration = 10,
		MinPlayers = 0,
		
		Initialize = function(map)
			-- Initialize the fire
		end,

		Start = function(duration, map)
			-- Start the fire
			FireService:Start(duration, map)
		end,

		End = function(map)
			-- End the fire
			FireService:End(map)
		end,
		
		ResetDisaster = function(map)
			-- Reset the fire
			FireService:ResetDisaster(map)
		end,
	},
	
	-- ACID RAIN 
	AcidRain = {
		Name = "Acid Rain",
		Description = "Acid rain begins to fall.",
		Duration = 10,
		MinPlayers = 0,
		
		Initialize = function(map)
			AcidRainService:Initialize(map)
		end,

		Start = function(duration, map)
			-- Start the acid rain
			AcidRainService:Start(duration, map)
		end,

		End = function()
			-- End the acid rain
			AcidRainService:End()
		end,
		
		ResetDisaster = function(map)
			AcidRainService:ResetDisaster(map)
		end,
	},
	
	-- TSUNAMI
	Tsunami = {
		Name = "Tsunami",
		Description = "A tsunami comes rushing in.",
		Duration = 10,
		MinPlayers = 0,

		Initialize = function(map)
		end,

		Start = function(duration, map)
			-- Start the acid rain
			TsunamiService:Start(duration, map)
		end,

		End = function()
			-- End the acid rain
			TsunamiService:End()
		end,

		ResetDisaster = function(map)
			TsunamiService:ResetDisaster(map)
		end,
	},
	
	-- LIGHTNING STORM
	LightningStorm = {
		Name = "Lightning Storm",
		Description = "Lightning storm rushes in",
		Duration = 10,
		MinPlayers = 0,

		Initialize = function(map)
			LightningStormService:Initialize(map)
		end,

		Start = function(duration, map)
			-- Start the lightning storm
			LightningStormService:Start(duration, map)
		end,

		End = function()
			-- End the lighning storm
			LightningStormService:End()
		end,

		ResetDisaster = function(map)
			LightningStormService:ResetDisaster(map)
		end,
	},
	
	-- BLACKHOLE
	Blackhole = {
		Name = "Blackhole",
		Description = "Blackhole starts pulling",
		Duration = 7,
		MinPlayers = 0,

		Initialize = function(map)
			BlackholeService:Initialize(map)
		end,

		Start = function(duration, map)
			-- Start the lightning storm
			BlackholeService:Start(duration, map)
		end,

		End = function()
			-- End the lighning storm
			BlackholeService:End()
		end,

		ResetDisaster = function(map)
			BlackholeService:ResetDisaster(map)
		end,
	},
	
	-- Tornado
	Tornado = {
		Name = "Tornado",
		Description = "Tornado starts pulling",
		Duration = 10,
		MinPlayers = 0,

		Initialize = function(map)
			TornadoService:Initialize(map)
		end,

		Start = function(duration, map)
			-- Start the lightning storm
			TornadoService:Start(duration, map)
		end,

		End = function()
			-- End the lighning storm
			TornadoService:End()
		end,

		ResetDisaster = function(map)
			TornadoService:ResetDisaster(map)
		end,
	},
	
	---- EARTHQUAKE 
	--Earthquake = {
	--	Name = "Earthquake",
	--	Description = "An earthquake breaks out.",
	--	Duration = 10,
	--	MinPlayers = 0,

	--	Start = function(duration, map)
	--		-- Start the earthquake
	--	end,

	--	End = function()
	--		-- End the earthquake
	--	end
	--},
	
	
	
	---- HEAT STROKE 
	--	HeatWave = {
	--	Name = "HeatWave",
	--	Description = "Heat wave sets in.",
	--	Duration = 10,
	--	MinPlayers = 0,

	--	Start = function(duration, map)
	--		-- Start the heat wave
	--	end,

	--	End = function()
	--		-- End the heat wave
	--	end
	--},
	
	
	
	
	
	
	
	---- ENVIRONMENTAL CHANGES --
	--DenseFog = {
	--	Name = "Dense Fog",
	--	Description = "A dense fog rolls in.",
	--	Duration = 0,
	--	MinPlayers = 0,
	--	Persistent = true,

	--	Start = function(duration, map)
	--		-- Start the fog
	--	end,

	--	End = function()
	--		-- End the fog
	--	end
	--},
}

return DisasterDefinitions
