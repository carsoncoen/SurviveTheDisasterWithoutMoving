----------------------------------------------------------------------------------------------------------------------------
-- DATA SERVICE MODULE SCRIPT 
-- @carsondev7
----------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local DataService = {}

-- MODULES --
local ProfileStore = require(script.Parent.ProfileStore)
local PlayerStoreTemplate = require(script.Parent.ProfileStoreTemplate)
local NetworkService = require(ServerScriptService.Server.Services.Networking.NetworkService)

-- ENUMS --
local UIType = require(ReplicatedStorage.Shared.Modules.Enums.UIType)
local SoundType	= require(ReplicatedStorage.Shared.Modules.Enums.SoundType)



DataService.Profiles = {} -- Player data

-- CONSTANTS --



------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------


-- Initialize player leaderstats and synchronize player data
local function _initializePlayer(player: Player, profile)
    -- Leaderstats
    local leaderstats = Instance.new("Folder", player)
    leaderstats.Name = "leaderstats"
	
    local wins = Instance.new("NumberValue")
	wins.Name = "Wins"
	wins.Value = profile.Data.Wins
	wins.Parent = leaderstats
	
	-- Reset inventory for now (Hotbar preserved by template/reconcile; reset if you clear inventory)
	profile.Data.Inventory.Consumables = {}
	profile.Data.Inventory.Gear = {}
	profile.Data.Inventory.Cosmetics = {}
	profile.Data.Inventory.EquippedCosmetics = {}
	if not profile.Data.Inventory.Hotbar then
		profile.Data.Inventory.Hotbar = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }
	end
	
	
	-- Update ui
	NetworkService:SendUIEvent(player, {
		uiType = UIType.UpdateTokens,		-- UI Type
		totalTokens = profile.Data.Tokens,	-- Total tokens
	})
end

-- Creates and stores player profile
local function _playerAdded(player: Player, PlayerStore)
    local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
        Cancel = function()
            return player.Parent ~= Players
        end
    })

    -- Sanity check for player existence
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GGPR compliance
        profile:Reconcile() -- Fill in missing data variables from template (if template changes between sessions)

        -- Player left/joined different server (session locking)
        profile.OnSessionEnd:Connect(function()
            DataService.Profiles[player] = nil
            player:Kick("Data error occured. Please rejoin.")
        end)

        -- Confirmed profile exists --> store player data
        if player.Parent == Players then
            DataService.Profiles[player] = profile
            _initializePlayer(player, profile) -- Initialize player leaderstats
        else
            profile:EndSession() 
        end
    else
        player:Kick("Data error occured. Please rejoin.")
    end
end

-- Remove player profile
local function _playerRemoving(player: Player)
    local profile = DataService.Profiles[player]
    if not profile then return end -- Validate profile

    profile:EndSession() -- End player profile session
    DataService.Profiles[player] = nil -- Clear profile memory
end

------------------------------------------------------------
-- PUBLIC FUNCTIONS --
------------------------------------------------------------

function DataService:Init()
    -- Initialize player data store
	local PlayerStore = ProfileStore.New(self:GetStoreName(), PlayerStoreTemplate)
    
	Players.PlayerAdded:Connect(function(player)
        _playerAdded(player, PlayerStore)
    end)

    Players.PlayerRemoving:Connect(function(player)
        _playerRemoving(player)
    end)
end

-- Return the name of the correct data store given the player circumstance
function DataService:GetStoreName()
    return RunService:IsStudio() and "Test1" or "LiveTest1"
end


-- Helper functions for getting / updating player data

-- Wait for profile to be loaded and then return it (times out after 15 seconds)
local PROFILE_LOAD_TIMEOUT = 15
function DataService:GetProfile(player: Player)
	local deadline = os.clock() + PROFILE_LOAD_TIMEOUT
	while not self.Profiles[player] do
		if os.clock() >= deadline then
			warn("[DataService] GetProfile timed out for", player.Name)
			return nil
		end
		task.wait()
	end
	return self.Profiles[player]
end


-- Add coins to player
function DataService.AddWin(player: Player)
	if not player then return end

	local profile = DataService:GetProfile(player)
	if not profile then return end

	profile.Data.Wins += 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Wins.Value = profile.Data.Wins
	end
end

-- Add donation to player
function DataService.AddDonation(player: Player, donatedAmount: number)
	if not player then return end

	local profile = DataService:GetProfile(player)
	if not profile then return end

	profile.Data.Donated += donatedAmount
end

-- Add tokens to player
function DataService.AddTokens(player: Player, tokenAmount: number, reason: string)
	if not player then return end

	local profile = DataService:GetProfile(player)
	if not profile then return end

	profile.Data.Tokens += tokenAmount
	NetworkService:SendUIEvent(player, {
		uiType = UIType.UpdateTokens,
		totalTokens = profile.Data.Tokens,
		tokenAmount = tokenAmount,
		reason = reason,
		tokenType = "Add",
	})
	NetworkService:SendSoundEffect(player, { soundType = SoundType.AddTokens })
end

-- Remove tokens from player
function DataService.RemoveTokens(player: Player, tokenAmount: number, reason: string)
	if not player then return end

	local profile = DataService:GetProfile(player)
	if not profile then return end

	profile.Data.Tokens -= tokenAmount
	NetworkService:SendUIEvent(player, {
		uiType = UIType.UpdateTokens,
		totalTokens = profile.Data.Tokens,
		tokenAmount = tokenAmount,
		reason = reason,
		tokenType = "Remove",
	})
	NetworkService:SendSoundEffect(player, { soundType = SoundType.Purchase })
end

-- Update player's round survivals
function DataService.UpdateRoundSurvivals(player: Player, currentDisaster)
	if not player or not currentDisaster then return end

	local profile = DataService:GetProfile(player)
	if not profile then return end

	if profile.Data.SurvivalsByDisaster[currentDisaster.Name] then
		profile.Data.RoundsSurvived += 1
		profile.Data.SurvivalsByDisaster[currentDisaster.Name] += 1
	end
end

function DataService.UpdateRoundDeaths(player: Player, currentDisaster)
	if not player or not currentDisaster then return end

	local profile = DataService:GetProfile(player)
	if not profile then return end

	if profile.Data.DeathsByDisaster[currentDisaster.Name] then
		profile.Data.DeathsByDisaster[currentDisaster.Name] += 1
	end
end



------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
DataService:Init()


return DataService