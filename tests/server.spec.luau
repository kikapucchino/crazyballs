-- Executes the actual server controller with deterministic scheduling and mock services.
-- This verifies protocol behavior; Studio remains required for real Roblox integration.
local runServer = require("./.generated/ServerHarness")
local loadWorkshop = require("./.generated/WorkshopHarness")
local Rules = require("../src/shared/GameRules")
local Economy = require("../src/shared/Economy")
local Mock = require("./mock")
local Config = require("../src/shared/Config")

Config.ResultsSeconds = 1
Config.AutoMarkPass.Id=123
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
		Connect = function(_, callback) table.insert(handlers, callback); return { Disconnect = function() end } end,
		Fire = function(_, ...)
			for _, callback in ipairs(handlers) do taskMock.spawn(callback, ...) end
		end,
	}
end

local snapshots, playersList, savedProfiles = {}, {}, {}
local shared = { Config = "Config", GameRules = "Rules", Economy = "Economy", AudioManifest = "Manifest", ChestRules="ChestRules",PetBuilder="PetBuilder" }
local players = { PlayerAdded = signal(), PlayerRemoving = signal() }
function players:GetPlayers() return table.clone(playersList) end
local function player(id)
	local object = { UserId = id, Name="User"..id, Parent = players, CharacterAdded = signal() }
	function object:Kick(reason) self.kicked = reason end
	table.insert(playersList, object)
	return object
end
local ada, ben = player(1), player(2)
local newInstance, allInstances, methods = Mock.instances()
local instance = { new = newInstance }
function methods:FireClient(target, snapshot) snapshots[target] = copy(snapshot) end
local profileStore = {}
function profileStore.load(target)
	local profile = { data = Economy.defaults(), practice = true, saveStatus = "Test", closing = false }
	savedProfiles[target] = profile
	return profile
end
function profileStore.writable(profile) return profile and not profile.closing end
function profileStore.save() return true end
function profileStore.close(profile) profile.closing = true end
local modules = { Manifest = require("../src/shared/AudioManifest"), Config = Config, Rules = Rules, Economy = Economy, ProfileStore = profileStore, CardHolder = { give = function() end } }
modules.ChestRules=require("../src/shared/ChestRules")
modules.PassService=require("../src/server/PassService")
modules.PetBuilder={}
modules.PetService={new=function() return {sync=function() end,remove=function() end} end}
modules.ResultFeed=require("../src/server/ResultFeed")
modules.GlobalPayouts={new=function() return {submit=function() end,view=function() return {status="Studio test payouts are excluded"} end,pump=function() end} end}
local services = { RunService={IsStudio=function() return true end},MarketplaceService={PromptGamePassPurchaseFinished=signal(),UserOwnsGamePassAsync=function(_,id) return id==2 end},HttpService={},Players = players, ReplicatedStorage = { WaitForChild = function() return shared end }, Lighting = {} }
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
local globals = Mock.globals()
modules.Workshop = loadWorkshop(gameMock, workspaceMock, instance, globals.Vector3, globals.Color3, globals.Enum, globals.Vector2, globals.UDim2, function() return require("../src/server/LobbyPlan") end, {Parent={LobbyPlan="LobbyPlan"}})
taskMock.spawn(function()
	runServer(gameMock, workspaceMock, taskMock, instance,
		{ new = function() return { NextInteger = function(_, low, high) return math.random(low, high) end } end },
		function(name) return assert(modules[name], name) end,
		{ Parent = { ProfileStore = "ProfileStore", Workshop = "Workshop", CardHolder = "CardHolder",PassService="PassService",PetService="PetService",ResultFeed="ResultFeed",GlobalPayouts="GlobalPayouts" } }, { clock = function() return scheduler.now end,time=function() return 1800000000+math.floor(scheduler.now) end })
end)
local function request(target, name, a, b, c, roundId)
	shared.Remotes.Action.OnServerEvent:Fire(target, name, a, b, c, roundId or snapshots[target].roundId)
	advance(0.001)
end
local function untilPhase(name)
	local timeout = scheduler.now + 180
	while snapshots[ada].phase ~= name and scheduler.now < timeout do advance(0.05) end
	assert(snapshots[ada].phase == name, "phase timeout: " .. name)
end
advance(1.1)
check(workspaceMock.CloudpopWorkshop and workspaceMock.CloudpopWorkshop.WelcomeMat
	and shared.Remotes and shared.Remotes.Action and shared.Remotes.State,
	"real workshop initialization completes and the server publishes both remotes")
check(#snapshots[ada].cards == 2 and #snapshots[ada].cards[1].cells == 25 and snapshots[ada].mainPending, "two 5x5 cards deal before drawing while unconfirmed main rewards stay disabled")
check(snapshots[ada].deadline == snapshots[ben].deadline and snapshots[ada].deadline - 1 == 15,
	"both players share the same server-authored fifteen-second countdown")
local multipliers = { snapshots[ada].cards[1].multiplier, snapshots[ada].cards[2].multiplier }
check(multipliers[1]>=1 and multipliers[1]<=20 and multipliers[2]>=1 and multipliers[2]<=20, "both cards show bounded multipliers before the first ball")
request(ada,"Mark",1,1)
check(not snapshots[ada].cards[1].cells[1].marked,"manual marks cannot mark uncalled numbers")
request(ada,"Setting","autoMark",true)
check(snapshots[ada].settings.autoMark == false,"unowned auto-mark requests are rejected")
request(ben,"Setting","autoMark",true)
check(snapshots[ben].pass.owned and snapshots[ben].settings.autoMark,"verified owner can enable Auto Mark")
request(ada,"ClaimChest")
check(savedProfiles[ada].data.chest.claims==0,"unconfirmed chest remote cannot grant a reward")
check(#snapshots[ada].bonuses == 4 and #snapshots[ada].bonuses[1].cells == 3 and #snapshots[ada].bonuses[2].cells == 4,
	"every player gets separate 3/4/4 bonus cards and an explicit pending wheel card")
check(snapshots[ada].deck == nil and #snapshots[ada].history == 0, "snapshots do not expose future draws or hidden mappings")
request(ada, "Participate", nil, nil, nil, -100)
check(not snapshots[ada].participated, "stale participation requests are rejected")
request(ada, "Participate")
request(ben, "Participate")
local early = player(4)
players.PlayerAdded:Fire(early)
advance(0.01)
request(early, "Participate")
players.PlayerRemoving:Fire(early)
early.Parent = nil
for index, entry in ipairs(playersList) do if entry == early then table.remove(playersList, index); break end end
advance(0.01)
check(savedProfiles[early].data.pesos == 0, "leaving before the first draw cannot farm participation")
untilPhase("Drawing")
check(#snapshots[ada].history == 0 and snapshots[ada].announcement.key == "start", "at countdown zero drawing starts with one shared start announcement")
advance(1.6)
check(snapshots[ada].history[1] == snapshots[ben].history[1] and #snapshots[ada].history == 1, "clients see the same first draw")
check(snapshots[ada].announcement.key == "number_" .. snapshots[ada].history[1], "shared number voice cue matches the visible ball")
local late = player(3)
players.PlayerAdded:Fire(late)
advance(0.01)
check(#snapshots[late].bonuses[1].cells == 0, "mid-round joins wait for fresh bonus cards")
request(ada, "Reward", 999999)
request(ada, "Cosmetic", { id = "marker_berry", price = -999 })
request(ada, "BonusResult", "crazy", math.huge)
check(snapshots[ada].pesos == 0 and not snapshots[ada].owned.marker_berry, "forged rewards, multipliers and prices have no effect")
request(ada, "Setting", "musicVolume", 0.2)
check(snapshots[ada].settings.musicVolume == 0.2, "valid music settings persist on server")
request(ada, "Setting", "musicVolume", 0/0)
request(ada, "Setting", "sfxVolume", math.huge)
check(snapshots[ada].settings.musicVolume == 0.2 and snapshots[ada].settings.sfxVolume == 0.7, "invalid volume values cannot corrupt saves")
untilPhase("Results")
local result, seen = snapshots[ada], {}
check(#result.history == 20, "main round draws exactly twenty balls")
for index, number in ipairs(result.history) do
	assert(number >= 1 and number <= 60 and not seen[number])
	assert(snapshots[ben].history[index] == number)
	seen[number] = true
end
check(true, "all twenty draws are unique, bounded, and identical for both clients")
for _, target in ipairs({ ada, ben }) do
	for _, card in ipairs(snapshots[target].bonuses) do
		local matched = 0
		for _, cell in ipairs(card.cells) do if seen[cell.number] then matched += 1 end end
		assert(card.progress == matched and card.qualified == (#card.cells > 0 and matched == #card.cells))
	end
end
check(true, "each player's qualification is computed from their own card")
check(result.cards[1].multiplier == multipliers[1] and result.cards[2].multiplier == multipliers[2], "card multipliers are fixed through the full round")
for _, card in ipairs(result.cards) do for _, cell in ipairs(card.cells) do assert(not cell.marked) end end
check(true,"called numbers never mark main cells for an unowned player")
for _,card in ipairs(snapshots[ben].cards) do for _,cell in ipairs(card.cells) do assert(cell.marked==(seen[cell.number]==true)) end end
check(true,"verified Auto Mark owner marks exactly called matching cells on the shared draw")
check(result.pesos == 20 and result.summary.bonusPending, "only existing participation reward is paid while bonus rules are pending")
request(ada, "Participate")
request(ada, "Reward", 9999)
check(snapshots[ada].pesos == 20, "repeated/post-round actions cannot duplicate rewards")
untilPhase("Intermission")
check(#snapshots[late].bonuses[1].cells == 3 and #snapshots[ada].history == 0, "reset deals fresh free cards to late joiners and clears draw history")
request(ada, "Participate")
untilPhase("Drawing")
advance(1.6)
local coins = savedProfiles[ada].data.pesos
players.PlayerRemoving:Fire(ada)
ada.Parent = nil
for index, entry in ipairs(playersList) do if entry == ada then table.remove(playersList, index); break end end
advance(0.01)
check(savedProfiles[ada].data.pesos == coins + 20 and savedProfiles[ada].closing, "leaving settles existing participation before closing the save")
taskMock.spawn(shutdown)
advance(0.2)
check(savedProfiles[ben].closing and savedProfiles[late].closing, "shutdown closes every remaining profile")
print("Server protocol: " .. passed .. " checks passed (mock Roblox services)")
