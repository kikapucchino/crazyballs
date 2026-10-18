-- Executes the actual server controller with deterministic scheduling and mock services.
-- This verifies protocol behavior; Studio remains required for real Roblox integration.
local runServer = require("./.generated/ServerHarness")
local loadWorkshop = require("./.generated/WorkshopHarness")
local Rules = require("../src/shared/GameRules")
local Economy = require("../src/shared/Economy")
local Config = require("../src/shared/Config")
Config.IntermissionSeconds = 2
Config.DrawSeconds = 0.2
Config.EventSeconds = 2
Config.ResultsSeconds = 1
math.randomseed(118)

local passed = 0
local function check(condition, name)
	assert(condition, name)
	passed += 1
	print("PASS " .. name)
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local scheduler = { now = 0, queue = {}, order = 0 }
local function schedule(thread, delay, arguments)
	scheduler.order += 1
	table.insert(scheduler.queue, { thread = thread, at = scheduler.now + delay, args = arguments or {}, order = scheduler.order })
end
local taskMock = {}
function taskMock.spawn(callback, ...)
	schedule(coroutine.create(callback), 0, table.pack(...))
end
function taskMock.wait(delay)
	return coroutine.yield(delay or 0.03)
end
local function advance(seconds)
	local deadline = scheduler.now + seconds
	while true do
		table.sort(scheduler.queue, function(a, b) return a.at < b.at or (a.at == b.at and a.order < b.order) end)
		local entry = scheduler.queue[1]
		if not entry or entry.at > deadline then break end
		table.remove(scheduler.queue, 1)
		scheduler.now = entry.at
		local ok, delay = coroutine.resume(entry.thread, table.unpack(entry.args, 1, entry.args.n or #entry.args))
		assert(ok, tostring(delay))
		if coroutine.status(entry.thread) ~= "dead" then schedule(entry.thread, delay) end
	end
	scheduler.now = deadline
end
local function signal()
	local handlers = {}
	return {
		Connect = function(_, callback) table.insert(handlers, callback) end,
		Fire = function(_, ...)
			for _, callback in ipairs(handlers) do taskMock.spawn(callback, ...) end
		end,
	}
end

local snapshots, playersList, savedProfiles = {}, {}, {}
local shared = { Config = "Config", GameRules = "Rules", Economy = "Economy" }
local players = { PlayerAdded = signal(), PlayerRemoving = signal() }
function players:GetPlayers() return table.clone(playersList) end
local function player(id)
	local object = { UserId = id, Parent = players }
	function object:Kick(reason) self.kicked = reason end
	table.insert(playersList, object)
	return object
end
local ada, ben = player(1), player(2)
local instance = {}
function instance.new(class)
	local object = {}
	if class == "RemoteEvent" then
		object.OnServerEvent = signal()
		function object:FireClient(target, snapshot) snapshots[target] = copy(snapshot) end
	end
	return setmetatable(object, { __newindex = function(self, key, value)
		rawset(self, key, value)
		if key == "Parent" then value[self.Name] = self end
	end })
end
local profileStore = {}
function profileStore.load(target)
	local profile = { data = Economy.defaults(), practice = true, saveStatus = "Test", closing = false }
	savedProfiles[target] = profile
	return profile
end
function profileStore.writable(profile) return profile and not profile.closing end
function profileStore.save() return true end
function profileStore.close(profile) profile.closing = true end
local modules = { Config = Config, Rules = Rules, Economy = Economy, ProfileStore = profileStore }
local services = { Players = players, ReplicatedStorage = { WaitForChild = function() return shared end }, Lighting = {} }
local shutdown
local gameMock = {
	GetService = function(_, name) return services[name] end,
	BindToClose = function(_, callback) shutdown = callback end,
}
local workspaceMock = setmetatable({
	GetServerTimeNow = function() return scheduler.now end,
	FindFirstChild = function(self, name) return rawget(self, name) end,
}, {
	__newindex = function(self, name, value)
		-- Roblox permits this write only in Studio properties, plugins or the command bar.
		if name == "FallenPartsDestroyHeight" then
			error("FallenPartsDestroyHeight cannot be written by a runtime game script")
		end
		rawset(self, name, value)
	end,
})
local function tuple(...) return { ... } end
modules.Workshop = loadWorkshop(gameMock, workspaceMock, instance,
	{ new = tuple }, { fromRGB = tuple }, {
		Material = { SmoothPlastic = "SmoothPlastic" },
		SurfaceType = { Smooth = "Smooth" }, PartType = { Ball = "Ball" },
	})
taskMock.spawn(function()
	runServer(gameMock, workspaceMock, taskMock, instance,
		{ new = function() return { NextInteger = function(_, low, high) return math.random(low, high) end } end },
		function(name) return assert(modules[name], name) end,
		{ Parent = { ProfileStore = "ProfileStore", Workshop = "Workshop" } }, { clock = function() return scheduler.now end })
end)
local function request(target, name, a, b, c, roundId)
	shared.Remotes.Action.OnServerEvent:Fire(target, name, a, b, c, roundId or snapshots[target].roundId)
	advance(0.001)
end
local function untilPhase(name)
	local timeout = scheduler.now + 30
	while snapshots[ada].phase ~= name and scheduler.now < timeout do advance(0.05) end
	assert(snapshots[ada].phase == name, "phase timeout: " .. name)
end
advance(1.1)
check(workspaceMock.CloudpopWorkshop and workspaceMock.CloudpopWorkshop.WelcomeMat
	and shared.Remotes and shared.Remotes.Action and shared.Remotes.State,
	"real workshop initialization completes and the server publishes both remotes")
check(#snapshots[ada].cards == 2 and #snapshots[ben].cards == 2, "every player receives two free cards")
check(snapshots[ada].deck == nil and #snapshots[ada].history == 0, "snapshots do not expose future draws")
request(ada, "Goal", "twins", nil, nil, -100)
check(snapshots[ada].goal == "trail" and not snapshots[ada].participated, "stale round requests cannot change an objective")
request(ada, "Mark", 1, 1)
check(not snapshots[ada].cards[1].cells[1].marked, "mark requests during intermission cannot mark undrawn numbers")
request(ada, "Swap", 1, 1, 2)
check(not snapshots[ada].swapped, "board swaps are rejected outside the event")
request(ada, "Goal", "twins")
request(ben, "Goal", "trail")
request(ada, "Setting", "autoMark", true)
request(ben, "Setting", "autoMark", true)
local early = player(4)
players.PlayerAdded:Fire(early)
advance(0.01)
request(early, "Goal", "trail")
players.PlayerRemoving:Fire(early)
early.Parent = nil
for index, entry in ipairs(playersList) do if entry == early then table.remove(playersList, index); break end end
advance(0.01)
check(savedProfiles[early].data.pesos == 0, "joining and leaving before the first draw cannot farm participation rewards")
untilPhase("Drawing")
check(snapshots[ada].history[1] == snapshots[ben].history[1], "clients see the same shared draw")
local originalGoal = snapshots[ada].goal
request(ada, "Goal", "trail")
check(snapshots[ada].goal == originalGoal, "objectives cannot change after drawing begins")
local late = player(3)
players.PlayerAdded:Fire(late)
advance(0.01)
check(#snapshots[late].cards == 0, "mid-round joins spectate until fresh cards are dealt")
untilPhase("Event")
local oldFirst = snapshots[ada].cards[1].cells[1].number
local oldSecond = snapshots[ada].cards[1].cells[2].number
request(ada, "Swap", 1, 1, 2)
check(snapshots[ada].swapped and snapshots[ada].cards[1].cells[1].number == oldSecond,
	"an event swap uses the server's card and changes the selected cells")
request(ada, "Swap", 1, 1, 2)
check(snapshots[ada].cards[1].cells[2].number == oldFirst, "repeated event requests cannot grant extra swaps")
request(ben, "Keep")
check(snapshots[ben].swapped and snapshots[ben].participated, "keeping the layout confirms a valid event decision")
local before = snapshots[ada].pesos
request(ada, "Reward", 999999)
request(ada, "Cosmetic", { id = "marker_berry", price = -999 })
check(snapshots[ada].pesos == before and not snapshots[ada].owned.marker_berry, "fabricated rewards and purchase prices are ignored")
untilPhase("Results")
local result = snapshots[ada]
check(result.pesos == result.summary.total and result.pesos >= 20 and result.pesos <= 60,
	"server settlement grants only the disclosed earned rewards")
request(ada, "Mark", 1, 1)
request(ada, "Keep")
request(ada, "Reward", 9999)
check(snapshots[ada].pesos == result.pesos, "post-round actions cannot duplicate rewards")
untilPhase("Intermission")
check(#snapshots[late].cards == 2, "spectators receive their two free cards next round")
request(ada, "Goal", "trail")
untilPhase("Drawing")
local coins = savedProfiles[ada].data.pesos
players.PlayerRemoving:Fire(ada)
ada.Parent = nil
for index, entry in ipairs(playersList) do if entry == ada then table.remove(playersList, index); break end end
advance(0.01)
check(savedProfiles[ada].data.pesos == coins + 20 and savedProfiles[ada].closing,
	"leaving settles eligible participation and closes the profile once")
taskMock.spawn(shutdown)
advance(0.2)
check(savedProfiles[ben].closing and savedProfiles[late].closing, "server shutdown closes every remaining profile")

print("Server protocol: " .. passed .. " checks passed (mock Roblox services)")
