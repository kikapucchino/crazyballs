local Economy = {}

function Economy.defaults()
	return {
		version = 1,
		pesos = 0,
		rounds = 0,
		owned = { marker_sun = true, card_cloud = true },
		equipped = { marker = "marker_sun", card = "card_cloud" },
		settings = { autoMark = false, reducedMotion = false },
	}
end

function Economy.find(catalog, id)
	for _, item in ipairs(catalog) do
		if item.id == id then
			return item
		end
	end
	return nil
end

local function nonnegativeInteger(value)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return math.clamp(math.floor(value), 0, 1000000000)
end

function Economy.normalize(raw, catalog)
	local profile = Economy.defaults()
	if type(raw) ~= "table" then
		return profile
	end
	profile.pesos = nonnegativeInteger(raw.pesos)
	profile.rounds = nonnegativeInteger(raw.rounds)
	for _, item in ipairs(catalog) do
		if type(raw.owned) == "table" and raw.owned[item.id] == true then
			profile.owned[item.id] = true
		end
	end
	for _, category in ipairs({ "marker", "card" }) do
		local id = if type(raw.equipped) == "table" then raw.equipped[category] else nil
		local item = Economy.find(catalog, id)
		if item and item.category == category and profile.owned[id] then
			profile.equipped[category] = id
		end
	end
	if type(raw.settings) == "table" then
		profile.settings.autoMark = raw.settings.autoMark == true
		profile.settings.reducedMotion = raw.settings.reducedMotion == true
	end
	return profile
end

function Economy.purchase(profile, catalog, id)
	if type(id) ~= "string" then
		return false, "Unknown item."
	end
	local item = Economy.find(catalog, id)
	if not item then
		return false, "Unknown item."
	end
	if profile.owned[id] then
		profile.equipped[item.category] = id
		return true, item.name .. " equipped."
	end
	if profile.pesos < item.price then
		return false, "Save " .. (item.price - profile.pesos) .. " more Pesos for " .. item.name .. "."
	end
	profile.pesos -= item.price
	profile.owned[id] = true
	profile.equipped[item.category] = id
	return true, item.name .. " purchased and equipped."
end

return Economy
