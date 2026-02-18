----------------------------------------
-- PLAGUE SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local AnimationService = require(ReplicatedStorage.Shared.Modules.Services.Animations.AnimationService)
local AnimationDefinitions = require(ReplicatedStorage.Shared.Modules.Services.Animations.AnimationDefinitions)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local RaycastService = require(game.ServerScriptService.Server.Services.Game.RaycastService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- CONFIGS --
local INFECTION_DELAY = 2
local INFECTION_DAMAGE = 25
local INFECTION_DAMAGE_DELAY = 3
local INFECTION_DISTANCE = 8
local plagueInProgress = false

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local PlagueService = {}


--------------------------------------------------------------------------------
-- PLAGUE LIFECYCLE
--------------------------------------------------------------------------------

function PlagueService:Start(duration, map)
	if plagueInProgress then
		return
	end
		
	plagueInProgress = true
	
	-- Start the plague
	local playersInGame = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if StateService:GetState(player, StateDefinitions.PLAYING) then
			table.insert(playersInGame, player)
		end
	end
	
	if #playersInGame == 0 then
		plagueInProgress = false
		return
	end
	
	local randomPlayer = playersInGame[math.random(1, #playersInGame)]
	if randomPlayer then
		task.spawn(function()
			self:InfectPlayers(randomPlayer, playersInGame)
		end)
	end
end

function PlagueService:End()
	if not plagueInProgress then return end
	
	-- End the plague
	plagueInProgress = false
end

function PlagueService:ResetDisaster()
	self:End()
end


--------------------------------------------------------------------------------
-- PLAGUE BEHAVIORS
--------------------------------------------------------------------------------

function PlagueService:InfectPlayers(startingPlayer, playersInGame)
	local infected = {startingPlayer}
	StateService:ChangeState(startingPlayer, StateDefinitions.INFECTED, true)

	task.spawn(function()
		self:DamageInfected(playersInGame)
	end)

	-- Infect players
	while plagueInProgress do
		local newlyInfected = {}

		for _, player in infected do
			for _, otherPlayer in ipairs(playersInGame) do
				if otherPlayer ~= player and not StateService:GetState(otherPlayer, StateDefinitions.INFECTED) then
					if player.Character and otherPlayer.Character and player.Character:FindFirstChild("Humanoid") and otherPlayer.Character:FindFirstChild("Humanoid") then
						local distance = (player.Character.HumanoidRootPart.Position - otherPlayer.Character.HumanoidRootPart.Position).Magnitude
						if distance < INFECTION_DISTANCE and RaycastService:HasLineOfSight(player.Character, otherPlayer.Character) then
							print(otherPlayer.Name .. " has been infected!")
							StateService:ChangeState(otherPlayer, StateDefinitions.INFECTED, true)
							table.insert(newlyInfected, otherPlayer)
						end
					end
				end
			end
		end

		for _, player in ipairs(newlyInfected) do
			table.insert(infected, player)
		end

		task.wait(INFECTION_DELAY)
	end
end


--------------------------------------------------------------------------------
-- PLAYER INTERACTIONS
--------------------------------------------------------------------------------

function PlagueService:DamageInfected(playersInGame)
	while plagueInProgress do
		for _, player in playersInGame do
			if player.Character and player.Character:FindFirstChild("Humanoid") and StateService:GetState(player, StateDefinitions.INFECTED) then
				AnimationService:PlayAnimation(player, AnimationDefinitions.Cough)
				player.Character.Humanoid:TakeDamage(INFECTION_DAMAGE)

				-- Play sound
				local sounds = SoundType.Cough
				local sound = sounds[math.random(1, #sounds)]:Clone()
				sound.Parent = player.Character
				sound:Play()
				task.delay(sound.TimeLength, function()
					sound:Destroy()
				end)
			end
		end

		task.wait(INFECTION_DAMAGE_DELAY)
	end
end


return PlagueService
