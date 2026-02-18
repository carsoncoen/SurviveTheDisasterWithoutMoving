------------------------------------------------------------
-- BLACKHOLE SERVICE
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
local RunService = game:GetService("RunService")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local MovementService = require(game.ServerScriptService.Server.Services.Player.MovementService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- VARIABLES --
local BlackholeService = {}
local isActive = false
local currentMap = nil
local currentBlackhole = nil
local blackholePart = ServerStorage.Disasters.Blackhole.BlackholePart
local blackholeSound = SoundService.SoundEffects.Disasters.Blackhole
local pullConnection = nil
local startTime = 0
local currentRadius = 0


-- CONFIG --
local MIN_RADIUS = 30					-- Starting pull radius
local MAX_RADIUS = 40					-- Maximum pull radius
local RADIUS_GROW_RATE = 1				-- Studs per second radius growth
local STRUCTURE_PULL_STRENGTH = 1000	-- Force strength
local PLAYER_PULL_STRENGTH = 230000		-- Player pull strength
local KILL_RADIUS = 8					-- Instant death radius
local PART_DESTROY_RADIUS = 8			-- Radius to destroy parts
local IMPULSE_COLLISIONS = false

------------------------------------------------------------
-- BLACKHOLE LIFECYCLE
------------------------------------------------------------

function BlackholeService:Initialize(map)
	if isActive then return end
	
	if not map then return end
	isActive = true
	currentMap = map
	currentRadius = MIN_RADIUS
	startTime = 0
	
	-- Clean up previous connection if it exists
	if pullConnection then
		pullConnection:Disconnect()
		pullConnection = nil
	end
end

function BlackholeService:Start(duration, map)
	if not isActive then return end
	
	-- Spawn the blackhole
	self:SpawnBlackhole()
	
	startTime = tick()

	-- Start pulling loop
	pullConnection = RunService.Heartbeat:Connect(function(dt)
		if isActive and currentBlackhole then
			-- Update radius over time
			local elapsed = tick() - startTime
			currentRadius = math.min(MIN_RADIUS + (elapsed * RADIUS_GROW_RATE), MAX_RADIUS)
			self:PullObjects(dt)
		end
	end)
end

function BlackholeService:End()
	if not isActive then return end

	isActive = false
	
	self:CleanupPlayerForces()

	-- Stop pull loop
	if pullConnection then
		pullConnection:Disconnect()
		pullConnection = nil
	end

	-- Remove blackhole
	if currentBlackhole then
		currentBlackhole:Destroy()
		currentBlackhole = nil
	end

	currentMap = nil
	currentRadius = 0
	startTime = 0
end

function BlackholeService:ResetDisaster()
	self:End()
end

------------------------------------------------------------
-- BLACKHOLE EFFECTS
------------------------------------------------------------

function BlackholeService:SpawnBlackhole()
	if not isActive or not currentMap then return end

	local base = currentMap.Base
	local baseCFrame, baseSize = base:GetBoundingBox()
	local basePosition = baseCFrame.Position

	local rng = Random.new()
	local randomX = basePosition.X + rng:NextNumber(-baseSize.X / 3, baseSize.X / 3)
	local randomZ = basePosition.Z + rng:NextNumber(-baseSize.Z / 3, baseSize.Z / 3)
	local spawnPosition = Vector3.new(randomX, basePosition.Y + math.random(20, 40), randomZ)
	
	local blackholeClone = blackholePart:Clone()
	blackholeClone.Position = spawnPosition
	
	local sound = blackholeSound:Clone()
	sound.Parent = blackholeClone
	sound:Play()
	
	blackholeClone.Parent = workspace

	currentBlackhole = blackholeClone
end

------------------------------------------------------------
-- PULL MECHANICS
------------------------------------------------------------

function BlackholeService:PullObjects(dt)
	if not currentBlackhole or not currentMap then return end

	-- Use the CENTER of the blackhole part, not position (which might be offset)
	local blackholePos = currentBlackhole.Position

	-- Get all parts in current radius
	local partsInRadius = workspace:GetPartBoundsInRadius(blackholePos, currentRadius)

	for _, part in ipairs(partsInRadius) do
		-- Skip the blackhole itself and its descendants
		if part == currentBlackhole or part:IsDescendantOf(currentBlackhole) then continue end

		-- Calculate distance from CENTER of blackhole to CENTER of part
		local partPos = part.Position
		local distance = (partPos - blackholePos).Magnitude
		local direction = (blackholePos - partPos).Unit

		-- Check if it's a player
		local character = part.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if player and StateService:GetState(player, StateDefinitions.PLAYING) then
			-- Handle player pull
			self:PullPlayer(player, character, part, direction, distance, blackholePos)
		elseif part:IsDescendantOf(currentMap.InteractiveParts) then
			-- Handle structure part pull
			self:PullStructurePart(part, direction, distance, blackholePos)
		end
	end
end

function BlackholeService:PullPlayer(player, character, rootPart, direction, distance, blackholePos)
	
	-- Force player to stand if they are sitting
	MovementService:ForceStand(player)
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Instant kill if too close to CENTER
	if distance < KILL_RADIUS then
		humanoid.Health = 0
		-- Remove pull force immediately
		local bodyVel = rootPart:FindFirstChild("BlackholePull")
		if bodyVel then
			bodyVel:Destroy()
		end
		return
	end

	-- Calculate pull strength (stronger when closer)
	local pullStrength = PLAYER_PULL_STRENGTH / math.max(distance, 1)

	-- Apply force to player
	if rootPart:IsA("BasePart") and rootPart.Name == "HumanoidRootPart" then
		-- Use BodyVelocity for smooth pull
		local bodyVel = rootPart:FindFirstChild("BlackholePull")
		if not bodyVel then
			bodyVel = Instance.new("BodyVelocity")
			bodyVel.Name = "BlackholePull"
			bodyVel.MaxForce = Vector3.new(100000, 100000, 100000)
			bodyVel.Parent = rootPart
		end

		-- Update velocity toward blackhole CENTER
		bodyVel.Velocity = direction * (pullStrength / 1000)
	end
end

function BlackholeService:PullStructurePart(part, direction, distance, blackholePos)
	if not part:IsA("BasePart") then return end

	-- Instant destroy parts that get too close to CENTER
	if distance < PART_DESTROY_RADIUS then
		part:Destroy()
		return
	end

	-- Collapse parts within collapse radius
	if distance < currentRadius then
		StructureService:Collapse(part, IMPULSE_COLLISIONS)
	end

	if not part.Anchored then
		-- Calculate pull strength
		local pullStrength = STRUCTURE_PULL_STRENGTH / math.max(distance, 1)

		-- Apply impulse toward CENTER
		local force = direction * pullStrength * part.AssemblyMass * 0.1
		part:ApplyImpulse(force)
	end
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------

-- Remove BodyVelocity from players when blackhole ends
function BlackholeService:CleanupPlayerForces()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bodyVel = rootPart:FindFirstChild("BlackholePull")
				if bodyVel then
					bodyVel:Destroy()
				end
			end
		end
	end
end

return BlackholeService