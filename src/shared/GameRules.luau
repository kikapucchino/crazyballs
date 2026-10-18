-- Pure round rules. Randomness is injected by the server, never by a client.
local Rules = {}
function Rules.isIndex(value, maximum)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= 1 and value <= maximum
end
function Rules.shuffle(count, random)
	local result = {}
	for value = 1, count do result[value] = value end
	for index = count, 2, -1 do
		local other = random(1, index)
		result[index], result[other] = result[other], result[index]
	end
	return result
end
function Rules.cardMultiplier(weights, random)
	assert(#weights == 20, "Provide weights for multipliers 1 through 20")
	local total = 0
	for _, weight in ipairs(weights) do
		assert(type(weight) == "number" and weight >= 0 and weight <= 1000000 and weight % 1 == 0, "Invalid card multiplier weight")
		total += weight
	end
	assert(total > 0, "At least one multiplier must be possible")
	local roll = random(1, total)
	for multiplier, weight in ipairs(weights) do
		roll -= weight
		if roll <= 0 then return multiplier end
	end
	error("Invalid random source")
end
-- Apply once to this card's eligible MAIN reward only. No production base/pattern is assumed.
function Rules.claimMainReward(state, cardIndex, base, eligible)
	if state.settled or not eligible or not Rules.isIndex(cardIndex, #state.cards) or state.claimed[cardIndex] then return nil end
	assert(type(base) == "number" and base % 1 == 0 and base >= 0 and base <= 1000000, "Invalid main base reward")
	local reward = base * state.multipliers[cardIndex]
	state.claimed[cardIndex] = true
	return reward
end
function Rules.newCardState(config, random)
	local state = { cards = {}, marks = {}, multipliers = {}, claimed = {}, bonuses = {}, participated = false, settled = false }
	-- Dealing/marking is independent of the still-unconfirmed pattern rewards.
	if config.Main.CardsEnabled then
		assert(Rules.isIndex(config.Main.Count, 8), "Confirm a main card count from 1 to 8")
		for index = 1, config.Main.Count do
			local deck, card = Rules.shuffle(config.NumberPool, random), {}
			for cell = 1, 25 do card[cell] = if cell == 13 and config.Main.FreeCenter then 0 else deck[cell] end
			state.cards[index], state.marks[index] = card, { [0] = true }
			state.multipliers[index] = Rules.cardMultiplier(config.Main.MultiplierWeights, random)
		end
	end
	for _, definition in ipairs(config.Bonuses) do
		local numbers, deck = {}, Rules.shuffle(config.NumberPool, random)
		for index = 1, definition.count do numbers[index] = deck[index] end
		state.bonuses[definition.id] = { numbers = numbers, progress = 0, qualified = false }
	end
	return state
end
function Rules.mark(state, drawn, cardIndex, cellIndex)
	if state.settled or not Rules.isIndex(cardIndex, #state.cards) or not Rules.isIndex(cellIndex, 25) then return false end
	local number = state.cards[cardIndex][cellIndex]
	if not drawn[number] or state.marks[cardIndex][number] then return false end
	state.marks[cardIndex][number], state.participated = true, true
	return true
end
function Rules.qualify(state, drawn)
	local newlyQualified = {}
	for id, card in pairs(state.bonuses) do
		local progress = 0
		for _, number in ipairs(card.numbers) do if drawn[number] then progress += 1 end end
		card.progress = progress
		if #card.numbers > 0 and progress == #card.numbers and not card.qualified then
			card.qualified = true
			table.insert(newlyQualified, id)
		end
	end
	return newlyQualified
end
function Rules.settle(state, rewards)
	if state.settled then return nil end
	state.settled = true
	return { total = if state.participated then rewards.Participation else 0, bonusPending = true }
end
return Rules
