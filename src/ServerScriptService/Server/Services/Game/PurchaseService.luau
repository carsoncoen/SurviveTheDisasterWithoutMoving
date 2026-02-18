------------------------------------------------------------
-- MARKETPLACE SERVICE
-- @carsondev7
-- Handles ALL developer product purchases
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- MODULES --
local DataService = require(game.ServerScriptService.Server.Services.Player.DataService)
local BadgeService = require(game.ServerScriptService.Server.Services.Game.BadgeService)
local ItemDefinitions = require(game.ServerScriptService.Server.Services.Items.ItemDefinitions)

-- VARIABLES --
local MarketplaceHandler = {}

local remoteEvents = ReplicatedStorage.RemoteEvents
local purchaseSuccessful = remoteEvents.Purchasing.PurchaseSuccessful

------------------------------------------------------------
-- PRODUCT REGISTRIES
------------------------------------------------------------

-- Donation products
local donationProducts = {
	["3524509583"] = { Value = 5 },
	["3524543479"] = { Value = 10 },
	["3524545312"] = { Value = 25 },
	["3524546393"] = { Value = 50 },
	["3524546814"] = { Value = 100 },
	["3524547268"] = { Value = 250 },
}

-- Shop item products (productId -> itemId)
-- Build this automatically from ItemDefinitions
local shopProducts = {}
for itemId, item in pairs(ItemDefinitions) do
	if item.DeveloperProductId then
		shopProducts[tostring(item.DeveloperProductId)] = itemId
	end
end

------------------------------------------------------------
-- RECEIPT HANDLER
------------------------------------------------------------

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local productId = tostring(receiptInfo.ProductId)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	-- Player might have left - still need to process
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Get player data
	local profile = DataService:GetProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Check if it's a donation
	local donationProduct = donationProducts[productId]
	if donationProduct then
		local success = MarketplaceHandler:ProcessDonation(player, profile, donationProduct)
		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	-- Check if it's a shop item
	local itemId = shopProducts[productId]
	if itemId then
		local success = MarketplaceHandler:ProcessShopPurchase(player, profile, itemId)
		if success then
			purchaseSuccessful:FireClient(player, itemId, true)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			purchaseSuccessful:FireClient(player, itemId, false)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	-- Unknown product - still grant it so player isnt charged twice
	warn("Unknown product ID:", productId)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

------------------------------------------------------------
-- PROCESSORS
------------------------------------------------------------

function MarketplaceHandler:ProcessDonation(player, profile, donationProduct)
	local success, err = pcall(function()
		local donationAmount = donationProduct.Value
		print("Donation of", donationAmount, "received from", player.Name)

		DataService.AddDonation(player, donationAmount)
		BadgeService:AwardBadge(player, BadgeService.badgeAssetIds.Supporter)
	end)

	if not success then
		warn("Failed to process donation:", err)
		return false
	end

	return true
end

function MarketplaceHandler:ProcessShopPurchase(player, profile, itemId)
	local item = ItemDefinitions[itemId]
	if not item then
		warn("Shop item not found:", itemId)
		return false
	end

	local result = true

	local success, err = pcall(function()
		print("Shop purchase:", item.Name, "for", player.Name)

		if item.Category == "Consumable" then
			local currentAmount = profile.Data.Inventory.Consumables[itemId] or 0
			if currentAmount < item.MaxStack then
				profile.Data.Inventory.Consumables[itemId] = currentAmount + 1
			else
				result = false 
			end

		elseif item.Category == "Gear" then
			if not table.find(profile.Data.Inventory.Gear, itemId) then
				table.insert(profile.Data.Inventory.Gear, itemId)
			else
				result = false
			end

		elseif item.Category == "Cosmetic" then
			if not table.find(profile.Data.Inventory.Cosmetics, itemId) then
				table.insert(profile.Data.Inventory.Cosmetics, itemId)
				if not profile.Data.Inventory.EquippedCosmetics[item.Category] then
					profile.Data.Inventory.EquippedCosmetics[item.Category] = itemId
				end
			else
				result = false
			end

		else
			warn("Unknown item category:", item.Category)
			result = false
		end
	end)

	if not success then
		warn("Failed to process shop purchase:", err)
		return false
	end

	return result
end

------------------------------------------------------------
-- INIT
------------------------------------------------------------

function MarketplaceHandler:Init()
end

MarketplaceHandler:Init()

return MarketplaceHandler