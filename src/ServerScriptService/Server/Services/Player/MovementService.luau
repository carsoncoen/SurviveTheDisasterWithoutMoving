----------------------------------------
-- MOVEMENT SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- CONFIGS --
local MIN_VELOCITY = 65			-- Minimum velocity to start falling movement
local MAX_VELOCITY = 400		-- Maximum falling velocity


local MovementService = {}



-- Freeze all players if they are in game
function MovementService:FreezePlayers()
	for _, player in ipairs(Players:GetPlayers()) do
			
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChild("Humanoid")
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if humanoid and StateService:GetState(player, StateDefinitions.PLAYING) then 
				--self:CreateFreezeEffects(rootPart, char)
				StateService:ChangeState(player, StateDefinitions.FROZEN, true)
				humanoid.WalkSpeed = 0
				humanoid.JumpHeight = 0
			end
		end
	end
end

-- Unfreeze players
function MovementService:UnfreezePlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then 
				--local ice = char:FindFirstChild("IceCube")
				--if ice then
				--	TweenService:Create(ice, TweenInfo.new(ICE_FADE_TIME), {Transparency = 1}):Play()
				--	task.delay(ICE_FADE_TIME, function()
				--		ice:Destroy()
				--	end)
				--end
				
				StateService:ChangeState(player, StateDefinitions.FROZEN, false)
				humanoid.WalkSpeed = 16
				humanoid.JumpHeight = 7.2
			end
		end
	end
end

-- Force player to stand up if they are sitting
function MovementService:ForceStand(player)
	if not player then return end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		if humanoid.Sit then
			humanoid.Sit = false
		end
	end
end

-- Detect if a player is falling
function MovementService:DetectFalling(player)
	if not player then return end

	local character = player.Character
	if not character then return end

	local rate=1/22

	local damage=0
	local lastvelocity=0

	while true do
		local delta=task.wait(rate)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root~=nil then
			local currentvelocity=(root.Velocity).magnitude
			local pain=currentvelocity*(rate/delta)-MIN_VELOCITY
			if pain>0 then
				damage=damage+(pain/(MAX_VELOCITY-MIN_VELOCITY)*100)
			elseif damage>0 then
				local h=character:FindFirstChild("Humanoid")
				if h and StateService:GetState(player, StateDefinitions.PLAYING) then
					h:TakeDamage(damage)
					damage=0
				end	
			end
			lastvelocity=currentvelocity
		end
	end
end



function MovementService:Init()
	game:GetService('Players').PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:DetectFalling(player)
		end)
	end)
end


MovementService:Init()
return MovementService
