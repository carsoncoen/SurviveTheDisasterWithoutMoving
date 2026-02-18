------------------------------------------------------------
-- FLOOD SERVICE
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- VARIABLES --
local FloodService = {}
local waterPart = workspace.World.Water
local rainClouds = workspace.World.RainClouds
local floodSound = SoundService.SoundEffects.Disasters.Flood
local rainSound = SoundService.SoundEffects.Disasters.Rain
local waterOriginalPos = waterPart.CFrame
local floodOccuring = false
local hitParts = {}

-- CONFIG --
local WATER_DAMAGE = 20
local IMPULSE_COLLISIONS = true			-- Enable/disable impulse collisions
local DAMAGE_CHANCE = 0.4 				-- Chance to damage parts
local BOBBLE_HEIGHT = 2					-- How high water bobs (in studs)
local BOBBLE_SPEED = 3					-- How fast water bobs (seconds per cycle)


------------------------------------------------------------
-- FLOOD LIFECYCLE
------------------------------------------------------------

-- Fade in rain clouds
function FloodService:Initialize(map)
	if floodOccuring then return end
	floodOccuring = true
	
	-- Tween in clouds and lower brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(rainClouds, tweenInfo, {Transparency = 0.3}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 0.5}):Play()
end

function FloodService:Start(duration, map)
		
	hitParts = {}
	
	-- Send rain effect to all players
	for _, player in Players:GetPlayers() do
		if StateService:GetState(player, StateDefinitions.PLAYING) then
			NetworkService:SendPostProcessingEffect(player, {
				Type = "Rain",
				Toggle = true
			})
		end
	end
	
	-- Stop bobbling during flood
	self:StopBobble()
	
	-- Play the flood sound
	TweenerService:FadeSoundIn(floodSound)
	TweenerService:FadeSoundIn(rainSound)
	
	-- Detect collisions with the water part
	self:DetectCollisions(waterPart, map)
	
	-- Get max height of map
	local maxWaterHeight = map.MaxWaterHeight.Value
	
	-- Get random water height
	local randomHeight = maxWaterHeight - math.random(0, 10)
	
	-- Move the water part up over time
	local tweenInfo = TweenInfo.new(duration / 3, Enum.EasingStyle.Linear)
	local goal = {CFrame = waterPart.CFrame + Vector3.new(0, randomHeight, 0)}

	TweenService:Create(waterPart, tweenInfo, goal):Play()
	
	
	-- Tween part back down to original position when duration is 2/3 of the duration
	task.delay(duration * (2 / 3), function()		
		local tweenInfo = TweenInfo.new(duration / 3, Enum.EasingStyle.Linear)
		local goal = {CFrame = waterOriginalPos}
		
		TweenService:Create(waterPart, tweenInfo, goal):Play()
		
		task.wait(duration / 3)
	end)
end

function FloodService:End()
	if not floodOccuring then return end
	
	-- End the flood
	floodOccuring = false
	TweenerService:FadeSoundOut(floodSound)
	TweenerService:FadeSoundOut(rainSound)
	
	-- Tween out clouds and reset brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(rainClouds, tweenInfo, {Transparency = 1}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 3}):Play()
	
	-- Stop the rain effect for all players
	for _, player in Players:GetPlayers() do
		NetworkService:SendPostProcessingEffect(player, {
			Type = "Rain",
			Toggle = false
		})
	end
	
	-- Resume bobbling after flood ends
	self:StartBobble()
end

function FloodService:ResetDisaster()
	self:End()
end


------------------------------------------------------------
-- DAMAGE INTERACTIONS
------------------------------------------------------------

function FloodService:DetectCollisions(part, map)
	task.spawn(function()
		while floodOccuring and part.Parent do
			for _, hit in ipairs(workspace:GetPartsInPart(part)) do

				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					if player and StateService:GetState(player, StateDefinitions.PLAYING) then
						if hit.Name ~= "Head" then continue end

						local humanoid = character:FindFirstChild("Humanoid")
						if humanoid and not StateService:GetState(player, StateDefinitions.DAMAGED) then
							humanoid.Health -= WATER_DAMAGE
							StateService:ChangeState(player, StateDefinitions.DAMAGED, true)
						end
					end

					-- If hit was not a player
				else
					if hit:IsDescendantOf(map.InteractiveParts) then
						if hitParts[hit] then continue end
						hitParts[hit] = true

						-- small chance to be affected
						if math.random() < DAMAGE_CHANCE then
							-- Structural logic
							StructureService:Collapse(hit, IMPULSE_COLLISIONS)
						end
					end
				end
			end
			task.wait(0.2)
		end
	end)
end

------------------------------------------------------------
-- PASSIVE EVENTS
------------------------------------------------------------

function FloodService:StartBobble()
	-- Don't start if already bobbling
	if bobbleConnection then return end

	-- Store original position if not already stored
	if not waterOriginalPos then
		waterOriginalPos = waterPart.CFrame
	end

	local bobbleTime = 0

	bobbleConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		bobbleTime = bobbleTime + dt

		-- Calculate bobble offset using sine wave
		local bobbleOffset = math.sin(bobbleTime * (math.pi / BOBBLE_SPEED)) * BOBBLE_HEIGHT

		-- Apply bobble to original position
		waterPart.CFrame = waterOriginalPos + Vector3.new(0, -bobbleOffset, 0)
	end)
end

function FloodService:StopBobble()
	if bobbleConnection then
		bobbleConnection:Disconnect()
		bobbleConnection = nil

		-- Reset to original position
		waterPart.CFrame = waterOriginalPos
	end
end


FloodService:StartBobble()
return FloodService
