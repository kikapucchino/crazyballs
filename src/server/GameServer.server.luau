local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Cloudpop")
local Config = require(Shared.Config)
local Rules = require(Shared.GameRules)
local Manifest = require(Shared.AudioManifest)
local Economy = require(Shared.Economy)
local Profiles = require(script.Parent.ProfileStore)
local Holder = require(script.Parent.CardHolder)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = Shared
local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

-- Publish networking before constructing scenery, so a scene error cannot hide the protocol.
require(script.Parent.Workshop).build()
local rng = Random.new()
local function nextInteger(low, high) return rng:NextInteger(low, high) end
local profiles, boards, summaries, rateLimits, loading, characterConnections = {}, {}, {}, {}, {}, {}
local round = { id = 0, phase = "Waiting", deadline = 0, history = {}, drawn = {}, announcement = nil, announcementId = 0 }
local closing = false

local function usable(player)
	return Profiles.writable(profiles[player])
end

local function changed(profile)
	profile.revision = (profile.revision or 0) + 1
	if not profile.practice then profile.saveStatus = "Changes waiting to save" end
end

local function send(player, notice)
	local profile = profiles[player]
	if not profile or player.Parent ~= Players then return end
	local board = boards[player]
	local cardViews = {}
	if board then
		for cardIndex, card in ipairs(board.cards) do
			local cells = {}
			for _, number in ipairs(card) do
				table.insert(cells, { number = number, marked = board.marks[cardIndex][number] == true,
					available = round.drawn[number] == true })
			end
			table.insert(cardViews, { cells = cells, multiplier = board.multipliers[cardIndex] })
		end
	end
	local bonusViews = {}
	for _, definition in ipairs(Config.Bonuses) do
		local card = board and board.bonuses[definition.id]
		local cells = {}
		if card then
			for _, number in ipairs(card.numbers) do
				table.insert(cells, { number = number, marked = round.drawn[number] == true })
			end
		end
		table.insert(bonusViews, { id = definition.id, name = definition.name, cells = cells,
			progress = if card then card.progress else 0, target = definition.count,
			qualified = card and card.qualified == true, pending = true })
	end
	-- Future draws and other players' profiles never leave the server.
	stateEvent:FireClient(player, {
		roundId = round.id, phase = round.phase, deadline = round.deadline,
		history = round.history, drawCount = Config.DrawCount, cards = cardViews,
		announcement = round.announcement, activeBonus = nil, bonuses = bonusViews, mainPending = not Config.Main.RewardsConfirmed, bonusPending = true,
		participated = if board then board.participated else false,
		pesos = profile.data.pesos, rounds = profile.data.rounds,
		owned = profile.data.owned, equipped = profile.data.equipped, settings = profile.data.settings,
		saveStatus = profile.saveStatus, practice = profile.practice,
		players = #Players:GetPlayers(), summary = summaries[player], notice = notice,
	})
end

local function broadcast()
	for player in pairs(profiles) do send(player) end
end

local function settle(player)
	local board, profile = boards[player], profiles[player]
	if not board or not profile or not usable(player) then return end
	-- Opening cards and leaving before the first draw is not a played round.
	if #round.history == 0 then return end
	local summary = Rules.settle(board, Config.Rewards)
	if not summary then return end
	profile.data.pesos += summary.total
	if board.participated then profile.data.rounds += 1 end
	changed(profile)
	summaries[player] = summary
end

local function addPlayer(player)
	if profiles[player] or loading[player] or closing then return end
	loading[player] = true
	local profile, problem = Profiles.load(player)
	loading[player] = nil
	if not profile then
		if player.Parent == Players then player:Kick(problem) end
		return
	end
	if player.Parent ~= Players or closing then
		Profiles.close(profile)
		return
	end
	profiles[player] = profile
	characterConnections[player] = player.CharacterAdded:Connect(function() task.spawn(Holder.give, player) end)
	task.spawn(Holder.give, player)
	if round.phase == "Intermission" then
		boards[player] = Rules.newCardState(Config, nextInteger)
	end
	broadcast()
end

local function removePlayer(player)
	local profile = profiles[player]
	if profile then
		-- Earned progress is settled even if a player leaves before the results screen.
		settle(player)
		Profiles.close(profile)
	end
	if characterConnections[player] then characterConnections[player]:Disconnect(); characterConnections[player] = nil end
	profiles[player], boards[player], summaries[player], rateLimits[player] = nil, nil, nil, nil
	broadcast()
end

action.OnServerEvent:Connect(function(player, name, a, b, c, requestedRound)
	if type(name) ~= "string" or not profiles[player] then return end
	local now = os.clock()
	local budget = rateLimits[player] or { tokens = 16, at = now }
	budget.tokens = math.min(16, budget.tokens + (now - budget.at) * 8)
	budget.at = now
	rateLimits[player] = budget
	if budget.tokens < 1 then return end
	budget.tokens -= 1
	if name == "Sync" then send(player); return end
	if not usable(player) then send(player, "Saving is reconnecting. Please wait."); return end
	local profile, board = profiles[player], boards[player]
	local notice
	if name == "Cosmetic" then
		local bought, message = Economy.purchase(profile.data, Config.Catalog, a)
		if bought then changed(profile) end
		notice = message
	elseif name == "Setting" then
		if a == "reducedMotion" then
			if type(b) ~= "boolean" then return end
		elseif a == "musicVolume" or a == "voiceVolume" or a == "sfxVolume" then
			if type(b) ~= "number" or b ~= b or b < 0 or b > 1 then return end
		else return end
		profile.data.settings[a] = b
		changed(profile)
	elseif board and requestedRound == round.id and not board.settled then
		if name == "Participate" then
			board.participated = true
		elseif name == "Mark" and (round.phase == "Drawing" or round.phase == "LastCall") then
			Rules.mark(board, round.drawn, a, b)
		end
	end
	send(player, notice)
end)

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(addPlayer, player) end

task.spawn(function()
	while not closing do
		task.wait(45)
		for player, profile in pairs(profiles) do
			if not profile.closing then
				task.spawn(function()
					Profiles.save(profile, false)
					if not profile.closing and not Profiles.writable(profile) then
						player:Kick("Your cloud save connection was interrupted. Please rejoin shortly.")
					else
						send(player)
					end
				end)
			end
		end
	end
end)

local function updateDisplay()
	local model = workspace:FindFirstChild("CloudpopWorkshop")
	if not model then return end
	local display, ball = model:FindFirstChild("DrawDisplay"), model:FindFirstChild("DrawnBall")
	local current = round.history[#round.history]
	local viewing = model:FindFirstChild("ViewingDisplay")
	if viewing then viewing.Readout.Text.Text = (if current then "BALL " .. current else "NEXT ROUND") .. "\n" .. #round.history .. " / " .. Config.DrawCount end
	if display then display.Readout.Text.Text = (if current then "BALL " .. current else "NEXT ROUND") .. "\n" .. #round.history .. " / " .. Config.DrawCount end
	if ball then ball.BallNumber.Text.Text = if current then tostring(current) else "—" end
end
local function phase(name, seconds, announcementKey)
	if announcementKey then
		local entry = assert(Manifest[announcementKey], "Missing announcement manifest entry")
		assert(entry.duration > 0 and entry.duration <= 3, "Voice clips must be at most 3 seconds for the draw cadence")
		round.announcementId += 1
		round.announcement = { id = round.announcementId, roundId = round.id, key = announcementKey,
			text = entry.text, duration = entry.duration, at = workspace:GetServerTimeNow() }
	end
	round.phase = name
	updateDisplay()
	round.deadline = workspace:GetServerTimeNow() + seconds
	broadcast()
	while not closing and workspace:GetServerTimeNow() < round.deadline do
		task.wait(math.min(0.15, round.deadline - workspace:GetServerTimeNow()))
	end
end

game:BindToClose(function()
	closing = true
	local remaining = 0
	for player, profile in pairs(profiles) do
		remaining += 1
		task.spawn(function()
			settle(player)
			Profiles.close(profile)
			remaining -= 1
		end)
	end
	local timeout = os.clock() + 25
	while (remaining > 0 or next(loading)) and os.clock() < timeout do task.wait(0.1) end
end)

while not closing do
	if next(profiles) == nil then
		round.phase = "Waiting"
		task.wait(1)
		continue
	end
	round.id += 1
	round.history, round.drawn = {}, {}
	boards, summaries = {}, {}
	for player in pairs(profiles) do
		if usable(player) then boards[player] = Rules.newCardState(Config, nextInteger) end
	end
	phase("Assignment", 0)
	phase("Intermission", Config.IntermissionSeconds, "upcoming")
	phase("Drawing", Manifest.start.duration, "start")
	local deck = Rules.shuffle(Config.NumberPool, nextInteger)
	for index = 1, Config.DrawCount do
		if closing then break end
		local number = deck[index]
		round.drawn[number] = true
		table.insert(round.history, number)
		for player, board in pairs(boards) do
			Rules.qualify(board, round.drawn)
		end
		phase("Drawing", Config.DrawSeconds, "number_" .. number)
	end
	if closing then break end
	phase("LastCall", 8, "lastCall")
	phase("Qualification", 0)
	-- Bonus execution is intentionally gated until distribution, timing and deduction rules are confirmed.
	for player in pairs(profiles) do settle(player) end
	phase("Results", Config.ResultsSeconds, "results")
	phase("Reset", 0)
end
