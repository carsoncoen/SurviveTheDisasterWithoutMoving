------------------------------------------------------------
-- INVENTORY UI HANDLER
-- @carsondev7
-- Same layout as shop; shows owned items only. Click consumable/gear = equip to first hotbar slot. Cosmetics = equip/unequip by type.
------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------
-- MODULES --
------------------------------------------------------------
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local SoundEffectHandler = require(game.StarterPlayer.StarterPlayerScripts.Client.Handlers.Audio.SoundEffectsHandler)

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local InventoryUIHandler = {}
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Inventory GUI (same structure as ShopGUI)
local inventoryGUI = playerGui:WaitForChild("InventoryGUI")
local invContainer = inventoryGUI:WaitForChild("Container")
local invContentsFrame = invContainer:WaitForChild("ContentsFrame")
local invContentTemplate = invContentsFrame:WaitForChild("Template")
local invCloseFrame = invContainer:WaitForChild("CloseFrame")
local invCloseButton = invCloseFrame:WaitForChild("CloseButton")

local invTabs = invContainer:WaitForChild("Tabs")
local invConsumablesTab = invTabs:WaitForChild("ConsumablesButton")
local invGearTab = invTabs:WaitForChild("GearButton")
local invCosmeticsTab = invTabs:WaitForChild("CosmeticsButton")

-- HUD
local hudGUI = playerGui:WaitForChild("HudGUI")
local hudContainer = hudGUI:WaitForChild("Container")
local invFrame = hudContainer:WaitForChild("InventoryFrame")
local invButton = invFrame:WaitForChild("Interact")

-- Remotes
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local invFolder = remoteFunctions:WaitForChild("Inventory")
local getInventoryState = invFolder:WaitForChild("GetInventoryState")
local equipToFirstSlot = invFolder:WaitForChild("EquipItemToFirstAvailableSlot")
local toggleCosmeticRF = invFolder:WaitForChild("ToggleCosmetic")

-- Cached state (Hotbar, DisplayItems, etc.)
local inventoryState = nil
local currentTab = "Gear"

------------------------------------------------------------
-- EQUIPPED STYLE (stroke grow + color)
------------------------------------------------------------
local EQUIPPED_STROKE_THICKNESS = 4
local EQUIPPED_STROKE_COLOR = Color3.fromRGB(243, 189, 56)
local NORMAL_STROKE_THICKNESS = 2
local NORMAL_STROKE_COLOR = Color3.fromRGB(0, 0, 0)

local function applyEquippedStyle(frame, equipped)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if not stroke then return end
	stroke.Thickness = equipped and EQUIPPED_STROKE_THICKNESS or NORMAL_STROKE_THICKNESS
	stroke.Color = equipped and EQUIPPED_STROKE_COLOR or NORMAL_STROKE_COLOR
end

------------------------------------------------------------
-- REFRESH STATE
------------------------------------------------------------

function InventoryUIHandler:RefreshInventory()
	inventoryState = getInventoryState:InvokeServer()
	if not inventoryState then return end
	if currentTab == "Consumable" then
		self:HighlightSelectedTab(invConsumablesTab)
		self:PopulateTab("Consumable")
	elseif currentTab == "Cosmetic" then
		self:HighlightSelectedTab(invCosmeticsTab)
		self:PopulateTab("Cosmetic")
	else
		self:HighlightSelectedTab(invGearTab)
		self:PopulateTab("Gear")
	end
end

------------------------------------------------------------
-- OPEN / CLOSE
------------------------------------------------------------

function InventoryUIHandler:OpenInventory()
	if not inventoryState then
		inventoryState = getInventoryState:InvokeServer()
	end
	TweenerService:SlideGuiIn(inventoryGUI, "LEFT", 0.25)
	self:HighlightSelectedTab(invGearTab)
	self:PopulateTab("Gear")
end

function InventoryUIHandler:CloseInventory()
	TweenerService:SlideGuiOut(inventoryGUI, "LEFT", 0.25)
end

------------------------------------------------------------
-- POPULATE TAB (owned items only; no OwnedOverlay; hover + equipped style)
------------------------------------------------------------

function InventoryUIHandler:PopulateTab(category)
	if not inventoryState or not inventoryState.DisplayItems then return end

	for _, child in ipairs(invContentsFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= invContentTemplate then
			child:Destroy()
		end
	end

	for itemId, item in pairs(inventoryState.DisplayItems) do
		if item.Category ~= category then continue end

		local clone = invContentTemplate:Clone()
		clone.Name = itemId
		clone.Visible = true
		clone.Parent = invContentsFrame

		local nameLabel = clone:FindFirstChild("Name")
		local icon = clone:FindFirstChild("Icon")
		local interactButton = clone:FindFirstChild("InteractButton")

		if nameLabel then nameLabel.Text = item.Name end
		if icon then icon.Image = item.Icon end

		local isEquipped = (item.InHotbarSlot and item.InHotbarSlot > 0) or item.EquippedCosmetic
		applyEquippedStyle(clone, isEquipped)

		if interactButton then
			TweenerService:ApplyButtonHoverEffect(interactButton, { Scale = 1.08 })
			interactButton.MouseButton1Click:Connect(function()
				SoundEffectHandler.PlaySound(SoundType.Click)
				if item.Category == "Consumable" or item.Category == "Gear" then
					local success, _message, newState = equipToFirstSlot:InvokeServer(itemId)
					if success and newState then
						inventoryState = newState
						SoundEffectHandler.PlaySound(SoundType.Purchase)
						InventoryUIHandler:RefreshInventory()
					else
						SoundEffectHandler.PlaySound(SoundType.Invalid)
					end
				elseif item.Category == "Cosmetic" then
					-- Toggle: equip if not equipped, unequip if already equipped for this type
					local success, _message, newState = toggleCosmeticRF:InvokeServer(itemId)
					if success and newState then
						inventoryState = newState
						SoundEffectHandler.PlaySound(SoundType.Purchase)
						InventoryUIHandler:RefreshInventory()
					else
						SoundEffectHandler.PlaySound(SoundType.Invalid)
					end
				end
			end)
		end
	end
end

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

function InventoryUIHandler:HighlightSelectedTab(button)
	if not button then return end
	for _, tab in pairs(invTabs:GetChildren()) do
		if not tab:IsA("TextButton") then continue end
		tab.BackgroundTransparency = 0.3
		tab.BackgroundColor3 = Color3.fromRGB(33, 102, 152)
		local s = tab:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = Color3.fromRGB(50, 170, 255)
			s.Thickness = 2
		end
	end
	button.BackgroundTransparency = 0.7
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 3
	end
end

------------------------------------------------------------
-- INPUT EVENTS
------------------------------------------------------------

invButton.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	if inventoryGUI.Enabled then
		InventoryUIHandler:CloseInventory()
		return
	end
	InventoryUIHandler:OpenInventory()
end)

invCloseButton.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	InventoryUIHandler:CloseInventory()
end)

invConsumablesTab.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	currentTab = "Consumable"
	InventoryUIHandler:HighlightSelectedTab(invConsumablesTab)
	InventoryUIHandler:PopulateTab("Consumable")
end)

invGearTab.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	currentTab = "Gear"
	InventoryUIHandler:HighlightSelectedTab(invGearTab)
	InventoryUIHandler:PopulateTab("Gear")
end)

invCosmeticsTab.MouseButton1Click:Connect(function()
	SoundEffectHandler.PlaySound(SoundType.Click)
	currentTab = "Cosmetic"
	InventoryUIHandler:HighlightSelectedTab(invCosmeticsTab)
	InventoryUIHandler:PopulateTab("Cosmetic")
end)

------------------------------------------------------------
-- INIT
------------------------------------------------------------

function InventoryUIHandler:Init()
	inventoryGUI.Enabled = false
end

InventoryUIHandler:Init()

return InventoryUIHandler
