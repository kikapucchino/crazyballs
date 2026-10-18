-- Engine-independent rules: also executed by tests/rules.spec.luau.
local Rules = {}

function Rules.isIndex(value, maximum)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= 1 and value <= maximum
end

function Rules.shuffle(count, nextInteger)
	local deck = {}
	for number = 1, count do
		deck[number] = number
	end
	for index = count, 2, -1 do
		local other = nextInteger(1, index)
		deck[index], deck[other] = deck[other], deck[index]
	end
	return deck
end

function Rules.newCardState(pool, nextInteger)
	local firstDeck = Rules.shuffle(pool, nextInteger)
	local secondDeck = Rules.shuffle(pool, nextInteger)
	local first, second = {}, { firstDeck[1] }
	for index = 1, 9 do
		first[index] = firstDeck[index]
	end
	-- At least one shared number makes Double Delivery possible on every pair.
	for _, number in ipairs(secondDeck) do
		if number ~= second[1] and #second < 9 then
			table.insert(second, number)
		end
	end
	local positions = Rules.shuffle(9, nextInteger)
	local mixedSecond = {}
	for index, position in ipairs(positions) do
		mixedSecond[index] = second[position]
	end
	return {
		cards = { first, mixedSecond },
		marks = { {}, {} },
		claimed = { false, false },
		goal = "trail",
		participated = false,
		swapped = false,
		settled = false,
	}
end

function Rules.mark(state, drawn, cardIndex, cellIndex)
	if state.settled or not Rules.isIndex(cardIndex, 2) or not Rules.isIndex(cellIndex, 9) then
		return false
	end
	local number = state.cards[cardIndex][cellIndex]
	if not drawn[number] or state.marks[cardIndex][number] then
		return false
	end
	state.marks[cardIndex][number] = true
	state.participated = true
	return true
end

function Rules.markAll(state, drawn)
	-- Automatic marks don't count as an interaction for participation rewards.
	local participated = state.participated
	for cardIndex, card in ipairs(state.cards) do
		for cellIndex in ipairs(card) do
			Rules.mark(state, drawn, cardIndex, cellIndex)
		end
	end
	state.participated = participated
end

function Rules.claimPatterns(state)
	local newlyClaimed = 0
	for cardIndex, card in ipairs(state.cards) do
		if not state.claimed[cardIndex] then
			for row = 0, 2 do
				local offset = row * 3
				local marks = state.marks[cardIndex]
				if marks[card[offset + 1]] and marks[card[offset + 2]] and marks[card[offset + 3]] then
					state.claimed[cardIndex] = true
					newlyClaimed += 1
					break
				end
			end
		end
	end
	return newlyClaimed
end

function Rules.swap(state, cardIndex, firstIndex, secondIndex)
	if state.settled or state.swapped or not Rules.isIndex(cardIndex, 2)
		or not Rules.isIndex(firstIndex, 9) or not Rules.isIndex(secondIndex, 9) or firstIndex == secondIndex then
		return false
	end
	local card = state.cards[cardIndex]
	card[firstIndex], card[secondIndex] = card[secondIndex], card[firstIndex]
	-- Marks are keyed by number and therefore travel with their cells.
	state.swapped = true
	state.participated = true
	return true
end

function Rules.goalProgress(state)
	if state.goal == "twins" then
		for number in pairs(state.marks[1]) do
			if state.marks[2][number] then
				return 1, 1
			end
		end
		return 0, 1
	end
	local unique = {}
	for _, marks in ipairs(state.marks) do
		for number in pairs(marks) do
			unique[number] = true
		end
	end
	local count = 0
	for _ in pairs(unique) do
		count += 1
	end
	return math.min(count, 5), 5
end

function Rules.settle(state, rewards)
	if state.settled then
		return nil
	end
	state.settled = true
	local patterns = (if state.claimed[1] then 1 else 0) + (if state.claimed[2] then 1 else 0)
	local progress, target = Rules.goalProgress(state)
	-- A player must make at least one choice or valid manual mark this round.
	local participation = if state.participated then rewards.Participation else 0
	local patternReward = if state.participated then patterns * rewards.Pattern else 0
	local objective = if state.participated and progress == target then rewards.Objective else 0
	return { participation = participation, patterns = patternReward, objective = objective,
		total = participation + patternReward + objective }
end

return Rules
