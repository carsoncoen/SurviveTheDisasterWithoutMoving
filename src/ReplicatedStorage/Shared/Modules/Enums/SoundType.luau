------------------------------------------
-- SHARED SOUND TYPE ENUMS MODULE SCRIPT 
-- @carsondev7
------------------------------------------

-- SERVICES --
local SoundService = game:GetService("SoundService")

-- REFERENCES --
local soundEffects = SoundService.SoundEffects

return {
	-- Notification sounds
	Notification = {
	},
	
	-- UI sounds
	TimeTick = {
		soundEffects.UI.TimeTick,
	},
	Click = {
		soundEffects.UI.Click
	},
	AddTokens = {
		soundEffects.UI.AddTokens
	},
	Purchase = {
		soundEffects.UI.Purchase,
	},
	Invalid = {
		soundEffects.UI.Invalid,
	},
	
	-- Rounds
	Winner = {
		soundEffects.Rounds.Winner,
	},
	NoWinners = {
		soundEffects.Rounds.NoWinners,
	},
	
	-- Player effects
	Cough = {
		soundEffects.Player.Cough1,
		soundEffects.Player.Cough2,
		soundEffects.Player.Cough3,
	},
	Freeze = {
		soundEffects.Player.Freeze
	}
}
