------------------------------------------------------------
-- NOTIFICATION UI HANDLER MODULE SCRIPT 
-- @carsondev7
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
local NotificationUIHandler = {}

-- ENUMS --
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- UI REFERENCES --
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Death feed
local deathFeedGUI = playerGui:WaitForChild("DeathFeedGUI")
local deathFeedContainer = deathFeedGUI:WaitForChild("Container")
local deathFeedTemplate = deathFeedContainer:WaitForChild("Template")

-- Tokens
local tokensGUI = playerGui:WaitForChild("TokensGUI")
local mainTokenContainer = tokensGUI:WaitForChild("Container")
local tokensContainer = mainTokenContainer:WaitForChild("TokensContainer")
local tokenLabel = tokensContainer:WaitForChild("Tokens")
local tokenFeedContainer = mainTokenContainer:WaitForChild("TokenFeed")
local tokenFeedTemplate = tokenFeedContainer:WaitForChild("Template")

------------------------------------------------------------
-- PUBLIC FUNCTIONS --
------------------------------------------------------------

-- Display death feed notification
function NotificationUIHandler:UpdateDeathFeed(data)
	if not data then return end
	
	local deathFeedClone = deathFeedTemplate:Clone()
	deathFeedClone.Text = data.playerName .. " has died!"
	deathFeedClone.TextTransparency = 1
	deathFeedClone.Parent = deathFeedContainer
	deathFeedClone.Visible = true
	
	-- Fade the label in and out
	TweenerService:Fade(deathFeedClone, 1, 1)
end

-- Display token feed notification
function NotificationUIHandler:UpdateTokens(data)
	if not data then return end
	
	tokenLabel.Text = data.totalTokens
	
	-- Display token feed notification
	if data.tokenAmount and data.reason then
		local tokenFeedClone = tokenFeedTemplate:Clone()
		if tokenFeedClone then
			
			-- Added tokens
			if data.tokenType == "Add" then
				-- White reason, gold tokens
				tokenFeedClone.Description.Text = string.format(
					'<font color="#FFFFFF">%s</font> <font color="#FFD700">+%d</font>',
					data.reason,
					data.tokenAmount
				)
				
				tokenFeedClone.Parent = tokenFeedContainer

				-- Fade the label in and out
				TweenerService:Fade(tokenFeedClone, .5, 1)
				TweenerService:FadeTextColor(tokenLabel, Color3.fromRGB(255, 200, 60), .5, 1)
				
			-- Removed tokens
			else
				-- White reason, red tokens
				tokenFeedClone.Description.Text = string.format(
					'<font color="#FFFFFF">%s</font> <font color="#ff0004">-%d</font>',
					data.reason,
					data.tokenAmount
				)				
				
				tokenFeedClone.Parent = tokenFeedContainer

				-- Fade the label in and out
				TweenerService:Fade(tokenFeedClone, .5, 1)
				TweenerService:FadeTextColor(tokenLabel, Color3.fromRGB(250, 0, 0), .5, 1)
			end
		end
	end
end


return NotificationUIHandler
