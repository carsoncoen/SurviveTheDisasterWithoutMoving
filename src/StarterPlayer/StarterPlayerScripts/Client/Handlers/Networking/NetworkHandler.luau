------------------------------------------------------------
-- NETWORK HANDLER MODULE SCRIPT (CLIENT)
-- @carsondev7
------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local NetworkHandler = {}

-- ENUMS --

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Player events

------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------


-- Fires a remote event for unlock events to the server
local function fireRemote(remote, data)
	if remote then
		remote:FireServer(data)
	else
		warn("[NetworkHandler] Invalid remote or player")
	end
end



------------------------------------------------------------
-- PUBLIC API --
------------------------------------------------------------


------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
return NetworkHandler
