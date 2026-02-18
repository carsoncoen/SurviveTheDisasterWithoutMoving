return {
    -- Main data
	Wins = 0,
	Donated = 0,
	Tokens = 0,
	
	-- Inventory (Hotbar: 1..10 = itemId or nil; Consumables/Gear/Cosmetics as before)
	Inventory = {
		Consumables = {},
		Gear = {},
		Cosmetics = {},
		EquippedCosmetics = {},
		Hotbar = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }, -- 10 slots
	},
	
	
	-- Extra stats
	RoundsSurvived = 0,
	SurvivalsByDisaster = {
		["Acid Rain"] = 0,
		["Flood"] = 0,
		["Fire"] = 0,
		["Lightning Storm"] = 0,
		["Meteor Strike"] = 0,
		["Plague"] = 0,
		["Tsunami"] = 0,
		["Wind Storm"] = 0,
		["Blackhole"] = 0,
		["Tornado"] = 0,
	},
	DeathsByDisaster = {
		["Acid Rain"] = 0,
		["Flood"] = 0,
		["Fire"] = 0,
		["Lightning Storm"] = 0,
		["Meteor Strike"] = 0,
		["Plague"] = 0,
		["Tsunami"] = 0,
		["Wind Storm"] = 0,
		["Blackhole"] = 0,
		["Tornado"] = 0,
	},
}