-- Shared presentation and tuning. The server owns every outcome.
return {
	Title = "Cloudpop Commons",
	DataStoreName = "CloudpopProfiles_v1",
	IntermissionSeconds = 12,
	DrawSeconds = 5,
	DrawCount = 18,
	EventAfterDraw = 8,
	EventSeconds = 18,
	ResultsSeconds = 12,
	NumberPool = 24,
	Rewards = { Participation = 20, Pattern = 15, Objective = 10 },
	Goals = {
		trail = { name = "Number trail", description = "Mark 5 different numbers", short = "5 different numbers" },
		twins = { name = "Double delivery", description = "Mark the same number on both cards", short = "One number on both cards" },
	},
	Catalog = {
		{ id = "marker_sun", name = "Sunbeam", category = "marker", price = 0, color = { 255, 199, 88 }, description = "A warm golden stamp" },
		{ id = "marker_berry", name = "Berry pop", category = "marker", price = 60, color = { 236, 128, 166 }, description = "A soft berry-pink stamp" },
		{ id = "marker_mint", name = "Mint breeze", category = "marker", price = 60, color = { 112, 222, 183 }, description = "A fresh mint-green stamp" },
		{ id = "card_cloud", name = "Cloud cream", category = "card", price = 0, color = { 255, 248, 232 }, description = "The original cream card" },
		{ id = "card_lilac", name = "Lilac post", category = "card", price = 150, color = { 233, 222, 252 }, description = "A lavender card frame" },
		{ id = "card_sea", name = "Sea glass", category = "card", price = 150, color = { 205, 240, 228 }, description = "A sea-green card frame" },
	},
}
