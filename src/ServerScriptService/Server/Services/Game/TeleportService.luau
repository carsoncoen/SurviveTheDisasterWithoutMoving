----------------------------------------
-- TELEPORT SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local MovementService = require(game.ServerScriptService.Server.Services.Player.MovementService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- REMOTES --

-- VARIABLES --
local TeleportService = {}

-- FUNCTIONS --
-- Teleport players to map spawn part
function TeleportService:TeleportPlayersToMap(map)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			MovementService:ForceStand(player)
			local mapSpawn = map.SpawnPart
			local randomX = math.random(-10, 10)
			local randomZ = math.random(-10, 10)
			local randomY = math.random(0, 0)
			local randomPos = Vector3.new(mapSpawn.Position.X + randomX, mapSpawn.Position.Y + 3, mapSpawn.Position.Z + randomZ)
			char:PivotTo(CFrame.new(randomPos))
		end
	end
end

-- Teleport single player to map spawn part
function TeleportService:TeleportPlayerToMap(player, map)
	if player and map then
		local char = player.Character
		if char then
			MovementService:ForceStand(player)
			local mapSpawn = map.SpawnPart
			local randomX = math.random(-10, 10)
			local randomZ = math.random(-10, 10)
			local randomY = math.random(0, 0)
			local randomPos = Vector3.new(mapSpawn.Position.X + randomX, mapSpawn.Position.Y + 3, mapSpawn.Position.Z + randomZ)
			char:PivotTo(CFrame.new(randomPos))
		end
	end
end

-- Teleport players to lobby spawn part
function TeleportService:TeleportPlayersToLobby()
	for _, player in ipairs(Players:GetPlayers()) do
		-- Only teleport is player is still in the map
		local isPlaying = StateService:GetState(player, StateDefinitions.PLAYING)
		if not isPlaying then continue end
		
		local char = player.Character
		if char then
			MovementService:ForceStand(player)
			local lobbySpawn = workspace.Lobby.SpawnLocation
			local randomX = math.random(-10, 10)
			local randomZ = math.random(-10, 10)
			local randomY = math.random(0, 0)
			local randomPos = Vector3.new(lobbySpawn.Position.X + randomX, lobbySpawn.Position.Y + 3, lobbySpawn.Position.Z + randomZ)
			char:PivotTo(CFrame.new(randomPos))
		end
	end
end


return TeleportService
