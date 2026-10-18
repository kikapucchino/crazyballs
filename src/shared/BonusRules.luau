-- Pure server-side building blocks. No production distribution is configured yet.
-- An award receipt is a computed outcome, NOT a persisted balance mutation.
local Bonus = {}
function Bonus.validate(definition, outcomes)
	if type(outcomes) ~= "table" or #outcomes == 0 then return false end
	if definition.id == "crazy" then return false end -- wheel rules still need confirmation
	if definition.id == "coin" and #outcomes ~= 2 then return false end
	local total = 0
	for _, outcome in ipairs(outcomes) do
		local value, weight = outcome.multiplier, outcome.weight
		if type(value) ~= "number" or value ~= value or value % 1 ~= 0
			or value < definition.minimum or value > definition.maximum then return false end
		if type(weight) ~= "number" or weight % 1 ~= 0 or weight <= 0 or weight > 1000000 then return false end
		total += weight
	end
	return total <= 1000000000
end
function Bonus.choose(definition, outcomes, random)
	assert(Bonus.validate(definition, outcomes), "Unconfirmed/invalid bonus distribution")
	local total = 0
	for _, outcome in ipairs(outcomes) do total += outcome.weight end
	local roll = random(1, total)
	for index, outcome in ipairs(outcomes) do
		roll -= outcome.weight
		if roll <= 0 then return index end
	end
	error("Random source returned an invalid roll")
end
function Bonus.newLedger()
	return { common = {}, receipts = {} }
end
-- caller supplies a trusted eligibility boolean and SERVER random source.
-- Duck uses a server-owned shuffled mapping; disconnect/timeout passes nil selection.
function Bonus.resolve(ledger, userId, definition, outcomes, eligible, selection, random, exact, base)
	if not eligible then return nil end
	local key = tostring(userId) .. ":" .. definition.id
	if ledger.receipts[key] then return ledger.receipts[key], false end
	assert(Bonus.validate(definition, outcomes), "Bonus is not configured")
	local index
	if definition.shared then
		index = ledger.common[definition.id]
		if not index then index = Bonus.choose(definition, outcomes, random); ledger.common[definition.id] = index end
	else
		if selection ~= nil then
			if type(selection) ~= "number" or selection % 1 ~= 0 or selection < 1 or selection > #outcomes then return nil end
			index = selection
		else index = random(1, #outcomes) end
	end
	local multiplier = outcomes[index].multiplier
	local receipt = { index = index, multiplier = tostring(multiplier), pesos = exact.multiplySmall(tostring(multiplier), base) }
	ledger.receipts[key] = receipt
	return receipt, true
end
return Bonus
