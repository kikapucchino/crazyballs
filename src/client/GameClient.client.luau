-- The ScreenGui and startup message are packaged in StarterGui, so they appear
-- even before dependencies replicate or if initialization fails.
local gui = script.Parent
local startup = gui:WaitForChild("StartupStatus", 10)
if not startup then
	warn("Cloudpop: the packaged StartupStatus is missing. Open the complete place file.")
	return
end
startup.Text = "CLOUDPOP COMMONS · build 0.1.2\nClient started. Connecting to the workshop…"

local function initialize()
local function dependency(parent, name)
	startup.Text = "CLOUDPOP COMMONS · build 0.1.2\nLoading " .. name .. "…"
	local child = parent:WaitForChild(name, 15)
	if not child then error("Timed out waiting for " .. parent:GetFullName() .. "." .. name, 0) end
	return child
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local Shared = dependency(ReplicatedStorage, "Cloudpop")
local Config = require(dependency(Shared, "Config"))
local Economy = require(dependency(Shared, "Economy"))
local remotes = dependency(Shared, "Remotes")
local action = dependency(remotes, "Action")
local stateEvent = dependency(remotes, "State")
startup.Text = "CLOUDPOP COMMONS · build 0.1.2\nBuilding your cards…"

local C = {
	ink = Color3.fromRGB(30, 71, 75), muted = Color3.fromRGB(87, 119, 119),
	background = Color3.fromRGB(225, 239, 229), cream = Color3.fromRGB(255, 248, 232),
	white = Color3.fromRGB(255, 253, 246), teal = Color3.fromRGB(40, 112, 116),
	mint = Color3.fromRGB(197, 232, 215), yellow = Color3.fromRGB(255, 199, 88),
	line = Color3.fromRGB(199, 217, 205), pink = Color3.fromRGB(243, 178, 191),
}
local current, swapSelection = nil, {}
local swapMode, soundOn = false, true
local activeTab = "Play"
local render

local function create(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties) do object[key] = value end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, parent)
end

local function label(parent, text, size, position, dimensions, color)
	return create("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size or 16,
		Font = Enum.Font.GothamMedium, TextColor3 = color or C.ink,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true, Position = position or UDim2.new(), Size = dimensions or UDim2.fromScale(1, 1),
	}, parent)
end

local function button(parent, text, position, dimensions, callback, background)
	local object = create("TextButton", {
		Text = text, Position = position, Size = dimensions,
		BackgroundColor3 = background or C.teal, TextColor3 = C.white,
		BorderSizePixel = 0, TextSize = 15, Font = Enum.Font.GothamBold,
		TextWrapped = true, AutoButtonColor = true,
	}, parent)
	corner(object, 12)
	object.Activated:Connect(callback)
	return object
end

local function panel(parent, name, height, order, color)
	local frame = create("Frame", { Name = name, BackgroundColor3 = color or C.cream,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, height), LayoutOrder = order }, parent)
	corner(frame, 18)
	return frame
end

local function fire(name, a, b, c)
	if current then action:FireServer(name, a, b, c, current.roundId) end
end

gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local background = create("Frame", { Name = "Background", Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.background, BorderSizePixel = 0 }, gui)
create("UIGradient", { Rotation = 35, Color = ColorSequence.new(C.background, Color3.fromRGB(210, 230, 230)) }, background)
local scroll = create("ScrollingFrame", { Name = "Page", AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, -24, 1, 0),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.teal, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y }, background)
create("UISizeConstraint", { MaxSize = Vector2.new(840, math.huge) }, scroll)
create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 26) }, scroll)
create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

local header = panel(scroll, "Header", 66, 1)
header.BackgroundTransparency = 1
local title = label(header, "CLOUDPOP", 26, UDim2.fromOffset(0, 0), UDim2.new(1, -142, 0, 32))
title.Font = Enum.Font.GothamBlack
label(header, "C O M M O N S  /  sky workshop", 11, UDim2.fromOffset(0, 31), UDim2.new(1, -135, 0, 28), C.muted)
local wallet = label(header, "0 Pesos", 21, UDim2.new(1, -132, 0, 0), UDim2.fromOffset(132, 32))
wallet.TextXAlignment = Enum.TextXAlignment.Right
wallet.Font = Enum.Font.GothamBold
local saving = label(header, "Connecting…", 11, UDim2.new(1, -145, 0, 29), UDim2.fromOffset(145, 30), C.muted)
saving.TextXAlignment = Enum.TextXAlignment.Right

local tabs = panel(scroll, "Tabs", 46, 2)
tabs.BackgroundTransparency = 1
local playTab, shopTab
local play = create("Frame", { Name = "Play", Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3 }, scroll)
create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, play)
local shop = create("Frame", { Name = "Wardrobe", Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4, Visible = false }, scroll)
create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, shop)
local function tab(name)
	activeTab = name
	play.Visible = name == "Play"
	shop.Visible = name == "Wardrobe"
	playTab.BackgroundColor3 = if play.Visible then C.teal else C.muted
	shopTab.BackgroundColor3 = if shop.Visible then C.teal else C.muted
end
playTab = button(tabs, "Play together", UDim2.new(), UDim2.new(0.5, -5, 1, 0), function() tab("Play") end)
shopTab = button(tabs, "Cosmetic wardrobe", UDim2.new(0.5, 5, 0, 0), UDim2.new(0.5, -5, 1, 0), function() tab("Wardrobe") end, C.muted)

local hero = panel(play, "AirMachine", 184, 1, C.teal)
local phaseLabel = label(hero, "WELCOME ABOARD", 12, UDim2.fromOffset(16, 12), UDim2.new(0.6, -20, 0, 24), C.mint)
phaseLabel.Font = Enum.Font.GothamBold
local ballNumber = label(hero, "?", 58, UDim2.fromOffset(14, 43), UDim2.fromOffset(86, 82), C.yellow)
ballNumber.Font = Enum.Font.GothamBlack
local latest = label(hero, "Pip is warming\nup the machine.", 14, UDim2.fromOffset(108, 43), UDim2.new(0.58, -115, 0, 82), C.white)
local countdown = label(hero, "Preparing your cards…", 13, UDim2.fromOffset(16, 135), UDim2.new(0.61, -24, 0, 36), C.white)

-- A self-contained miniature air machine, rendered locally. Its balls never decide draws.
local viewport = create("ViewportFrame", { Name = "MachineView", BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.6, 0.05), Size = UDim2.fromScale(0.39, 0.88),
	Ambient = Color3.fromRGB(210, 220, 223), LightColor = Color3.fromRGB(255, 239, 210),
	LightDirection = Vector3.new(-1, -1, -2) }, hero)
local world = create("WorldModel", { Name = "Display" }, viewport)
local camera = create("Camera", { CFrame = CFrame.lookAt(Vector3.new(0, 3, 15), Vector3.new(0, 0, 0)), FieldOfView = 34 }, viewport)
viewport.CurrentCamera = camera
local function displayPart(name, size, position, color, shape)
	return create("Part", { Name = name, Anchored = true, CanCollide = false, Size = size,
		Position = position, Color = color, Shape = shape or Enum.PartType.Block,
		Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth }, world)
end
displayPart("Stand", Vector3.new(5, 0.8, 3.5), Vector3.new(0, -2.7, 0), C.mint)
displayPart("Housing", Vector3.new(3.7, 1, 2.4), Vector3.new(0, -2, 0), C.yellow)
displayPart("Cap", Vector3.new(4.5, 0.5, 2.8), Vector3.new(0, 2.5, 0), C.pink)
for _, x in ipairs({ -2.1, 2.1 }) do
	displayPart("BrassSupport", Vector3.new(0.18, 4.2, 0.18), Vector3.new(x, 0.15, 0), C.yellow)
end
local chamber = displayPart("Chamber", Vector3.new(4.1, 4.1, 3.3), Vector3.new(0, 0.2, 0), C.white, Enum.PartType.Ball)
chamber.Transparency = 0.86
local animatedBalls = {}
for index = 1, 10 do
	animatedBalls[index] = displayPart("Ball" .. index, Vector3.new(0.7, 0.7, 0.7),
		Vector3.new(math.sin(index) * 1.5, math.cos(index) * 1.3, 0),
		({ C.yellow, C.pink, C.mint, C.white })[index % 4 + 1], Enum.PartType.Ball)
end

local instructionPanel = panel(play, "PipTip", 78, 2, C.mint)
label(instructionPanel, "PIP'S POST", 11, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 20), C.teal).Font = Enum.Font.GothamBold
local instruction = label(instructionPanel, "Two free cards. One shared draw. Finish any horizontal row!", 14,
	UDim2.fromOffset(14, 27), UDim2.new(1, -28, 0, 44))

local goalPanel = panel(play, "Objective", 132, 3)
local goalTitle = label(goalPanel, "Choose a delivery • either earns +10 Pesos", 14, UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 36))
local trail = button(goalPanel, "Number trail\nMark 5 different numbers", UDim2.fromOffset(10, 49), UDim2.new(0.5, -15, 0, 72), function() fire("Goal", "trail") end)
local twins = button(goalPanel, "Double delivery\nSame number on both cards", UDim2.new(0.5, 5, 0, 49), UDim2.new(0.5, -15, 0, 72), function() fire("Goal", "twins") end)
local goalProgress = label(goalPanel, "", 14, UDim2.fromOffset(12, 42), UDim2.new(1, -24, 0, 32))

local eventPanel = panel(play, "TailwindSwitch", 176, 4, C.yellow)
eventPanel.Visible = false
label(eventPanel, "TAILWIND SWITCH", 17, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 28)).Font = Enum.Font.GothamBold
local eventText = label(eventPanel, "Swap any two cells on ONE card, or keep your layout. Marks travel with numbers.", 13,
	UDim2.fromOffset(12, 39), UDim2.new(1, -24, 0, 57))
local swapButton = button(eventPanel, "Preview a swap", UDim2.fromOffset(10, 110), UDim2.new(0.5, -15, 0, 52), function()
	if not current or current.swapped then return end
	if #swapSelection == 2 then
		fire("Swap", swapSelection[1].card, swapSelection[1].cell, swapSelection[2].cell)
		swapMode, swapSelection = false, {}
	else
		swapMode = not swapMode
		swapSelection = {}
	end
	if render then render() end
end)
local keepButton = button(eventPanel, "Keep layout", UDim2.new(0.5, 5, 0, 110), UDim2.new(0.5, -15, 0, 52), function()
	if swapMode then
		swapMode, swapSelection = false, {}
		if render then render() end
	else
		fire("Keep")
	end
end, C.muted)

local cardsFrame = panel(play, "Cards", 280, 5)
cardsFrame.BackgroundTransparency = 1
local cardLayout = create("UIGridLayout", { CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, cardsFrame)
local cardPanels, cardTitles, cells, cellStrokes, cellIndicators, cardGrids = {}, {}, {}, {}, {}, {}
for cardIndex = 1, 2 do
	local card = panel(cardsFrame, "Card" .. cardIndex, 260, cardIndex)
	cardPanels[cardIndex] = card
	cardTitles[cardIndex] = label(card, "DELIVERY " .. (if cardIndex == 1 then "A" else "B"), 12,
		UDim2.fromOffset(9, 4), UDim2.new(1, -18, 0, 34), C.muted)
	cardTitles[cardIndex].Font = Enum.Font.GothamBold
	local grid = create("Frame", { Name = "Numbers", BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -50) }, card)
	cardGrids[cardIndex] = create("UIGridLayout", { CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 3 }, grid)
	cells[cardIndex], cellStrokes[cardIndex], cellIndicators[cardIndex] = {}, {}, {}
	for cellIndex = 1, 9 do
		local cell = button(grid, "—", UDim2.new(), UDim2.fromOffset(50, 50), function()
			if not current or not current.cards[cardIndex] then return end
			if swapMode and current.phase == "Event" and not current.swapped then
				if #swapSelection == 0 or swapSelection[1].card ~= cardIndex then
					swapSelection = { { card = cardIndex, cell = cellIndex } }
				elseif swapSelection[1].cell == cellIndex then
					swapSelection = {}
				else
					swapSelection[2] = { card = cardIndex, cell = cellIndex }
				end
				if render then render() end
			else
				fire("Mark", cardIndex, cellIndex)
			end
		end, C.white)
		cell.Name = "Cell" .. cellIndex
		cell.LayoutOrder = cellIndex
		cell.TextColor3 = C.ink
		cell.Font = Enum.Font.GothamBold
		cell.TextSize = 23
		cells[cardIndex][cellIndex] = cell
		cellIndicators[cardIndex][cellIndex] = label(cell, "", 13, UDim2.new(1, -17, 0, 1), UDim2.fromOffset(16, 17))
		cellIndicators[cardIndex][cellIndex].TextXAlignment = Enum.TextXAlignment.Center
		cellStrokes[cardIndex][cellIndex] = create("UIStroke", { Thickness = 2, Color = C.line,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, cell)
	end
end

local function resizeCards()
	local width = cardsFrame.AbsoluteSize.X
	if width <= 0 then return end
	local columns = if width < 350 then 1 else 2
	local cardWidth = (width - (columns - 1) * 12) / columns
	local cellSize = math.floor((cardWidth - 28) / 3)
	local cardHeight = cellSize * 3 + 62
	cardLayout.FillDirectionMaxCells = columns
	cardLayout.CellSize = UDim2.fromOffset(math.floor(cardWidth), cardHeight)
	cardsFrame.Size = UDim2.new(1, 0, 0, if columns == 1 then cardHeight * 2 + 12 else cardHeight)
	for _, grid in ipairs(cardGrids) do grid.CellSize = UDim2.fromOffset(cellSize, cellSize) end
end
cardsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeCards)
task.defer(resizeCards)

local legend = panel(play, "Legend", 47, 6, C.mint)
label(legend, "• = ready to mark     ✓ = stamped\nAny horizontal row completes that card.", 12,
	UDim2.fromOffset(12, 2), UDim2.new(1, -24, 1, -4))

local results = panel(play, "RoundResults", 118, 7, C.yellow)
results.Visible = false
local resultsTitle = label(results, "Delivery complete!", 22, UDim2.fromOffset(14, 9), UDim2.new(1, -28, 0, 34))
resultsTitle.Font = Enum.Font.GothamBold
local resultsDetail = label(results, "", 14, UDim2.fromOffset(14, 47), UDim2.new(1, -28, 0, 61))

local historyPanel = panel(play, "History", 142, 8)
label(historyPanel, "SHARED DRAW HISTORY", 12, UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 29), C.muted).Font = Enum.Font.GothamBold
local historyFrame = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 43),
	Size = UDim2.new(1, -24, 0, 90) }, historyPanel)
create("UIGridLayout", { CellSize = UDim2.new(0.125, -6, 0, 25), CellPadding = UDim2.fromOffset(6, 6),
	FillDirectionMaxCells = 8, SortOrder = Enum.SortOrder.LayoutOrder }, historyFrame)
local historyLabels = {}
for number = 1, 24 do
	local chip = label(historyFrame, tostring(number), 13)
	chip.BackgroundTransparency = 0
	chip.BackgroundColor3 = C.white
	chip.TextXAlignment = Enum.TextXAlignment.Center
	chip.LayoutOrder = number
	corner(chip, 7)
	historyLabels[number] = chip
end

local options = panel(play, "Accessibility", 106, 9)
local autoButton = button(options, "Auto-mark: OFF", UDim2.fromOffset(8, 8), UDim2.new(0.5, -12, 0, 44), function()
	if current then fire("Setting", "autoMark", not current.settings.autoMark) end
end)
local motionButton = button(options, "Motion: ON", UDim2.new(0.5, 4, 0, 8), UDim2.new(0.5, -12, 0, 44), function()
	if current then fire("Setting", "reducedMotion", not current.settings.reducedMotion) end
end, C.muted)
local soundButton
soundButton = button(options, "Sound: ON", UDim2.fromOffset(8, 59), UDim2.new(0.5, -12, 0, 39), function()
	soundOn = not soundOn
	soundButton.Text = if soundOn then "Sound: ON" else "Sound: OFF"
end, C.muted)
label(options, "Free accessibility options.\nNo speed bonus.", 11, UDim2.new(0.5, 6, 0, 60), UDim2.new(0.5, -14, 0, 37), C.muted)

local shopIntro = panel(shop, "ShopIntro", 112, 1, C.mint)
label(shopIntro, "MAKE YOURSELF AT HOME", 18, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 42)).Font = Enum.Font.GothamBold
label(shopIntro, "Pick exactly what you love. These cosmetics change appearance only. All prices are earned Pesos.", 14,
	UDim2.fromOffset(14, 48), UDim2.new(1, -28, 0, 55))
local shopButtons = {}
for index, item in ipairs(Config.Catalog) do
	local row = panel(shop, item.id, 126, index + 1)
	local swatch = create("Frame", { BackgroundColor3 = Color3.fromRGB(table.unpack(item.color)),
		BorderSizePixel = 0, Position = UDim2.fromOffset(12, 16), Size = UDim2.fromOffset(48, 48) }, row)
	corner(swatch, if item.category == "marker" then 24 else 10)
	label(row, item.name, 16, UDim2.fromOffset(72, 7), UDim2.new(1, -82, 0, 30)).Font = Enum.Font.GothamBold
	label(row, item.description, 12, UDim2.fromOffset(72, 35), UDim2.new(1, -82, 0, 30), C.muted)
	shopButtons[item.id] = button(row, "Loading…", UDim2.new(1, -164, 1, -52), UDim2.fromOffset(152, 44), function()
		fire("Cosmetic", item.id)
	end)
	label(row, string.upper(item.category), 10, UDim2.fromOffset(12, 76), UDim2.new(1, -188, 0, 24), C.muted)
end

local toast = label(background, "", 15, UDim2.new(0.5, 0, 1, -16), UDim2.new(1, -32, 0, 74), C.white)
toast.Name = "Notice"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.BackgroundColor3 = C.ink
toast.BackgroundTransparency = 0.04
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.ZIndex = 30
toast.Visible = false
corner(toast, 16)
create("UISizeConstraint", { MaxSize = Vector2.new(580, 90) }, toast)
create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, toast)
local toastVersion = 0
local function notify(message)
	toastVersion += 1
	local version = toastVersion
	toast.Text, toast.Visible = message, true
	task.delay(4, function() if toastVersion == version then toast.Visible = false end end)
end

local ping = create("Sound", { Name = "SoftDrawPing", SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.15, PlaybackSpeed = 1.1 }, SoundService)

render = function()
	if not current then return end
	local s = current
	wallet.Text = tostring(s.pesos) .. " Pesos"
	saving.Text = s.saveStatus
	local phaseNames = { Waiting = "WELCOME ABOARD", Intermission = "FRESH DELIVERY", Drawing = "SHARED SKY DRAW",
		Event = "A LITTLE CHANGE OF WIND", LastCall = "FINAL STAMPS", Results = "DELIVERY COMPLETE" }
	phaseLabel.Text = phaseNames[s.phase] or s.phase
	ballNumber.Text = if #s.history > 0 then tostring(s.history[#s.history]) else "?"
	latest.Text = if #s.history > 0 then "Ball " .. #s.history .. " / " .. s.drawCount .. "\nEveryone's draw" else "Two free cards.\nYour next adventure."
	local participating = #s.cards == 2
	if not participating then
		instruction.Text = "Welcome! Watch the shared draw. Your two free cards arrive next round."
	elseif s.phase == "Intermission" then
		instruction.Text = "Hi, I'm Pip! Choose a delivery below, then stamp drawn numbers. Any horizontal row wins."
	elseif s.phase == "Event" then
		instruction.Text = "Draws are paused. Preview one swap below, or keep your layout. You can still mark drawn numbers."
	elseif s.phase == "Results" then
		instruction.Text = "Everyone keeps their earned Pesos. Fresh cards and another breeze are on their way."
	else
		instruction.Text = if s.participated then "Stamp matching numbers whenever you're ready. Complete each card once for +15 Pesos."
			else "Make one choice or manual mark to join this round's rewards. Auto-mark players can tap its setting."
	end
	goalPanel.Visible = participating and s.phase ~= "Results"
	local choosing = s.phase == "Intermission"
	goalPanel.Size = UDim2.new(1, 0, 0, if choosing then 132 else 86)
	trail.Visible, twins.Visible = choosing, choosing
	goalProgress.Visible = not choosing
	goalTitle.Text = if choosing then "Choose a delivery • either earns +10 Pesos" else Config.Goals[s.goal].name .. " • +10 Pesos"
	goalProgress.Text = Config.Goals[s.goal].short .. "   " .. s.goalProgress .. "/" .. s.goalTarget
	trail.BackgroundColor3 = if s.goal == "trail" then C.teal else C.muted
	twins.BackgroundColor3 = if s.goal == "twins" then C.teal else C.muted
	trail.Text = (if s.goal == "trail" and s.participated then "✓ " else "") .. "Number trail\nMark 5 different numbers"
	twins.Text = (if s.goal == "twins" and s.participated then "✓ " else "") .. "Double delivery\nSame number on both cards"
	eventPanel.Visible = s.phase == "Event" and participating
	if s.swapped then
		eventText.Text = "Your decision is confirmed. The draw will resume shortly."
		swapButton.Text, keepButton.Text = "Decision saved", "All set!"
	elseif #swapSelection == 2 then
		local a, b = swapSelection[1], swapSelection[2]
		eventText.Text = "PREVIEW: " .. s.cards[a.card].cells[a.cell].number .. " ↔ " .. s.cards[b.card].cells[b.cell].number
			.. ". Review the card, then confirm."
		swapButton.Text, keepButton.Text = "Confirm swap", "Cancel preview"
	elseif swapMode then
		eventText.Text = "Tap two cells on the same card. You'll see the new layout before you confirm."
		swapButton.Text, keepButton.Text = "Exit preview", "Cancel preview"
	else
		eventText.Text = "Swap any two cells on ONE card, or keep your layout. Marks travel with numbers."
		swapButton.Text, keepButton.Text = "Preview a swap", "Keep layout"
	end
	local markerItem = Economy.find(Config.Catalog, s.equipped.marker)
	local cardItem = Economy.find(Config.Catalog, s.equipped.card)
	local markerColor = Color3.fromRGB(table.unpack(markerItem.color))
	for cardIndex = 1, 2 do
		cardPanels[cardIndex].BackgroundColor3 = Color3.fromRGB(table.unpack(cardItem.color))
		local card = s.cards[cardIndex]
		cardTitles[cardIndex].Text = if card and card.complete then "✓ ROW COMPLETE" else "DELIVERY " .. (if cardIndex == 1 then "A" else "B")
		for cellIndex = 1, 9 do
			local sourceIndex = cellIndex
			if #swapSelection == 2 and swapSelection[1].card == cardIndex then
				if cellIndex == swapSelection[1].cell then sourceIndex = swapSelection[2].cell end
				if cellIndex == swapSelection[2].cell then sourceIndex = swapSelection[1].cell end
			end
			local data = if card then card.cells[sourceIndex] else nil
			local cell, stroke = cells[cardIndex][cellIndex], cellStrokes[cardIndex][cellIndex]
			cell.Text = if data then tostring(data.number) else "—"
			cellIndicators[cardIndex][cellIndex].Text = if data and data.marked then "✓" elseif data and data.available then "•" else ""
			cell.BackgroundColor3 = if data and data.marked then markerColor else C.white
			stroke.Color = if data and data.available and not data.marked then C.teal else C.line
			stroke.Thickness = if data and data.available and not data.marked then 3 else 1
			for _, selected in ipairs(swapSelection) do
				if selected.card == cardIndex and selected.cell == cellIndex then
					stroke.Color, stroke.Thickness = C.teal, 4
				end
			end
		end
	end
	local drawn = {}
	for _, number in ipairs(s.history) do drawn[number] = true end
	for number, chip in ipairs(historyLabels) do
		chip.BackgroundColor3 = if drawn[number] then C.teal else C.white
		chip.TextColor3 = if drawn[number] then C.white else C.muted
	end
	results.Visible = s.phase == "Results" and s.summary ~= nil
	if results.Visible then
		resultsTitle.Text = "+" .. s.summary.total .. " Pesos delivered"
		resultsDetail.Text = "Participation " .. s.summary.participation .. "  •  Rows " .. s.summary.patterns
			.. "  •  Objective " .. s.summary.objective .. (if s.practice then "\nStudio practice: balance resets when you stop." else "\nLooking good! Progress saves automatically.")
	end
	autoButton.Text = if s.settings.autoMark then "Auto-mark: ON" else "Auto-mark: OFF"
	motionButton.Text = if s.settings.reducedMotion then "Motion: REDUCED" else "Motion: ON"
	for _, item in ipairs(Config.Catalog) do
		local equipped = s.equipped[item.category] == item.id
		shopButtons[item.id].Text = if equipped then "✓ Equipped" elseif s.owned[item.id] then "Equip" else "Buy · " .. item.price .. " Pesos"
		shopButtons[item.id].BackgroundColor3 = if equipped then C.muted else C.teal
	end
end

stateEvent.OnClientEvent:Connect(function(snapshot)
	local previous = current
	if not previous or snapshot.roundId ~= previous.roundId or snapshot.phase ~= "Event" or snapshot.swapped then
		swapMode, swapSelection = false, {}
	end
	current = snapshot
	if previous and snapshot.roundId == previous.roundId and #snapshot.history > #previous.history then
		if soundOn then ping:Play() end
		if not snapshot.settings.reducedMotion then
			ballNumber.TextSize = 68
			TweenService:Create(ballNumber, TweenInfo.new(0.4, Enum.EasingStyle.Back), { TextSize = 58 }):Play()
		end
	end
	if snapshot.notice then notify(snapshot.notice) end
	if previous and snapshot.phase == "Event" and previous.phase ~= "Event" then
		tab("Play")
		notify("Tailwind Switch! The draw is paused for a free board decision.")
	end
	render()
end)

local elapsed = 0
RunService.RenderStepped:Connect(function(delta)
	elapsed += delta
	local reduced = current and current.settings.reducedMotion
	if not reduced then
		for index, ball in ipairs(animatedBalls) do
			local t = elapsed * 0.85 + index * 2.4
			ball.Position = Vector3.new(math.sin(t) * 1.25, math.cos(t * 1.4) * 1.25 + 0.25, math.sin(t * 0.7) * 0.7 + 0.3)
		end
	end
	if current then
		local remaining = math.max(0, math.ceil(current.deadline - workspace:GetServerTimeNow()))
		local prefixes = { Intermission = "Draw begins in ", Drawing = "Next moment in ", Event = "Draw resumes in ",
			LastCall = "Finish your marks · ", Results = "Fresh cards in ", Waiting = "Getting ready · " }
		countdown.Text = (prefixes[current.phase] or "") .. remaining .. "s  •  " .. current.players .. " aboard"
	end
end)

task.spawn(function()
	while not current do
		action:FireServer("Sync")
		task.wait(2)
	end
end)

startup.Visible = false
end

local ok, problem = xpcall(initialize, debug.traceback)
if not ok then
	startup.Visible = true
	startup.Text = "Cloudpop couldn't finish opening.\nStop the test, then press Play again.\n\n"
		.. (string.match(tostring(problem), "[^\n]+") or "Startup error")
	warn("Cloudpop startup failed:\n" .. tostring(problem))
end
