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
	local audio
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
	local touch = game:GetService("UserInputService").TouchEnabled
	local layout = require(waitFor(shared, "CardLayout"))
	local manifest = require(waitFor(shared, "AudioManifest"))
	-- Audio receives only the consenting-human recording manifest; there is no speech synthesis.
	audio = require(waitFor(gui, "AudioController")).new(Config.Audio, manifest)
	local state, panelOpen, auxiliary = nil, not touch, nil
	local previousRound, previousCount, previousQualified = nil, 0, {}
	local function request(name, a, b, c)
		action:FireServer(name, a, b, c, if state then state.roundId else 0)
	end
	local hud = frame("HUD", gui, UDim2.fromOffset(330,90), UDim2.new(0.5,0,0,8))
	hud.AnchorPoint = Vector2.new(0.5,0)
	local ball = label("CurrentBall",hud,"—",UDim2.fromOffset(64,60),UDim2.fromOffset(8,0),32)
	ball.TextXAlignment=Enum.TextXAlignment.Center
	local counter = label("DrawCount",hud,"0 / 20",UDim2.fromOffset(114,24),UDim2.fromOffset(82,6),18)
	local balance = label("Pesos",hud,"0 Pesos",UDim2.fromOffset(220,22),UDim2.fromOffset(82,30),14)
	local history = label("RecentBalls",hud,"Fresh pool · 1–60",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,64),12)
	local phaseText = label("Phase",hud,"Connecting…",UDim2.fromOffset(126,24),UDim2.fromOffset(195,6),14)
	phaseText.TextXAlignment=Enum.TextXAlignment.Right
	local subtitles=label("PresenterSubtitle",gui,"",UDim2.fromOffset(420,38),UDim2.new(0.5,0,0,104),15)
	subtitles.AnchorPoint,subtitles.BackgroundColor3,subtitles.BackgroundTransparency=Vector2.new(0.5,0),colors.navy,0.1
	subtitles.TextXAlignment,subtitles.Visible=Enum.TextXAlignment.Center,false
	round(subtitles)
	local toast=label("Notice",gui,"",UDim2.fromOffset(330,40),UDim2.new(0.5,0,0,150),13)
	toast.AnchorPoint,toast.BackgroundColor3,toast.BackgroundTransparency=Vector2.new(0.5,0),colors.navy,0.1
	toast.Visible=false
	round(toast)
	local noticeUntil=0
	local function notify(text)
		toast.Text,toast.Visible=text,true
		noticeUntil=workspace:GetServerTimeNow()+5
	end
	local cardPanel=require(waitFor(gui,"CardPanel")).new(gui,{frame=frame,label=label,button=button,make=make,colors=colors},Config,layout,request)
	local aux=frame("AuxiliaryPanel",gui,UDim2.fromOffset(350,370),UDim2.new(0.5,0,1,-80))
	aux.AnchorPoint,aux.Visible=Vector2.new(0.5,1),false
	local auxTitle=label("Title",aux,"SETTINGS",UDim2.new(1,-70,0,44),UDim2.fromOffset(12,0),16)
	local body=make("ScrollingFrame","Body",aux,{Size=UDim2.new(1,-20,1,-54),Position=UDim2.fromOffset(10,46),CanvasSize=UDim2.fromOffset(0,420),
		ScrollBarThickness=4,BackgroundTransparency=1,BorderSizePixel=0,ScrollingDirection=Enum.ScrollingDirection.Y})
	local settings=make("Frame","Settings",body,{Size=UDim2.new(1,-6,0,420),BackgroundTransparency=1})
	local looks=make("Frame","Looks",body,{Size=UDim2.new(1,-6,0,340),BackgroundTransparency=1})
	local resize,render
	local compactPresentation=false
	button("Close",aux,"×",UDim2.fromOffset(44,40),UDim2.new(1,-50,0,2),function() auxiliary=nil; resize() end)
	local function openCards()
		panelOpen,auxiliary=true,nil
		request("Participate")
		resize()
	end
	local cardsButton=button("CardsButton",gui,"Cards",UDim2.fromOffset(88,44),UDim2.fromOffset(0,0),function()
		if panelOpen and not auxiliary then panelOpen=false; resize() else openCards() end
	end)
	local looksButton=button("LooksButton",gui,"Looks",UDim2.fromOffset(88,44),UDim2.fromOffset(0,0),function() auxiliary="Looks"; resize() end)
	local settingsButton=button("SettingsButton",gui,"Settings",UDim2.fromOffset(88,44),UDim2.fromOffset(0,0),function() auxiliary="Settings"; resize() end)
	local reduced=button("reducedMotion",settings,"Reduced motion · Off",UDim2.new(1,0,0,44),UDim2.fromOffset(0,0),function()
		if state then request("Setting","reducedMotion",not state.settings.reducedMotion) end
	end)
	local volumes,mutes,previousVolumes={},{},{}
	for index,entry in ipairs({{"musicVolume","Music"},{"voiceVolume","Voice"},{"sfxVolume","Effects"}}) do
		local key,title,y=entry[1],entry[2],52+(index-1)*62
		volumes[key]=label(key,settings,title,UDim2.new(1,-172,0,44),UDim2.fromOffset(0,y),14)
		for _,delta in ipairs({-0.1,0.1}) do
			button(key..tostring(delta),settings,if delta<0 then "−" else "+",UDim2.fromOffset(44,44),UDim2.new(1,if delta<0 then -162 else -112,0,y),function()
				if state then request("Setting",key,math.clamp(math.floor(((state.settings[key] or 0)+delta)*10+0.5)/10,0,1)) end
			end)
		end
		mutes[key]=button(key.."Mute",settings,"Mute",UDim2.fromOffset(62,44),UDim2.new(1,-62,0,y),function()
			if not state then return end
			local current=state.settings[key] or 0
			if current>0 then previousVolumes[key]=current; request("Setting",key,0)
			else request("Setting",key,previousVolumes[key] or 0.5) end
		end)
	end
	local saveLabel=label("SaveStatus",settings,"",UDim2.new(1,0,0,56),UDim2.fromOffset(0,245),12)
	label("Credits",settings,"Created by Kikapucchino",UDim2.new(1,0,0,28),UDim2.fromOffset(0,308),13)
	label("AudioSlots",settings,"Human voice and music recordings are awaiting licensed audio.",UDim2.new(1,0,0,54),UDim2.fromOffset(0,342),12)
	local cosmeticButtons={}
	for index,item in ipairs(Config.Catalog) do
		cosmeticButtons[item.id]=button(item.id,looks,item.name,UDim2.new(1,0,0,48),UDim2.fromOffset(0,(index-1)*56),function() request("Cosmetic",item.id) end)
	end
	local function cosmeticColor(category,fallback)
		local item=state and Economy.find(Config.Catalog,state.equipped[category])
		return if item then Color3.fromRGB(table.unpack(item.color)) else fallback
	end
	resize=function()
		local viewport=gui.AbsoluteSize
		local geometry=cardPanel:resize(viewport.X,viewport.Y,touch)
		cardPanel.root.Visible=panelOpen and auxiliary==nil
		aux.Visible=auxiliary~=nil
		settings.Visible,looks.Visible=auxiliary=="Settings",auxiliary=="Looks"
		auxTitle.Text=if auxiliary then string.upper(auxiliary) else ""
		aux.Size=UDim2.fromOffset(math.min(350,geometry.width),geometry.height)
		aux.Position=UDim2.new(0.5,0,1,-geometry.footer)
		compactPresentation=(cardPanel.root.Visible or aux.Visible) and viewport.Y-geometry.footer-geometry.height<235
		hud.Visible=not compactPresentation
		subtitles.Position=UDim2.new(0.5,0,0,if compactPresentation then 8 else 104)
		body.CanvasSize=UDim2.fromOffset(0,if auxiliary=="Looks" then 340 else 408)
		local bottom=geometry.footer+(if cardPanel.root.Visible or aux.Visible then geometry.height+48 else 48)
		for index,item in ipairs({cardsButton,looksButton,settingsButton}) do item.Position=UDim2.new(0.5,-138+(index-1)*94,1,-bottom) end
		hud.Size=UDim2.fromOffset(math.min(330,viewport.X-20),90)
		subtitles.Size=UDim2.fromOffset(math.min(420,viewport.X-24),38)
	end
	render=function()
		if not state then return end
		ball.Text=tostring(state.history[#state.history] or "—")
		counter.Text,balance.Text=#state.history.." / "..state.drawCount,tostring(state.pesos).." Pesos"
		local recent={}
		for index=math.max(1,#state.history-5),#state.history do table.insert(recent,tostring(state.history[index])) end
		history.Text=if #recent>0 then "Recent · "..table.concat(recent," · ") else "Fresh pool · 1–60"
		cardPanel:render(state,cosmeticColor("card",colors.ice),cosmeticColor("marker",colors.cyan))
		reduced.Text="Reduced motion · "..(if state.settings.reducedMotion then "On" else "Off")
		for key,view in pairs(volumes) do
			local title=if key=="musicVolume" then "Music" elseif key=="voiceVolume" then "Voice" else "Effects"
			local value=state.settings[key] or 0
			view.Text=title.." "..math.floor(value*100+0.5).."%"
			mutes[key].Text=if value>0 then "Mute" else "Unmute"
		end
		saveLabel.Text=(state.saveStatus or "")..(if state.practice then "\nStudio practice · progress is temporary" else "")
		for _,item in ipairs(Config.Catalog) do
			local suffix=if state.equipped[item.category]==item.id then "Equipped" elseif state.owned[item.id] then "Equip" else item.price.." Pesos"
			cosmeticButtons[item.id].Text=item.name.." · "..suffix
		end
	end
	stateEvent.OnClientEvent:Connect(function(snapshot)
		if previousRound~=snapshot.roundId then previousCount,previousQualified=0,{} end
		if #snapshot.history>previousCount then audio:play("draw") end
		for _,bonus in ipairs(snapshot.bonuses) do
			if bonus.qualified and not previousQualified[bonus.id] then
				notify(bonus.name.." qualified · payout rules pending")
				audio:play("qualify")
				previousQualified[bonus.id]=true
			end
		end
		if snapshot.phase=="Results" and (not state or state.phase~="Results") and snapshot.summary then
			notify("Round complete · +"..snapshot.summary.total.." Pesos")
			audio:play("result")
		end
		if state and state.roundId==snapshot.roundId then
			local marked=false
			for index,current in ipairs(snapshot.cards) do
				local old=state.cards[index]
				for cellIndex,cell in ipairs(current.cells) do
					if old and old.cells[cellIndex] and cell.marked and not old.cells[cellIndex].marked then marked=true end
				end
			end
			if marked then audio:play("mark") end
		end
		previousRound,previousCount,state=snapshot.roundId,#snapshot.history,snapshot
		audio:setVolumes(state.settings)
		audio:setTrack(state.activeBonus or "lobby")
		-- The same authoritative snapshot reveals the ball and queues its matching voice/subtitle.
		audio:announce(state.announcement,workspace:GetServerTimeNow())
		effects:update(state)
		if state.notice then notify(state.notice) end
		if status then status.Visible=false end
		render()
	end)
	local player=Players.LocalPlayer
	local function bindCharacter(character)
		character.ChildAdded:Connect(function(child) if child:IsA("Tool") and child.Name=="Cards" then openCards() end end)
		if character:FindFirstChild("Cards") then openCards() end
	end
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then bindCharacter(player.Character) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	RunService.RenderStepped:Connect(function()
		local now=workspace:GetServerTimeNow()
		if state then
			local seconds=math.max(0,math.ceil(state.deadline-now))
			if state.phase=="Intermission" then cardPanel:setStatus("Starts in "..seconds.."s") end
			phaseText.Text=if state.phase=="Intermission" then "Starts in "..seconds elseif state.phase=="Drawing" then "DRAWING" elseif state.phase=="Results" then "RESULTS · "..seconds elseif state.phase=="Bonus" then "BONUS" else state.phase
		end
		local caption=audio:update(now)
		local noticeActive=now<noticeUntil
		if compactPresentation and caption=="" and noticeActive then caption=toast.Text end
		subtitles.Text,subtitles.Visible=caption,caption~=""
		toast.Visible=noticeActive and not compactPresentation
	end)
	request("Sync")
	if status then status.Visible=false end
	task.spawn(function()
		local attempts=0
		while not state do
			task.wait(3)
			if not state then
				request("Sync"); attempts+=1
				if attempts>=5 and status then status.Text="Waiting for the server. Check Studio Output for a startup or save-load error."; status.Visible=true end
			end
		end
	end)
end
local ok,problem=xpcall(initialize,debug.traceback)
if not ok then
	warn("Cloudpop client startup: "..tostring(problem))
	if status then status.Text="Cloudpop couldn't finish opening.\n"..tostring(problem):match("[^\n]+"); status.Visible=true end
end
