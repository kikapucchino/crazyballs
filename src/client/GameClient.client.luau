-- Compact HUD. Roblox owns the avatar, camera, chat, movement and backpack controls.
local gui = script.Parent
local status = gui:FindFirstChild("StartupStatus")
if status then status.Text = "Opening Cloudpop…" end
local function initialize()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local function waitFor(parent, name)
		local child = parent:WaitForChild(name, 15)
		assert(child, "Timed out waiting for " .. parent:GetFullName() .. "." .. name)
		return child
	end
	local shared = waitFor(ReplicatedStorage, "Cloudpop")
	local Config = require(waitFor(shared, "Config"))
	local Economy = require(waitFor(shared, "Economy"))
	local audio = require(waitFor(gui, "AudioController")).new(Config.Audio)
	local effects = require(waitFor(gui, "WorldEffects")).new()
	local remotes = waitFor(shared, "Remotes")
	local action, stateEvent = waitFor(remotes, "Action"), waitFor(remotes, "State")
	local colors = {
		navy = Color3.fromRGB(16, 30, 53), panel = Color3.fromRGB(24, 47, 78), blue = Color3.fromRGB(47, 84, 125),
		ice = Color3.fromRGB(226, 242, 255), muted = Color3.fromRGB(164, 190, 215), cyan = Color3.fromRGB(99, 222, 240),
	}
	local function make(class, name, parent, properties)
		local object = Instance.new(class)
		object.Name = name
		for key, value in pairs(properties or {}) do object[key] = value end
		object.Parent = parent
		return object
	end
	local function round(object, radius)
		make("UICorner", "Corners", object, { CornerRadius = UDim.new(0, radius or 10) })
	end
	local function frame(name, parent, size, position)
		local object = make("Frame", name, parent, { Size = size, Position = position or UDim2.fromOffset(0, 0), BackgroundColor3 = colors.panel, BorderSizePixel = 0 })
		round(object)
		return object
	end
	local function label(name, parent, text, size, position, fontSize)
		return make("TextLabel", name, parent, { Text = text, Size = size, Position = position, BackgroundTransparency = 1,
			TextColor3 = colors.ice, TextSize = fontSize or 16, Font = Enum.Font.GothamMedium, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left })
	end
	local function button(name, parent, text, size, position, callback)
		local object = make("TextButton", name, parent, { Text = text, Size = size, Position = position,
			BackgroundColor3 = colors.blue, TextColor3 = colors.ice, TextSize = 14, Font = Enum.Font.GothamBold,
			BorderSizePixel = 0, AutoButtonColor = true })
		round(object, 8)
		object.Activated:Connect(callback)
		return object
	end
	local state, page, cardIndex, isOpen = nil, "Main", 1, false
	local previousRound, previousCount, previousQualified = nil, 0, {}
	local function request(name, a, b, c)
		action:FireServer(name, a, b, c, if state then state.roundId else 0)
	end
	local hud = frame("HUD", gui, UDim2.fromOffset(330, 116), UDim2.new(0.5, 0, 0, 10))
	hud.AnchorPoint = Vector2.new(0.5, 0)
	local ball = label("CurrentBall", hud, "—", UDim2.fromOffset(62, 62), UDim2.fromOffset(12, 8), 34)
	ball.TextXAlignment, ball.Font = Enum.TextXAlignment.Center, Enum.Font.GothamBold
	local counter = label("DrawCount", hud, "0 / 20", UDim2.new(1, -94, 0, 23), UDim2.fromOffset(86, 10), 18)
	local balance = label("Pesos", hud, "0 Pesos", UDim2.new(1, -94, 0, 22), UDim2.fromOffset(86, 34), 14)
	local history = label("RecentBalls", hud, "Waiting for the first ball", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 70), 13)
	local phaseText = label("Phase", hud, "Connecting…", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 92), 12)
	phaseText.TextColor3 = colors.muted
	local toast = label("Notice", gui, "", UDim2.fromOffset(330, 44), UDim2.new(1, -12, 0, 134), 14)
	toast.AnchorPoint, toast.BackgroundColor3, toast.BackgroundTransparency = Vector2.new(1, 0), colors.navy, 0.1
	toast.Visible = false
	round(toast)
	local noticeUntil = 0
	local function notify(text)
		toast.Text, toast.Visible = text, true
		noticeUntil = workspace:GetServerTimeNow() + 6
	end
	local panel = frame("CardPanel", gui, UDim2.fromOffset(330, 438), UDim2.new(1, -12, 0, 144))
	panel.AnchorPoint, panel.Visible = Vector2.new(1, 0), false
	label("PanelTitle", panel, "YOUR CARDS", UDim2.new(1, -68, 0, 36), UDim2.fromOffset(12, 4), 16)
	local tabs = {}
	local body = make("ScrollingFrame", "PanelBody", panel, { Position = UDim2.fromOffset(10, 96), Size = UDim2.new(1, -20, 1, -106),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromOffset(0, 360) })
	local pages = {}
	for _, name in ipairs({ "Main", "Bonuses", "Looks", "Settings" }) do
		pages[name] = make("Frame", name, body, { Size = UDim2.new(1, -6, 0, 500), BackgroundTransparency = 1, Visible = name == page })
	end
	local render, resize
	local function open(nextPage)
		page = nextPage or page
		isOpen, panel.Visible = true, true
		request("Participate")
		if render then render() end
	end
	button("Close", panel, "×", UDim2.fromOffset(44, 36), UDim2.new(1, -50, 0, 4), function() isOpen, panel.Visible = false, false; if resize then resize() end end)
	for index, name in ipairs({ "Main", "Bonuses", "Looks", "Settings" }) do
		tabs[name] = button(name .. "Tab", panel, name, UDim2.new(0.25, -6, 0, 44), UDim2.new((index - 1) / 4, 4, 0, 44), function() open(name) end)
	end
	button("CardsButton", gui, "Cards", UDim2.fromOffset(106, 44), UDim2.new(0.5, 4, 1, -126), function()
		if isOpen then isOpen, panel.Visible = false, false; if resize then resize() end else open() end
	end)
	button("SettingsButton", gui, "Settings", UDim2.fromOffset(88, 44), UDim2.new(0.5, -94, 1, -126), function() open("Settings") end)
	local main = pages.Main
	local mainHint = label("MainHint", main, "", UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, 0), 13)
	local card = frame("MainCard", main, UDim2.new(1, 0, 0, 280), UDim2.fromOffset(0, 52))
	local cells = {}
	for index = 1, 25 do
		cells[index] = button("Cell" .. index, card, "—", UDim2.new(0.2, -5, 0.2, -5),
			UDim2.new((index - 1) % 5 / 5, 3, math.floor((index - 1) / 5) / 5, 3), function() request("Mark", cardIndex, index) end)
	end
	local nextCard = button("NextCard", main, "Next card", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 340), function()
		if state and #state.cards > 0 then cardIndex = cardIndex % #state.cards + 1; render() end
	end)
	local bonusRows = {}
	for index, definition in ipairs(Config.Bonuses) do
		local row = frame(definition.id, pages.Bonuses, UDim2.new(1, 0, 0, 86), UDim2.fromOffset(0, (index - 1) * 94))
		local title = label("Title", row, definition.name, UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 6), 15)
		local numbers = label("Numbers", row, "", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 28), 18)
		local progress = label("Progress", row, "", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 57), 12)
		bonusRows[definition.id] = { title = title, numbers = numbers, progress = progress }
	end
	label("BonusPending", pages.Bonuses, "Bonus payouts await confirmed rules. Go CRazy: 64 segments and 3 prize pointers.", UDim2.new(1, 0, 0, 58), UDim2.fromOffset(0, 376), 13)
	local cosmeticButtons = {}
	for index, item in ipairs(Config.Catalog) do
		cosmeticButtons[item.id] = button(item.id, pages.Looks, item.name, UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, (index - 1) * 56), function() request("Cosmetic", item.id) end)
	end
	local settingButtons = {}
	for index, entry in ipairs({ { "autoMark", "Automatic marking" }, { "reducedMotion", "Reduced motion" } }) do
		local key, title = entry[1], entry[2]
		settingButtons[key] = button(key, pages.Settings, title, UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, (index - 1) * 52), function()
			if state then request("Setting", key, not state.settings[key]) end
		end)
	end
	local volumeLabels = {}
	for index, entry in ipairs({ { "musicVolume", "Music" }, { "sfxVolume", "Sound effects" } }) do
		local key, title, y = entry[1], entry[2], 108 + (index - 1) * 56
		volumeLabels[key] = label(key, pages.Settings, title, UDim2.new(1, -104, 0, 44), UDim2.fromOffset(0, y), 14)
		for _, delta in ipairs({ -0.1, 0.1 }) do
			button(key .. tostring(delta), pages.Settings, if delta < 0 then "−" else "+", UDim2.fromOffset(44, 44), UDim2.new(1, if delta < 0 then -96 else -46, 0, y), function()
				if state then request("Setting", key, math.clamp(math.floor(((state.settings[key] or 0) + delta) * 10 + 0.5) / 10, 0, 1)) end
			end)
		end
	end
	local saveLabel = label("SaveStatus", pages.Settings, "", UDim2.new(1, 0, 0, 54), UDim2.fromOffset(0, 224), 12)
	label("Credits", pages.Settings, "Created by Kikapucchino", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 284), 13)
	label("AudioSlots", pages.Settings, "Soundtrack slots are awaiting licensed audio.", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 319), 12)
	local function cosmeticColor(category, fallback)
		local item = state and Economy.find(Config.Catalog, state.equipped[category])
		return if item then Color3.fromRGB(table.unpack(item.color)) else fallback
	end
	render = function()
		for name, view in pairs(pages) do
			view.Visible = name == page
			tabs[name].BackgroundColor3 = if name == page then colors.blue else colors.navy
		end
		local heights = { Main = 394, Bonuses = 444, Looks = 340, Settings = 366 }
		body.CanvasSize = UDim2.fromOffset(0, heights[page])
		if resize then resize() end
		if not state then return end
		ball.Text = tostring(state.history[#state.history] or "—")
		counter.Text, balance.Text = #state.history .. " / " .. state.drawCount, tostring(state.pesos) .. " Pesos"
		local recent = {}
		for index = math.max(1, #state.history - 5), #state.history do table.insert(recent, tostring(state.history[index])) end
		history.Text = if #recent > 0 then "Recent  ·  " .. table.concat(recent, "  ·  ") else "Fresh pool · 1–60"
		cardIndex = math.min(cardIndex, math.max(1, #state.cards))
		local data = state.cards[cardIndex]
		mainHint.Text = if state.mainPending then "5×5 cards · count, patterns and free center await confirmation." elseif not data then "Next round: your free cards arrive together." else "Card " .. cardIndex .. " / " .. #state.cards .. " · tap matching numbers"
		card.BackgroundColor3 = cosmeticColor("card", colors.ice)
		for index, cell in ipairs(cells) do
			local entry = data and data.cells[index]
			cell.Text = if entry then (if entry.number == 0 then "FREE" else (if entry.marked then "✓" else "") .. tostring(entry.number)) else "—"
			cell.BackgroundColor3 = if entry and entry.marked then cosmeticColor("marker", colors.cyan) elseif entry and entry.available then colors.cyan else colors.blue
			cell.TextColor3 = if entry and (entry.marked or entry.available) then colors.navy else colors.ice
			cell.Active = entry ~= nil and entry.available and not entry.marked
		end
		nextCard.Visible = #state.cards > 1
		for _, bonus in ipairs(state.bonuses) do
			local row, numbers = bonusRows[bonus.id], {}
			for _, entry in ipairs(bonus.cells) do table.insert(numbers, (if entry.marked then "✓" else "") .. entry.number) end
			row.numbers.Text = if #numbers > 0 then table.concat(numbers, "   ") else "Awaiting card rules"
			row.progress.Text = if bonus.qualified then "QUALIFIED · result rules pending" elseif bonus.target == 0 then "Qualification count not set" elseif #bonus.cells == 0 then "Joining next round" else bonus.progress .. " / " .. bonus.target .. " matched"
			row.title.TextColor3 = if bonus.qualified then colors.cyan else colors.ice
		end
		for _, item in ipairs(Config.Catalog) do
			local suffix = if state.equipped[item.category] == item.id then "Equipped" elseif state.owned[item.id] then "Equip" else item.price .. " Pesos"
			cosmeticButtons[item.id].Text = item.name .. " · " .. suffix
		end
		settingButtons.autoMark.Text = "Automatic marking · " .. (if state.settings.autoMark then "On" else "Off")
		settingButtons.reducedMotion.Text = "Reduced motion · " .. (if state.settings.reducedMotion then "On" else "Off")
		volumeLabels.musicVolume.Text = "Music  " .. math.floor((state.settings.musicVolume or 0.5) * 100 + 0.5) .. "%"
		volumeLabels.sfxVolume.Text = "Sound effects  " .. math.floor((state.settings.sfxVolume or 0.7) * 100 + 0.5) .. "%"
		saveLabel.Text = (state.saveStatus or "") .. (if state.practice then "\nStudio practice · progress is temporary" else "")
	end
	stateEvent.OnClientEvent:Connect(function(snapshot)
		if previousRound ~= snapshot.roundId then previousCount, previousQualified = 0, {} end
		if #snapshot.history > previousCount then audio:play("draw") end
		for _, bonus in ipairs(snapshot.bonuses) do
			if bonus.qualified and not previousQualified[bonus.id] then
				notify(bonus.name .. " qualified · payout rules pending")
				audio:play("qualify")
				previousQualified[bonus.id] = true
			end
		end
		if snapshot.phase == "Results" and (not state or state.phase ~= "Results") and snapshot.summary then
			notify("Round complete · +" .. snapshot.summary.total .. " Pesos")
			audio:play("result")
		end
		if state and state.roundId == snapshot.roundId then
			local marked = false
			for index, current in ipairs(snapshot.cards) do
				local old = state.cards[index]
				for cellIndex, cell in ipairs(current.cells) do
					if old and cell.marked and not old.cells[cellIndex].marked then marked = true end
				end
			end
			if marked then audio:play("mark") end
		end
		if status then status.Visible = false end
		previousRound, previousCount, state = snapshot.roundId, #snapshot.history, snapshot
		audio:setVolumes(state.settings)
		audio:setTrack("lobby")
		effects:update(state)
		if state.notice then notify(state.notice) end
		render()
	end)
	local player = Players.LocalPlayer
	local function bindCharacter(character)
		-- A single Character.ChildAdded subscription per character; Roblox destroys it on respawn.
		character.ChildAdded:Connect(function(child) if child:IsA("Tool") and child.Name == "Cards" then open("Main") end end)
		if character:FindFirstChild("Cards") then open("Main") end
	end
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then bindCharacter(player.Character) end
	resize = function()
		local viewport = gui.AbsoluteSize
		local width = math.min(330, math.max(240, viewport.X - 24))
		hud.Size, toast.Size = UDim2.fromOffset(width, 116), UDim2.fromOffset(width, 44)
		panel.Size = UDim2.fromOffset(width, math.max(100, math.min(510, viewport.Y - 294)))
		if viewport.Y < 480 then
			panel.Position = UDim2.new(0.5, width / 2, 0, 8)
			panel.Size = UDim2.fromOffset(width, math.max(130, viewport.Y - 146))
			hud.Visible = not isOpen
		else
			panel.Position, hud.Visible = UDim2.new(1, -12, 0, 144), true
		end
		card.Size = UDim2.new(1, 0, 0, width - 26)
		nextCard.Position = UDim2.fromOffset(0, width + 34)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	task.defer(resize)
	RunService.RenderStepped:Connect(function()
		if state then
			local seconds = math.max(0, math.ceil(state.deadline - workspace:GetServerTimeNow()))
			phaseText.Text = state.phase .. " · " .. seconds .. "s · " .. state.players .. " here"
		end
		if toast.Visible and workspace:GetServerTimeNow() >= noticeUntil then toast.Visible = false end
	end)
	render()
	request("Sync")
	if status then status.Visible = false end
	-- A lost initial request must not leave the HUD waiting forever.
	task.spawn(function()
		local attempts = 0
		while not state do
			task.wait(3)
			if not state then
				request("Sync")
				attempts += 1
				if attempts >= 5 and status then
					status.Text = "Waiting for the server. Check Studio Output for a server startup or profile-load error."
					status.Visible = true
				end
			end
		end
	end)
end
local ok, problem = xpcall(initialize, debug.traceback)
if not ok then
	warn("Cloudpop client startup: " .. tostring(problem))
	if status then
		status.Text = "Cloudpop couldn't finish opening.\n" .. tostring(problem):match("[^\n]+")
		status.Visible = true
	end
end
