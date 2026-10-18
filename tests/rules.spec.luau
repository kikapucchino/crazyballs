local Rules = require("../src/shared/GameRules")
local Economy = require("../src/shared/Economy")
local Config = require("../src/shared/Config")
local Bonus = require("../src/shared/BonusRules")
local Exact = require("../src/shared/ExactInteger")
local passed = 0
local function test(name, callback)
	local ok, message = pcall(callback)
	assert(ok, name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end
math.randomseed(7313)
local function random(low, high) return math.random(low, high) end

test("1000 fresh pools contain 60 unique values and expose exactly 20 unique draws", function()
	for _ = 1, 1000 do
		local deck, seen = Rules.shuffle(Config.NumberPool, random), {}
		assert(#deck == 60 and Config.DrawCount == 20)
		for _, value in ipairs(deck) do assert(Rules.isIndex(value, 60) and not seen[value]); seen[value] = true end
		local draws = { table.unpack(deck, 1, Config.DrawCount) }
		assert(#draws == 20)
	end
end)
test("bonus cards use distinct 1–60 numbers and preserve every requested name/count", function()
	for _ = 1, 100 do
		local state = Rules.newCardState(Config, random)
		assert(#state.cards == 2 and #state.cards[1] == 25)
		for _, definition in ipairs(Config.Bonuses) do
			local seen, card = {}, state.bonuses[definition.id]
			assert(#card.numbers == definition.count)
			for _, value in ipairs(card.numbers) do assert(Rules.isIndex(value, 60) and not seen[value]); seen[value] = true end
		end
	end
	assert(Config.Bonuses[1].name == "Coin flip" and Config.Bonuses[2].name == "Duck hunt")
	assert(Config.Bonuses[3].name == "Pačinki" and Config.Bonuses[4].name == "Go CRazy")
end)
test("multiple bonus types qualify independently and a pending wheel never auto-qualifies", function()
	local state, drawn = Rules.newCardState(Config, random), {}
	for _, card in pairs(state.bonuses) do for _, number in ipairs(card.numbers) do drawn[number] = true end end
	assert(#Rules.qualify(state, drawn) == 3)
	assert(not state.bonuses.crazy.qualified)
	assert(#Rules.qualify(state, drawn) == 0)
end)
test("qualification depends on individual cards, never on another player's success", function()
	local a, b = Rules.newCardState(Config, random), Rules.newCardState(Config, random)
	a.bonuses.coin.numbers, b.bonuses.coin.numbers = {1,2,3}, {4,5,6}
	Rules.qualify(a, { [1] = true, [2] = true, [3] = true })
	Rules.qualify(b, { [1] = true, [2] = true, [3] = true })
	assert(a.bonuses.coin.qualified and not b.bonuses.coin.qualified)
end)
test("configured main cards are 5x5, marking rejects forged/undrawn cells", function()
	local configuration = table.clone(Config)
	configuration.Main = { CardsEnabled = true, Count = 2, FreeCenter = true, MultiplierWeights = Config.Main.MultiplierWeights }
	local state = Rules.newCardState(configuration, random)
	assert(#state.cards == 2 and #state.cards[1] == 25 and state.cards[1][13] == 0 and state.marks[1][0])
	assert(not Rules.mark(state, {}, 1, 1))
	local drawn = { [state.cards[1][1]] = true }
	for _, bad in ipairs({0, -1, 26, 1.5, math.huge, 0/0, "1", {}}) do
		assert(not Rules.mark(state, drawn, 1, bad))
		assert(not Rules.mark(state, drawn, bad, 1))
	end
	assert(Rules.mark(state, drawn, 1, 1))
	assert(not Rules.mark(state, drawn, 1, 1))
end)
test("participation settles once; merely receiving cards cannot farm it", function()
	local state = Rules.newCardState(Config, random)
	assert(Rules.settle(state, Config.Rewards).total == 0)
	assert(Rules.settle(state, Config.Rewards) == nil)
	state = Rules.newCardState(Config, random)
	state.participated = true
	assert(Rules.settle(state, Config.Rewards).total == 20)
	assert(Rules.settle(state, Config.Rewards) == nil)
end)
test("multiplier validators preserve signed bounds and reject invalid distributions", function()
	for index = 1, 3 do
		local definition = Config.Bonuses[index]
		assert(Bonus.validate(definition, {{multiplier=definition.minimum,weight=1},{multiplier=definition.maximum,weight=1}}))
		for _, invalid in ipairs({ definition.minimum - 1, definition.maximum + 1, math.huge, 0/0, "20", 1.5 }) do
			assert(not Bonus.validate(definition, {{multiplier=invalid,weight=1},{multiplier=1,weight=1}}))
		end
		assert(not Bonus.validate(definition, {{multiplier=1,weight=0},{multiplier=1,weight=1}}))
	end
	assert(not Bonus.validate(Config.Bonuses[4], {{multiplier=1,weight=1}}))
	assert(not Config.BonusPayoutsEnabled)
end)
test("weighted selection maps exact roll boundaries to their disclosed outcomes", function()
	local distribution = {{multiplier=-3,weight=2},{multiplier=20,weight=3}}
	for roll = 1, 5 do
		local selected = Bonus.choose(Config.Bonuses[1], distribution, function(low, high) assert(low == 1 and high == 5); return roll end)
		assert(selected == (if roll <= 2 then 1 else 2))
	end
end)
test("shared coin results stay identical and duplicate receipts cannot award twice", function()
	local ledger, definition = Bonus.newLedger(), Config.Bonuses[1]
	local outcomes = {{multiplier=-5,weight=1},{multiplier=20,weight=1}}
	local first, awarded = Bonus.resolve(ledger, 1, definition, outcomes, true, nil, function() return 2 end, Exact, 20)
	assert(awarded and first.pesos == "400")
	local second = Bonus.resolve(ledger, 2, definition, outcomes, true, nil, function() error("must reuse common result") end, Exact, 20)
	assert(second.multiplier == first.multiplier)
	local duplicate, isNew = Bonus.resolve(ledger, 1, definition, outcomes, true, nil, random, Exact, 20)
	assert(duplicate == first and not isNew)
	assert(Bonus.resolve(ledger, 3, definition, outcomes, false, nil, random, Exact, 20) == nil)
end)
test("Duck timeout/disconnect fallback picks once and preserves signed multiplier", function()
	local ledger, definition = Bonus.newLedger(), Config.Bonuses[2]
	local outcomes = {{multiplier=-100,weight=1},{multiplier=100,weight=1}}
	local automatic = Bonus.resolve(ledger, 1, definition, outcomes, true, nil, function() return 1 end, Exact, 20)
	assert(automatic.pesos == "-2000")
	local lateChoice, isNew = Bonus.resolve(ledger, 1, definition, outcomes, true, 2, random, Exact, 20)
	assert(lateChoice == automatic and not isNew)
	assert(Bonus.resolve(ledger, 2, definition, outcomes, true, 9, random, Exact, 20) == nil)
end)
test("exact signed payouts exceed floating-point precision without rounding or overflow", function()
	assert(Exact.multiplySmall("1", 20) == "20")
	assert(Exact.multiplySmall("5", 20) == "100")
	assert(Exact.multiplySmall("20", 20) == "400")
	assert(Exact.multiplySmall("-999999999999999999999999999999", 20) == "-19999999999999999999999999999980")
	assert(Exact.normalize("-0000") == "0" and Exact.format("1234567") == "1,234,567")
	assert(Exact.format("-123456789012345678901") == "−1.234e+20")
	for _, invalid in ipairs({"inf", "NaN", "3.2", "1e200", string.rep("9", 1025)}) do assert(not pcall(Exact.normalize, invalid)) end
	assert(not pcall(Exact.multiplySmall, string.rep("9", 1024), 20))
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
		assert(normalized.equipped.marker == "marker_sun" and normalized.settings.autoMark == false)
	end
	local valid = Economy.defaults()
	valid.pesos = 99
	valid.owned.card_sea = true
	valid.equipped.card = "card_sea"
	local normalized = Economy.normalize(valid, Config.Catalog)
	assert(normalized.pesos == 99 and normalized.equipped.card == "card_sea")
end)

test("saved volume settings migrate old profiles and sanitize nonfinite inputs", function()
	local profile = Economy.normalize({ settings = { musicVolume = 0/0, sfxVolume = 0.25 } }, Config.Catalog)
	assert(profile.settings.musicVolume == 0.5 and profile.settings.sfxVolume == 0.25)
	assert(Economy.normalize({}, Config.Catalog).settings.musicVolume == 0.5)
end)
test("1000 deals use unique numbers per card and fixed 1–20 integer multipliers", function()
	for _=1,1000 do
		local state=Rules.newCardState(Config,random)
		for index,card in ipairs(state.cards) do
			local seen={}
			for _,number in ipairs(card) do assert(number>=1 and number<=60 and not seen[number]); seen[number]=true end
			local multiplier=state.multipliers[index]
			assert(multiplier%1==0 and multiplier>=1 and multiplier<=20)
			Rules.mark(state,{[card[1]]=true},index,1)
			assert(state.multipliers[index]==multiplier)
		end
	end
end)
test("configured multiplier weights map exactly to their probability intervals",function()
	for roll=1,20 do assert(Rules.cardMultiplier(Config.Main.MultiplierWeights,function() return roll end)==roll) end
	local weights=table.create(20,0); weights[3]=2; weights[20]=1
	assert(Rules.cardMultiplier(weights,function() return 2 end)==3)
	assert(Rules.cardMultiplier(weights,function() return 3 end)==20)
	weights[1]=-1
	assert(not pcall(Rules.cardMultiplier,weights,random))
end)
test("a main multiplier applies once to that card reward, never to participation or another card",function()
	local state=Rules.newCardState(Config,random)
	state.multipliers={7,20}
	assert(Rules.claimMainReward(state,1,10,false)==nil)
	assert(Rules.claimMainReward(state,1,10,true)==70)
	assert(Rules.claimMainReward(state,1,10,true)==nil)
	assert(Rules.claimMainReward(state,2,10,true)==200)
	state.participated=true
	assert(Rules.settle(state,Config.Rewards).total==20)
end)
print("Rules/economy: " .. passed .. " tests passed")
