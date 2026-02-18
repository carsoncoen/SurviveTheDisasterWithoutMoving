----------------------------------------
-- SHARED ANIMATION SERVICE MODULE SCRIPT 
-- @carsondev7
----------------------------------------

----------------------------
-- SERVICES --
----------------------------

----------------------------
-- VARIABLES --
----------------------------

local AnimationService = {}
local activeTracks = {} -- [player][animation] = AnimationTrack




-- CONSTANTS --


----------------------------
-- PRIVATE FUNCTIONS --
----------------------------


----------------------------
-- PUBLIC FUNCTIONS --
----------------------------

local function getAnimator(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end


function AnimationService:PlayAnimation(player: Player, animation: Animation)
	if not player or not animation then return end
	
	if AnimationService:IsTrackPlaying(player, animation) then return end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	activeTracks[player] = activeTracks[player] or {}

	-- Reuse track if already loaded
	if activeTracks[player][animation] then
		activeTracks[player][animation]:Play()
		return
	end

	local animator = getAnimator(humanoid)
	local track = animator:LoadAnimation(animation)

	activeTracks[player][animation] = track
	track:Play()
end


function AnimationService:StopAnimation(player: Player, animation: Animation)
	if not activeTracks[player] then return end
	local track = activeTracks[player][animation]
	if not track then return end

	track:Stop()
end

-- Check if a track is playing
function AnimationService:IsTrackPlaying(player: Player, animation: Animation)
	if not activeTracks[player] then return false end
	local track = activeTracks[player][animation]
	if not track then return false end
	return track.IsPlaying
end


----------------------------
-- MAIN --
----------------------------

return AnimationService
