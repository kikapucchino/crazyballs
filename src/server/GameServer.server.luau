local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Cloudpop")
local Config = require(Shared.Config)
local Rules = require(Shared.GameRules)
local Economy = require(Shared.Economy)
local Profiles = require(script.Parent.ProfileStore)
require(script.Parent.Workshop).build()

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = Shared
local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

local rng = Random.new()
local function nextInteger(low, high) return rng:NextInteger(low, high) end
local profiles, boards, summaries, rateLimits, loading = {}, {}, {}, {}, {}
local round = { id = 0, phase = "Waiting", deadline = 0, history = {}, drawn = {} }
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
			table.insert(cardViews, { cells = cells, complete = board.claimed[cardIndex] })
		end
	end
	local progress, target = 0, 5
	if board then progress, target = Rules.goalProgress(board) end
	-- Future draws and other players' profiles never leave the server.
	stateEvent:FireClient(player, {
		roundId = round.id, phase = round.phase, deadline = round.deadline,
		history = round.history, drawCount = Config.DrawCount, cards = cardViews,
		goal = if board then board.goal else "trail", goalProgress = progress, goalTarget = target,
		swapped = if board then board.swapped else false,
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

local function checkPatterns(player)
	local count = Rules.claimPatterns(boards[player])
	if count > 0 then
		send(player, "Row complete! +" .. count * Config.Rewards.Pattern .. " Pesos at round end.")
	end
end

local function settle(player)
	local board, profile = boards[player], profiles[player]
	if not board or not profile or not usable(player) then return end
	-- Choosing an objective and leaving before the first draw is not a played round.
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
	if round.phase == "Intermission" then
		boards[player] = Rules.newCardState(Config.NumberPool, nextInteger)
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
		if (a ~= "autoMark" and a ~= "reducedMotion") or type(b) ~= "boolean" then return end
		profile.data.settings[a] = b
		changed(profile)
		if board and not board.settled then
			board.participated = true
			if a == "autoMark" and b then
				Rules.markAll(board, round.drawn)
				checkPatterns(player)
			end
		end
	elseif board and requestedRound == round.id and not board.settled then
		if name == "Goal" and round.phase == "Intermission" and type(a) == "string" and Config.Goals[a] then
			board.goal = a
			board.participated = true
		elseif name == "Mark" and (round.phase == "Drawing" or round.phase == "Event" or round.phase == "LastCall") then
			if Rules.mark(board, round.drawn, a, b) then checkPatterns(player) end
		elseif name == "Swap" and round.phase == "Event" then
			if Rules.swap(board, a, b, c) then
				checkPatterns(player)
				notice = "Tailwind delivered! Your marks moved with their numbers."
			end
		elseif name == "Keep" and round.phase == "Event" and not board.swapped then
			board.swapped = true
			board.participated = true
			notice = "Layout kept. Enjoy the breeze!"
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

local function phase(name, seconds)
	round.phase = name
	round.deadline = workspace:GetServerTimeNow() + seconds
	broadcast()
	while not closing and workspace:GetServerTimeNow() < round.deadline do task.wait(0.15) end
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
		if usable(player) then boards[player] = Rules.newCardState(Config.NumberPool, nextInteger) end
	end
	phase("Intermission", Config.IntermissionSeconds)
	local deck = Rules.shuffle(Config.NumberPool, nextInteger)
	for index = 1, Config.DrawCount do
		if closing then break end
		local number = deck[index]
		round.drawn[number] = true
		table.insert(round.history, number)
		for player, board in pairs(boards) do
			if usable(player) and profiles[player].data.settings.autoMark then
				Rules.markAll(board, round.drawn)
				checkPatterns(player)
			end
		end
		phase("Drawing", Config.DrawSeconds)
		if index == Config.EventAfterDraw then phase("Event", Config.EventSeconds) end
	end
	if closing then break end
	phase("LastCall", 8)
	for player in pairs(profiles) do settle(player) end
	phase("Results", Config.ResultsSeconds)
end
