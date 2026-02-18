------------------------------------------------------------
-- TUTORIAL UI HANDLER MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- MODULES --
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local SoundEffectsHandler = require(game.StarterPlayer.StarterPlayerScripts.Client.Handlers.Audio.SoundEffectsHandler)

-- ENUMS --
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local tutorialGUI = playerGui:WaitForChild("TutorialGUI")
local tutorialContainer = tutorialGUI:WaitForChild("Container")
local closeButtonFrame = tutorialContainer:WaitForChild("CloseFrame")
local closeButton = closeButtonFrame:WaitForChild("CloseButton")

local TutorialUIHandler = {}

closeButton.MouseButton1Click:Connect(function()
	SoundEffectsHandler.PlaySound(SoundType.Click)
	TutorialUIHandler:Close()
end)

function TutorialUIHandler:Open()
	tutorialGUI.Enabled = true
end

function TutorialUIHandler:Close()
	TweenerService:ShrinkGui(tutorialGUI, 0.25)
end

-- Enable tutorial ui on join
function TutorialUIHandler:Init()
	self:Open()
end

TutorialUIHandler:Init()
return TutorialUIHandler
