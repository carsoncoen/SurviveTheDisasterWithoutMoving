----------------------------------------
-- ANIMATION DEFINITIONS
-- @carsondev7
----------------------------------------

----------------------------------------
-- SERVICES
----------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES --
local animationsFolder = ReplicatedStorage:WaitForChild("Animations")


local Animations = {
	-- Disasters --
	Cough = animationsFolder.Player.Cough,
}

return Animations
