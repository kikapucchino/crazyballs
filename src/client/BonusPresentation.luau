-- Original procedural cinematics. Animation follows an immutable server result;
-- it never selects a reward, moves the camera or disables Roblox character controls.
local Presentation={}
function Presentation.new(normalGui,ui,request,touch)
	local make,label,button=ui.make,ui.label,ui.button
	local colors=ui.colors
	local overlay=make("ScreenGui","CloudpopBonus",normalGui.Parent,{ResetOnSpawn=false,DisplayOrder=-1,Enabled=false,IgnoreGuiInset=false})
	local backdrop=make("Frame","Backdrop",overlay,{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.navy,BorderSizePixel=0,Active=false})
	make("UIGradient","SkyGradient",backdrop,{Color=ColorSequence.new(colors.navy,colors.panel),Rotation=75})
	local safe=make("Frame","SafeArea",backdrop,{BackgroundTransparency=1})
	local title=label("Title",safe,"",UDim2.new(1,0,0,36),UDim2.fromOffset(0,0),26)
	title.TextXAlignment=Enum.TextXAlignment.Center
	local phase=label("Phase",safe,"",UDim2.new(1,0,0,32),UDim2.fromOffset(0,38),15)
	phase.TextXAlignment=Enum.TextXAlignment.Center
	local stage=make("Frame","Stage",safe,{BackgroundTransparency=1,ClipsDescendants=true})
	local canvas=make("Frame","Canvas",stage,{Size=UDim2.fromOffset(600,320),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),BackgroundTransparency=1})
	local scale=make("UIScale","VisualScale",canvas,{Scale=1})
	local details=make("ScrollingFrame","OutcomeLabels",safe,{BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,60),ScrollingDirection=Enum.ScrollingDirection.Y})
	local detailText=label("Values",details,"",UDim2.new(1,-8,0,60),UDim2.fromOffset(0,0),14)
	detailText.TextYAlignment=Enum.TextYAlignment.Top
	local resultText=label("ActualResult",safe,"",UDim2.new(1,0,0,58),UDim2.new(0,0,1,-112),18)
	resultText.TextXAlignment=Enum.TextXAlignment.Center
	local choices=make("ScrollingFrame","Choices",safe,{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.X})
	local choiceButtons={}
	local self={root=overlay,event=nil,previousEnabled=true,visuals={},reduced=false,logicalHeight=320}
	local function circle(name,parent,size,x,y,color)
		local object=make("Frame",name,parent,{Size=UDim2.fromOffset(size,size),Position=UDim2.fromOffset(x,y),BackgroundColor3=color,BorderSizePixel=0})
		make("UICorner","Round",object,{CornerRadius=UDim.new(1,0)})
		return object
	end
	local function clear()
		for _,child in ipairs(canvas:GetChildren()) do if child~=scale then child:Destroy() end end
		for _,child in ipairs(choices:GetChildren()) do child:Destroy() end
		self.visuals={};choiceButtons={}
	end
	local function build(event)
		clear()
		self.logicalHeight=if event.kind=="duck" then math.max(320,math.ceil(event.slotCount/4)*102+10) else 320
		canvas.Size=UDim2.fromOffset(600,self.logicalHeight)
		if event.kind=="coin" then
			local coin=circle("Coin",canvas,242,179,39,colors.cyan)
			coin.ClipsDescendants=true
			make("UIStroke","Rim",coin,{Color=colors.ice,Thickness=7})
			local face=label("CoinFace",coin,"",UDim2.fromScale(1,1),UDim2.fromOffset(0,0),48)
			face.TextColor3,face.TextXAlignment=colors.navy,Enum.TextXAlignment.Center
			self.visuals.coin,self.visuals.face=coin,face
		elseif event.kind=="duck" then
			self.visuals.ducks={}
			for index=1,event.slotCount do
				local x,y=44+(index-1)%4*140,10+math.floor((index-1)/4)*102
				local card=make("Frame","Duck"..index,canvas,{Size=UDim2.fromOffset(120,90),Position=UDim2.fromOffset(x,y),BackgroundColor3=colors.blue,BorderSizePixel=0})
				make("UICorner","Corners",card,{CornerRadius=UDim.new(0,18)})
				local body=circle("Body",card,36,40,18,colors.cyan);body.Size=UDim2.fromOffset(42,30)
				circle("Head",card,20,67,7,colors.ice)
				circle("Eye",card,4,78,11,colors.navy)
				local value=label("Value",card,"",UDim2.new(1,0,0,34),UDim2.fromOffset(0,52),22);value.TextXAlignment=Enum.TextXAlignment.Center
				self.visuals.ducks[index]={card=card,label=value,x=x,y=y}
			end
		elseif event.kind=="pacinki" then
			for row=1,7 do for column=1,9 do circle("Peg",canvas,7,44+column*50+(row%2)*22,10+row*33,colors.ice) end end
			self.visuals.slots={}
			for index=1,event.slotCount do
				local slot=make("Frame","Slot"..index,canvas,{Size=UDim2.fromOffset(550/event.slotCount-2,34),Position=UDim2.fromOffset(25+(index-1)*550/event.slotCount,280),BackgroundColor3=if index%2==0 then colors.cyan else colors.blue,BorderSizePixel=0})
				self.visuals.slots[index]=slot
			end
			self.visuals.ball=circle("DropBall",canvas,18,291,0,colors.cyan)
		elseif event.kind=="crazy" then
			local wheel=circle("Wheel",canvas,284,158,18,colors.blue)
			make("UIStroke","Rim",wheel,{Color=colors.cyan,Thickness=5})
			for index=1,64 do
				local angle=(index-1)*math.pi*2/64
				local tick=make("Frame","Sector"..index,wheel,{Size=UDim2.fromOffset(4,16),Position=UDim2.fromOffset(140+math.sin(angle)*127,134-math.cos(angle)*127),Rotation=(index-1)*360/64,BackgroundColor3=if index%2==0 then colors.ice else colors.cyan,BorderSizePixel=0})
				if index%4==1 then
					local number=label("Index",wheel,tostring(index),UDim2.fromOffset(28,18),UDim2.fromOffset(128+math.sin(angle)*102,133-math.cos(angle)*102),12)
					number.TextXAlignment=Enum.TextXAlignment.Center
				end
			end
			local center=circle("Hub",canvas,132,234,94,colors.navy)
			local hub=label("SelectedSpot",center,"64 SECTORS\n3 PRIZE SPOTS",UDim2.fromScale(1,1),UDim2.fromOffset(0,0),17);hub.TextXAlignment=Enum.TextXAlignment.Center
			self.visuals.pointers={}
			for index,offset in ipairs(event.pointerOffsets or {}) do
				local angle=offset*math.pi*2/64
				local pointer=circle("PrizePointer"..index,canvas,28,286+math.sin(angle)*148,146-math.cos(angle)*148,colors.blue)
				local text=label("Spot",pointer,tostring(index),UDim2.fromScale(1,1),UDim2.fromOffset(0,0),18);text.TextXAlignment=Enum.TextXAlignment.Center
				self.visuals.pointers[index]=pointer
			end
			self.visuals.wheel,self.visuals.hub=wheel,hub
		end
		for index=1,event.choiceCount do
			local width=if event.kind=="crazy" then 126 else 72
			choiceButtons[index]=button("Choice"..index,choices,(if event.kind=="crazy" then "Prize spot " else "Duck ")..index,UDim2.fromOffset(width-6,44),UDim2.fromOffset((index-1)*width,0),function()
				local current=self.event
				if current and current.eligible and current.phase=="Choice" and not current.choice and workspace:GetServerTimeNow()<current.deadline then request("BonusChoice",current.id,index) end
			end)
		end
		choices.CanvasSize=UDim2.fromOffset(event.choiceCount*(if event.kind=="crazy" then 126 else 72),50)
	end
	function self:resize()
		local viewport=normalGui.AbsoluteSize
		local landscape=viewport.X>viewport.Y
		local side=if touch and landscape then 150 else 16
		local footer=if not touch then 16 elseif landscape then 72 else math.min(210,viewport.Y*0.28)
		local width,height=math.max(180,viewport.X-side*2),math.max(200,viewport.Y-footer-12)
		safe.Position,safe.Size=UDim2.fromOffset(side,12),UDim2.fromOffset(width,height)
		local compact=height<360
		local showValues=compact and self.event and (self.event.phase=="Preview" or self.event.phase=="Choice")
		stage.Visible=not showValues
		details.Visible=not compact or showValues
		local visualHeight=math.max(56,math.min(320,height-244))
		stage.Position,stage.Size=UDim2.fromOffset(0,72),UDim2.new(1,0,0,visualHeight)
		scale.Scale=math.min(width/600,visualHeight/self.logicalHeight)
		details.Position,details.Size=UDim2.fromOffset(0,if compact then 72 else 80+visualHeight),UDim2.new(1,0,0,if compact then height-192 else math.max(42,height-visualHeight-198))
	end
	function self:accept(event,reduced)
		self.reduced=reduced==true
		if not event or not event.eligible then
			if self.event then normalGui.Enabled=self.previousEnabled end
			self.event=nil;overlay.Enabled=false;return
		end
		if not self.event then self.previousEnabled=normalGui.Enabled end
		if not self.event or self.event.id~=event.id then build(event) end
		self.event=event;normalGui.Enabled=false;overlay.Enabled=true
		title.Text=event.name
		local values={}
		for index,value in ipairs(event.values) do table.insert(values,index..": "..value.."×") end
		detailText.Text=if #values>0 then table.concat(values,"   ·   ") else "Multipliers covered until the reveal."
		-- Keep all 64 values readable in a scrollable list, independent of wheel scale.
		if event.kind=="crazy" or event.slotCount>12 then
			local rows={};for index,value in ipairs(values) do table.insert(rows,value) end
			detailText.Text=table.concat(rows,"\n")
		end
		local detailHeight=if event.kind=="crazy" or event.slotCount>12 then #values*22 else math.max(60,math.ceil(#values/3)*24)
		detailText.Size,details.CanvasSize=UDim2.new(1,-8,0,detailHeight),UDim2.fromOffset(0,detailHeight)
		for index,choice in ipairs(choiceButtons) do
			choice.Active=event.phase=="Choice" and not event.choice
			choice.BackgroundColor3=if event.choice==index then colors.cyan else colors.blue
			choice.TextColor3=if event.choice==index then colors.navy else colors.ice
		end
		choices.Visible=event.phase=="Choice"
		local result=event.result
		resultText.Text=if event.phase=="Reveal" then
			(if result and result.committed then result.multiplier.."× · "..(if result.pesos>0 then "+" else "")..result.pesos.." Pesos" else "Result could not be confirmed. No payout is shown.")
			elseif event.phase=="Choice" then (if event.choice then "Choice locked: "..event.choice else "Choose once · the server chooses if you do not respond")
			elseif event.phase=="Preview" then "Remember the multipliers before they are covered"
			elseif event.phase=="Resolving" then "Confirming the outcome…" else "Watch the shared bonus unfold"
		self:resize();self:update(workspace:GetServerTimeNow())
	end
	function self:update(now)
		local event=self.event;if not event then return end
		local remaining=math.max(0,math.ceil(event.deadline-now))
		phase.Text=event.phase..(if event.phase=="Resolving" then "" else " · "..remaining.."s")
		local duration=math.max(0.001,event.deadline-event.startedAt)
		local t=math.clamp((now-event.startedAt)/duration,0,1)
		local moving=event.phase=="Animate" and not self.reduced
		local result=event.result
		if event.kind=="coin" then
			local width=if moving then math.max(14,math.abs(math.cos(t*math.pi*8))*242) else 242
			self.visuals.coin.Size,self.visuals.coin.Position=UDim2.fromOffset(width,242),UDim2.fromOffset(300-width/2,39)
			local index=if result and (event.phase=="Reveal" or not moving or t>=1) then result.index elseif moving then math.floor(t*8)%2+1 else 1
			self.visuals.face.Text=(event.values[index] or "?").."×"
		elseif event.kind=="duck" then
			for index,duck in ipairs(self.visuals.ducks) do
				local shuffle=event.phase=="Shuffle" and not self.reduced
				duck.card.Position=UDim2.fromOffset(duck.x+(if shuffle then math.sin(t*math.pi*4+index)*24 else 0),duck.y+(if shuffle then math.sin(t*math.pi*6+index)*8 else 0))
				duck.label.Text=if event.values[index] then event.values[index].."×" else "?"
				duck.card.BackgroundColor3=if event.phase=="Reveal" and result and result.index==index then colors.cyan else colors.blue
			end
		elseif event.kind=="pacinki" then
			local index=result and result.index
			local target=if index then 25+(index-0.5)*550/event.slotCount-9 else 291
			local progress=if event.phase=="Reveal" then 1 elseif moving then t elseif event.phase=="Animate" then 1 else 0
			local x=291+(target-291)*progress+(if moving then math.sin(progress*math.pi*14)*22*(1-progress) else 0)
			self.visuals.ball.Position=UDim2.fromOffset(x,progress*288)
		elseif event.kind=="crazy" then
			local target=if result and result.stopIndex then -(result.stopIndex-1)*360/64 else 0
			for index,pointer in ipairs(self.visuals.pointers) do pointer.BackgroundColor3=if event.choice==index then colors.cyan else colors.blue end
			local rotation=if moving then (1440+target)*(1-(1-t)^3) elseif event.phase=="Reveal" or event.phase=="Animate" then target else 0
			self.visuals.wheel.Rotation=rotation
			self.visuals.hub.Text=if event.choice then "PRIZE SPOT "..event.choice..(if event.phase=="Reveal" and result and result.index then "\nSECTOR "..result.index else "") else "64 SECTORS\n3 PRIZE SPOTS"
		end
	end
	function self:isActive() return self.event~=nil end
	normalGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:resize() end)
	return self
end
return Presentation
