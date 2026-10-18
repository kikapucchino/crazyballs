local Rules = require("../src/shared/GameRules")
local Economy = require("../src/shared/Economy")
local Config = require("../src/shared/Config")
local passed = 0
local function test(name, callback)
	local ok, message = pcall(callback)
	assert(ok, name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end
math.randomseed(7313)
local function random(low, high) return math.random(low, high) end
local function board()
	local state = Rules.newCardState(24, random)
	state.cards = { { 1, 2, 3, 4, 5, 6, 7, 8, 9 }, { 1, 10, 11, 12, 13, 14, 15, 16, 17 } }
	return state
end

test("500 decks contain every number exactly once; cards have valid unique numbers and overlap", function()
	for _ = 1, 500 do
		local deck = Rules.shuffle(24, random)
		local seen = {}
		assert(#deck == 24)
		for _, number in ipairs(deck) do
			assert(Rules.isIndex(number, 24) and not seen[number])
			seen[number] = true
		end
		local state = Rules.newCardState(24, random)
		local first, common = {}, false
		for index, card in ipairs(state.cards) do
			local unique = {}
			assert(#card == 9)
			for _, number in ipairs(card) do
				assert(Rules.isIndex(number, 24) and not unique[number])
				unique[number] = true
				if index == 1 then first[number] = true elseif first[number] then common = true end
			end
		end
		assert(common)
	end
end)

test("undrawn, duplicate, out-of-range and malformed marks are rejected", function()
	local state = board()
	assert(not Rules.mark(state, {}, 1, 1))
	for _, bad in ipairs({ 0, -1, 10, math.huge, 0 / 0, "1", {}, true, 1.5 }) do
		assert(not Rules.mark(state, { [1] = true }, 1, bad))
		assert(not Rules.mark(state, { [1] = true }, bad, 1))
	end
	assert(not Rules.mark(state, { [1] = true }, nil, 1))
	assert(Rules.mark(state, { [1] = true }, 1, 1))
	assert(not Rules.mark(state, { [1] = true }, 1, 1))
end)

test("only complete horizontal rows claim; each card pays at most once", function()
	local state = board()
	local drawn = { [1] = true, [4] = true, [7] = true }
	Rules.markAll(state, drawn)
	assert(Rules.claimPatterns(state) == 0)
	drawn[2], drawn[3] = true, true
	Rules.markAll(state, drawn)
	assert(Rules.claimPatterns(state) == 1)
	assert(Rules.claimPatterns(state) == 0)
	drawn[10], drawn[11] = true, true
	Rules.markAll(state, drawn)
	assert(Rules.claimPatterns(state) == 1)
	assert(Rules.claimPatterns(state) == 0)
end)

test("tailwind moves marks with their numbers and can complete a row", function()
	local state = board()
	Rules.markAll(state, { [1] = true, [2] = true, [4] = true })
	assert(Rules.claimPatterns(state) == 0)
	assert(Rules.swap(state, 1, 3, 4))
	assert(state.cards[1][3] == 4 and state.marks[1][4])
	assert(not state.marks[1][3])
	assert(Rules.claimPatterns(state) == 1)
	assert(not Rules.swap(state, 2, 1, 2))
end)

test("illegal swaps cannot consume a player's event choice", function()
	local state = board()
	assert(not Rules.swap(state, 1, 1, 1))
	assert(not Rules.swap(state, 3, 1, 2))
	assert(not Rules.swap(state, 1, 0 / 0, 2))
	assert(not Rules.swap(state, 1, 1, "2"))
	assert(not state.swapped and not state.participated)
end)

test("number trail counts distinct marked numbers across both cards", function()
	local state = board()
	Rules.markAll(state, { [1] = true })
	assert(Rules.goalProgress(state) == 1)
	Rules.markAll(state, { [2] = true, [3] = true, [4] = true, [10] = true, [11] = true })
	local value, target = Rules.goalProgress(state)
	assert(value == 5 and target == 5)
end)

test("double delivery needs a marked copy on both cards", function()
	local state = board()
	state.goal = "twins"
	Rules.mark(state, { [1] = true }, 1, 1)
	assert(Rules.goalProgress(state) == 0)
	Rules.mark(state, { [1] = true }, 2, 1)
	assert(Rules.goalProgress(state) == 1)
end)

test("automatic marking catches previous draws but requires a participation choice", function()
	local state = board()
	local drawn = {}
	for number = 1, 24 do drawn[number] = true end
	Rules.markAll(state, drawn)
	Rules.claimPatterns(state)
	assert(not state.participated)
	assert(Rules.settle(state, Config.Rewards).total == 0)
end)

test("settlement awards exact rewards once; settled cards reject changes", function()
	local state = board()
	state.participated = true
	local drawn = {}
	for number = 1, 24 do drawn[number] = true end
	Rules.markAll(state, drawn)
	Rules.claimPatterns(state)
	local result = Rules.settle(state, Config.Rewards)
	assert(result.total == 60 and result.participation == 20 and result.patterns == 30 and result.objective == 10)
	assert(Rules.settle(state, Config.Rewards) == nil)
	assert(not Rules.mark(state, drawn, 1, 1))
	assert(not Rules.swap(state, 1, 1, 2))
end)

test("participation remains rewarding with no completed pattern", function()
	local state = board()
	Rules.mark(state, { [1] = true }, 1, 1)
	local result = Rules.settle(state, Config.Rewards)
	assert(result.total == 20 and result.patterns == 0 and result.objective == 0)
end)

test("cosmetics require exact server catalog prices; repeats only equip", function()
	local profile = Economy.defaults()
	assert(not Economy.purchase(profile, Config.Catalog, "marker_berry"))
	assert(profile.pesos == 0 and not profile.owned.marker_berry)
	profile.pesos = 75
	assert(Economy.purchase(profile, Config.Catalog, "marker_berry"))
	assert(profile.pesos == 15 and profile.owned.marker_berry and profile.equipped.marker == "marker_berry")
	assert(Economy.purchase(profile, Config.Catalog, "marker_berry"))
	assert(profile.pesos == 15)
	assert(not Economy.purchase(profile, Config.Catalog, { price = -100 }))
	assert(not Economy.purchase(profile, Config.Catalog, "free_wins"))
end)

test("profile normalization strips unknown ownership and invalid balances", function()
	for _, value in ipairs({ math.huge, -math.huge, 0 / 0, "100", -10 }) do
		local normalized = Economy.normalize({ pesos = value, owned = { exploit = true },
			equipped = { marker = "marker_berry" }, settings = { autoMark = "yes" } }, Config.Catalog)
		assert(normalized.pesos == 0 and not normalized.owned.exploit)
		assert(normalized.equipped.marker == "marker_sun" and not normalized.settings.autoMark)
	end
	local valid = Economy.defaults()
	valid.pesos = 99
	valid.owned.card_sea = true
	valid.equipped.card = "card_sea"
	local normalized = Economy.normalize(valid, Config.Catalog)
	assert(normalized.pesos == 99 and normalized.equipped.card == "card_sea")
end)

test("random rounds never exceed the disclosed reward cap", function()
	for _ = 1, 500 do
		local state = Rules.newCardState(24, random)
		state.participated = true
		state.goal = if random(0, 1) == 0 then "trail" else "twins"
		local deck, drawn = Rules.shuffle(24, random), {}
		for index = 1, 18 do
			drawn[deck[index]] = true
			Rules.markAll(state, drawn)
			if index == 8 then Rules.swap(state, random(1, 2), 1, 9) end
			Rules.claimPatterns(state)
		end
		local result = Rules.settle(state, Config.Rewards)
		assert(result.total >= 20 and result.total <= 60)
		assert(result.total % 5 == 0)
	end
end)

print("Rules and economy: " .. passed .. " tests passed")
