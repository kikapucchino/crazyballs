local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Cloudpop")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)

local Store = {}
local database
local LEASE_SECONDS = 300

local function getDatabase()
	-- GetDataStore can itself fail in an unpublished place. Practice never calls it.
	if not database then database = DataStoreService:GetDataStore(Config.DataStoreName) end
	return database
end

local function retry(operation)
	for attempt = 1, 3 do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		warn("Cloudpop data request failed (attempt " .. attempt .. "). " .. tostring(result))
		if attempt < 3 then
			task.wait(attempt * 2)
		end
	end
	return false, nil
end

function Store.load(player)
	-- Studio is deliberately session-only unless explicitly opted in on this module.
	-- Use a separate published TEST experience when enabling Studio saves.
	if RunService:IsStudio() and script:GetAttribute("EnableStudioSaves") ~= true then
		return { data = Economy.defaults(), practice = true, saveStatus = "Studio practice · not saved", closing = false }
	end
	local token = HttpService:GenerateGUID(false)
	local key = "player_" .. player.UserId
	local denial = "Profile is open on another server. Please retry shortly."
	local ok, record = retry(function()
		return getDatabase():UpdateAsync(key, function(old)
			if old ~= nil then
				if type(old) ~= "table" or type(old.data) ~= "table" or old.data.version ~= 1 then
					denial = "Your save needs a compatible game version. Please retry later."
					return nil
				end
				if type(old.lock) == "table" and old.lock.id ~= token
					and type(old.lock.expires) == "number" and old.lock.expires > os.time() then
					return nil
				end
			end
			return {
				data = Economy.normalize(if old then old.data else nil, Config.Catalog),
				lock = { id = token, expires = os.time() + LEASE_SECONDS },
			}
		end)
	end)
	if not ok then
		return nil, "Cloud saves are unavailable. Please retry; your existing save has not been replaced."
	end
	if not record or not record.lock or record.lock.id ~= token then
		return nil, denial
	end
	return { data = record.data, key = key, token = token, expires = record.lock.expires,
		practice = false, saving = false, closing = false, saveStatus = "Cloud save connected" }
end

function Store.writable(profile)
	return profile and not profile.closing and (profile.practice or os.time() < profile.expires - 30)
end

function Store.save(profile, release)
	if profile.practice then
		return true
	end
	while profile.saving do
		task.wait(0.1)
	end
	profile.saving = true
	local snapshot = Economy.normalize(profile.data, Config.Catalog)
	local snapshotRevision = profile.revision or 0
	local ok, result = retry(function()
		return getDatabase():UpdateAsync(profile.key, function(old)
			-- Never overwrite another server's session or resurrect a released lock.
			if type(old) ~= "table" or type(old.lock) ~= "table" or old.lock.id ~= profile.token then
				return nil
			end
			return { data = snapshot, lock = if release then nil else {
				id = profile.token, expires = os.time() + LEASE_SECONDS,
			} }
		end)
	end)
	profile.saving = false
	if ok and result then
		if not release then
			profile.expires = result.lock.expires
		end
		profile.saveStatus = if (profile.revision or 0) == snapshotRevision then "Progress saved" else "Changes waiting to save"
		if Store.onSaved then
			local notified,problem=pcall(Store.onSaved,profile,snapshot)
			if not notified then warn("Payout indexing deferred: "..tostring(problem)) end
		end
		return true
	end
	profile.saveStatus = "Save delayed · retrying"
	return false
end

function Store.close(profile)
	if profile.closing then
		while not profile.closed do task.wait(0.1) end
		return
	end
	profile.closing = true
	if not Store.save(profile, true) then
		warn("Cloudpop could not finish a profile save; its session lock will expire automatically.")
	end
	profile.closed = true
end

return Store
