------------------------------------------------------------
-- ITEM DEFINITIONS MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

-- SERVICES --

-- MODULES --
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local ModifierService = require(game.ServerScriptService.Server.Services.Player.ModifierService)

local ItemDefinitions = {
	
	----------------------------------------------------------------------------------------------------
	-- CONSUMABLES
	----------------------------------------------------------------------------------------------------

	-- CONSUMABLES (Temporary modifiers)
	BloxyCola = {
		Id = "BloxyCola",
		Name = "Bloxy Cola",
		Description = "2x speed for 10 seconds",
		Category = "Consumable",
		TokenPrice = 0,
		RobuxPrice = 10,
		Icon = "rbxassetid://80503995013152",
		DeveloperProductId = "",
		MaxStack = 3,

		OnUse = function(player)
			if not StateService:GetState(player, StateDefinitions.PLAYING) then
				return false, "Not in game"
			end

			-- Check if this specific item is already active
			if ModifierService:HasModifier(player, "Speed", "BloxyCola") then
				return false, "Bloxy Cola already active"
			end

			-- Add temporary +16 speed for 10 seconds
			ModifierService:AddModifier(player, "Speed", "BloxyCola", 16, 10)

			return true, "Speed boost activated!"
		end
	},


	----------------------------------------------------------------------------------------------------
	-- GEAR ITEMS (Permanent)
	----------------------------------------------------------------------------------------------------

	GravityCoil = {
		Id = "GravityCoil",
		Name = "Gravity Coil",
		Description = "Grants a major jump boost when held!",
		Category = "Gear",
		TokenPrice = 1000,
		RobuxPrice = 200,
		Icon = "rbxassetid://82164661631248",
		DeveloperProductId = "3538967382",
		
		OnEquip = function(player)
			-- Add permanent 2x jump (7.2 * 2 = 14.4) when held
			ModifierService:AddModifier(player, "Jump", "GravityCoil", 7.2, nil)
		end,
		
		OnUnequip = function(player)
			-- Remove the permanent jump boost when not held
			ModifierService:RemoveModifier(player, "Jump", "GravityCoil")
		end,
		
	},

	TeddyBear = {
		Id = "TeddyBear",
		Name = "Teddy Bear",
		Description = "He will love you forever",
		Category = "Gear",
		TokenPrice = 0,
		RobuxPrice = 0,
		Icon = "rbxassetid://100232523759017",
		DeveloperProductId = "",
		Model = nil,
		
		OnUse = function(player)
			print("Used Teddy Bear")
		end
	},
	
	
	----------------------------------------------------------------------------------------------------
	-- COSMETICS (one per CosmeticType equipped: e.g. Victory, Death)
	----------------------------------------------------------------------------------------------------

	--FireworksVictory = {
	--	Id = "FireworksVictory",
	--	Name = "Fireworks Victory",
	--	Description = "Fireworks when you win",
	--	Category = "Cosmetic",
	--	CosmeticType = "VictoryEffect",  -- Only one Victory effect can be equipped
	--	TokenPrice = 1000,
	--	Icon = "rbxassetid://123460",
	--},

	--ExplosionDeath = {
	--	Id = "ExplosionDeath",
	--	Name = "Explosion Death",
	--	Description = "Explode when you die",
	--	Category = "Cosmetic",
	--	CosmeticType = "DeathEffect",  -- Only one Death effect can be equipped
	--	TokenPrice = 800,
	--	Icon = "rbxassetid://123461",
	--},
}

return ItemDefinitions