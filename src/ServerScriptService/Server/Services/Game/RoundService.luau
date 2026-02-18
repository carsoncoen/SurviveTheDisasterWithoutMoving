------------------------------------------------------------
-- ROUND SERVICE MODULE SCRIPT --
-- @carsondev7
------------------------------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- MODULES --
local MovementService = require(game.ServerScriptService.Server.Services.Player.MovementService)
local TeleportService = require(game.ServerScriptService.Server.Services.Game.TeleportService)
local StateService = require(game.ServerScriptService.Server.Services.Player.StateService)
local DisasterService = require(game.ServerScriptService.Server.Services.Disasters.DisasterService)
local NetworkService = require(game.ServerScriptService.Server.Services.Networking.NetworkService)
local StateDefinitions = require(game.ServerScriptService.Server.Services.Player.StateDefinitions)
local DataService = require(game.ServerScriptService.Server.Services.Player.DataService)
local WeldService = require(game.ServerScriptService.Server.Services.Game.WeldService)
local TweenerService = require(game.ReplicatedStorage.Shared.Modules.Services.Animations.TweenerService)

-- ENUMS --
local UIType = require(ReplicatedStorage.Shared.Modules.Enums.UIType)
local SoundType	= require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- UTILS --
local winnerStand = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("WinnerStand"):WaitForChild("Stand")
local winnerStandText = winnerStand.ScreenGUI.Container.WinnerName
local winnerRig = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("WinnerRig")

-- CONFIGURATION --
local Config = {
	-- Timing
	INTERMISSION_TIME = 100,
	MAX_DISASTER_CHANGE_TIME = 15,
	MIN_DISASTER_CHANGE_TIME = 5,
	LATE_JOIN_THRESHOLD = 5,
	WINNER_DISPLAY_TIME = 8,
	MAP_DISPLAY_TIME = 3,

	-- Game Rules
	MIN_PLAYERS_TO_START = 2,		-- Minimum players required to start a round
	MIN_PLAYERS_TO_END = 1,			-- Players remaining before round ends
	PLAYTESTING_MODE = true,		-- Set to false for release
	
	-- Rewards
	BASE_TOKENS_PER_ROUND = 5,		-- Tokens awarded per round
	TOKEN_RATE = 5,					-- (rate * round number)
	TOKENS_FOR_WINNING = 100,		-- Tokens for winning
}

-- STATE --
local gameActive = false
local currentDisaster = nil
local currentMap = nil
local currentPlayersThisGame = {}
local currentGameStartTime = 0
local currentRound = 0
local PlayerImages = {}

local RoundService = {}

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function RoundService:Init()
	task.spawn(function()
		self:SetupPlayerEvents()
		self:StartRoundLoop()
	end)
end

function RoundService:SetupPlayerEvents()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:OnCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:HandlePlayerRemoving(player)
	end)
end

---------------------------------------------------------------------------
-- MAIN GAME LOOP
---------------------------------------------------------------------------

function RoundService:StartRoundLoop()
	task.spawn(function()
		while true do
			-- Wait for minimum players (production only)
			if not Config.PLAYTESTING_MODE then
				self:WaitForPlayers()
			end

			local hasEnoughPlayers = self:StartIntermission()
			if not hasEnoughPlayers then
				continue
			end

			hasEnoughPlayers = self:ChooseMap()
			if not hasEnoughPlayers then
				self:CleanUpMap()
				continue
			end

			self:StartRound()
			self:EndRound()
		end
	end)
end

function RoundService:WaitForPlayers()
	while #Players:GetPlayers() < Config.MIN_PLAYERS_TO_START do
		for _, player in ipairs(Players:GetPlayers()) do
			NetworkService:SendUIEvent(player, {
				uiType = UIType.WaitingForPlayers,
				playersNeeded = Config.MIN_PLAYERS_TO_START,
				currentPlayers = #Players:GetPlayers(),
			})
		end
		task.wait(1)
	end
end

function RoundService:StartIntermission()
	for i = Config.INTERMISSION_TIME, 1, -1 do
		-- Check if we still have enough players
		if not Config.PLAYTESTING_MODE and #Players:GetPlayers() < Config.MIN_PLAYERS_TO_START then
			return false
		end

		for _, player in ipairs(Players:GetPlayers()) do
			NetworkService:SendUIEvent(player, {
				uiType = UIType.Intermission,
				timeLeft = i,
			})
		end
		task.wait(1)
	end

	return true
end

function RoundService:ChooseMap()
	self:InitMap()
	if not currentMap then 
		warn("Could not find map") 
		return false
	end

	for i = Config.MAP_DISPLAY_TIME, 1, -1 do
		-- Check if we still have enough players
		if not Config.PLAYTESTING_MODE and #Players:GetPlayers() < Config.MIN_PLAYERS_TO_START then
			return false
		end

		for _, player in ipairs(Players:GetPlayers()) do
			NetworkService:SendUIEvent(player, {
				uiType = UIType.MapDisplay,
				mapName = currentMap.Name,
			})
		end
		task.wait(1)
	end

	return true
end

function RoundService:StartRound()
	-- Final check before starting round
	if not Config.PLAYTESTING_MODE and #Players:GetPlayers() < Config.MIN_PLAYERS_TO_START then
		gameActive = false
		return
	end
	
	gameActive = true
	currentGameStartTime = tick()

	-- Setup
	self:InitPlayers()
	TeleportService:TeleportPlayersToMap(currentMap)

	-- Disaster cycle loop
	while gameActive do
		self:StartDisasterCycle()
		if not self:CheckRoundConditions() then 
			break 
		end
		task.wait(0.1)
	end
end

function RoundService:EndRound()
	gameActive = false

	-- Teleport and show results
	TeleportService:TeleportPlayersToLobby()
	local resultsTable = self:HandleResults()

	for _, player in ipairs(Players:GetPlayers()) do
		if player and player.Character then
			NetworkService:SendUIEvent(player, {
				uiType = UIType.RoundOver,
				results = resultsTable,
			})
		end
	end
	
	-- Update winner stand
	--self:UpdateWinnerStand(resultsTable[1])

	-- Cleanup
	StateService:ResetAllStates()
	TweenerService:ResetPlayerTweenEffects()
	DisasterService:ResetDisasters(currentMap)
	self:CleanUpMap()

	currentRound = 0
	currentPlayersThisGame = {}

	task.wait(Config.WINNER_DISPLAY_TIME)
end

---------------------------------------------------------------------------
-- DISASTER MANAGEMENT
---------------------------------------------------------------------------

function RoundService:StartDisasterCycle()
	if not gameActive then return end
	
	local numPlayersAlive = #self:GetPlayersInRound()
	
	-- Choose and initialize disaster
	currentDisaster = DisasterService:ChooseRandomDisaster(numPlayersAlive)
	if not currentDisaster then 
		warn("Could not find disaster") 
		return 
	end
	
	DisasterService:InitializeDisaster(currentDisaster, currentMap)
	currentRound += 1

	-- Calculate countdown time (gets shorter each round)
	local countdownTime = math.max(
		Config.MAX_DISASTER_CHANGE_TIME - currentRound, 
		Config.MIN_DISASTER_CHANGE_TIME
	)
	
	-- Countdown before disaster starts
	for i = countdownTime, 1, -1 do
		if not gameActive then break end
		
		-- Start freeze effect only when countdown reaches 5
		if i == 3 then
			local playersInRound = self:GetPlayersInRound()
			TweenerService:FadeFreezeEffect(playersInRound, 5)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			NetworkService:SendUIEvent(player, {
				uiType = UIType.NewDisasterStarting,
				timeLeft = i,
				disasterType = currentDisaster.Name,
			})
		end
		task.wait(1)
	end

	self:StartNewDisaster()
end

function RoundService:StartNewDisaster()
	if not gameActive then return end

	-- Start disaster
	MovementService:FreezePlayers()
	
	-- Send audio of freeze to all players
	local playersInRound = self:GetPlayersInRound()
	for _, player in ipairs(playersInRound) do
		NetworkService:SendSoundEffect(player, {soundType = SoundType.Freeze})
	end
	
	DisasterService:StartDisaster(currentDisaster, currentMap)

	-- Disaster duration countdown
	for i = currentDisaster.Duration, 1, -1 do
		if not gameActive then break end

		for _, player in ipairs(Players:GetPlayers()) do
			NetworkService:SendUIEvent(player, {
				uiType = UIType.DisasterInProgress,
				timeLeft = i,
			})
		end
		task.wait(1)
	end
	
	-- Tokens to add to all surviving players
	local tokensToAdd = self:CalculateTokensForRound()

	-- Update rounds stats for all players (local and datastore data)
	for player, data in pairs(currentPlayersThisGame) do
		if player and player.Character and StateService:GetState(player, StateDefinitions.PLAYING) then
			data.RoundsSurvived = currentRound
			
			-- Update round survivals
			local success, err = pcall(function()
				DataService.UpdateRoundSurvivals(player, currentDisaster)
			end)
			if not success then
				warn("Failed to update round survivals for " .. player.Name .. ": " .. err)
			end
			
			-- Update tokens
			local success, err = pcall(function()
				DataService.AddTokens(player, tokensToAdd, "Round Survived")
			end)
			if not success then
				warn("Failed to update tokens for " .. player.Name .. ": " .. err)
			end
		end
	end

	-- End disaster
	DisasterService:EndDisaster(currentDisaster, currentMap)
	currentDisaster = nil
	MovementService:UnfreezePlayers()
	
	-- Fade out the freeze visual effect for players
	local playersInRound = self:GetPlayersInRound()
	TweenerService:FadeUnfreezeEffect(playersInRound, 0.5)
end

---------------------------------------------------------------------------
-- GAME CONDITIONS
---------------------------------------------------------------------------

function RoundService:CheckRoundConditions()
	if not gameActive then return false end

	local playersInGame = 0
	local playersAlive = 0

	-- Count players in this game
	for player in pairs(currentPlayersThisGame) do
		if player then
			playersInGame += 1
		end
	end

	-- Count alive players
	for _, player in ipairs(Players:GetPlayers()) do
		if player and StateService:GetState(player, StateDefinitions.PLAYING) then
			playersAlive += 1
		end
	end

	-- PLAYTESTING MODE: Single player never ends until they die
	if Config.PLAYTESTING_MODE and playersInGame == 1 then
		return playersAlive > 0
	end

	-- Normal mode: End when too few players remain
	print("Players alive:", playersAlive)
	return playersAlive > Config.MIN_PLAYERS_TO_END
end

---------------------------------------------------------------------------
-- RESULTS & SCORING
---------------------------------------------------------------------------

function RoundService:HandleResults()
	local survivors = {}
	local dead = {}

	-- Categorize players
	for player, data in pairs(currentPlayersThisGame) do
		if not player or not player.Character then continue end

		local entry = {
			Player = player,
			Name = player.Name,
			Image = PlayerImages[player.UserId],
			RoundsSurvived = data.RoundsSurvived,
			DeathTime = data.DeathTime,
			TokensEarned = self:CalculateTokensForGame(data.RoundsSurvived),
		}

		if data.DeathTime == 0 and player.Character and StateService:GetState(player, StateDefinitions.PLAYING) then
			table.insert(survivors, entry)
		else
			table.insert(dead, entry)
		end
	end

	-- Sort dead players by death time (latest death = higher rank)
	table.sort(dead, function(a, b)
		return a.DeathTime > b.DeathTime
	end)

	-- Build final results table
	local results = {}
	local rank = 1

	-- Add survivors (they win)
	for _, entry in ipairs(survivors) do
		entry.Rank = rank
		rank += 1
		
		-- Add tokens for winnings
		entry.TokensEarned += Config.TOKENS_FOR_WINNING
		
		local success, err = pcall(function()
			DataService.AddWin(entry.Player)
			DataService.AddTokens(entry.Player, Config.TOKENS_FOR_WINNING, "Won Game")
		end)
		
		if not success then
			warn("Failed to add win for player:", entry.Player.Name, err)
		end
		
		table.insert(results, entry)
	end

	-- Add dead players
	for _, entry in ipairs(dead) do
		-- If no survivors, last person alive wins
		if rank == 1 then
			-- Add tokens for winning
			entry.TokensEarned += Config.TOKENS_FOR_WINNING
			
			local success, err = pcall(function()
				DataService.AddWin(entry.Player)
				DataService.AddTokens(entry.Player, Config.TOKENS_FOR_WINNING, "Won Game")
			end)

			if not success then
				warn("Failed to add win for player:", entry.Player.Name, err)
			end
		end
		entry.Rank = rank
		rank += 1
		table.insert(results, entry)
	end

	return results
end

function RoundService:UpdateWinnerStand(winner)
	if not winner or not winner.Player then return end

	-- Clear old winner if exists
	local existingWinner = winnerStand:FindFirstChildOfClass("Model")
	if existingWinner then
		existingWinner:Destroy()
	end

	-- Clone new winner rig
	local winnerClone = winnerRig:Clone()
	winnerClone.Parent = winnerStand

	local rootPart = winnerClone:FindFirstChild("HumanoidRootPart")
	local humanoid = winnerClone:FindFirstChild("Humanoid")

	if rootPart and humanoid then
		-- Get spawn position
		local spawnCFrame = winnerStand.CharacterSpawn.CFrame

		-- Offset by hip height so feet are on the ground
		local heightOffset = humanoid.HipHeight
		local offsetCFrame = spawnCFrame + Vector3.new(0, heightOffset, 0)

		rootPart.CFrame = offsetCFrame
		
		rootPart.Anchored = true
		
		-- Update winner text
		winnerStandText.Text = winner.Player.Name

		-- Apply winner's appearance
		task.spawn(function()
			local success, winnerDesc = pcall(function()
				return Players:GetHumanoidDescriptionFromUserIdAsync(winner.Player.UserId)
			end)

			if success and winnerDesc then
				humanoid:ApplyDescriptionAsync(winnerDesc)
			else
				warn("Failed to get description for winner:", winner.Player.Name)
			end
		end)
	end
end

---------------------------------------------------------------------------
-- PLAYER MANAGEMENT
---------------------------------------------------------------------------

function RoundService:InitPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and humanoid.Health > 0 then
			StateService:ChangeState(player, StateDefinitions.PLAYING, true)
			StateService:AddForceField(player)

			currentPlayersThisGame[player] = {
				RoundsSurvived = 0,
				DeathTime = 0,
			}
		end
	end
end

function RoundService:OnCharacterAdded(player, character)
	self:HandleDeath(player, character)
	self:HandleLateJoin(player)
	self:GetPlayerImage(player)
end

function RoundService:HandleLateJoin(player)
	-- Only allow late joins if game just started
	if currentRound == 0 or not currentMap then return end

	local timeSinceStart = tick() - currentGameStartTime
	if timeSinceStart >= Config.LATE_JOIN_THRESHOLD then return end

	local isPlaying = StateService:GetState(player, StateDefinitions.PLAYING)
	if isPlaying then return end

	-- Validate player state
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Add player to game
	print("Late joiner detected:", player.Name)
	StateService:ChangeState(player, StateDefinitions.PLAYING, true)
	StateService:AddForceField(player)

	currentPlayersThisGame[player] = {
		RoundsSurvived = 0,
		DeathTime = 0,
	}

	TeleportService:TeleportPlayerToMap(player, currentMap)
end

function RoundService:HandlePlayerRemoving(player)
	-- If player was in active game
	if gameActive and currentPlayersThisGame[player] and StateService:GetState(player, StateDefinitions.PLAYING) then
		-- Mark as dead
		currentPlayersThisGame[player].DeathTime = tick()

		-- Check if round should end
		gameActive = self:CheckRoundConditions()
	end
end

function RoundService:HandleDeath(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		if gameActive and currentPlayersThisGame[player] and StateService:GetState(player, StateDefinitions.PLAYING) then
			-- Mark death time
			currentPlayersThisGame[player].DeathTime = tick()
			StateService:ResetStates(player)
			
			-- Update player data store stats
			local success, err = pcall(function()
				DataService.UpdateRoundDeaths(player, currentDisaster)
			end)
			
			if not success then
				warn("Failed to update round deaths for", player.Name, ":", err)
			end

			-- Check if round should end
			gameActive = self:CheckRoundConditions()
			
			-- Send death notification to all clients
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				NetworkService:SendUIEvent(otherPlayer, {
					uiType = UIType.DeathFeed,
					playerName = player.Name,
				})
			end
		else
			StateService:ResetStates(player)
		end
	end)
end

function RoundService:GetPlayerImage(player)
	local success, image = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
		)
	end)

	PlayerImages[player.UserId] = success and image or "rbxassetid://0"

	if not success then
		warn("Failed to get thumbnail for", player.Name)
	end
end

-- Helper function to get players in the current round
function RoundService:GetPlayersInRound()
	local playersInGame = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if StateService:GetState(player, StateDefinitions.PLAYING) then
			table.insert(playersInGame, player)
		end
	end
	return playersInGame
end

-- Helper function to calculate tokens for a specific round (roundNumber optional; uses currentRound if nil)
function RoundService:CalculateTokensForRound(roundNumber)
	local round = roundNumber or currentRound
	return (round * Config.TOKEN_RATE) + Config.BASE_TOKENS_PER_ROUND
end

-- Helper function to calculate total tokens earned across all rounds in a game
function RoundService:CalculateTokensForGame(roundsSurvived)
	local tokens = 0
	for roundNum = 1, roundsSurvived do
		tokens += self:CalculateTokensForRound(roundNum)
	end
	return tokens
end

---------------------------------------------------------------------------
-- MAP MANAGEMENT
---------------------------------------------------------------------------

function RoundService:InitMap()
	local maps = ServerStorage.Maps:GetChildren()
	if #maps == 0 then 
		warn("No maps found") 
		return 
	end

	-- Choose random map
	local selectedMap = maps[math.random(1, #maps)]
	--local selectedMap = ServerStorage.Maps["Research Center"] -- For testing specific map

	local map = selectedMap:Clone()
	map.Parent = workspace
	currentMap = map
end

function RoundService:CleanUpMap()
	if currentMap then
		currentMap:Destroy()
		currentMap = nil
	end
end


---------------------------------------------------------------------------
-- START SERVICE
---------------------------------------------------------------------------
RoundService:Init()

return RoundService