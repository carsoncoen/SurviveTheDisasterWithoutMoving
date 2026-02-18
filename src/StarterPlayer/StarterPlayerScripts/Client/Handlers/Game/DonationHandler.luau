------------------------------------------------------------
-- DONATION HANDLER
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- MODULES --

-- VARIABLES --
local lobby = workspace:WaitForChild("Lobby")
local donationPart = lobby:WaitForChild("DonationPart")
local donationGui = donationPart:WaitForChild("DonationGUI")
local buttonContainer = donationGui:WaitForChild("Container")
local player = Players.LocalPlayer


local DonationHandler = {}

function DonationHandler:DetectButtons()
	for _, button in pairs(buttonContainer:GetChildren()) do
		if button:IsA("TextButton") then
			button.MouseButton1Click:Connect(function()
				local productId = button.ProductId.Value

				local success, productInfo = pcall(function()
					return MarketplaceService:GetProductInfoAsync(productId, Enum.InfoType.Product)
				end)

				if success and productInfo then
					-- Checks if product is for sale
					if productInfo.IsForSale then
						--print("This is for sale")
						-- Prompts product purchase
						MarketplaceService:PromptProductPurchase(player, productId)
					else
						-- Notifies product isn't for sale
						--print("This product is not currently for sale.")
					end
				else
					--print("Error retrieving product info: " .. tostring(productInfo))
				end
			end)
		end
	end
end

function DonationHandler:Init()
	self:DetectButtons()
end

-- INIT --
DonationHandler:Init()
return DonationHandler
