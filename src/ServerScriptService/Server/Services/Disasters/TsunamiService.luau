------------------------------------------------------------
-- TSUNAMI SERVICE
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
local TsunamiService = {}
local isActive = false
local tsunamiModel = ServerStorage.Disasters.Tsunami.TsunamiWave
local tsunamiSound = SoundService.SoundEffects.Disasters.Tsunami
local currentTsunami = nil
local hitParts = {}

-- CONFIG --
local SPAWN_DISTANCE = 300				-- Distance from map center to spawn tsunami
local TRAVEL_SPEED = 50					-- Studs per second
local DAMAGE_CHANCE = 0.6 				-- Chance to damage parts
local IMPULSE_COLLISIONS = true			-- Enable/disable impulse collisions
local TSUNAMI_DAMAGE = 50				-- Damage dealt to players


------------------------------------------------------------
-- TSUNAMI LIFECYCLE
------------------------------------------------------------

function TsunamiService:Start(duration, map)
	if isActive or not map then return end
	isActive = true
	hitParts = {}

	-- Get map center and size
	local mapCFrame, mapSize = map.Base:GetBoundingBox()
	local mapCenter = mapCFrame.Position

	-- Get original Y position from the model in ServerStorage
	local originalY = tsunamiModel:GetPivot().Position.Y

	-- Choose random angle (0-360 degrees)
	local angle = math.rad(math.random(0, 360))

	-- Calculate spawn position at fixed distance from center (preserve Y)
	local spawnOffset = Vector3.new(math.cos(angle) * SPAWN_DISTANCE, 0, math.sin(angle) * SPAWN_DISTANCE)
	local spawnPosition = Vector3.new(mapCenter.X + spawnOffset.X, originalY, mapCenter.Z + spawnOffset.Z)

	-- Calculate direction toward map center (only X and Z, ignore Y)
	local targetPosition = Vector3.new(mapCenter.X, originalY, mapCenter.Z)
	local direction = (targetPosition - spawnPosition).Unit

	-- Create lookAt CFrame that maintains Y position
	local lookAtCFrame = CFrame.new(spawnPosition, targetPosition)

	-- Clone and position tsunami
	currentTsunami = tsunamiModel:Clone()
	currentTsunami:PivotTo(lookAtCFrame)

	-- Randomly scale tsunami
	local rng = Random.new()
	local randomScale = rng:NextNumber(0.75, 1.25)
	currentTsunami:ScaleTo(randomScale)
	currentTsunami.Parent = workspace
	
	local tsunamiSound:Sound = tsunamiSound:Clone()
	tsunamiSound.Parent = currentTsunami.PrimaryPart
	tsunamiSound:Play()

	-- Start collision detection
	for _, part in ipairs(currentTsunami:GetDescendants()) do
		if part:IsA("BasePart") then
			self:DetectCollisions(part, map)
		end
	end

	-- Calculate travel distance (to map center + extra to cover whole map)
	local travelDistance = SPAWN_DISTANCE + (mapSize.Magnitude / 2) + 250
	local travelTime = travelDistance / TRAVEL_SPEED

	-- Get the part to tween (PrimaryPart or first BasePart)
	local partToTween = currentTsunami.PrimaryPart

	-- Calculate end position (same Y level, moving in forward direction)
	local endPosition = spawnPosition + (direction * travelDistance)

	-- Keep the same rotation, only change position
	local startCFrame = partToTween.CFrame
	local endCFrame = startCFrame - startCFrame.Position + endPosition

	local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
	local tween = TweenService:Create(partToTween, tweenInfo, {CFrame = endCFrame}):Play()
end

function TsunamiService:End()
	if not isActive then return end

	isActive = false

	-- Cleanup tsunami
	if currentTsunami then
		currentTsunami:Destroy()
		currentTsunami = nil
	end

	hitParts = {}
end

function TsunamiService:ResetDisaster()
	self:End()
end

------------------------------------------------------------
-- DAMAGE INTERACTIONS
------------------------------------------------------------

function TsunamiService:DetectCollisions(part, map)
	task.spawn(function()
		while isActive and part.Parent do
			local partsInContact = workspace:GetPartsInPart(part)

			for _, hit in ipairs(partsInContact) do
				-- Check for players
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)

				if player then
					-- Ensure player is in game
					if StateService:GetState(player, StateDefinitions.PLAYING) then
						-- Only damage head to avoid multiple hits
						if hit.Name == "Head" then
							local humanoid = character:FindFirstChild("Humanoid")
							if humanoid and not StateService:GetState(player, StateDefinitions.DAMAGED) then
								humanoid.Health -= TSUNAMI_DAMAGE
								StateService:ChangeState(player, StateDefinitions.DAMAGED, true)
							end
						end
					end
					-- Check for structures
				elseif hit:IsDescendantOf(map.InteractiveParts) then
					-- Skip if already hit this part
					if hitParts[hit] then continue end

					hitParts[hit] = true

					-- Random chance to damage
					if math.random() < DAMAGE_CHANCE then
						StructureService:Collapse(hit, IMPULSE_COLLISIONS)
					end
				end
			end

			task.wait(0.2)
		end
	end)
end


return TsunamiService