----------------------------------------------------------------------------------------------------------------------------
-- NETWORK SERVICE MODULE SCRIPT 
-- @carsondev7
----------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local NetworkService = {}

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Events
local guiEvents = remoteEvents:WaitForChild("GUI")
local notificationEvent = guiEvents:WaitForChild("NotificationEvent")
local soundEffectEvent = remoteEvents:WaitForChild("Audio"):WaitForChild("SoundEffect")
local postProcessingEvent = remoteEvents:WaitForChild("PostProcessing"):WaitForChild("PostProcessing")

------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------

-- Fires a remote event for player
local function fireRemoteEvent(remote, player, data)
	if remote and player and player:IsA("Player") then
		remote:FireClient(player, data)
	else
		warn("[NetworkService] Invalid remote", remote)
	end
end


------------------------------------------------------------
-- PUBLIC API --
------------------------------------------------------------

-- Send confirmation to client
function NetworkService:SendUIEvent(player, data)
	fireRemoteEvent(notificationEvent, player, data)
end

-- Send sound effect to client
function NetworkService:SendSoundEffect(player, data)
	fireRemoteEvent(soundEffectEvent, player, data)
end

-- Send pp effect to client
function NetworkService:SendPostProcessingEffect(player, data)
	fireRemoteEvent(postProcessingEvent, player, data)
end



------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
return NetworkService
