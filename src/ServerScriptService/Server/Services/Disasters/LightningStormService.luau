------------------------------------------------------------
-- LIGHTNING STORM SERVICE
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- VARIABLES --
local LightningStormService = {}
local isActive = false
local currentMap = nil
local activeStrikeThread = nil
local lightningPart = ServerStorage.Disasters.LightningStorm.LightningPart
local soundPart = ServerStorage.Disasters.LightningStorm.SoundPart
local lightningSounds = {
	SoundService.SoundEffects.Disasters.Lightning1,
	SoundService.SoundEffects.Disasters.Lightning2,
	SoundService.SoundEffects.Disasters.Lightning3
}
local rainClouds = workspace.World.RainClouds

-- CONFIG --
local IMPULSE_COLLISIONS = true			-- Enable/disable impulse collisions
local LIGHTNING_HEIGHT = 150			-- Height above map to start raycast
local LIGHTNING_RADIUS = 15				-- Radius of lightning damage
local STRIKE_INTERVAL_MIN = 1			-- Min time between strikes
local STRIKE_INTERVAL_MAX = 1.5			-- Max time between strikes
local PLAYER_TARGET_CHANCE = 0.25		-- Chance to target a player if available


------------------------------------------------------------
-- LIGHTNING STORM LIFECYCLE
------------------------------------------------------------

function LightningStormService:Initialize(map)
	if isActive or not map then return end
	isActive = true
	currentMap = map

	-- Clean up previous strike thread if it exists
	if activeStrikeThread then
		task.cancel(activeStrikeThread)
		activeStrikeThread = nil
	end
	
	-- Tween in clouds and lower brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(rainClouds, tweenInfo, {Transparency = 0.3}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 0.5}):Play()
end


function LightningStormService:Start(duration, map)
	if not isActive then return end
	
	-- Send rain effect to all players
	for _, player in Players:GetPlayers() do
		if StateService:GetState(player, StateDefinitions.PLAYING) then
			NetworkService:SendPostProcessingEffect(player, {
				Type = "Rain",
				Toggle = true
			})
		end
	end
	
	activeStrikeThread = task.spawn(function()
		self:SpawnLightningStrikes()
		activeStrikeThread = nil
	end)
end

function LightningStormService:End()
	if not isActive then return end
	isActive = false
	currentMap = nil
	
	if activeStrikeThread then
		task.cancel(activeStrikeThread)
		activeStrikeThread = nil
	end
	
	-- Stop the rain effect for all players
	for _, player in Players:GetPlayers() do
		NetworkService:SendPostProcessingEffect(player, {
			Type = "Rain",
			Toggle = false
		})
	end
	
	-- Tween out clouds and raise brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(rainClouds, tweenInfo, {Transparency = 1}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 3}):Play()
end

function LightningStormService:ResetDisaster()
	self:End()
end


------------------------------------------------------------
-- LIGHTNING EFFECTS
------------------------------------------------------------

function LightningStormService:SpawnLightningStrikes()
	if not isActive or not currentMap or not currentMap.Base then return end

	local base = currentMap.Base
	local basePart = base.PrimaryPart
	local basePosition = basePart.Position
	local baseSize = basePart.Size

	local rng = Random.new()

	while isActive do
		if not currentMap or not currentMap.Base then break end
		
		local outsidePlayers = self:GetOutsidePlayers()
		local targetPosition = nil

		-- Randomly decide to target a player or random location
		if #outsidePlayers > 0 and rng:NextNumber(0, 1) < PLAYER_TARGET_CHANCE then
			-- Target a random outside player
			local randomPlayer = outsidePlayers[rng:NextInteger(1, #outsidePlayers)]

			if randomPlayer and randomPlayer.Character and StateService:GetState(randomPlayer, StateDefinitions.PLAYING) then
				local humanoid = randomPlayer.Character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					targetPosition = randomPlayer.Character:GetPivot().Position

					-- Kill player
					humanoid.Health = 0
				end
			end
		end

		-- If no player targeted, strike random location on map
		if not targetPosition then
			-- Generate random position within base bounds
			local randomX = basePosition.X + rng:NextNumber(-baseSize.X / 2, baseSize.X / 2)
			local randomZ = basePosition.Z + rng:NextNumber(-baseSize.Z / 2, baseSize.Z / 2)
			local rayOrigin = Vector3.new(randomX, basePosition.Y + baseSize.Y + LIGHTNING_HEIGHT, randomZ)

			-- Raycast down to find ground
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Include
			rayParams.FilterDescendantsInstances = {currentMap}

			local result = workspace:Raycast(rayOrigin, Vector3.new(0, -1000, 0), rayParams)

			if result then
				targetPosition = result.Position
			end
		end

		-- Create lightning at target position
		if targetPosition then
			self:CreateLightning(targetPosition)
		end
	
		
		if isActive then
			-- Wait before next strike
			task.wait(rng:NextNumber(STRIKE_INTERVAL_MIN, STRIKE_INTERVAL_MAX))
		end
	end
end

-- Create lightning at position and collapse nearby parts
function LightningStormService:CreateLightning(position)
	if not isActive then return end
	
	-- Get random lightning sound
	local lightningSound = lightningSounds[math.random(1, #lightningSounds)]
	local soundClone = lightningSound:Clone()
	local soundPartClone = soundPart:Clone()
	soundPartClone.Position = position
	soundPartClone.Parent = workspace
	soundClone.Parent = soundPartClone
	soundClone:Play()
	
	-- Create lightning visual effect
	local lightningPartClone = lightningPart:Clone()
	lightningPartClone.Position = position
	
	-- Random lightning orientation
	for _, child in pairs(lightningPartClone.Moveable:GetChildren()) do
		if child:IsA("Attachment") then
			-- Create random offset
			local randomOffset = Vector3.new(
				math.random(-10, 10), 
				0, 
				math.random(-10, 10)
			)

			-- Apply offset to the attachment's CFrame
			child.CFrame = child.CFrame * CFrame.new(randomOffset)
		end
	end
	
	-- Get random orientation
	local randomRotation = CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
	lightningPartClone.CFrame = CFrame.new(position) * randomRotation
	
	-- Place strike in world
	lightningPartClone.Parent = workspace

	-- Get parts in radius of strike
	local partsInRadius = workspace:GetPartBoundsInRadius(position, LIGHTNING_RADIUS)

	-- Damage structures
	for _, part in ipairs(partsInRadius) do
		if part:IsDescendantOf(currentMap.InteractiveParts) then
			StructureService:Collapse(part, IMPULSE_COLLISIONS)
		end
	end

	-- Cleanup visual after short delay
	Debris:AddItem(lightningPartClone, 0.25)
	
	-- Cleanup sound and smoke after it finishes playing
	task.spawn(function()
		local smoke = soundPartClone.Smoke
		if smoke then
			smoke.Enabled = true
			task.wait(0.5)
			smoke.Enabled = false
			Debris:AddItem(soundPartClone, 5)
		end
	end)
end


------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------

function LightningStormService:GetOutsidePlayers()
	if not currentMap or not isActive then return {} end

	local outsidePlayers = {}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, player in ipairs(Players:GetPlayers()) do
		if not StateService:GetState(player, StateDefinitions.PLAYING) then continue end

		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		-- Raycast upward to check for ceiling
		rayParams.FilterDescendantsInstances = {character}
		local rayResult = workspace:Raycast(root.Position, Vector3.new(0, 100, 0), rayParams)

		-- If no ceiling found, player is outside
		if not rayResult then
			table.insert(outsidePlayers, player)
		end
	end

	return outsidePlayers
end

return LightningStormService