------------------------------------------------------------
-- TORNADO SERVICE
-- @carsondev7
------------------------------------------------------------
-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
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
local TornadoService = {}
local isActive = false
local currentMap = nil
local currentTornado = nil
local tornadoModel = ServerStorage.Disasters.Tornado.Tornado
local tornadoSound = SoundService.SoundEffects.Disasters.Tornado
local rainClouds = workspace.World.RainClouds
local moveConnection = nil
local damageConnection = nil

-- CONFIG --
local TRAVEL_SPEED = 10							-- Studs per second
local PULL_BOX_SIZE = Vector3.new(30, 120, 30)	-- Size of the pull box (X, Y, Z)
local STRUCTURE_PULL_STRENGTH = 5000			-- Structure pull strength
local PLAYER_PULL_STRENGTH = 200000				-- Player pull strength
local KILL_RADIUS = 5							-- Instant kill radius (horizontal only)
local DAMAGE_CHANCE = 0.6 						-- Chance to damage structures
local IMPULSE_COLLISIONS = true			
local TORNADO_DAMAGE = 15				
local PATH_CHANGE_INTERVAL = 3					-- Change direction every X seconds
local EJECT_HEIGHT_THRESHOLD = 55				-- Height above tornado base to eject parts
local EJECT_FORCE = 10							-- Strength of ejection


------------------------------------------------------------
-- TORNADO LIFECYCLE
------------------------------------------------------------

function TornadoService:Initialize(map)
	if isActive or not map then return end
	isActive = true
	currentMap = map
	
	-- CLEANUP PREV CONNECTIONS IF THEY STILL EXIST
	-- Stop movement
	if moveConnection then
		moveConnection:Disconnect()
		moveConnection = nil
	end

	-- Stop damage
	if damageConnection then
		damageConnection:Disconnect()
		damageConnection = nil
	end

	-- Cleanup tornado
	if currentTornado then
		currentTornado:Destroy()
		currentTornado = nil
	end

	-- Tween in clouds and lower brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(rainClouds, tweenInfo, {Transparency = 0}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 0.4}):Play()
end

function TornadoService:Start(duration, map)
	if not isActive or not map then return end

	-- Get map bounds
	local mapCFrame, mapSize = map.Base:GetBoundingBox()
	local primaryPos = map.Base.PrimaryPart.Position
	local mapCenter = mapCFrame.Position
	local primaryY = primaryPos.Y

	-- Spawn tornado at random edge
	local spawnPos = self:GetRandomEdgePosition(mapCenter, mapSize, primaryY)
	currentTornado = tornadoModel:Clone()
	currentTornado:PivotTo(CFrame.new(spawnPos))
	
	-- Play tornado sound
	local tornadoSoundClone = tornadoSound:Clone()
	tornadoSoundClone.Parent = currentTornado.PrimaryPart
	tornadoSoundClone:Play()
	
	currentTornado.Parent = workspace
	

	-- Start movement
	moveConnection = RunService.Heartbeat:Connect(function(dt)
		if isActive and currentTornado then
			self:MoveTornado(dt, mapCenter, mapSize, primaryY)
		end
	end)

	-- Start damage detection
	damageConnection = RunService.Heartbeat:Connect(function()
		if isActive and currentTornado then
			self:DetectCollisions()
		end
	end)
end

function TornadoService:End()
	if not isActive then return end

	isActive = false
	currentMap = nil

	-- Clean up all player forces before ending
	self:CleanupAllPlayers()

	-- Stop movement
	if moveConnection then
		moveConnection:Disconnect()
		moveConnection = nil
	end

	-- Stop damage
	if damageConnection then
		damageConnection:Disconnect()
		damageConnection = nil
	end

	-- Cleanup tornado
	if currentTornado then
		currentTornado:Destroy()
		currentTornado = nil
	end

	-- Reset weather
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(rainClouds, tweenInfo, {Transparency = 1}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 2}):Play()
end

function TornadoService:ResetDisaster()
	self:End()
end

------------------------------------------------------------
-- MOVEMENT
------------------------------------------------------------

-- Get random position at edge of map
function TornadoService:GetRandomEdgePosition(mapCenter, mapSize, baseY)
	local rng = Random.new()
	local side = rng:NextInteger(1, 4)
	local x, z

	if side == 1 then -- Top edge
		x = mapCenter.X + rng:NextNumber(-mapSize.X/2, mapSize.X/2)
		z = mapCenter.Z + mapSize.Z/2
	elseif side == 2 then -- Bottom edge
		x = mapCenter.X + rng:NextNumber(-mapSize.X/2, mapSize.X/2)
		z = mapCenter.Z - mapSize.Z/2
	elseif side == 3 then -- Left edge
		x = mapCenter.X - mapSize.X/2
		z = mapCenter.Z + rng:NextNumber(-mapSize.Z/2, mapSize.Z/2)
	else -- Right edge
		x = mapCenter.X + mapSize.X/2
		z = mapCenter.Z + rng:NextNumber(-mapSize.Z/2, mapSize.Z/2)
	end

	return Vector3.new(x, baseY, z)
end

-- Move tornado along path
function TornadoService:MoveTornado(dt, mapCenter, mapSize, baseY)
	if not currentTornado then return end

	-- Get current position
	local currentPos = currentTornado:GetPivot().Position

	-- Generate target if needed
	if not self.targetPos or not self.lastPathChange then
		self.lastPathChange = tick()
		self.targetPos = self:GetRandomTargetPosition(mapCenter, mapSize, baseY)
	end

	-- Change target periodically for wandering effect
	if tick() - self.lastPathChange > PATH_CHANGE_INTERVAL then
		self.lastPathChange = tick()
		self.targetPos = self:GetRandomTargetPosition(mapCenter, mapSize, baseY)
	end

	-- Move toward target
	local direction = (self.targetPos - currentPos).Unit
	local movement = direction * TRAVEL_SPEED * dt

	-- Keep at BASE_HEIGHT above map base (not terrain/buildings)
	local newPos = currentPos + movement
	newPos = Vector3.new(newPos.X, baseY, newPos.Z)

	-- Update position
	currentTornado:PivotTo(CFrame.new(newPos))

	-- Check if reached target
	local distanceToTarget = (self.targetPos - newPos).Magnitude
	if distanceToTarget < 10 then
		self.targetPos = self:GetRandomTargetPosition(mapCenter, mapSize, baseY)
		self.lastPathChange = tick()
	end
end

-- Get random position within map bounds
function TornadoService:GetRandomTargetPosition(mapCenter, mapSize, baseY)
	local rng = Random.new()

	local x = mapCenter.X + rng:NextNumber(-mapSize.X/2 * 0.8, mapSize.X/2 * 0.8)
	local z = mapCenter.Z + rng:NextNumber(-mapSize.Z/2 * 0.8, mapSize.Z/2 * 0.8)

	return Vector3.new(x, baseY, z)
end

------------------------------------------------------------
-- DAMAGE INTERACTIONS
------------------------------------------------------------

function TornadoService:DetectCollisions()
	if not currentTornado or not currentMap then return end

	local tornadoPos = currentTornado:GetPivot().Position

	-- Create bounding box centered on tornado
	-- Box extends from ground up to capture tall buildings
	local boxCFrame = CFrame.new(tornadoPos)
	local boxSize = PULL_BOX_SIZE

	-- Get all parts in bounding box
	local partsInBox = workspace:GetPartBoundsInBox(boxCFrame, boxSize)

	-- Track which players are in range this frame
	local playersInRange = {}

	for _, part in ipairs(partsInBox) do
		-- Skip tornado itself
		if part:IsDescendantOf(currentTornado) then continue end

		-- Calculate distance (horizontal distance for kill radius, 3D for pull strength)
		local horizontalDistance = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(tornadoPos.X, 0, tornadoPos.Z)).Magnitude
		local fullDistance = (part.Position - tornadoPos).Magnitude

		-- Check if player
		local character = part.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if player and StateService:GetState(player, StateDefinitions.PLAYING) then
			playersInRange[player] = true
			self:PullPlayer(player, character, part, tornadoPos, horizontalDistance, fullDistance)
		elseif part:IsDescendantOf(currentMap.InteractiveParts) then
			self:PullStructure(part, tornadoPos, horizontalDistance, fullDistance)
		end
	end

	-- Clean up players who escaped the tornado
	self:CleanupEscapedPlayers(playersInRange)
end

function TornadoService:PullPlayer(player, character, rootPart, tornadoPos, horizontalDistance, fullDistance)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Force player to stand if they are sitting
	MovementService:ForceStand(player)

	-- Kill if too close (based on horizontal distance only)
	if horizontalDistance < KILL_RADIUS then
		humanoid.Health -= TORNADO_DAMAGE
		self:RemoveTornadoForces(rootPart)
		return
	end

	-- Pull toward tornado (spiral upward)
	if rootPart:IsA("BasePart") and rootPart.Name == "HumanoidRootPart" then
		-- Calculate pull strength (stronger when closer)
		-- Use full 3D distance for pull strength so higher parts still get pulled
		local pullStrength = PLAYER_PULL_STRENGTH / math.max(fullDistance, 1)

		-- Direction toward tornado center, with strong upward component
		local horizontalDir = (tornadoPos - rootPart.Position) * Vector3.new(1, 0, 1)

		-- Upward force increases the higher you are (simulate updraft)
		local heightFactor = math.clamp((rootPart.Position.Y - tornadoPos.Y) / 50, 0, 1)
		local upwardStrength = 0.3 + (heightFactor * 0.4) -- 0.3 to 0.7

		local direction = (horizontalDir.Unit + Vector3.new(0, upwardStrength, 0)).Unit

		-- Apply velocity
		local bodyVel = rootPart:FindFirstChild("TornadoPull")
		if not bodyVel then
			bodyVel = Instance.new("BodyVelocity")
			bodyVel.Name = "TornadoPull"
			bodyVel.MaxForce = Vector3.new(100000, 100000, 100000)
			bodyVel.Parent = rootPart
		end

		bodyVel.Velocity = direction * (pullStrength / 1000)

		-- Spin player
		local bodyGyro = rootPart:FindFirstChild("TornadoSpin")
		if not bodyGyro then
			bodyGyro = Instance.new("BodyAngularVelocity")
			bodyGyro.Name = "TornadoSpin"
			bodyGyro.MaxTorque = Vector3.new(0, 100000, 0)
			bodyGyro.AngularVelocity = Vector3.new(0, 10, 0)
			bodyGyro.Parent = rootPart
		end
	end
end

function TornadoService:PullStructure(part, tornadoPos, horizontalDistance, fullDistance)
	if not part:IsA("BasePart") then return end

	local damageRadius = PULL_BOX_SIZE.X / 2 * 0.5
	if horizontalDistance < damageRadius and math.random() < DAMAGE_CHANCE then
		StructureService:Collapse(part, IMPULSE_COLLISIONS)
	end

	if not part.Anchored then
		local heightAboveTornado = part.Position.Y - tornadoPos.Y

		if heightAboveTornado > EJECT_HEIGHT_THRESHOLD then
			-- Random ejection
			local angle = math.random() * math.pi * 2
			local ejectDir = Vector3.new(
				math.cos(angle),
				math.random(0.3, 0.7),  -- Random upward angle
				math.sin(angle)
			).Unit

			local ejectForce = ejectDir * EJECT_FORCE * part.AssemblyMass
			part:ApplyImpulse(ejectForce)

			part.AssemblyAngularVelocity = Vector3.new(
				math.random(-25, 25),
				math.random(-25, 25),
				math.random(-25, 25)
			)
		else
			-- Normal pull
			local pullStrength = STRUCTURE_PULL_STRENGTH / math.max(fullDistance, 1)
			local horizontalDir = (tornadoPos - part.Position) * Vector3.new(1, 0, 1)
			local heightFactor = math.clamp(heightAboveTornado / 50, 0, 1)
			local upwardStrength = 0.5 + (heightFactor * 0.3)
			local direction = (horizontalDir.Unit + Vector3.new(0, upwardStrength, 0)).Unit

			local force = direction * pullStrength * part.AssemblyMass * 0.1
			part:ApplyImpulse(force)

			part.AssemblyAngularVelocity = Vector3.new(
				math.random(-10, 10),
				math.random(-10, 10),
				math.random(-10, 10)
			)
		end
	end
end


-- Clean up players who escaped the pull radius
function TornadoService:CleanupEscapedPlayers(playersInRange)
	for _, player in ipairs(Players:GetPlayers()) do
		-- If player was not in range this frame, clean up their forces
		if not playersInRange[player] and player.Character then
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				self:RemoveTornadoForces(rootPart)
			end
		end
	end
end

-- Remove tornado forces from a part
function TornadoService:RemoveTornadoForces(rootPart)
	local bodyVel = rootPart:FindFirstChild("TornadoPull")
	if bodyVel then
		bodyVel:Destroy()
	end

	local bodyGyro = rootPart:FindFirstChild("TornadoSpin")
	if bodyGyro then
		bodyGyro:Destroy()
	end
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------

-- Clean up all players when tornado ends
function TornadoService:CleanupAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				self:RemoveTornadoForces(rootPart)
			end
		end
	end
end

return TornadoService