 ------------------------------------------------------------
-- FIRE SERVICE MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)

local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local fireActive = false
local currentMap = nil

local fireInstance = ServerStorage.Disasters.Fire.Fire	
local fireSoundPart = ServerStorage.Disasters.Fire.FireSoundPart
local fireSound = SoundService.SoundEffects.Disasters.Fire

-- CONFIGS --
local UPDATE_INTERVAL = 1.5				
local DAMAGE_INTERVAL = 1.5				
local FIRE_DAMAGE = 10					
local SPREAD_RADIUS = 4					
local SOUND_UPDATE_INTERVAL = 0.5		
local IMPULSE_COLLISIONS = false	

-- Fire clustering settings
local FIRE_CLUSTER_SIZE = 25			
local FIRE_UPDATE_INTERVAL = 1			
local CLUSTER_RADIUS = 20				


local FireService = {}

------------------------------------------------------------
-- FIRE LIFECYCLE
------------------------------------------------------------

function FireService:Start(duration, map)
	fireActive = true
	currentMap = map
	self.ActiveFires = {}
	self.FireClusters = {}
	self.FirePartsFolder = Instance.new("Folder")
	self.FirePartsFolder.Name = "FireEffects"
	self.FirePartsFolder.Parent = map

	local parts = {}
	for _, part in ipairs(map.InteractiveParts:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	-- Cleanup existing fire sound
	local existingSoundPart = map:FindFirstChild("FireSoundPart")
	if existingSoundPart then
		existingSoundPart:Destroy()
	end

	-- Clone fire sound
	local fireSoundPartClone = fireSoundPart:Clone()
	fireSoundPartClone.Parent = map

	local fireSoundClone = fireSound:Clone()
	fireSoundClone.Parent = fireSoundPartClone
	fireSoundClone:Play()

	-- Select random part
	local randomPart = parts[math.random(1, #parts)]

	-- Start fire
	self:Ignite(randomPart)

	-- Core fire loop
	task.spawn(function()
		while fireActive do
			task.wait(UPDATE_INTERVAL)
			FireService:Update(UPDATE_INTERVAL)
		end
	end)

	-- Player damage loop
	task.spawn(function()
		while fireActive do
			task.wait(DAMAGE_INTERVAL)
			self:DamagePlayers()
		end
	end)

	-- Update fire sound and visual effects
	task.spawn(function()
		while fireActive do
			self:UpdateFireSound(fireSoundClone, fireSoundPartClone)

			self:UpdateFireClusters()

			task.wait(FIRE_UPDATE_INTERVAL)
		end
	end)
end

function FireService:End()
	if not fireActive or not currentMap then return end

	self:ExtinguishAll()

	if currentMap:FindFirstChild("FireSoundPart") then
		currentMap.FireSoundPart:Destroy()
	end

	if self.FirePartsFolder then
		self.FirePartsFolder:Destroy()
	end

	self.FireClusters = {}
	fireActive = false
	currentMap = nil
end

function FireService:ResetDisaster()
	self:End()

	self.ActiveFires = {}
end


------------------------------------------------------------
-- FIRE BEHAVIORS
------------------------------------------------------------

function FireService:Ignite(part)
	if not currentMap or not fireActive then return end
	if not part or not part:IsA("BasePart") or CollectionService:HasTag(part, "Burning") then return end

	CollectionService:AddTag(part, "Burning")

	part.Color = Color3.fromRGB(47, 47, 47)
	part.Material = Enum.Material.Basalt

	self.ActiveFires[part] = {
		Part = part,
		UnanchorCooldown = math.random(1, 3),
		Unanchored = false,
		TimeLeft = math.random(8, 12),
		SpreadCooldown = 0
	}
end

-- In FireService, replace the Update function:

function FireService:Update(dt)
	if not currentMap or not fireActive then return end

	local partsToCollapse = {}  -- Batch collapse operations

	for part, data in pairs(self.ActiveFires) do
		if not part or not part.Parent then
			self.ActiveFires[part] = nil
			continue
		end

		-- Burn timer
		data.TimeLeft -= dt
		if data.TimeLeft <= 0 then
			self:Extinguish(part)
			continue
		end

		-- Unanchor
		data.UnanchorCooldown -= dt
		if not data.Unanchored and data.UnanchorCooldown <= 0 then
			table.insert(partsToCollapse, part)
			data.Unanchored = true
		end

		-- Spread
		data.SpreadCooldown -= dt
		if data.SpreadCooldown <= 0 then
			self:TrySpread(part)
			data.SpreadCooldown = math.random(1, 3)
		end
	end

	-- Collapse all parts at once
	if #partsToCollapse > 0 then
		for _, part in ipairs(partsToCollapse) do
			StructureService:Collapse(part, IMPULSE_COLLISIONS)
		end
		--StructureService:BatchCollapse(partsToCollapse, IMPULSE_COLLISIONS)
	end
end

function FireService:TrySpread(part)
	if not currentMap or not fireActive then return end
	if not part or not part.Parent then return end


	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { part }

	local boxSize = part.Size + Vector3.new(SPREAD_RADIUS, SPREAD_RADIUS, SPREAD_RADIUS)
	local nearby = workspace:GetPartBoundsInBox(part.CFrame, boxSize, params)

	local spreadChance = (3 / math.max(1, #nearby))
	local maxSpreadParts = math.floor(#nearby / 1.5)

	local partsSpread = 0
	for _, hit in ipairs(nearby) do
		if currentMap and not hit:IsDescendantOf(currentMap.InteractiveParts) then continue end
		if math.random() < spreadChance then
			partsSpread += 1
			self:Ignite(hit)
			if partsSpread >= maxSpreadParts then break end
		end
	end
end

function FireService:UpdateFireClusters()
	if not currentMap or not fireActive then return end

	-- Collect all active fire positions
	local firePositions = {}
	for part in pairs(self.ActiveFires) do
		if part and part.Parent then
			table.insert(firePositions, part.Position)
		end
	end

	if #firePositions == 0 then
		for _, cluster in ipairs(self.FireClusters) do
			if cluster.Part then
				cluster.Part.Transparency = 1
				local fire = cluster.Part:FindFirstChildOfClass("Fire")
				if fire then fire.Enabled = false end
			end
		end
		return
	end

	-- Group fires into clusters
	local clusterGroups = self:ClusterPositions(firePositions, FIRE_CLUSTER_SIZE)

	-- Reuse existing clusters or create new ones
	for i, clusterPositions in ipairs(clusterGroups) do
		-- Calculate center of cluster
		local sum = Vector3.zero
		for _, pos in ipairs(clusterPositions) do
			sum += pos
		end
		local center = sum / #clusterPositions

		-- Get or create cluster
		local cluster = self.FireClusters[i]
		if not cluster or not cluster.Part or not cluster.Part.Parent then
			-- Create new cluster
			local firePart = Instance.new("Part")
			firePart.Name = "FireCluster"
			firePart.Size = Vector3.new(4, 4, 4)
			firePart.Position = center
			firePart.Anchored = true
			firePart.CanCollide = false
			firePart.Transparency = 1
			firePart.Parent = self.FirePartsFolder

			local fire = fireInstance:Clone()
			fire.Parent = firePart

			cluster = {
				Part = firePart,
				Fire = fire
			}
			self.FireClusters[i] = cluster
		end

		-- Update existing cluster
		cluster.Part.Position = center
		cluster.Part.Transparency = 1

		-- Update fire properties
		local fireSize = math.clamp(#clusterPositions * 1.5, 5, 25)
		local fireHeat = math.clamp(#clusterPositions * 0.8, 5, 25)

		cluster.Fire.Size = fireSize
		cluster.Fire.Heat = fireHeat
		cluster.Fire.Enabled = true
	end

	-- Hide unused clusters
	for i = #clusterGroups + 1, #self.FireClusters do
		local cluster = self.FireClusters[i]
		if cluster and cluster.Part then
			cluster.Part.Transparency = 1
			if cluster.Fire then
				cluster.Fire.Enabled = false
			end
		end
	end
end

function FireService:ClusterPositions(positions, maxPerCluster)
	if #positions == 0 then return {} end

	local clusters = {}
	local used = {}

	for i, pos in ipairs(positions) do
		if used[i] then continue end

		local cluster = {pos}
		used[i] = true

		-- Find nearby positions
		for j, otherPos in ipairs(positions) do
			if not used[j] and #cluster < maxPerCluster then
				local distance = (pos - otherPos).Magnitude
				if distance < CLUSTER_RADIUS then
					table.insert(cluster, otherPos)
					used[j] = true
				end
			end
		end

		table.insert(clusters, cluster)
	end

	return clusters
end

function FireService:Extinguish(part)
	CollectionService:RemoveTag(part, "Burning")
	part.Color = Color3.fromRGB(97, 96, 98)
	part.Material = Enum.Material.Slate
	self.ActiveFires[part] = nil
end

function FireService:UpdateFireSound(sound, parentPart)
	if not currentMap or not fireActive then return end
	if not sound or not parentPart then return end

	local count = 0
	local sum = Vector3.zero

	for part in pairs(self.ActiveFires) do
		if part and part.Parent then
			sum += part.Position
			count += 1
		end
	end

	if count == 0 then
		sound.Volume = 0
		return
	end

	local avgPos = sum / count
	parentPart.Position = avgPos
	sound.Volume = math.clamp(count / 15, 0.1, 0.5)
end

function FireService:ExtinguishAll()
	for part in pairs(self.ActiveFires) do
		self:Extinguish(part)
	end
	self.ActiveFires = {}

	for _, cluster in ipairs(self.FireClusters) do
		if cluster.Part then
			cluster.Part.Transparency = 1
			if cluster.Fire then
				cluster.Fire.Enabled = false
			end
		end
	end
end

-- Get fire count (for debugging)
function FireService:GetFireCount()
	local count = 0
	for _ in pairs(self.ActiveFires) do
		count += 1
	end
	return count
end


------------------------------------------------------------
-- PLAYER INTERACTIONS
------------------------------------------------------------

function FireService:DamagePlayers()
	if not currentMap or not fireActive then return end

	for part in pairs(self.ActiveFires) do
		local parts = workspace:GetPartsInPart(part)
		for _, hit in ipairs(parts) do
			if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
				local humanoid = hit.Parent:FindFirstChild("Humanoid")
				if humanoid then
					humanoid:TakeDamage(FIRE_DAMAGE)
				end
			end
		end
	end
end

return FireService