------------------------------------------------------------
-- ASSET LOADER HANDLER MODULE SCRIPT 
-- @carsondev7
------------------------------------------------------------

------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

------------------------------------------------------------
-- MODULES --
------------------------------------------------------------
local PreloadService = require(ReplicatedStorage.Shared.Modules.Services.Init.PreloadService)

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local AssetLoader = {}

-- UI REFERENCES --
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------


------------------------------------------------------------
-- PUBLIC FUNCTIONS --
------------------------------------------------------------
function AssetLoader:Init()
	-- Preload critical assets before allowing player control
	--_safeSetCore("ResetButtonCallback", false) -- Disable player resetting

	-- Start preloading
	PreloadService:PreloadAssets(function(loaded, total, asset)
		--LoadingScreenUIHandler:UpdateAssetCounter(loaded, total)
		print(`[PRELOAD] {loaded}/{total}: {asset}`)
	end)


	self:Finished()
end


function AssetLoader:Finished()
	print("GameInit complete.")
end


------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
AssetLoader:Init()

return AssetLoader
