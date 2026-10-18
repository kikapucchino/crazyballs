-- Public tuning only. Outcomes, decks, and hidden selections live on the server.
return {
	Title = "Cloudpop Commons",
	Build = "0.5.0",
	AutoMarkPass = { Id = 0, IntendedPrice = 60 },
	PaidBonusOffer = {Enabled=false,Id=0,IntendedPrice=99}, -- Three random bonuses across three consecutive rounds; policy/payouts unresolved, no purchase flow.
	Chest = { Permanent = true, ClaimRulesConfirmed = false, EffectEnabled = false, ResetMode = "", ResetOffsetSeconds = 0,
		RewardMode = "", RewardUnits = 0 },
	DataStoreName = "CloudpopProfiles_v1",
	IntermissionSeconds = 15,
	DrawSeconds = 4,
	DrawCount = 20,
	ResultsSeconds = 10,
	NumberPool = 60,
	-- Two free numbered 5x5 cards; every distinct row, column and diagonal can pay once.
	Main = { Count = 2, Grid = 5, StartingMarks = {Minimum=8,Maximum=12}, StartingPatternPolicy="pay", CardMultiplierEnabled=false, FreeCenter = false, Patterns = {"row","column","diagonal"}, LineBasePesos=15, CardsEnabled = true, RewardsConfirmed = true,
		MultiplierCells = {Enabled=true,Minimum=1,Maximum=2,Values={10,20,50},Stacking="replace"},
		-- Legacy distribution retained for compatibility; CardMultiplierEnabled=false disables it.
		MultiplierWeights = { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 },
	},
	Rewards = { Participation = 0 }, -- Removed by request: rewards come from completed lines/bonuses only.
	BonusBasePesos = 20,
	BonusStartingMarks = {MaximumTotal=8},
	Bonuses = {
		{ id = "coin", name = "Coin flip", count = 3, minimum = -50, maximum = 50, shared = true },
		{ id = "duck", name = "Duck hunt", count = 4, minimum = -100, maximum = 100, shared = false },
		{ id = "pacinki", name = "Pačinki", count = 4, minimum = -200, maximum = 200, shared = true },
		{ id = "crazy", name = "Go CRazy", count = 0, shared = true },
	},
	-- No distribution, timing, retrigger, or deduction policy is invented here.
	-- A future enablement must validate ALL of these and complete the policy review.
	BonusPayoutsEnabled = false,
	GoCRazy = { Segments = 64, PrizePointers = 3, Confirmed = false },
	Audio = {
		References = {lobby="https://youtu.be/8bTuNaVfNTE",bonusIntro="https://youtu.be/dzdTQrzWS_M"},
		-- References are not playable assets. Supply licensed, permitted Roblox IDs only.
		BonusIntroSeconds = 3,
		Music = { lobby = "", bonusIntro = "", coin = "", duck = "", pacinki = "", crazy = "" },
		SFX = { draw = "", mark = "", qualify = "", reveal = "", result = "" },
	},
	Catalog = {
		{ id="card_frost",name="Legendary Frostglass",category="card",payment="Robux",passId=0,price=0,color={170,214,255},description="A frost-blue card frame. Cosmetic only; no reward or odds change." },
		{ id="marker_aurora",name="Legendary Aurora",category="marker",payment="Robux",passId=0,price=0,color={99,222,240},glyph="★",description="Cyan star marks. Cosmetic only; no reward or odds change." },
		{ id="marker_moon",name="Legendary Moonlight",category="marker",payment="Robux",passId=0,price=0,color={226,242,255},glyph="✦",description="Icy four-point star marks. Cosmetic only; no reward or odds change." },
		{ id="pet_lumen", name="Lumen Loaf", category="pet", price=500, color={131,223,239}, description="A tiny lantern companion with soft sails" },
		{ id="pet_prism", name="Prismote", category="pet", price=500, color={179,176,244}, description="A curious cubic creature with orbiting beads" },
		{ id="pet_tassel", name="Tide Tassel", category="pet", price=500, color={127,201,183}, description="A sea-glass companion with three flowing ribbons" },
		{ id = "marker_sun", name = "Sunbeam", category = "marker", price = 0, color = { 255, 199, 88 }, description = "A warm golden stamp" },
		{ id = "marker_berry", name = "Berry pop", category = "marker", price = 60, color = { 236, 128, 166 }, description = "A berry-pink stamp" },
		{ id = "marker_mint", name = "Mint breeze", category = "marker", price = 60, color = { 112, 222, 183 }, description = "A mint-green stamp" },
		{ id = "card_cloud", name = "Cloud ice", category = "card", price = 0, color = { 222, 239, 255 }, description = "An icy blue card frame" },
		{ id = "card_lilac", name = "Lilac post", category = "card", price = 150, color = { 233, 222, 252 }, description = "A lavender card frame" },
		{ id = "card_sea", name = "Sea glass", category = "card", price = 150, color = { 174, 232, 240 }, description = "A sea-blue card frame" },
	},
}
