----------------------------------------------------------------------------------------------------------------------------
-- START CLIENT SCRIPT 
-- @carsondev7
----------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local StarterPlayer = game:GetService("StarterPlayer")

------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local handlersFolder = StarterPlayer.StarterPlayerScripts.Client.Handlers
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- MODULES --

------------------------------------------------------------
-- PRIVATE FUNCTIONS --
------------------------------------------------------------
local function safeRequire(moduleScript)
	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn("[Init] Failed to load module:", moduleScript:GetFullName())
		warn(result)
	end
	return ok, result
end


-- Initiate every client module script handler
function Init()
	for _, categoryFolder in pairs(handlersFolder:GetChildren()) do
		if categoryFolder:IsA("Folder") then
			for _, handler in pairs(categoryFolder:GetChildren()) do
				if handler:IsA("ModuleScript") then
					safeRequire(handler)
				end
			end
		end
	end
end

------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
Init()