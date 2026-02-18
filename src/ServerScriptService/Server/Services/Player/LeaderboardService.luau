----------------------------------------
-- LEADERBOARD SERVICE
-- @carsondev7
----------------------------------------


-- SERVICES --
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- MODULES --
local DataService = require(game.ServerScriptService.Server.Services.Player.DataService)

-- VARIABLES --
local globalWinsDatastore = DataStoreService:GetOrderedDataStore("WinsTest2")
local globalWinsLeaderboard = game.Workspace.Lobby.GlobalWinsLeaderboard
local globalWinsContainer = globalWinsLeaderboard.Leaderboard.ContainerGui.ContainerFrame
local globalWinsRefreshLabel = globalWinsLeaderboard.Leaderboard.ContainerGui.RefreshLabel

local donationsDatastore = DataStoreService:GetOrderedDataStore("DonationsTest2")
local donationLeaderboard = game.Workspace.Lobby.DonationLeaderboard
local donationContainer = donationLeaderboard.Leaderboard.ContainerGui.ContainerFrame
local donationRefreshLabel = donationLeaderboard.Leaderboard.ContainerGui.RefreshLabel


local localWinsLeaderboard = game.Workspace.Lobby.WinsLeaderboard
local localWinsContainer = localWinsLeaderboard.Leaderboard.ContainerGui.ContainerFrame
local localWinsRefreshLabel = localWinsLeaderboard.Leaderboard.ContainerGui.RefreshLabel	


local REFRESH_INTERVAL = 60 -- 1 minute

local LeaderboardService = {}

-- templates
local playerLeaderboardTemplate = ReplicatedStorage:WaitForChild("GUI"):WaitForChild("PlayerLeaderboardTemplate")


function LeaderboardService:UpdateGlobalLeaderboard(dataStore, container)
	local success, errorMessage = pcall(function()
		local data = dataStore:GetSortedAsync(false, 10) -- top 10 players
		local currPage = data:GetCurrentPage()
		
		for rank, currData in ipairs(currPage) do
			local userId = tonumber(currData.key)

			-- Skip negative UserIds (local test players)
			if userId and userId > 0 then

				local success, userName = pcall(function()
					return game.Players:GetNameFromUserIdAsync(userId)
				end)

				if success and userName then

					local name = userName
					local value = currData.value
					local isOnLeaderboard = false

					for _, v in pairs(container:GetChildren()) do
						if v:IsA("Frame") and v:FindFirstChild("PlayerName") and v.PlayerName.Text == name then
							isOnLeaderboard = true
							break
						end
					end

					if value and not isOnLeaderboard then
						local newLeaderboardFrame = playerLeaderboardTemplate:Clone()
						newLeaderboardFrame:FindFirstChild("PlayerName").Text = name
						newLeaderboardFrame:FindFirstChild("Value").Text = value
						newLeaderboardFrame:FindFirstChild("Rank").Text = "#" .. rank

						-- Alternate transparency based on rank
						if rank % 2 == 0 then
							newLeaderboardFrame.BackgroundTransparency = 0.5
						end

						newLeaderboardFrame.Parent = container
					end
				else
					warn("Failed to get username for UserId: " .. tostring(userId))
				end
			else
				warn("Skipping invalid or local test player UserId: " .. tostring(userId))
			end
		end
	end)

	if not success then
		warn("Leaderboard update failed: " .. tostring(errorMessage))
	end
end

function LeaderboardService:UpdateLocalLeaderboard(container)
	local sortedData = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		if player and player.Character then
			local profile = DataService:GetProfile(player)
			if profile then
				table.insert(sortedData, {player = player, wins = profile.Data.Wins})
			end
		end
	end
	
	-- Sort player data on wins
	table.sort(sortedData, function(a, b)
		return a.wins > b.wins
	end)
	
	local rank = 1
	
	for _, playerData in ipairs(sortedData) do
		local player = playerData.player
		local wins = playerData.wins
		
		local isOnLeaderboard = false
		
		if not player or not wins then continue end
		
		for _, v in pairs(container:GetChildren()) do
			if v:IsA("Frame") and v:FindFirstChild("PlayerName") and v.PlayerName.Text == player.Name then
				isOnLeaderboard = true
				break
			end
		end

		if not isOnLeaderboard then
			local newLeaderboardFrame = playerLeaderboardTemplate:Clone()
			newLeaderboardFrame:FindFirstChild("PlayerName").Text = player.Name
			newLeaderboardFrame:FindFirstChild("Value").Text = wins
			newLeaderboardFrame:FindFirstChild("Rank").Text = "#" .. rank

			-- Alternate transparency based on rank
			if rank % 2 == 0 then
				newLeaderboardFrame.BackgroundTransparency = 0.5
			end

			newLeaderboardFrame.Parent = container
		end
		
		rank += 1
	end
end


function LeaderboardService:Start()
	while true do
		-- update all data stores
		for _, player in pairs(Players:GetPlayers()) do
			-- Skip local test players
			if player.UserId > 0 then
				-- wins datastore
				local profile = DataService:GetProfile(player)
				if profile then
					local wins = profile.Data.Wins
					if wins and wins > 0 then
						globalWinsDatastore:SetAsync(player.UserId, wins)
					end
					
					local donated = profile.Data.Donated
					if donated and donated > 0 then
						donationsDatastore:SetAsync(player.UserId, donated)
					end
				end
			else
				warn("Skipping local test player: " .. player.Name)
			end
		end

		-- remove all previous frames
		for _, child in pairs(globalWinsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		for _, child in pairs(donationContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		for _, child in pairs(localWinsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	
		task.spawn(function()
			-- update global leaderboards
			self:UpdateGlobalLeaderboard(globalWinsDatastore, globalWinsContainer)
			self:UpdateGlobalLeaderboard(donationsDatastore, donationContainer)

			-- update local leaderboard
			self:UpdateLocalLeaderboard(localWinsContainer)
		end)
		
		-- Update refresh labels then update leaderboards
		for i = REFRESH_INTERVAL, 1, -1 do
			-- Update refresh timers for leaderboards
			localWinsRefreshLabel.Text = "Refreshing in " .. i .. "s"
			globalWinsRefreshLabel.Text = "Refreshing in " .. i .. "s"
			donationRefreshLabel.Text = "Refreshing in " .. i .. "s"
			task.wait(1)
		end
	end
end

task.spawn(function()
	LeaderboardService:Start()
end)
return LeaderboardService
