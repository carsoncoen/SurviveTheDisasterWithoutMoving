------------------------------------------------------------
-- MOVEMENT HANDLER MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

------------------------------------------------------------
-- MODULES --
------------------------------------------------------------

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local MovementHandler = {}

local player = Players.LocalPlayer

-- MODULES --
local NetworkHandler = require(game.StarterPlayer.StarterPlayerScripts.Client.Handlers.Networking.NetworkHandler)

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------


------------------------------------------------------------
-- PUBLIC FUNCTIONS --
------------------------------------------------------------




function MovementHandler:Init()
	
end


------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
MovementHandler:Init()
return MovementHandler
