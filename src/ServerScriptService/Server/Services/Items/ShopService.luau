------------------------------------------------------------
-- SHOP SERVICE MODULE SCRIPT
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
local DataService = require(game.ServerScriptService.Server.Services.Player.DataService)
local ItemDefinitions = require(script.Parent.ItemDefinitions)

-- VARIABLES --
local ShopService = {}

local remoteFunctions = ReplicatedStorage.RemoteFunctions
local getShopData = remoteFunctions.Items.GetShopData
local purchaseItem = remoteFunctions.Items.PurchaseItem

--------------------------------------------------------------------------------
-- CLIENT REQUESTS
--------------------------------------------------------------------------------

getShopData.OnServerInvoke = function(player)
	-- Verify player is sending valid request
	if not player then return end
	
	return ShopService:GetShopData(player)
end

purchaseItem.OnServerInvoke = function(player, itemId, purchaseMethod)
	if not player then return false, "Invalid player" end
	if type(itemId) ~= "string" or ItemDefinitions[itemId] == nil then
		return false, "Invalid item"
	end
	if type(purchaseMethod) ~= "string" then return false, "Invalid purchase method" end

	if purchaseMethod == "Tokens" then
		return ShopService:PurchaseItemWithTokens(player, itemId)
	end

	return false, "Invalid purchase method"
end

------------------------------------------------------------
-- ITEM PROCESSING
------------------------------------------------------------

-- Purchase an item
function ShopService:PurchaseItemWithTokens(player, itemId)
	local item = ItemDefinitions[itemId]
	if not item then
		warn("Item not found:", itemId)
		return false, "Item not found"
	end

	-- Get player data
	local profile = DataService:GetProfile(player)
	if not profile then
		return false, "Data not loaded"
	end

	-- Check if can afford
	if profile.Data.Tokens < item.TokenPrice then
		return false, "Not enough tokens"
	end

	-- Handle different item types
	if item.Category == "Consumable" then
		-- Check if already at max stack
		local currentAmount = profile.Data.Inventory.Consumables[itemId] or 0
		if currentAmount >= item.MaxStack then
			return false, "Already at max stack"
		end

		-- Add to inventory
		profile.Data.Inventory.Consumables[itemId] = currentAmount + 1

	elseif item.Category == "Gear" then
		-- Check if already owned
		if table.find(profile.Data.Inventory.Gear, itemId) then
			return false, "Already owned"
		end

		-- Add to gear (permanent) items
		table.insert(profile.Data.Inventory.Gear, itemId)

	elseif item.Category == "Cosmetic" then  -- Cosmetics
		-- Check if already owned
		if table.find(profile.Data.Inventory.Cosmetics, itemId) then
			return false, "Already owned"
		end

		-- Add to owned cosmetics
		table.insert(profile.Data.Inventory.Cosmetics, itemId)

		-- Auto-equip if nothing equipped in this category
		if not profile.Data.Inventory.EquippedCosmetics[item.Category] then
			profile.Data.Inventory.EquippedCosmetics[item.Category] = itemId
		end
	else
		warn("Unknown item category:", item.Category)
		return false, "Unknown item type"
	end

	-- Deduct tokens
	DataService.RemoveTokens(player, item.TokenPrice, "Purchased " .. item.Name)

	return true, "Purchase successful"
end


-- Equip a cosmetic
function ShopService:EquipCosmetic(player, itemId)
	local item = ItemDefinitions[itemId]
	if not item then return false end

	local profile = DataService:GetProfile(player)
	if not profile then return false end

	-- Check if owned
	if not table.find(profile.Data.Inventory.Cosmetics, itemId) then
		return false, "Don't own this item"
	end

	-- Equip (one per CosmeticType, e.g. Victory, Death)
	local slotKey = item.CosmeticType or item.Category
	profile.Data.Inventory.EquippedCosmetics[slotKey] = itemId

	return true
end

-- Unequip cosmetic by CosmeticType or category (e.g. "Victory", "Death")
function ShopService:UnequipCosmetic(player, categoryOrType)
	if type(categoryOrType) ~= "string" or categoryOrType == "" then
		return false, "Invalid category"
	end
	local profile = DataService:GetProfile(player)
	if not profile then return false end
	profile.Data.Inventory.EquippedCosmetics[categoryOrType] = nil
	return true
end

-- Toggle cosmetic: equip if not equipped for this type, unequip if this one is already equipped
function ShopService:ToggleCosmetic(player, itemId)
	local item = ItemDefinitions[itemId]
	if not item or item.Category ~= "Cosmetic" then
		return false, "Invalid cosmetic"
	end
	local profile = DataService:GetProfile(player)
	if not profile then return false, "Data not loaded" end
	if not table.find(profile.Data.Inventory.Cosmetics, itemId) then
		return false, "Don't own this item"
	end
	local slotKey = item.CosmeticType or item.Category
	if profile.Data.Inventory.EquippedCosmetics[slotKey] == itemId then
		profile.Data.Inventory.EquippedCosmetics[slotKey] = nil
	else
		profile.Data.Inventory.EquippedCosmetics[slotKey] = itemId
	end
	return true
end

-- Use a consumable (consumes one) or gear that has OnUse (no consume)
function ShopService:UseItem(player, itemId)
	local item = ItemDefinitions[itemId]
	if not item then
		return false, "Item not found"
	end

	local profile = DataService:GetProfile(player)
	if not profile then return false end

	if item.Category == "Consumable" then
		local currentAmount = profile.Data.Inventory.Consumables[itemId] or 0
		if currentAmount <= 0 then
			return false, "Don't have this item"
		end
		if type(item.OnUse) ~= "function" then
			return false, "Can't use this item"
		end
		local success = item.OnUse(player)
		if not success then
			return false, "Failed to use"
		end
		profile.Data.Inventory.Consumables[itemId] = currentAmount - 1
		return true
	end

	if item.Category == "Gear" and type(item.OnUse) == "function" then
		if table.find(profile.Data.Inventory.Gear, itemId) == nil then
			return false, "Don't own this item"
		end
		item.OnUse(player)
		return true
	end

	return false, "Can't use this item"
end


------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

-- Check if player owns an item or is at max capacity
function ShopService:OwnsItem(player, item)
	local profile = DataService:GetProfile(player)
	if not profile then return false end
	
	if item.Category == "Consumable" then
		return (profile.Data.Inventory.Consumables[item.Id] or 0) >= item.MaxStack
	elseif item.Category == "Gear" then
		return table.find(profile.Data.Inventory.Gear, item.Id) ~= nil
	elseif item.Category == "Cosmetic" then
		return table.find(profile.Data.Inventory.Cosmetics, item.Id) ~= nil
	end
end


------------------------------------------------------------
-- REMOTE FUNCTIONS
------------------------------------------------------------

-- Strip sensitive data for client display
function ShopService:GetShopData(player)
	local clientSafeData = {}
	
	for itemId, item in pairs(ItemDefinitions) do
		local ownsItem = self:OwnsItem(player, item)
		
		clientSafeData[itemId] = {
			Id = item.Id,
			Name = item.Name,
			Description = item.Description,
			Category = item.Category,
			TokenPrice = item.TokenPrice,
			RobuxPrice = item.RobuxPrice,
			Icon = item.Icon,
			DeveloperProductId = item.DeveloperProductId,
			OwnsItem = ownsItem,
		}
	end

	return clientSafeData
end


return ShopService