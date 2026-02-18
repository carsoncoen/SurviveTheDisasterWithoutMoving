------------------------------------------------------------
-- ACID RAIN SERVICE
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)
local RaycastService = require(game.ServerScriptService.Server.Services.Game.RaycastService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local AcidRainService = {}
local acidClouds = workspace.World.AcidClouds
local rainSound = SoundService.SoundEffects.Disasters.Rain
local isActive = false
local currentMap = nil			
local acidRainThreads = {}

-- Cache raycast params once
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

-- CONFIGS --
local DAMAGE_CHANCE = .15 				-- Chance to deal damage to part
local INFECTED_DAMAGE_CHANCE = .35		-- Chance to deal damage to infected part
local IMPULSE_COLLISIONS = true			-- Enable/disable impulse collisions
local UPDATE_INTERVAL = 2				-- Seconds between each acid update
local DAMAGE_INTERVAL = 2.5				-- How long game checks between damaging players
local ACID_DAMAGE = 20 					-- Damage dealt to part
local IMPULSE_COLLISIONS = true			-- Enable/disable impulse collisions


----------------------------------------------------------------------------------------------------
-- ACID RAIN LIFECYCLE
----------------------------------------------------------------------------------------------------

-- Fade in acid clouds
function AcidRainService:Initialize(map)
	if isActive then return end
	isActive = true
	currentMap = map

	-- Tween in clouds and lower brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(acidClouds, tweenInfo, {Transparency = 0.1}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 0.5}):Play()
	
	-- Cancel any previous threads
	for _, thread in acidRainThreads do
		task.cancel(thread)
	end
end


function AcidRainService:Start(duration, map)
	if not isActive then return end
	
	-- Init active rain parts table if it doesn't exist
	if not self.ActiveAcidRainParts then
		self.ActiveAcidRainParts = {}
	end
	
	-- Fade in rain sound
	TweenerService:FadeSoundIn(rainSound)
	
	-- Setup raycast params
	local ignoreList = {}
	-- Send acid rain effect to all players
	for _, player in Players:GetPlayers() do
		if StateService:GetState(player, StateDefinitions.PLAYING) then
			NetworkService:SendPostProcessingEffect(player, {
				Type = "AcidRain",
				Toggle = true
			})
		end
		
		if player.Character then
			-- Add to param filter
			table.insert(ignoreList, player.Character)
		end
		
	end
	
	params.FilterDescendantsInstances = { ignoreList }
	
	-- Get external parts
	local externalParts = RaycastService:GetExternalParts(currentMap, params)
	if not externalParts then return end
	
	local thread1 = task.spawn(function()
		while isActive do
			task.wait(UPDATE_INTERVAL)
			self:HitExternalParts(externalParts)
			self:UpdateAcidRainParts(UPDATE_INTERVAL)
		end
	end)
	
	local thread2 = task.spawn(function()
		while isActive do
			task.wait(DAMAGE_INTERVAL)
			self:DamageOutsidePlayers()
		end
	end)
	
	table.insert(acidRainThreads, thread1)
	table.insert(acidRainThreads, thread2)
end


function AcidRainService:End()
	if not isActive then return end
	isActive = false
	currentMap = nil
	
	-- Fade out rain sound
	TweenerService:FadeSoundOut(rainSound)
	
	-- Tween out clouds and reset brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(acidClouds, tweenInfo, {Transparency = 1}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 3}):Play()

	-- Stop the acid rain effect for all players
	for _, player in Players:GetPlayers() do
		NetworkService:SendPostProcessingEffect(player, {
			Type = "AcidRain",
			Toggle = false
		})
	end
end

-- Reset stored acid rain parts for that round
function AcidRainService:ResetDisaster()
	self:End()
	self.ActiveAcidRainParts = {}
end


----------------------------------------------------------------------------------------------------
-- DAMAGE INTERACTIONS
----------------------------------------------------------------------------------------------------

-- Each round randomly damage parts around the map
function AcidRainService:HitExternalParts(externalParts)
	if not currentMap or not isActive then return end

	-- Randomly damage parts
	for _, part in externalParts do
		if CollectionService:HasTag(part, "Acid") then
			if math.random() < INFECTED_DAMAGE_CHANCE then
				if self.ActiveAcidRainParts[part] then
					self.ActiveAcidRainParts[part].Stage += 1
				end
			end
		else
			if math.random() < DAMAGE_CHANCE then
				CollectionService:AddTag(part, "Acid")
				self.ActiveAcidRainParts[part] = {
					Part = part,
					Stage = 1,
					Unanchored = false,
				}
			end
		end
	end
end

function AcidRainService:UpdateAcidRainParts(dt)
	if not currentMap or not isActive then return end

	for part, data in pairs(self.ActiveAcidRainParts) do
		if not part or not part.Parent then
			self.ActiveAcidRainParts[part] = nil
			continue
		end

		-- Change part color
		if data.Stage == 1 then
			part.Color = Color3.fromRGB(180, 203, 137)
			part.Material = Enum.Material.Salt

			-- Change part color
		elseif data.Stage == 2 then
			part.Color = Color3.fromRGB(179, 203, 91)
			part.Material = Enum.Material.Salt

			-- Unanchor part
		elseif data.Stage == 3 then
			part:Destroy()
			self.ActiveAcidRainParts[part] = nil
			
			--if not data.Unanchored then
			--	part.Color = Color3.fromRGB(127, 144, 18)
			--	part.Material = Enum.Material.Salt

			--	-- Structural logic
			--	StructureService:Collapse(part, IMPULSE_COLLISIONS)
			--	data.Unanchored = true
			--end
		end
	end
end

function AcidRainService:DamageOutsidePlayers()
	if not currentMap or not isActive then return end

	-- Raycast player to ceiling
	for _, player in Players:GetPlayers() do
		if player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			if StateService:GetState(player, StateDefinitions.PLAYING) then
				local char = player.Character
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then continue end

				-- Check if player is outside
				local ceilingHit = workspace:Raycast(root.Position, Vector3.new(0, 100, 0), params)
				if ceilingHit == nil then
					local humanoid = char:FindFirstChild("Humanoid")
					if humanoid then
						humanoid:TakeDamage(ACID_DAMAGE)
					end
				end
			end
		end
	end
end


return AcidRainService
