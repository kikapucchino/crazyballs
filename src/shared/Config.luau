-- Public tuning only. Outcomes, decks, and hidden selections live on the server.
return {
	Title = "Cloudpop Commons",
	Build = "0.3.0",
	DataStoreName = "CloudpopProfiles_v1",
	IntermissionSeconds = 15,
	DrawSeconds = 4,
	DrawCount = 20,
	ResultsSeconds = 10,
	NumberPool = 60,
	-- Two dealt cards are confirmed. The center is numbered while free-center/pattern rules remain pending.
	Main = { Count = 2, Grid = 5, FreeCenter = false, Patterns = {}, CardsEnabled = true, RewardsConfirmed = false,
		-- Relative integer weights. All 20 outcomes have weight 1 => exactly 5% each.
		MultiplierWeights = { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 },
	},
	Rewards = { Participation = 20 }, -- Existing participation reward, not a bonus multiplier.
	BonusBasePesos = 20,
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
		Music = { lobby = "", coin = "", duck = "", pacinki = "", crazy = "" },
		SFX = { draw = "", mark = "", qualify = "", reveal = "", result = "" },
	},
	Catalog = {
		{ id = "marker_sun", name = "Sunbeam", category = "marker", price = 0, color = { 255, 199, 88 }, description = "A warm golden stamp" },
		{ id = "marker_berry", name = "Berry pop", category = "marker", price = 60, color = { 236, 128, 166 }, description = "A berry-pink stamp" },
		{ id = "marker_mint", name = "Mint breeze", category = "marker", price = 60, color = { 112, 222, 183 }, description = "A mint-green stamp" },
		{ id = "card_cloud", name = "Cloud ice", category = "card", price = 0, color = { 222, 239, 255 }, description = "An icy blue card frame" },
		{ id = "card_lilac", name = "Lilac post", category = "card", price = 150, color = { 233, 222, 252 }, description = "A lavender card frame" },
		{ id = "card_sea", name = "Sea glass", category = "card", price = 150, color = { 174, 232, 240 }, description = "A sea-blue card frame" },
	},
}
