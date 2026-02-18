----------------------------------------
-- SOUND EFFECTS SERVICE MODULE SCRIPT 
-- @carsondev7
----------------------------------------

----------------------------
-- SERVICES --
----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

----------------------------
-- MODULES --
----------------------------

----------------------------
-- VARIABLES --
----------------------------
local SoundEffectsHandler = {}

local player = Players.LocalPlayer
local soundEffectsEnabled = true

-- REMOTES --
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local soundEffectEvent = remoteEvents:WaitForChild("Audio"):WaitForChild("SoundEffect")

----------------------------
-- PRIVATE FUNCTIONS --
----------------------------

-- Pick random from list
local function _getRandomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

----------------------------
-- PUBLIC FUNCTIONS --
----------------------------

function SoundEffectsHandler.PlaySound(sound) -- Takes in list of possible sound effects for given event
    if not sound then return end

    -- Choose random sound from the "sound" list
    local randomSound = _getRandomSound(sound)
    if randomSound then
        if soundEffectsEnabled then
            -- Clone the sound so overlapping sounds don’t cut each other off
            local soundClone = randomSound:Clone()
            soundClone.Parent = player.Character
            soundClone:Play()

            -- Cleanup once finished
            soundClone.Ended:Connect(function()
                soundClone:Destroy()
            end)
        end
    else
        warn("[SoundEffectsHandler] Invalid sound type:", randomSound)
    end
end

-- Listen for server sound effect requests
soundEffectEvent.OnClientEvent:Connect(function(data)
	if not data or not data.soundType then return end
	
    SoundEffectsHandler.PlaySound(data.soundType)
end)

-- Toggle sound effects
function SoundEffectsHandler:SetSoundEffectsEnabled(value)
    soundEffectsEnabled = value
end


----------------------------
-- MAIN --
----------------------------
return SoundEffectsHandler
