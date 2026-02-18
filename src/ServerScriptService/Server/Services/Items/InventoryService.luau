------------------------------------------------------------
-- INVENTORY SERVICE
-- @carsondev7
-- Hotbar (consumables/gear) + cosmetic equip; remotes for UI.
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
local DataService = require(game.ServerScriptService.Server.Services.Player.DataService)
local ShopService = require(script.Parent.ShopService)
local ItemDefinitions = require(script.Parent.ItemDefinitions)

-- CONSTANTS --
local HOTBAR_SLOT_COUNT = 10

-- VARIABLES --
local InventoryService = {}
local playerSelectedSlot = {} -- [player] = slotIndex (for Gear OnEquip/OnUnequip)

-- REMOTES --
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local invFolder = remoteFunctions:WaitForChild("Inventory")
local getInventoryStateRF = invFolder:WaitForChild("GetInventoryState")
local equipItemToFirstAvailableSlotRF = invFolder:WaitForChild("EquipItemToFirstAvailableSlot")
local setHotbarSlotRF = invFolder:WaitForChild("SetHotbarSlot")
local selectHotbarSlotRF = invFolder:WaitForChild("SelectHotbarSlot")
local deselectHotbarSlotRF = invFolder:WaitForChild("DeselectHotbarSlot")
local useItemRF = invFolder:WaitForChild("UseItem")

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function getHotbar(profile)
	local hotbar = profile.Data.Inventory.Hotbar
	if type(hotbar) ~= "table" then
		hotbar = {}
		profile.Data.Inventory.Hotbar = hotbar
	end
	-- Ensure 1..HOTBAR_SLOT_COUNT exist
	for i = 1, HOTBAR_SLOT_COUNT do
		if hotbar[i] == nil and rawget(hotbar, i) == nil then
			hotbar[i] = nil
		end
	end
	return hotbar
end

local function playerOwnsItem(profile, itemId, category)
	if category == "Consumable" then
		return (profile.Data.Inventory.Consumables[itemId] or 0) > 0
	end
	if category == "Gear" then
		return table.find(profile.Data.Inventory.Gear, itemId) ~= nil
	end
	if category == "Cosmetic" then
		return table.find(profile.Data.Inventory.Cosmetics, itemId) ~= nil
	end
	return false
end

------------------------------------------------------------
-- INVENTORY STATE (client-safe)
------------------------------------------------------------

function InventoryService:GetInventoryState(player)
	local profile = DataService:GetProfile(player)
	if not profile then return nil end

	local hotbar = getHotbar(profile)
	local hotbarCopy = {}
	for i = 1, HOTBAR_SLOT_COUNT do
		hotbarCopy[i] = hotbar[i]
	end

	-- Build display list for UI (Name, Icon, Category, etc.)\
	local displayItems = {}
	local function addItem(itemId, category, count)
		local item = ItemDefinitions[itemId]
		if not item then return end
		local inHotbarSlot = nil
		for slot = 1, HOTBAR_SLOT_COUNT do
			if hotbar[slot] == itemId then 
				inHotbarSlot = slot 
				break 
			end
		end
		local slotKey = item.CosmeticType or item.Category
		local equippedCosmetic = (category == "Cosmetic" and profile.Data.Inventory.EquippedCosmetics[slotKey] == itemId)
		displayItems[itemId] = {
			Id = itemId,
			Name = item.Name,
			Description = item.Description,
			Icon = item.Icon,
			Category = item.Category,
			CosmeticType = item.CosmeticType,
			Count = count,
			InHotbarSlot = inHotbarSlot,
			EquippedCosmetic = equippedCosmetic,
		}
	end
	for itemId, count in pairs(profile.Data.Inventory.Consumables) do
		if count and count > 0 then addItem(itemId, "Consumable", count) end
	end
	for _, itemId in ipairs(profile.Data.Inventory.Gear) do
		addItem(itemId, "Gear", nil)
	end
	for _, itemId in ipairs(profile.Data.Inventory.Cosmetics) do
		addItem(itemId, "Cosmetic", nil)
	end

	return {
		Hotbar = hotbarCopy,
		Consumables = profile.Data.Inventory.Consumables,
		Gear = profile.Data.Inventory.Gear,
		Cosmetics = profile.Data.Inventory.Cosmetics,
		EquippedCosmetics = profile.Data.Inventory.EquippedCosmetics,
		DisplayItems = displayItems,
	}
end

------------------------------------------------------------
-- EQUIP TO FIRST AVAILABLE SLOT (one call: validate, add, return state)
------------------------------------------------------------

function InventoryService:EquipItemToFirstAvailableSlot(player, itemId)
	if type(itemId) ~= "string" or itemId == "" then
		return false, "Invalid item", nil
	end

	local profile = DataService:GetProfile(player)
	if not profile then return false, "Data not loaded", nil end

	local item = ItemDefinitions[itemId]
	if not item then
		return false, "Item not found", nil
	end

	if item.Category ~= "Consumable" and item.Category ~= "Gear" then
		return false, "Only consumables and gear go in the hotbar", nil
	end

	if not playerOwnsItem(profile, itemId, item.Category) then
		return false, "You don't own this item", nil
	end

	local hotbar = getHotbar(profile)
	local firstEmpty = nil
	for i = 1, HOTBAR_SLOT_COUNT do
		if not hotbar[i] or hotbar[i] == "" then
			firstEmpty = i
			break
		end
	end

	if not firstEmpty then
		return false, "Hotbar is full", nil
	end

	hotbar[firstEmpty] = itemId
	return true, nil, self:GetInventoryState(player)
end

------------------------------------------------------------
-- HOTBAR SLOT
------------------------------------------------------------

function InventoryService:SetHotbarSlot(player, slotIndex, itemId)
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > HOTBAR_SLOT_COUNT then
		return false, "Invalid slot"
	end

	local profile = DataService:GetProfile(player)
	if not profile then return false, "Data not loaded" end

	local hotbar = getHotbar(profile)

	if itemId == nil or itemId == "" then
		hotbar[slotIndex] = nil
		return true
	end

	if type(itemId) ~= "string" then
		return false, "Invalid item"
	end

	local item = ItemDefinitions[itemId]
	if not item then
		return false, "Item not found"
	end

	if item.Category ~= "Consumable" and item.Category ~= "Gear" then
		return false, "Only consumables and gear go in the hotbar"
	end

	if not playerOwnsItem(profile, itemId, item.Category) then
		return false, "You don't own this item"
	end

	hotbar[slotIndex] = itemId
	return true
end

------------------------------------------------------------
-- SELECT / DESELECT (Gear OnEquip / OnUnequip)
------------------------------------------------------------

function InventoryService:SelectHotbarSlot(player, slotIndex)
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > HOTBAR_SLOT_COUNT then
		return false, "Invalid slot"
	end

	-- Deselect previous first so we only have one "held" item
	self:DeselectHotbarSlot(player)

	local profile = DataService:GetProfile(player)
	if not profile then return false, "Data not loaded" end

	local hotbar = getHotbar(profile)
	local itemId = hotbar[slotIndex]
	if not itemId then
		playerSelectedSlot[player] = slotIndex
		return true
	end

	local item = ItemDefinitions[itemId]
	if item and item.Category == "Gear" and type(item.OnEquip) == "function" then
		item.OnEquip(player)
	end

	playerSelectedSlot[player] = slotIndex
	return true
end

function InventoryService:DeselectHotbarSlot(player)
	local prevSlot = playerSelectedSlot[player]
	playerSelectedSlot[player] = nil

	if not prevSlot then return true end

	local profile = DataService:GetProfile(player)
	if not profile then return true end

	local hotbar = getHotbar(profile)
	local itemId = hotbar[prevSlot]
	if not itemId then return true end

	local item = ItemDefinitions[itemId]
	if item and item.Category == "Gear" and type(item.OnUnequip) == "function" then
		item.OnUnequip(player)
	end
	return true
end

------------------------------------------------------------
-- CLEANUP ON LEAVE
------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
	InventoryService:DeselectHotbarSlot(player)
	playerSelectedSlot[player] = nil
end)

------------------------------------------------------------
-- REMOTE HANDLERS
------------------------------------------------------------

getInventoryStateRF.OnServerInvoke = function(player)
	if not player then return nil end
	return InventoryService:GetInventoryState(player)
end

equipItemToFirstAvailableSlotRF.OnServerInvoke = function(player, itemId)
	if not player then return false, "Invalid player", nil end
	return InventoryService:EquipItemToFirstAvailableSlot(player, itemId)
end

setHotbarSlotRF.OnServerInvoke = function(player, slotIndex, itemId)
	if not player then return false, "Invalid player" end
	return InventoryService:SetHotbarSlot(player, slotIndex, itemId)
end

selectHotbarSlotRF.OnServerInvoke = function(player, slotIndex)
	if not player then return false, "Invalid player" end
	return InventoryService:SelectHotbarSlot(player, slotIndex)
end

deselectHotbarSlotRF.OnServerInvoke = function(player)
	if not player then return false end
	return InventoryService:DeselectHotbarSlot(player)
end

useItemRF.OnServerInvoke = function(player, itemId)
	if not player then return false, "Invalid player" end
	if type(itemId) ~= "string" or ItemDefinitions[itemId] == nil then
		return false, "Invalid item"
	end
	return ShopService:UseItem(player, itemId)
end

return InventoryService
