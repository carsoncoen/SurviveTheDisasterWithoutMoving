----------------------------------------
-- SWINGS SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)

-- ENUMS --
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)

-- VARIABLES --
local TAG = "Swing"
local SwingsService = {}

-- CONFIGS -- 
local SWING_FORCE = 300


--------------------------------------------------------------------------------
-- SWINGS FUNCTIONS
--------------------------------------------------------------------------------

function SwingsService:CreateSeatConnection(seat)
	if not seat or not seat:IsA("VehicleSeat") then return end
	
	-- If throttle input is changed
	seat:GetPropertyChangedSignal("ThrottleFloat"):Connect(function()
		if seat.Occupant then
			local player = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
			if player and not StateService:GetState(player, StateDefinitions.FROZEN) then
				seat.BodyThrust.Force = Vector3.new(0, 0, -SWING_FORCE * seat.ThrottleFloat)
			end
		end
	end)
	
	-- If seat becomes occupied/unoccpied (reset its force)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not seat.Occupant then
			seat.BodyThrust.Force = Vector3.new(0, 0, 0)
		end
	end)
		
end


--------------------------------------------------------------------------------
-- INIT SWINGS
--------------------------------------------------------------------------------

function SwingsService:Init()
	-- Initiate any tagged seats already in the workspace
	for _, seat in CollectionService:GetTagged(TAG) do
		self:CreateSeatConnection(seat)
	end

	-- Initiate any newly placed seat in the workspace
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(seat)
		self:CreateSeatConnection(seat)
	end)
end

SwingsService:Init()
return SwingsService
