------------------------------------------------------------
-- ROUND UI HANDLER MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- MODULES --
local TweenerService = require(ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)
local SoundEffectsHandler = require(game.StarterPlayer.StarterPlayerScripts.Client.Handlers.Audio.SoundEffectsHandler)
local ConfettiService = require(ReplicatedStorage.Shared.Modules.Services.Utils.ConfettiService)

-- ENUMS --
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- VARIABLES --
local UIStates = {}
local currentState = nil

local disasterTypeColor = {
	["Meteor Strike"] = Color3.fromRGB(255, 156, 69),
	["Flood"] = Color3.fromRGB(0, 174, 255),
	["Plague"] = Color3.fromRGB(115, 140, 79),
	["Wind Storm"] = Color3.fromRGB(216, 255, 254),
	["Fire"] = Color3.fromRGB(255, 193, 180),
	["Acid Rain"] = Color3.fromRGB(174, 217, 160),
	["Tsunami"] = Color3.fromRGB(103, 220, 255),
	["Lightning Storm"] = Color3.fromRGB(211, 212, 255),
	["Blackhole"] = Color3.fromRGB(25, 25, 25),
	["Tornado"] = Color3.fromRGB(130, 130, 130),
}


local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local roundGui = playerGui:WaitForChild("RoundGUI")
local roundFrame = roundGui:WaitForChild("Background")
local roundTextLabel = roundFrame:WaitForChild("RoundText")

local mapNameGui = playerGui:WaitForChild("MapNameGUI")
local mapNameFrame = mapNameGui:WaitForChild("Background")
local mapNameTextLabel = mapNameFrame:WaitForChild("MapName")

--local winnersGui = playerGui:WaitForChild("WinnersGUI")
--local winnersBackground = winnersGui:WaitForChild("Background")
--local winnersFrame = winnersBackground:WaitForChild("WinnersFrame")
--local noWinnersFrame = winnersBackground:WaitForChild("NoWinnersFrame")

local resultsGui = playerGui:WaitForChild("ResultsGUI")
local resultsContainer = resultsGui:WaitForChild("Container")
local resultsScroller = resultsContainer:WaitForChild("ResultsScroller")
local tokensContainer = resultsContainer:WaitForChild("TokensContainer")
local tokensEarnedTextLabel = tokensContainer:WaitForChild("TokensEarned")
local mainHeader = resultsContainer:WaitForChild("MainHeader")
local playerTemplate = resultsContainer:WaitForChild("PlayerTemplate")
local playerTemplate1st = resultsContainer:WaitForChild("1stPlayerTemplate")

local nextDisasterGui = playerGui:WaitForChild("NextDisasterGUI")
local nextDisasterFrame = nextDisasterGui:WaitForChild("Background")
local nextDisasterTextLabel = nextDisasterFrame:WaitForChild("DisasterType")
local countdownFrame = nextDisasterFrame:WaitForChild("CountdownFrame")
local disasterCountdownTextLabel = countdownFrame:WaitForChild("Countdown")

local RoundUIHandler = {}

-- Update waiting for players ui
UIStates.WaitingForPlayers = {
	enter = function()
		roundGui.Enabled = true
	end,

	update = function(data)
		roundGui.Enabled = true -- Make sure it's enable in case joined late
		roundTextLabel.Text = "Waiting for enough players to start..  " .. "(" .. data.currentPlayers .. "/" .. data.playersNeeded .. ")"
	end,

	exit = function()
		roundGui.Enabled = false
	end,
}

-- Update intermission ui
UIStates.Intermission = {
	enter = function()
		roundGui.Enabled = true
	end,

	update = function(data)
		roundGui.Enabled = true -- Make sure it's enable in case joined late
		roundTextLabel.Text = "Intermission.. " .. data.timeLeft .. "s"
		SoundEffectsHandler.PlaySound(SoundType.TimeTick)
	end,

	exit = function()
		roundGui.Enabled = false
	end,
}


-- Update map display ui
UIStates.MapDisplay = {
	enter = function()
		TweenerService:SlideGuiIn(mapNameGui, "DOWN", 1)
		--TweenerService:ExpandGui(mapNameGui, 0.25)
	end,

	update = function(data)
		mapNameTextLabel.Text = data.mapName:upper()
	end,

	exit = function()
		TweenerService:SlideGuiOut(mapNameGui, "UP", 1)
		--TweenerService:ShrinkGui(mapNameGui, 0.25)
	end,
}

-- Update new disaster starting ui
UIStates.NewDisasterStarting = {
	enter = function()
		TweenerService:SlideGuiIn(nextDisasterGui, "UP", 1)
	end,

	update = function(data)
		nextDisasterTextLabel.Text = data.disasterType:upper()
		nextDisasterTextLabel.TextColor3 = disasterTypeColor[data.disasterType]
		disasterCountdownTextLabel.Text = "Starts in " .. data.timeLeft .. "s"
		SoundEffectsHandler.PlaySound(SoundType.TimeTick)
	end,

	exit = function()
		TweenerService:SlideGuiOut(nextDisasterGui, "UP", 1)
	end,
}

-- Update disaster in progress ui
UIStates.DisasterInProgress = {
	enter = function()
	end,

	update = function(data)
	end,

	exit = function()
	end,
}

-- Update round over ui
UIStates.RoundOver = {
	enter = function(data)
		
		TweenerService:SlideGuiIn(resultsGui, "DOWN", 1)
		ConfettiService:Play()
		SoundEffectsHandler.PlaySound(SoundType.Winner)
		
		for _, child in pairs(resultsScroller:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end,

	update = function(data)
		if data.results then
			for _, resultsData in pairs(data.results) do
				
				local playerFrame
				if resultsData.Rank == 1 then
					playerFrame = playerTemplate1st:Clone()
				else
					playerFrame = playerTemplate:Clone()
				end
				
				if playerFrame then
					-- If player is the local player, highlight them
					if resultsData.Name == player.Name then
						playerFrame.BackgroundColor3 = Color3.fromRGB(157, 216, 255)
						tokensEarnedTextLabel.Text = resultsData.TokensEarned
						if resultsData.RoundsSurvived == 1 then
							mainHeader.Text = "You Survived " .. resultsData.RoundsSurvived .. " Round!"
						else
							mainHeader.Text = "You Survived " .. resultsData.RoundsSurvived .. " Rounds!"
						end
					end
					playerFrame:WaitForChild("Name").Text = resultsData.Name
					playerFrame:WaitForChild("RoundsSurvived").Text = resultsData.RoundsSurvived
					playerFrame:WaitForChild("Rank").Text = "#" .. resultsData.Rank
					playerFrame:WaitForChild("PlayerImage").Image = resultsData.Image
					playerFrame.Parent = resultsScroller
					playerFrame.Visible = true
				end
			end
		end
	end,

	exit = function()
		TweenerService:SlideGuiOut(resultsGui, "UP", 1)
		task.delay(3, function()
			for _, child in pairs(resultsScroller:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
		end)
	end,
}



function RoundUIHandler:Update(data)
	if not data or not data.uiType then return end

	-- state change
	if currentState ~= data.uiType then
		if currentState then
			local prev = UIStates[currentState]
			if prev and prev.exit then
				prev.exit()
			end
		end

		currentState = data.uiType

		local nextState = UIStates[currentState]
		if nextState and nextState.enter then
			nextState.enter(data)
		end
	end

	-- per-update logic
	local active = UIStates[currentState]
	if active and active.update then
		active.update(data)
	end
end



return RoundUIHandler
