----------------------------------------
-- MAIN UI HANDLER MODULE SCRIPT 
-- @carsondev7
----------------------------------------

----------------------------
-- SERVICES --
----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------
-- VARIABLES --
----------------------------
local UIHandler = {}

-- SHARED MODULES --
local RoundUIHandler = require(script.Parent.RoundUIHandler)
local NotificationUIHandler = require(script.Parent.NotificationUIHandler)

-- ENUMS --
local UIType = require(ReplicatedStorage.Shared.Modules.Enums.UIType)

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local guiEvents = remoteEvents:WaitForChild("GUI")
local notificationEvent = guiEvents:WaitForChild("NotificationEvent")

-- CONSTANTS --


----------------------------
-- PRIVATE FUNCTIONS --
----------------------------

local handlers = {
    
	-- GUI --
	[UIType.WaitingForPlayers] = function(data)
		RoundUIHandler:Update(data)
	end,
	[UIType.Intermission] = function(data)
		RoundUIHandler:Update(data)
	end,
	[UIType.MapDisplay] = function(data)
		RoundUIHandler:Update(data)
	end,
	[UIType.NewDisasterStarting] = function(data)
		RoundUIHandler:Update(data)
	end,
	[UIType.DisasterInProgress] = function(data)
		RoundUIHandler:Update(data)
	end,
	[UIType.RoundOver] = function(data)
		RoundUIHandler:Update(data)
	end,
	[UIType.DeathFeed] = function(data)
		NotificationUIHandler:UpdateDeathFeed(data)
	end,
	[UIType.UpdateTokens] = function(data)
		NotificationUIHandler:UpdateTokens(data)
	end,
	
}


----------------------------
-- PUBLIC FUNCTIONS --
----------------------------

-- Start listening for remote UI events
function UIHandler:Start()
    -- Listen for every event in GUI remote events
	for _, event in guiEvents:GetChildren() do
        if event:IsA("RemoteEvent") then
			event.OnClientEvent:Connect(function(data)
				--print(data)
                self:HandleUIEvent(data)
            end)
        end 
    end
end

-- Handles all UI events given the Enum UI type, directing to the proper UI method
function UIHandler:HandleUIEvent(data)
	local uiType = data.uiType	
	
	local handler = handlers[uiType]
    if handler then
        local success, err = pcall(handler, data)
		if not success then
            warn("UI handler error for type:", uiType, err)
        end
    else
        warn("Unhandled ui type:", uiType)
    end
end

----------------------------
-- MAIN --
----------------------------
UIHandler:Start()
return UIHandler
