----------------------------------------
-- METEOR STRIKE SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local StructureService = require(game.ServerScriptService.Server.Services.Game.StructureService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local meteorStrikeParts = ServerStorage.Disasters.MeteorStrike
local meteorTint = workspace.World.MeteorTint
local meteorPart = meteorStrikeParts.Meteor
local meteorSound = SoundService.SoundEffects.Disasters.Meteor
local meteorsDropped = {}
local isActive = false

-- CONFIGS --
local IMPULSE_COLLISIONS = true		-- Enable/disable impulse collisions
local METEOR_DELAY = 0.75 			-- Delay between meteor parts dropping

local MeteorStrikeService = {}

--------------------------------------------------------------------------------
-- METEOR STRIKE LIFECYCLE
--------------------------------------------------------------------------------

-- Fade in meteor tint
function MeteorStrikeService:Initialize(map)
	isActive = true
	
	-- Tween in clouds and lower brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(meteorTint, tweenInfo, {Transparency = 0.3}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = .5}):Play()
end

function MeteorStrikeService:Start(duration, map)
	
	meteorsDropped = {}
	local meteorCount = math.random(8, 12)
	
	-- Spawn meteors
	task.spawn(function()
		for i = 1, meteorCount do
			if not isActive then break end
			
			self:DropMeteorPart(duration, map)
			task.wait(METEOR_DELAY)
		end
	end)
end

function MeteorStrikeService:End()
	if not isActive then return end
	
	-- End the meteor strike
	isActive = false
	
	-- Tween out tint and reset brightness
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
	TweenService:Create(meteorTint, tweenInfo, {Transparency = 1}):Play()
	TweenService:Create(Lighting, tweenInfo, {Brightness = 3}):Play()

	-- Ensure all meteor parts are gone
	for _, meteorPart in ipairs(meteorsDropped) do
		if meteorPart then
			meteorPart:Destroy()
		end
	end
end

function MeteorStrikeService:ResetDisaster()
	self:End()
end


--------------------------------------------------------------------------------
-- METEOR BEHAVIORS
--------------------------------------------------------------------------------

function MeteorStrikeService:DropMeteorPart(duration, map)

	-- Get the primary part of the map
	local mapBase = map:FindFirstChild("Base")
	local primaryPart = mapBase.PrimaryPart
	if not primaryPart then
		warn("No primary part found for map")
		return
	end
	
	local rng = Random.new()
	
	-- Get a random position on the map and set spawn position
	local basePart = mapBase.PrimaryPart
	local basePosition = basePart.Position
	local baseSize = basePart.Size

	local spawnPosition = Vector3.new(
		basePosition.X + rng:NextNumber(-baseSize.X / 2, baseSize.X / 2),
		350,
		basePosition.Z + rng:NextNumber(-baseSize.Z / 2, baseSize.Z / 2)
	)

	-- Clone the meteor part
	local meteorClone = meteorPart:Clone()
	table.insert(meteorsDropped, meteorClone)

	-- Scale the meteor part random amount
	local randomScale = rng:NextNumber(0.5, 1.5)
	meteorClone.Size = meteorClone.Size * randomScale

	meteorClone.Parent = workspace

	-- Play meteor sound
	local soundClone = meteorSound:Clone()
	soundClone.Parent = meteorClone
	soundClone:Play()

	-- Detect collisions with the meteor part
	self:DetectCollisions(meteorClone, map)

	-- Drop the meteor part from above the map
	local meteorCFrame = CFrame.new(spawnPosition)
	meteorClone.CFrame = meteorCFrame
	meteorClone.AssemblyLinearVelocity = Vector3.new(0, -150, 0) -- fall down
	meteorClone.Parent = workspace
end


--------------------------------------------------------------------------------
-- DAMAGE INTERACTIONS
--------------------------------------------------------------------------------

function MeteorStrikeService:DetectCollisions(part, map)
	-- Detect collisions with the meteor part
	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if character then
			-- Check if meteor touched player
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0
				end

				-- Check if meteor touched interactable map parts
			else
				if hit:IsDescendantOf(map.InteractiveParts) then
					-- Structural logic
					StructureService:Collapse(hit, IMPULSE_COLLISIONS)
				end
			end
		end
	end)
end

return MeteorStrikeService
