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
	local state = { cards = {}, marks = {}, premarks = {}, tiles = {}, multipliers = {}, claimed = {}, bonuses = {}, participated = false, settled = false }
	-- Starting marks and multiplier cells are fixed at deal time; the shared draw pool is unchanged.
	if config.Main.CardsEnabled then
		assert(Rules.isIndex(config.Main.Count, 8), "Confirm a main card count from 1 to 8")
		for index = 1, config.Main.Count do
			local deck, card = Rules.shuffle(config.NumberPool, random), {}
			for cell = 1, 25 do card[cell] = if cell == 13 and config.Main.FreeCenter then 0 else deck[cell] end
			state.cards[index], state.marks[index],state.premarks[index] = card, {},{}
			local limits=config.Main.StartingMarks
			local count=random(limits.Minimum,limits.Maximum)
			assert(count>=8 and count<=12 and count%1==0,"Main starting marks must be 8–12")
			local positions=Rules.shuffle(25,random)
			local chosen=0
			if config.Main.FreeCenter then state.marks[index][0]=true;state.premarks[index][0]=true;chosen=1 end
			for _,position in ipairs(positions) do
				local number=card[position]
				if not state.marks[index][number] and chosen<count then
					state.marks[index][number],state.premarks[index][number]=true,true;chosen+=1
				end
			end
			state.multipliers[index] = if config.Main.CardMultiplierEnabled then Rules.cardMultiplier(config.Main.MultiplierWeights, random) else 1
			state.tiles[index]={}
			local tuning=config.Main.MultiplierCells
			if tuning and tuning.Enabled then
				local count=random(tuning.Minimum,tuning.Maximum)
				assert(count>=1 and count<=2,"At most two multiplier cells per main card")
				local slots=Rules.shuffle(25,random)
				for tile=1,count do state.tiles[index][slots[tile]]=tuning.Values[random(1,#tuning.Values)] end
			end
		end
	end
	for _, definition in ipairs(config.Bonuses) do
		local numbers, deck = {}, Rules.shuffle(config.NumberPool, random)
		for index = 1, definition.count do numbers[index] = deck[index] end
		state.bonuses[definition.id] = { numbers = numbers, marks = {}, premarks = {}, progress = 0, qualified = false }
	end
	local candidates,capacity={},0
	for _,definition in ipairs(config.Bonuses) do
		local card=state.bonuses[definition.id]
		capacity+=math.max(0,#card.numbers-1)
		for _,number in ipairs(card.numbers) do table.insert(candidates,{card=card,number=number}) end
	end
	local target=random(0,math.min(config.BonusStartingMarks.MaximumTotal,capacity))
	local assigned,byCard=0,{}
	for _,index in ipairs(Rules.shuffle(#candidates,random)) do
		local entry=candidates[index];local card=entry.card
		if assigned<target and (byCard[card] or 0)<#card.numbers-1 then
			card.premarks[entry.number],card.marks[entry.number]=true,true
			byCard[card]=(byCard[card] or 0)+1;assigned+=1
		end
	end
	Rules.qualify(state)
	return state
end
function Rules.mark(state, drawn, cardIndex, cellIndex)
	if state.settled or not Rules.isIndex(cardIndex, #state.cards) or not Rules.isIndex(cellIndex, 25) then return false end
	local number = state.cards[cardIndex][cellIndex]
	if not drawn[number] or state.marks[cardIndex][number] then return false end
	state.marks[cardIndex][number], state.participated = true, true
	return true
end
function Rules.markBonus(state,drawn,id,cellIndex)
	if state.settled or type(id)~="string" then return false end
	local card=state.bonuses[id]
	if not card or not Rules.isIndex(cellIndex,#card.numbers) then return false end
	local number=card.numbers[cellIndex]
	if not drawn[number] or card.marks[number] then return false end
	card.marks[number],state.participated=true,true
	Rules.qualify(state)
	return true
end
function Rules.markAll(state, drawn)
	if state.settled then return end
	for index,card in ipairs(state.cards) do
		for _,number in ipairs(card) do if drawn[number] then state.marks[index][number]=true end end
	end
	for _,card in pairs(state.bonuses) do
		for _,number in ipairs(card.numbers) do if drawn[number] then card.marks[number]=true end end
	end
	Rules.qualify(state)
end
function Rules.qualify(state)
	local newlyQualified = {}
	for id, card in pairs(state.bonuses) do
		local progress = 0
		for _, number in ipairs(card.numbers) do if card.marks[number] then progress += 1 end end
		card.progress = progress
		if #card.numbers > 0 and progress == #card.numbers and not card.qualified then
			card.qualified = true
			table.insert(newlyQualified, id)
		end
	end
	return newlyQualified
end
function Rules.lineAwards(state,completedByCard,startingByCard,base,startingPolicy,patterns,stacking)
	assert(type(base)=="number" and base%1==0 and base>0 and base<=1000000,"Invalid line base reward")
	local awards,held={},0
	for cardIndex,completed in ipairs(completedByCard) do
		local seen,heldCells={},0
		for _,id in ipairs(completed) do
			if seen[id] then continue end
			seen[id]=true
			local atStart=table.find(startingByCard[cardIndex] or {},id)~=nil
			if atStart and startingPolicy~="pay" then held+=1
			else
				local cellFactor,hasTile=1,false
				for _,pattern in ipairs(patterns or {}) do
					if pattern.id~=id then continue end
					for _,cellIndex in ipairs(pattern.cells) do
						local multiplier=state.tiles[cardIndex] and state.tiles[cardIndex][cellIndex]
						if multiplier then hasTile=true;cellFactor*=multiplier end
					end
				end
				if hasTile and stacking~="multiply" and stacking~="replace" then heldCells+=1
				else
					local factor=cellFactor*(if stacking=="replace" then 1 else state.multipliers[cardIndex])
					table.insert(awards,{cardIndex=cardIndex,patternId=id,lines=1,multiplier=factor,pesos=base*factor})
				end
			end
		end
		held+=heldCells
	end
	return awards,held
end
function Rules.settle(state, _rewards)
	if state.settled then return nil end
	state.settled = true
	return { total = 0, bonusPending = true }
end
return Rules
