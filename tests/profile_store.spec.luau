-- tools/check.py wraps the real module with injectable Roblox services.
local loadStore = require("./.generated/ProfileStoreHarness")
local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")
local passed = 0
local function test(name, callback)
	local ok, message = pcall(callback)
	assert(ok, name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end
local function environment(studio)
	local database = { records = {}, failures = 0, calls = 0, acquisitions = 0, uncertain = false }
	function database:UpdateAsync(key, transform)
		self.calls += 1
		if self.failures > 0 then self.failures -= 1; error("simulated storage outage") end
		local result = transform(copy(self.records[key]))
		if result then self.records[key] = copy(result) end
		if self.uncertain then self.uncertain = false; error("simulated lost response after commit") end
		return copy(result)
	end
	local clock = { value = 10000 }
	local service = {}
	function service:GetDataStore()
		database.acquisitions += 1
		assert(not studio, "practice accessed DataStore")
		return database
	end
	local serial = 0
	local services = {
		DataStoreService = service,
		HttpService = { GenerateGUID = function() serial += 1; return "session" .. serial end },
		RunService = { IsStudio = function() return studio end },
		ReplicatedStorage = { WaitForChild = function() return {
			Config = "../../src/shared/Config", Economy = "../../src/shared/Economy",
		} end },
	}
	local store = loadStore({ GetService = function(_, name) return services[name] end },
		{ GetAttribute = function() return false end }, { wait = function() end }, function() end,
		{ time = function() return clock.value end })
	return store, database, clock
end

test("unpublished Studio practice never acquires or writes a DataStore", function()
	local store, db = environment(true)
	local profile = store.load({ UserId = 1 })
	assert(profile.practice and store.writable(profile))
	profile.data.pesos = 60
	assert(store.save(profile, false))
	store.close(profile)
	assert(profile.closed and db.calls == 0 and db.acquisitions == 0)
end)

test("live profiles acquire one session lock; simultaneous sessions are refused", function()
	local store, db = environment(false)
	local first = store.load({ UserId = 1 })
	assert(first and not first.practice)
	local second, problem = store.load({ UserId = 1 })
	assert(second == nil and string.find(problem, "another server"))
	assert(db.records.player_1.lock.id == first.token)
end)

test("save, release and rejoin retain the balance, cosmetics and settings", function()
	local store, db = environment(false)
	local first = store.load({ UserId = 1 })
	first.data.pesos = 100
	assert(Economy.purchase(first.data, Config.Catalog, "marker_berry"))
	first.data.settings.voiceVolume = 0.3
	first.data.settings.autoMark = true -- legacy field is deliberately discarded
	assert(store.save(first, false))
	store.close(first)
	assert(db.records.player_1.lock == nil)
	local second = store.load({ UserId = 1 })
	assert(second.data.pesos == 40 and second.data.owned.marker_berry)
	assert(second.data.equipped.marker == "marker_berry" and second.data.settings.voiceVolume == 0.3 and second.data.settings.autoMark == nil)
end)

test("an expired session cannot overwrite the replacement server's save", function()
	local store, db, clock = environment(false)
	local first = store.load({ UserId = 1 })
	clock.value += 301
	local second = store.load({ UserId = 1 })
	second.data.pesos = 125
	assert(store.save(second, false))
	first.data.pesos = 999
	assert(not store.save(first, false))
	assert(db.records.player_1.data.pesos == 125 and db.records.player_1.lock.id == second.token)
end)

test("mutation freezes before lease expiry; successful heartbeat restores it", function()
	local store, _, clock = environment(false)
	local profile = store.load({ UserId = 1 })
	clock.value += 271
	assert(not store.writable(profile))
	assert(store.save(profile, false))
	assert(store.writable(profile))
end)

test("transient requests retry; persistent load failures do not return a blank profile", function()
	local store, db = environment(false)
	db.failures = 2
	assert(store.load({ UserId = 1 }))
	assert(db.calls == 3)
	db.failures = 3
	local profile, message = store.load({ UserId = 2 })
	assert(profile == nil and message and db.records.player_2 == nil)
end)

test("unknown save schemas fail closed without replacing data", function()
	local store, db = environment(false)
	db.records.player_1 = { data = { version = 99, pesos = 50 } }
	local profile = store.load({ UserId = 1 })
	assert(profile == nil and db.records.player_1.data.version == 99)
end)

test("retry after a lost acquisition response preserves its session identity", function()
	local store, db = environment(false)
	db.uncertain = true
	local profile = store.load({ UserId = 1 })
	assert(profile and db.records.player_1.lock.id == profile.token)
	assert(db.calls == 2)
end)

test("failed saves retain the previous persisted data and report retry status", function()
	local store, db = environment(false)
	local profile = store.load({ UserId = 1 })
	profile.data.pesos = 45
	db.failures = 3
	assert(not store.save(profile, false))
	assert(db.records.player_1.data.pesos == 0 and profile.saveStatus == "Save delayed · retrying")
	assert(store.save(profile, false))
	assert(db.records.player_1.data.pesos == 45)
end)

print("Profile persistence: " .. passed .. " tests passed (mock DataStore)")
