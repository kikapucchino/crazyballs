local Economy = {}

function Economy.defaults()
	return {
		version = 1,
		pesos = 0,
		rounds = 0,
		owned = { marker_sun = true, card_cloud = true },
		equipped = { marker = "marker_sun", card = "card_cloud" },
		chest = { lastClaimAt = 0, lastClaimKey = "", claims = 0, rewardUnits = 0 },
		payoutOutbox = {},
		settings = { autoMark = false, reducedMotion = false, musicVolume = 0.5, voiceVolume = 0.8, sfxVolume = 0.7 },
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
	for _, category in ipairs({ "marker", "card", "pet" }) do
		local id = if type(raw.equipped) == "table" then raw.equipped[category] else nil
		local item = Economy.find(catalog, id)
		if item and item.category == category and profile.owned[id] then
			profile.equipped[category] = id
		end
	end
	if type(raw.chest) == "table" then
		for _,key in ipairs({"lastClaimAt","claims","rewardUnits"}) do profile.chest[key]=nonnegativeInteger(raw.chest[key]) end
		-- Timestamps need the epoch range rather than the legacy currency cap.
		local at=raw.chest.lastClaimAt
		if type(at)=="number" and at%1==0 and at>=0 and at<=9999999999 then profile.chest.lastClaimAt=at end
		if type(raw.chest.lastClaimKey)=="string" and #raw.chest.lastClaimKey<=40 then profile.chest.lastClaimKey=raw.chest.lastClaimKey end
	end
	if type(raw.payoutOutbox)=="table" then
		for _,entry in ipairs(raw.payoutOutbox) do
			if #profile.payoutOutbox>=2048 then break end
			if type(entry)=="table" and type(entry.id)=="string" and #entry.id<=39
				and type(entry.playerName)=="string" and #entry.playerName<=30
				and type(entry.source)=="string" and #entry.source<=60
				and type(entry.multiplier)=="string" and #entry.multiplier<=1025
				and type(entry.userId)=="number" and entry.userId%1==0 and entry.userId>0
				and type(entry.at)=="number" and entry.at%1==0 and entry.at>0
				and type(entry.pesos)=="number" and entry.pesos%1==0 and entry.pesos>0 and entry.pesos<=1000000000 then
				table.insert(profile.payoutOutbox,{id=entry.id,userId=entry.userId,playerName=entry.playerName,
					source=entry.source,multiplier=entry.multiplier,pesos=entry.pesos,at=entry.at,test=entry.test==true})
			end
		end
	end
	if type(raw.settings) == "table" then
		profile.settings.autoMark = raw.settings.autoMark == true
		profile.settings.reducedMotion = raw.settings.reducedMotion == true
		for _, key in ipairs({ "musicVolume", "voiceVolume", "sfxVolume" }) do
			local value = raw.settings[key]
			if type(value) == "number" and value == value and math.abs(value) < math.huge then
				profile.settings[key] = math.clamp(value, 0, 1)
			end
		end
	end
	return profile
end

function Economy.unequipPet(profile)
	profile.equipped.pet=nil
	return true,"Pet unequipped."
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
