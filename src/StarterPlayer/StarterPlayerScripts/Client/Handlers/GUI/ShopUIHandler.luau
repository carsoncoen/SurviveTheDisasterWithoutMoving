------------------------------------------------------------
-- SHOP UI HANDLER MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

------------------------------------------------------------
-- MODULES --
------------------------------------------------------------
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local SoundEffectHandler = require(game.StarterPlayer.StarterPlayerScripts.Client.Handlers.Audio.SoundEffectsHandler)

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local ShopUIHandler = {}

-- ENUMS --
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- UI REFERENCES --
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Main shop gui
local shopGUI = playerGui:WaitForChild("ShopGUI")
local shopContainer = shopGUI:WaitForChild("Container")
local shopContentsFrame = shopContainer:WaitForChild("ContentsFrame")
local shopContentTemplate = shopContentsFrame:WaitForChild("Template")
local closeFrame = shopContainer:WaitForChild("CloseFrame")
local closeButton = closeFrame:WaitForChild("CloseButton")

-- Tabs
local shopTabs = shopContainer:WaitForChild("Tabs")
local consumablesTab = shopTabs:WaitForChild("ConsumablesButton")
local gearTab = shopTabs:WaitForChild("GearButton")
local cosmeticsTab = shopTabs:WaitForChild("CosmeticsButton")

-- Item description
local itemDescriptionFrame = shopContainer:WaitForChild("ItemDescription")
local itemDescriptionCloseFrame = itemDescriptionFrame:WaitForChild("CloseFrame")
local closeItemDescriptionButton = itemDescriptionCloseFrame:WaitForChild("CloseButton")
local tokensPurchaseFrame = itemDescriptionFrame:WaitForChild("TokensPurchaseFrame")
local robuxPurchaseFrame = itemDescriptionFrame:WaitForChild("RobuxPurchaseFrame")
local tokensPurchaseButton = tokensPurchaseFrame:WaitForChild("Purchase")
local robuxPurchaseButton = robuxPurchaseFrame:WaitForChild("Purchase")

local hudGUI = playerGui:WaitForChild("HudGUI")
local hudContainer = hudGUI:WaitForChild("Container")
local shopFrame = hudContainer:WaitForChild("ShopFrame")
local shopButton = shopFrame:WaitForChild("Interact")

-- Remotes
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getShopData = remoteFunctions:WaitForChild("Items"):WaitForChild("GetShopData")
local purchaseItem = remoteFunctions:WaitForChild("Items"):WaitForChild("PurchaseItem")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local purchaseSuccessful = remoteEvents:WaitForChild("Purchasing"):WaitForChild("PurchaseSuccessful")

-- Cache shop data
local shopItems = getShopData:InvokeServer()

-- Store currently selected item
local currentSelectedItem = nil

------------------------------------------------------------
-- REMOTE EVENTS --
------------------------------------------------------------

purchaseSuccessful.OnClientEvent:Connect(function(itemId, success)
	if success then
		SoundEffectHandler.PlaySound(SoundType.Purchase)
		ShopUIHandler:RefreshShop()
		print("Successfully purchased:", itemId)
	else
		SoundEffectHandler.PlaySound(SoundType.Invalid)
		print("Failed to purchase:", itemId)
	end
end)

------------------------------------------------------------
-- INPUT EVENTS --
------------------------------------------------------------

-- Open/Close
shopButton.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)

	if shopGUI.Enabled then
		ShopUIHandler:CloseShop()
		return
	end

	ShopUIHandler:OpenShop()
end)

closeButton.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:CloseShop()
end)

-- Tabs
consumablesTab.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:CloseItemDescription()
	
	ShopUIHandler:HighlightSelectedTab(consumablesTab)
	ShopUIHandler:PopulateTab("Consumable")
end)

gearTab.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:CloseItemDescription()
	
	ShopUIHandler:HighlightSelectedTab(gearTab)
	ShopUIHandler:PopulateTab("Gear")
end)

cosmeticsTab.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:CloseItemDescription()
	
	ShopUIHandler:HighlightSelectedTab(cosmeticsTab)
	ShopUIHandler:PopulateTab("Cosmetic")
end)

-- Item description close
closeItemDescriptionButton.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:CloseItemDescription()
end)

-- Purchase buttons
tokensPurchaseButton.MouseButton1Click:Connect(function()
	if not currentSelectedItem then return end

	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:PurchaseWithTokens(currentSelectedItem)
end)

robuxPurchaseButton.MouseButton1Click:Connect(function()
	if not currentSelectedItem then return end

	SoundEffectHandler.PlaySound(SoundType.Click)
	ShopUIHandler:PurchaseWithRobux(currentSelectedItem)
end)

------------------------------------------------------------
-- PUBLIC FUNCTIONS --
------------------------------------------------------------

function ShopUIHandler:OpenShop()
	itemDescriptionFrame.Visible = false
	TweenerService:SlideGuiIn(shopGUI, "LEFT", .25)
	
	ShopUIHandler:HighlightSelectedTab(gearTab)
	self:PopulateTab("Gear")
end

function ShopUIHandler:CloseShop()
	itemDescriptionFrame.Visible = false
	currentSelectedItem = nil
	TweenerService:SlideGuiOut(shopGUI, "LEFT", .25)
end

-- Repopulate shop Items and tab
function ShopUIHandler:RefreshShop()
	shopItems = getShopData:InvokeServer()
	local currentCategory = currentSelectedItem and currentSelectedItem.Category
	if currentCategory then
		ShopUIHandler:PopulateTab(currentCategory)
	else
		ShopUIHandler:HighlightSelectedTab(gearTab)
		ShopUIHandler:PopulateTab("Gear")
	end
	self:CloseItemDescription()
end

function ShopUIHandler:OpenItemDescription(item)
	-- Update UI
	itemDescriptionFrame:WaitForChild("Name").Text = item.Name
	itemDescriptionFrame:WaitForChild("Description").Text = item.Description
	itemDescriptionFrame:WaitForChild("Icon").Image = item.Icon
	tokensPurchaseFrame:WaitForChild("Price").Text = item.TokenPrice or item.Price or 0
	robuxPurchaseFrame:WaitForChild("Price").Text = item.RobuxPrice or 0

	-- Update current selection
	currentSelectedItem = item

	-- Show frame
	itemDescriptionFrame.Visible = true
end

function ShopUIHandler:CloseItemDescription()
	itemDescriptionFrame.Visible = false
	currentSelectedItem = nil
end

function ShopUIHandler:PopulateTab(category)
	-- Clear existing items
	for _, child in ipairs(shopContentsFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= shopContentTemplate then
			child:Destroy()
		end
	end

	-- Create item buttons
	for itemId, item in pairs(shopItems) do
		if item.Category ~= category then continue end

		local itemClone = shopContentTemplate:Clone()
		itemClone.Name = itemId
		itemClone:WaitForChild("Name").Text = item.Name
		itemClone:WaitForChild("Icon").Image = item.Icon
		itemClone:WaitForChild("TokenPrice").Text = item.TokenPrice or item.Price or 0
		itemClone:WaitForChild("OwnedOverlay").Visible = item.OwnsItem or false
		itemClone.Visible = true
		itemClone.Parent = shopContentsFrame
		
		local interactBtn = itemClone:WaitForChild("InteractButton")
		TweenerService:ApplyButtonHoverEffect(interactBtn, { Scale = 1.08 })
		-- Only connect if not owned
		if item.OwnsItem then
			interactBtn.Interactable = false
		else
			-- Connect button (ONE connection per item)
			interactBtn.MouseButton1Click:Connect(function()
				SoundEffectHandler.PlaySound(SoundType.Click)

				-- Toggle if clicking same item
				if itemDescriptionFrame.Visible and currentSelectedItem and currentSelectedItem.Id == item.Id then
					self:CloseItemDescription()
					return
				end

				-- Show item description
				self:OpenItemDescription(item)
			end)
		end
	end
end

function ShopUIHandler:PurchaseWithTokens(item)
	if not item then 
		warn("No item selected")
		return 
	end
	
	print("Attempting to purchase", item.Name, "with tokens")
	
	-- Request purchase from server
	local success, message = purchaseItem:InvokeServer(item.Id, "Tokens")
	if success then
		ShopUIHandler:RefreshShop()
	else
		SoundEffectHandler.PlaySound(SoundType.Invalid)
	 	warn("Purchase failed:", message)
	end
end

function ShopUIHandler:PurchaseWithRobux(item)
	if not item then 
		warn("No item selected")
		return 
	end

	print("Attempting to purchase", item.Name, "with Robux")

	local productId = item.DeveloperProductId

	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfoAsync(productId, Enum.InfoType.Product)
	end)

	if success and productInfo then
		-- Checks if product is for sale
		if productInfo.IsForSale then
			-- Prompts product purchase
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end
end

------------------------------------------------------------
-- HELPERS --
------------------------------------------------------------

-- Highlight selected tab
function ShopUIHandler:HighlightSelectedTab(button)
	if not button then return end
	
	-- Reset all tabs
	gearTab.BackgroundTransparency = 0.5
	for _, tab in pairs(shopTabs:GetChildren()) do
		if not tab:IsA("TextButton") then continue end
		
		tab.BackgroundTransparency = 0.3
		tab.BackgroundColor3 = Color3.fromRGB(33, 102, 152)
		tab:WaitForChild("UIStroke").Color = Color3.fromRGB(50, 170, 255)
		tab:WaitForChild("UIStroke").Thickness = 2
	end
	
	-- Highlight selected tab
	button.BackgroundTransparency = 0.7
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button:WaitForChild("UIStroke").Color = Color3.fromRGB(255, 255, 255)
	button:WaitForChild("UIStroke").Thickness = 3
end

------------------------------------------------------------
-- INITIALIZATION --
------------------------------------------------------------

function ShopUIHandler:Init()
	-- Hide shop on startup
	shopGUI.Enabled = false
	itemDescriptionFrame.Visible = false

	print("Shop UI initialized with", #shopItems, "items")
end

ShopUIHandler:Init()

return ShopUIHandler