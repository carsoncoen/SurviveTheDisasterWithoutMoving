----------------------------------------
-- SHARED PRELOAD SERVICE MODULE
-- @carsondev7
----------------------------------------

----------------------------
-- SERVICES --
----------------------------
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local PreloadService = {}

-- ASSET FOLDERS --
local animationsFolder = ReplicatedStorage:WaitForChild("Animations")
local soundsFolder = SoundService:WaitForChild("SoundEffects")

-- List of folders containing assets to preload
local assetFolders = {
	animationsFolder,
	soundsFolder,
}

----------------------------
-- PUBLIC FUNCTIONS --
----------------------------

function PreloadService:PreloadAssets(callback)
	-- Flatten all assets inside the folders
	local assetsToPreload = {}
	for _, folder in ipairs(assetFolders) do
		for _, subFolder in ipairs(folder:GetDescendants()) do
			for _, asset in ipairs(subFolder:GetDescendants()) do
				-- Only preload instances that can actually be loaded
				if asset:IsA("Instance") then
					table.insert(assetsToPreload, asset)
				end
			end
		end
	end

	local total = #assetsToPreload
	local loaded = 0

	ContentProvider:PreloadAsync(assetsToPreload, function(assetId)
		loaded += 1
		if callback then
			callback(loaded, total, assetId)
		end
	end)
end

----------------------------
-- MAIN --
----------------------------
return PreloadService
