-- Execute the actual client initializer and render callbacks without a Roblox renderer.
local startClient = require("./.generated/ClientHarness")
local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")
local passed = 0
local function test(name, callback)
	local ok, message = pcall(callback)
	assert(ok, name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end

local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback) table.insert(callbacks, callback) end,
		Fire = function(_, ...)
			for _, callback in ipairs(callbacks) do callback(...) end
		end,
	}
end

local function environment(missing)
	local instances, warnings, requests, deferred = {}, {}, {}, {}
	local methods = {}
	local function node(class, name, parent)
		local properties = { ClassName = class, Name = name or class, AbsoluteSize = { X = 400, Y = 300 },
			Visible = true, Activated = signal(), OnClientEvent = signal() }
		local children = {}
		local object = setmetatable({}, {
			__index = function(_, key)
				if key == "children" then return children end
				return methods[key] or properties[key]
			end,
			__newindex = function(self, key, value)
				properties[key] = value
				if key == "Parent" then table.insert(value.children, self) end
			end,
		})
		if parent then object.Parent = parent end
		table.insert(instances, object)
		return object
	end
	function methods:FindFirstChild(name, recursive)
		for _, child in ipairs(self.children) do
			if child.Name == name then return child end
			if recursive then
				local found = child:FindFirstChild(name, true)
				if found then return found end
			end
		end
		return nil
	end
	function methods:WaitForChild(name) return self:FindFirstChild(name) end
	function methods:GetFullName() return self.Name end
	function methods:GetPropertyChangedSignal() return signal() end
	function methods:FireServer(...) table.insert(requests, table.pack(...)) end
	function methods:Play() end
	local gui = node("ScreenGui", "CloudpopUI")
	local status = node("TextLabel", "StartupStatus", gui)
	status.Text = "Loading"
	local replication = node("ReplicatedStorage")
	local shared = node("Folder", "Cloudpop", replication)
	local config = node("ModuleScript", "Config", shared)
	local economy = node("ModuleScript", "Economy", shared)
	local remotes
	if missing ~= "Remotes" then
		remotes = node("Folder", "Remotes", shared)
		node("RemoteEvent", "Action", remotes)
		node("RemoteEvent", "State", remotes)
	end
	local services = {
		Players = { LocalPlayer = {} }, ReplicatedStorage = replication,
		RunService = { RenderStepped = signal() }, SoundService = node("SoundService"),
		TweenService = { Create = function() return { Play = function() end } end },
	}
	local enum = {}
	for group, names in pairs({
		Font = { "GothamMedium", "GothamBold", "GothamBlack" },
		TextXAlignment = { "Left", "Right", "Center" }, TextYAlignment = { "Center" },
		ZIndexBehavior = { "Sibling" }, AutomaticSize = { "Y" }, ScrollingDirection = { "Y" },
		SortOrder = { "LayoutOrder" }, PartType = { "Ball", "Block" }, Material = { "SmoothPlastic" },
		SurfaceType = { "Smooth" }, ApplyStrokeMode = { "Border" }, EasingStyle = { "Back" },
	}) do
		enum[group] = {}
		for _, name in ipairs(names) do enum[group][name] = group .. "." .. name end
	end
	local function constructor(...) return { ... } end
	local env = {
		game = { GetService = function(_, name) return assert(services[name], name) end },
		script = { Parent = gui }, workspace = { GetServerTimeNow = function() return 1 end },
		task = {
			defer = function(callback) table.insert(deferred, callback) end,
			delay = function() end,
			spawn = function(callback)
				local ok, problem = coroutine.resume(coroutine.create(callback))
				assert(ok, problem)
			end,
			wait = function() coroutine.yield() end,
		},
		Instance = { new = function(class) return node(class) end },
		require = function(module)
			if module == config then return Config end
			if module == economy then return Economy end
			error("unexpected require")
		end,
		warn = function(message) table.insert(warnings, message) end,
		Color3 = { fromRGB = constructor }, ColorSequence = { new = constructor },
		UDim = { new = constructor }, UDim2 = { new = constructor, fromOffset = constructor, fromScale = constructor },
		Vector2 = { new = constructor }, Vector3 = { new = constructor }, CFrame = { lookAt = constructor },
		Enum = enum, TweenInfo = { new = constructor },
	}
	return { env = env, gui = gui, status = status, remotes = remotes, instances = instances,
		warnings = warnings, requests = requests, deferred = deferred, services = services }
end

local function snapshot(phase)
	local data = Economy.defaults()
	local cards = {}
	for cardIndex = 1, 2 do
		local cells = {}
		for number = 1, 9 do
			cells[number] = { number = number + (cardIndex - 1) * 9, marked = false, available = false }
		end
		cards[cardIndex] = { cells = cells, complete = false }
	end
	return { roundId = 1, phase = phase, deadline = 10, history = {}, drawCount = 18, cards = cards,
		goal = "trail", goalProgress = 0, goalTarget = 5, swapped = false, participated = false,
		pesos = 0, rounds = 0, owned = data.owned, equipped = data.equipped, settings = data.settings,
		saveStatus = "Studio practice", practice = true, players = 1 }
end

test("packaged client builds the interface, subscribes and requests its first snapshot", function()
	local h = environment()
	startClient(h.env)
	assert(#h.warnings == 0, h.warnings[1])
	assert(not h.status.Visible)
	assert(h.gui:FindFirstChild("Cards", true) and h.gui:FindFirstChild("Wardrobe", true))
	assert(#h.requests == 1 and h.requests[1][1] == "Sync")
	for _, callback in ipairs(h.deferred) do callback() end
	h.remotes:FindFirstChild("State").OnClientEvent:Fire(snapshot("Intermission"))
	assert(h.gui:FindFirstChild("Card1", true):FindFirstChild("Cell1", true).Text == "1")
end)

test("missing server remotes show a visible startup error instead of an empty workshop", function()
	local h = environment("Remotes")
	startClient(h.env)
	assert(h.status.Visible and string.find(h.status.Text, "Remotes"))
	assert(#h.warnings == 1 and #h.requests == 0)
end)

test("client renders drawing, event, results and spectator snapshots", function()
	local h = environment()
	startClient(h.env)
	assert(#h.warnings == 0, h.warnings[1])
	local event = h.remotes:FindFirstChild("State").OnClientEvent
	local drawing = snapshot("Drawing")
	drawing.history = { 1 }
	drawing.cards[1].cells[1].available = true
	event:Fire(drawing)
	h.gui:FindFirstChild("Card1", true):FindFirstChild("Cell1", true).Activated:Fire()
	assert(h.requests[#h.requests][1] == "Mark" and h.requests[#h.requests][5] == 1)
	event:Fire(snapshot("Event"))
	assert(h.gui:FindFirstChild("TailwindSwitch", true).Visible)
	local result = snapshot("Results")
	result.summary = { total = 35, participation = 20, patterns = 15, objective = 0 }
	result.pesos = 35
	event:Fire(result)
	assert(h.gui:FindFirstChild("RoundResults", true).Visible)
	local spectator = snapshot("Drawing")
	spectator.cards = {}
	event:Fire(spectator)
	assert(h.gui:FindFirstChild("Card1", true):FindFirstChild("Cell1", true).Text == "—")
	h.services.RunService.RenderStepped:Fire(0.1)
end)

print("Client startup: " .. passed .. " tests passed (mock Roblox services)")
