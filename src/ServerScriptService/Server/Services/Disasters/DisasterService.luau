------------------------------------------------------------
-- DISASTER SERVICE
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
local DisasterDefinitions = require(script.Parent.DisasterDefinitions)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- ENUMS --
local SoundType	= require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local DisasterService = {}


------------------------------------------------------------
-- DISASTER FUNCTIONS
------------------------------------------------------------

-- Initialize any pre disaster events before it actually starts
function DisasterService:InitializeDisaster(disaster, map)
	if not disaster or not map then return end
	-- Initialize the disaster
	disaster.Initialize(map)
end


function DisasterService:StartDisaster(disaster, map)
	if not disaster or not map then return end
	
	-- Start the disaster
	disaster.Start(disaster.Duration, map)
end
	
	
function DisasterService:EndDisaster(disaster, map)
	if not disaster then return end
	-- End the disaster
	disaster.End(map)
end


function DisasterService:ResetDisasters(map)
	for _, disaster in pairs(DisasterDefinitions) do
		disaster.ResetDisaster(map)
	end
end


function DisasterService:ChooseRandomDisaster(numPlayersAlive)
	local disasters = {}
	
	--return DisasterDefinitions["Tornado"]

	for name, disaster in pairs(DisasterDefinitions) do
		if disaster.MinPlayers <= numPlayersAlive then
			table.insert(disasters, disaster)
		end
	end

	-- Remove last disaster to prevent repeat
	if self.LastDisaster then
		for i = #disasters, 1, -1 do
			if disasters[i] == self.LastDisaster then
				table.remove(disasters, i)
				break
			end
		end
	end

	local chosenDisaster = disasters[math.random(1, #disasters)]
	self.LastDisaster = chosenDisaster

	return chosenDisaster
end


return DisasterService
