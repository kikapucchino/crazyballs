local startClient = require("./.generated/ClientHarness")
local loadAudio = require("./.generated/AudioControllerHarness")
local loadPanel = require("./.generated/CardPanelHarness")
local loadEffects = require("./.generated/WorldEffectsHarness")
local loadHolder = require("./.generated/CardHolderHarness")
local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")
local Mock = require("./mock")
local passed = 0
local function test(name, callback)
	local ok, problem = pcall(callback)
	assert(ok, name .. ": " .. tostring(problem))
	passed += 1
	print("PASS " .. name)
end
local function environment(missing)
	local new, all, methods = Mock.instances()
	local warnings, requests, deferred, delayed = {}, {}, {}, {}
	local gui = new("ScreenGui", "CloudpopUI")
	local status = new("TextLabel", "StartupStatus", gui)
	local replication = new("ReplicatedStorage")
	local shared = new("Folder", "Cloudpop", replication)
	local layout = new("ModuleScript", "CardLayout", shared)
	local manifest = new("ModuleScript", "AudioManifest", shared)
	local panel = new("ModuleScript", "CardPanel", gui)
	local config, economy = new("ModuleScript", "Config", shared), new("ModuleScript", "Economy", shared)
	local audioModule, effectsModule = new("ModuleScript", "AudioController", gui), new("ModuleScript", "WorldEffects", gui)
	local remotes
	if not missing then
		remotes = new("Folder", "Remotes", shared)
		new("RemoteEvent", "Action", remotes)
		new("RemoteEvent", "State", remotes)
	end
	local player = new("Player")
	local services = { ContentProvider = { PreloadAsync = function(_, ids, callback)
		for _, id in ipairs(ids) do callback(id, "AssetFetchStatus.Success") end
	end }, UserInputService = { TouchEnabled = false }, Players = { LocalPlayer = player }, ReplicatedStorage = replication, SoundService = new("SoundService"),
		RunService = { RenderStepped = Mock.signal() }, TweenService = { Create = function(_, target, _, properties)
			return { Play = function() for k, v in pairs(properties) do target[k] = v end end, Cancel = function() end }
		end } }
	function methods:FireServer(...) table.insert(requests, table.pack(...)) end
	local env = Mock.globals()
	env.game = { GetService = function(_, name) return assert(services[name], name) end }
	env.script = { Parent = gui }
	env.workspace = { GetServerTimeNow = function() return 1 end, FindFirstChild = function() return nil end }
	env.task = {
		defer = function(callback) table.insert(deferred, callback) end,
		delay = function(_, callback) table.insert(delayed, callback) end,
		spawn = function(callback, ...)
			local ok, problem = coroutine.resume(coroutine.create(callback), ...)
			assert(ok, problem)
		end,
		wait = function() coroutine.yield() end,
	}
	env.Instance, env.warn = { new = new }, function(message) table.insert(warnings, message) end
	env.require = function(module)
		if module == config then return Config elseif module == economy then return Economy
		elseif module == panel then return loadPanel(env) elseif module == layout then return require("../src/shared/CardLayout") elseif module == manifest then return require("../src/shared/AudioManifest") elseif module == audioModule then return loadAudio(env) elseif module == effectsModule then return loadEffects(env) end
		error("Unknown module")
	end
	return { env = env, gui = gui, status = status, remotes = remotes, warnings = warnings, requests = requests,
		deferred = deferred, delayed = delayed, services = services, new = new, all = all, player = player }
end
local function snapshot(phase)
	local data, bonuses = Economy.defaults(), {}
	for _, definition in ipairs(Config.Bonuses) do
		local cells = {}
		for index = 1, definition.count do cells[index] = {number = index, marked = false} end
		table.insert(bonuses, { id=definition.id, name=definition.name, cells=cells, target=definition.count, progress=0, qualified=false })
	end
	return { roundId=1, phase=phase, deadline=10, history={}, drawCount=20, cards={}, bonuses=bonuses, mainPending=true,
		pesos=0, owned=data.owned, equipped=data.equipped, settings=data.settings, saveStatus="Studio practice", practice=true, players=2 }
end
test("real client starts with horizontal bottom-center cards and requests sync", function()
	local h = environment()
	startClient(h.env)
	assert(#h.warnings == 0, h.warnings[1])
	assert(not h.status.Visible and h.gui.CardPanel.Visible)
	assert(h.gui.HUD and #h.requests == 1 and h.requests[1][1] == "Sync")
	for _, callback in ipairs(h.deferred) do callback() end
	h.remotes.State.OnClientEvent:Fire(snapshot("Intermission"))
	h.gui.CardsButton.Activated:Fire()
	h.gui.CardsButton.Activated:Fire()
	assert(h.gui.CardPanel.Visible and h.requests[#h.requests][1] == "Participate")
	assert(h.gui:FindFirstChild("MainCard1", true):FindFirstChild("Cell25").Text == "—")
	assert(h.gui:FindFirstChild("Credits", true).Text == "Created by Kikapucchino")
end)
test("missing remotes retain a readable startup error", function()
	local h = environment(true)
	startClient(h.env)
	assert(h.status.Visible and string.find(h.status.Text, "Remotes") and #h.warnings == 1)
end)
test("real client renders draws, qualification, results and sends server-validated actions", function()
	local h = environment()
	startClient(h.env)
	assert(#h.warnings == 0, h.warnings[1])
	local data = snapshot("Drawing")
	data.history, data.mainPending = { 1, 2, 3 }, false
	local cells = {}
	for i=1,25 do cells[i] = {number=i, marked=false, available=i<=3} end
	data.cards = {{cells=cells,multiplier=7}}
	data.bonuses[1].qualified, data.bonuses[1].progress = true, 3
	h.remotes.State.OnClientEvent:Fire(data)
	assert(h.gui.HUD.CurrentBall.Text == "3" and h.gui.HUD.DrawCount.Text == "3 / 20")
	assert(string.find(h.gui:FindFirstChild("coin", true).Progress.Text, "QUALIFIED"))
	h.gui:FindFirstChild("MainCard1", true).Cell1.Activated:Fire()
	local request = h.requests[#h.requests]
	assert(request[1] == "Mark" and request[2] == 1 and request[3] == 1 and request[5] == 1)
	data.phase, data.summary, data.pesos = "Results", {total=20}, 20
	h.remotes.State.OnClientEvent:Fire(data)
	assert(h.gui.HUD.Pesos.Text == "20 Pesos")
	h.services.RunService.RenderStepped:Fire(0.1)
end)
test("equipping the replicated holder opens cards without camera changes", function()
	local h = environment()
	startClient(h.env)
	assert(#h.warnings == 0, h.warnings[1])
	local character = h.new("Model")
	h.player.CharacterAdded:Fire(character)
	character.ChildAdded:Fire(h.new("Tool", "Cards"))
	assert(h.gui.CardPanel.Visible)
	assert(h.env.workspace.CurrentCamera == nil)
end)
test("card-holder grant is idempotent and creates a visible, noncolliding tool", function()
	local h = environment()
	local player = h.new("Player", "Ada", h.new("Players"))
	local backpack = h.new("Backpack", "Backpack", player)
	local holder = loadHolder(h.env)
	holder.give(player); holder.give(player)
	assert(#backpack:GetChildren() == 1 and backpack.Cards.Handle and not backpack.Cards.CanBeDropped)
	assert(not backpack.Cards.Handle.CanCollide and backpack.Cards.Handle.Massless)
	player.Character = h.new("Model")
	backpack.Cards.Parent = player.Character
	holder.give(player)
	assert(#backpack:GetChildren() == 0)
end)
test("audio skips empty IDs and rapid track switches leave only the newest track playing", function()
	local h = environment()
	local audio = loadAudio(h.env).new({ Music={lobby="", coin="rbxassetid://123", duck="rbxassetid://456"}, SFX={} })
	audio:setTrack("lobby")
	for _, callback in ipairs(h.delayed) do callback() end
	assert(not h.services.SoundService.CloudpopMusic.IsPlaying)
	table.clear(h.delayed)
	audio:setTrack("coin"); audio:setTrack("duck")
	for _, callback in ipairs(h.delayed) do callback() end
	assert(h.services.SoundService.CloudpopMusic.SoundId == "rbxassetid://456")
	local playing = 0
	for _, sound in ipairs(h.services.SoundService:GetChildren()) do if sound.IsPlaying then playing += 1 end end
	assert(playing == 1)
end)
test("queued human voice ducks one looping track and restores it after the cue",function()
	local h=environment()
	local audio=loadAudio(h.env).new({Music={lobby="rbxassetid://123",coin="rbxassetid://456"},SFX={}},
		{number_7={assetId="rbxassetid://789"}})
	audio:setTrack("lobby")
	for _,callback in ipairs(h.delayed) do callback() end
	local sound=h.services.SoundService
	assert(sound.CloudpopMusic.Looped and sound.CloudpopMusic.Volume==0.5)
	audio:announce({id=1,key="number_7",text="Number 7.",at=0,duration=1.5},0)
	assert(audio:update(0)=="Number 7." and sound.CloudpopVoice.IsPlaying)
	assert(math.abs(sound.CloudpopMusic.Volume-0.11)<0.00001)
	audio:setVolumes({musicVolume=0.8,voiceVolume=0,sfxVolume=0})
	assert(sound.CloudpopVoice.Volume==0 and sound.CloudpopMusic.Volume==0.8)
	audio:setVolumes({musicVolume=0.8,voiceVolume=1,sfxVolume=0})
	assert(math.abs(sound.CloudpopMusic.Volume-0.176)<0.00001)
	audio:announce({id=2,key="number_7",text="Queued",at=1.5,duration=1.5},0.1)
	assert(audio:update(0.1)=="Number 7.")
	assert(audio:update(1.5)=="Queued")
	assert(audio:update(3)=="" and not sound.CloudpopVoice.IsPlaying and sound.CloudpopMusic.Volume==0.8)
end)
test("duplicate, expired and missing voice cues cannot replay old numbers or duck silent audio",function()
	local h=environment()
	local audio=loadAudio(h.env).new({Music={lobby="rbxassetid://123"},SFX={}},{number_1={assetId=""}})
	audio:setTrack("lobby");for _,callback in ipairs(h.delayed) do callback() end
	audio:announce({id=1,key="number_1",text="Number 1.",at=0,duration=1.5},0)
	assert(audio:update(0)=="Number 1." and not h.services.SoundService.CloudpopVoice.IsPlaying)
	assert(h.services.SoundService.CloudpopMusic.Volume==0.5)
	audio:update(2)
	audio:announce({id=1,key="number_1",text="Wrong replay",at=2,duration=1.5},2)
	audio:announce({id=2,key="number_1",text="Expired",at=0,duration=1.5},2)
	assert(audio:update(2)=="")
end)
test("all sixty voice-manifest number subtitles match their immutable draw key",function()
	local manifest=require("../src/shared/AudioManifest")
	for number=1,60 do
		local cue=manifest["number_"..number]
		assert(cue and cue.text=="Number "..number.."." and cue.duration<=3 and cue.assetId=="")
	end
	for _,key in ipairs({"upcoming","start","lastCall","results","coin","duck","pacinki","crazy"}) do assert(manifest[key]) end
end)
test("main cells use distinct symbols for called and marked states; volume mute sends a setting",function()
	local h=environment();startClient(h.env)
	local data=snapshot("Drawing");local cells={}
	for index=1,25 do cells[index]={number=index,marked=index==2,available=index<=2} end
	data.cards={{cells=cells,multiplier=20}}
	h.remotes.State.OnClientEvent:Fire(data)
	local card=h.gui:FindFirstChild("MainCard1",true)
	assert(card.Cell1.Text=="•1" and card.Cell2.Text=="✓2" and card.Cell3.Text=="3")
	assert(string.find(card.Multiplier.Text,"20×"))
	h.gui:FindFirstChild("voiceVolumeMute",true).Activated:Fire()
	local request=h.requests[#h.requests]
	assert(request[1]=="Setting" and request[2]=="voiceVolume" and request[3]==0)
end)
test("unloaded voice assets fall back to the correct subtitle without delayed playback",function()
	local h=environment()
	h.services.ContentProvider.PreloadAsync=function() end
	local audio=loadAudio(h.env).new({Music={},SFX={}},{number_9={assetId="rbxassetid://789"}})
	audio:announce({id=1,key="number_9",text="Number 9.",at=0,duration=1.5},0)
	assert(audio:update(0)=="Number 9." and not h.services.SoundService.CloudpopVoice.IsPlaying)
	assert(audio:update(2)=="")
end)
print("Client/tool/audio: " .. passed .. " tests passed (mock Roblox services)")
