----------------------------------------------------------------------------------------------------------------------------
-- START SERVER SCRIPT 
-- @carsondev7
----------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------
-- SERVICES --
------------------------------------------------------------
local ServerScriptService = game:GetService("ServerScriptService")


------------------------------------------------------------
-- VARIABLES --
------------------------------------------------------------
local serviceFolder = ServerScriptService.Server.Services


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


-- Initiate every server module script service
function Init()
	for _, categoryFolder in pairs(serviceFolder:GetChildren()) do
		if categoryFolder:IsA("Folder") then
			for _, service in pairs(categoryFolder:GetChildren()) do
				if service:IsA("ModuleScript") then
					safeRequire(service)
				end
			end
		end
	end
end

------------------------------------------------------------
-- MAIN --
------------------------------------------------------------
Init()