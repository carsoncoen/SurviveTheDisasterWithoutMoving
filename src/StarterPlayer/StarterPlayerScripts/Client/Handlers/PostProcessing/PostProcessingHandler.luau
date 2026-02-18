------------------------------------------------------------
-- POST PROCESSING HANDLER MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
------------------------------------------------------------
-- MODULES --
------------------------------------------------------------
local EffectDefinitions = require(script.Parent.EffectDefinitions)

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local PostProcessingHandler = {}

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera


-- Flood
local water = workspace:WaitForChild("World"):WaitForChild("Water")
local underwaterBlur = Lighting:WaitForChild("UnderwaterBlur")
local underwaterColor = Lighting:WaitForChild("UnderwaterColor")

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local postProcessingEvent = remoteEvents:WaitForChild("PostProcessing"):WaitForChild("PostProcessing")

------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------

-- Check if players cam is under water level, add post processing effect
local function updateUnderwaterEffect()
	RunService.RenderStepped:Connect(function()
		if not water or not water.Parent then return end

		local waterSurfaceY = water.Position.Y + water.Size.Y / 2
		local camY = camera.CFrame.Position.Y

		if camY < waterSurfaceY then
			-- Underwater
			underwaterColor.Enabled = true
			underwaterBlur.Enabled = true
		else
			-- Above water
			underwaterColor.Enabled = false
			underwaterBlur.Enabled = false
		end
	end)
end

-- Reset lighting properties
local function resetLighting()
	Lighting.Brightness = 3
end

------------------------------------------------------------
-- PUBLIC FUNCTIONS --
------------------------------------------------------------
function PostProcessingHandler:AddEffect(data)
	if not data or not data.Type then return end
	
	local effect = EffectDefinitions[data.Type]
	if not effect then return end
	
	-- Apply effect
	effect.Start(data)
end

function PostProcessingHandler:RemoveEffect(data)
	if not data then return end
	
	local effect = EffectDefinitions[data.Type]
	if not effect then return end
	
	-- Stop effect
	effect.End(data)
end


function PostProcessingHandler.Init()
	task.spawn(updateUnderwaterEffect)
end


postProcessingEvent.OnClientEvent:Connect(function(data)
	if not data then return end
	
	if data.Toggle then
		PostProcessingHandler:AddEffect(data)
	else
		PostProcessingHandler:RemoveEffect(data)
	end
end)


------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
PostProcessingHandler:Init()

return PostProcessingHandler
