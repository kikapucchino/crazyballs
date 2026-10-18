-- Horizontal main cards and an adjacent 2x2 bonus group, in one bottom-center tray.
local Panel = {}
function Panel.new(gui, ui, config, layout, request)
	local frame, label, button, make = ui.frame, ui.label, ui.button, ui.make
	local colors = ui.colors
	local tray = frame("CardPanel", gui, UDim2.fromOffset(930,392), UDim2.new(0.5,0,1,-78))
	tray.AnchorPoint = Vector2.new(0.5,1)
	local scroll = make("ScrollingFrame","CardScroll",tray,{Position=UDim2.fromOffset(10,90),Size=UDim2.new(1,-20,1,-100),
		BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,ScrollingDirection=Enum.ScrollingDirection.XY,
		CanvasSize=UDim2.fromOffset(930,302)})
	local cards, bonusRows, geometry = {}, {}, nil
	local patternLabel=label("ActivePatterns",tray,"Pattern schedule awaiting confirmation",UDim2.new(1,-20,0,38),UDim2.fromOffset(10,46),12)
	local heading=label("Title",tray,"YOUR CARDS",UDim2.fromOffset(110,44),UDim2.fromOffset(10,0),14)
	button("MainNavigation",tray,"Main",UDim2.fromOffset(64,40),UDim2.fromOffset(122,3),function() scroll.CanvasPosition=Vector2.new(0,0) end)
	button("BonusNavigation",tray,"Bonus →",UDim2.fromOffset(86,40),UDim2.fromOffset(192,3),function()
		if geometry then scroll.CanvasPosition=Vector2.new(geometry.bonusX,0) end
	end)
	local function createCard(index)
		local card=frame("MainCard"..index,scroll,UDim2.fromOffset(layout.CardWidth,layout.CardHeight),UDim2.fromOffset((index-1)*(layout.CardWidth+layout.Gap),0))
		local title=label("Multiplier",card,"Card "..index.." · awaiting deal",UDim2.new(1,-16,0,28),UDim2.fromOffset(8,2),15)
		local cells,strokes={},{}
		for cellIndex=1,25 do
			cells[cellIndex]=button("Cell"..cellIndex,card,"—",UDim2.fromOffset(44,44),
				UDim2.fromOffset(8+(cellIndex-1)%5*46,32+math.floor((cellIndex-1)/5)*46),function() request("Mark",index,cellIndex) end)
					strokes[cellIndex]=make("UIStroke","PatternHighlight",cells[cellIndex],{Color=colors.cyan,Thickness=3,Enabled=false,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		end
		local rewardNote=label("RewardNote",card,"Pattern rewards pending",UDim2.new(1,-16,0,38),UDim2.fromOffset(8,262),11)
		rewardNote.TextColor3=colors.navy
		return {frame=card,title=title,cells=cells,strokes=strokes,note=rewardNote}
	end
	for index=1,config.Main.Count do cards[index]=createCard(index) end
	local group=frame("BonusGroup",scroll,UDim2.fromOffset(layout.BonusWidth,layout.CardHeight),UDim2.fromOffset(config.Main.Count*(layout.CardWidth+layout.Gap),0))
	group.BackgroundTransparency=1
	for index,definition in ipairs(config.Bonuses) do
		local row=frame(definition.id,group,UDim2.fromOffset(192,132),UDim2.fromOffset((index-1)%2*204,math.floor((index-1)/2)*144))
		local title=label("Title",row,definition.name,UDim2.new(1,-16,0,26),UDim2.fromOffset(8,4),16)
		local numbers=label("Numbers",row,"Waiting for cards",UDim2.new(1,-16,0,52),UDim2.fromOffset(8,32),20)
		local cells={}
		for cellIndex=1,definition.count do
			cells[cellIndex]=button("Cell"..cellIndex,row,"—",UDim2.fromOffset(44,44),UDim2.fromOffset((192-(definition.count*46-2))/2+(cellIndex-1)*46,36),function() request("MarkBonus",definition.id,cellIndex) end)
		end
		local progress=label("Progress",row,"",UDim2.new(1,-16,0,38),UDim2.fromOffset(8,89),13)
		bonusRows[definition.id]={title=title,numbers=numbers,progress=progress,cells=cells}
	end
	local self={root=tray}
	function self:resize(width,height,touch)
		geometry=layout.compute(width,height,touch,config.Main.Count)
		tray.Size,tray.Position=UDim2.fromOffset(geometry.width,geometry.height),UDim2.new(0.5,0,1,-geometry.footer)
		scroll.CanvasSize=UDim2.fromOffset(geometry.contentWidth,layout.CardHeight)
		group.Position=UDim2.fromOffset(geometry.bonusX,0)
		return geometry
	end
	function self:setStatus(text) heading.Text=text end
	function self:render(snapshot,cardColor,markerColor,markerGlyph)
		markerGlyph=markerGlyph or "✓"
		patternLabel.Text=(snapshot.patternDescription or "Pattern schedule awaiting confirmation").."\n◇ start · • called · "..markerGlyph.." marked"
		heading.Text="Ball "..tostring(snapshot.history[#snapshot.history] or "—").." · "..#snapshot.history.."/20"
		for index,view in ipairs(cards) do
			local data=snapshot.cards[index]
			view.title.Text=if data then "Card "..index.." · 15 Pesos / line" else "Card "..index.." · next round"
			view.frame.BackgroundColor3=cardColor
			view.title.TextColor3=colors.navy
			local completed=data and data.completed or {}
			view.note.Text=if #completed>0 then "COMPLETE · "..table.concat(completed,", ").." · pays at round results" else "15 Pesos / line · cell multipliers multiply"
			for cellIndex,cell in ipairs(view.cells) do
				local entry=data and data.cells[cellIndex]
				local prefix=if entry and entry.premarked then "◇" elseif entry and entry.marked then markerGlyph elseif entry and entry.available then "•" else ""
				cell.Text=if entry then (if entry.number==0 then "FREE" else prefix..entry.number) else "—"
				if entry and entry.multiplier then cell.Text..="\n"..entry.multiplier.."×" end
				cell.TextSize=if entry and entry.multiplier then 14 else 18
				view.strokes[cellIndex].Enabled=data~=nil and data.highlight~=nil and data.highlight[cellIndex]==true
				cell.BackgroundColor3=if entry and entry.premarked then colors.ice elseif entry and entry.marked then markerColor elseif entry and entry.available then colors.cyan else colors.blue
				cell.TextColor3=if entry and (entry.marked or entry.available) then colors.navy else colors.ice
				cell.Active=entry~=nil and entry.available and not entry.marked
			end
		end
		for _,bonus in ipairs(snapshot.bonuses) do
			local row,numbers=bonusRows[bonus.id],{}
			for _,entry in ipairs(bonus.cells) do table.insert(numbers,(if entry.marked then "✓" else "")..entry.number) end
			row.numbers.Text=if #numbers>0 then "" else "Awaiting numbers"
			for index,cell in ipairs(row.cells) do
				local entry=bonus.cells[index]
				cell.Text=if entry then (if entry.premarked then "◇" elseif entry.marked then markerGlyph elseif entry.available then "•" else "")..entry.number else "—"
				cell.TextSize=17
				cell.BackgroundColor3=if entry and entry.premarked then colors.ice elseif entry and entry.marked then markerColor elseif entry and entry.available then colors.cyan else colors.blue
				cell.TextColor3=if entry and (entry.marked or entry.available) then colors.navy else colors.ice
				cell.Active=entry~=nil and entry.available and not entry.marked
			end
			row.progress.Text=if bonus.qualified then "✓ QUALIFIED\nResolution pending" elseif bonus.target==0 then "Qualification count pending" elseif #bonus.cells==0 then "Joining next round" else bonus.progress.." / "..bonus.target.." marked"
			row.title.TextColor3=if bonus.qualified then colors.cyan else colors.ice
		end
	end
	return self
end
return Panel
