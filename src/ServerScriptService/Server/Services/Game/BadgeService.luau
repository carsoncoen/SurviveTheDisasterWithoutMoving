----------------------------------------
-- BADGE SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BS = game:GetService("BadgeService")

-- MODULES --
local DataService = require(script.Parent.Parent.Player.DataService)

-- VARIABLES --
local BadgeService = {}

BadgeService.badgeAssetIds = {
	PlayTester = "2136872103763951",
	Supporter = "4128222154169333",
}


--------------------------------------------------------------------------------
-- BADGE FUNCTIONS
--------------------------------------------------------------------------------

-- Listen for badges
function BadgeService:AwardBadge(player, badgeId)
	local success, result = pcall(function()
		if not BS:UserHasBadgeAsync(player.UserId, badgeId) then
			BS:AwardBadgeAsync(player.UserId, badgeId)
		end
	end)
	if not success then
		warn("Failed to award badge: " .. tostring(result))
	end
	return success
end


-- Award players badges for join events
function BadgeService:ListenForJoins()
	Players.PlayerAdded:Connect(function(player)
		-- Award play tester badges 
		if not BS:UserHasBadgeAsync(player.UserId, self.badgeAssetIds.PlayTester) then
			BS:AwardBadgeAsync(player.UserId, self.badgeAssetIds.PlayTester)
			print("Awarded play tester badge to " .. player.Name)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	-- phantom
	if player.UserId == 4676059716 then
		-- Award supporter badges to these folk
		if not BS:UserHasBadgeAsync(player.UserId, BadgeService.badgeAssetIds.Supporter) then
			BS:AwardBadgeAsync(player.UserId, BadgeService.badgeAssetIds.Supporter)
		end
	end
	
end)


BadgeService:ListenForJoins()
return BadgeService
