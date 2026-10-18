-- Presentation orchestration for trusted, fully configured bonus events.
-- No production odds/timing policy is invented here. The round controller must supply
-- an eligible roster, immutable public values, private resolver and committed outcomes.
local Queue={}
local allowed={coin=true,duck=true,pacinki=true,crazy=true}
function Queue.new(clock,random,onComplete,introSeconds)
	local self={pending={},active=nil,seen={},order={}}
	local function stages(event)
		local result={{name="Intro",seconds=event.introSeconds or introSeconds or 3}}
		if event.kind=="duck" then
			table.insert(result,{name="Preview",seconds=4});table.insert(result,{name="Cover",seconds=1});table.insert(result,{name="Shuffle",seconds=3})
		end
		if event.kind=="duck" or event.kind=="crazy" then table.insert(result,{name="Choice",seconds=12}) end
		table.insert(result,{name="Animate",seconds=5});table.insert(result,{name="Reveal",seconds=6})
		return result
	end
	function self:enqueue(event)
		assert(type(event.id)=="string" and allowed[event.kind] and type(event.resolve)=="function","Invalid trusted bonus event")
		assert(type(event.values)=="table" and #event.values>0 and #event.values<=64,"Supply confirmed outcome labels")
		assert(event.kind~="coin" or #event.values==2,"Coin requires two confirmed faces")
		assert(event.kind~="crazy" or #event.values==64,"Go CRazy requires 64 confirmed sectors")
		if event.kind=="crazy" then
			assert(type(event.pointerOffsets)=="table" and #event.pointerOffsets==3,"Supply three confirmed prize-pointer offsets")
			local used={}
			for _,offset in ipairs(event.pointerOffsets) do
				assert(type(offset)=="number" and offset%1==0 and offset>=0 and offset<64 and not used[offset],"Invalid prize-pointer offset")
				used[offset]=true
			end
			assert(type(event.stopIndex)=="number" and event.stopIndex%1==0 and event.stopIndex>=1 and event.stopIndex<=64,"Supply authoritative shared wheel stop")
		end
		if event.kind=="duck" then
			assert(type(event.previewValues)=="table" and #event.previewValues==#event.values,"Supply the initial Duck preview and final private mapping")
			local counts={}
			for _,value in ipairs(event.values) do counts[value]=(counts[value] or 0)+1 end
			for _,value in ipairs(event.previewValues) do assert(counts[value] and counts[value]>0,"Preview must contain the same outcomes");counts[value]-=1 end
		end
		assert(type(event.eligible)=="table" and next(event.eligible),"No eligible roster")
		if self.seen[event.id] then return false end
		self.seen[event.id]=true;table.insert(self.order,event.id)
		if #self.order>256 then self.seen[table.remove(self.order,1)]=nil end
		local prepared=table.clone(event)
		prepared.values=table.clone(event.values);prepared.eligible=table.clone(event.eligible)
		prepared.previewValues=event.previewValues and table.clone(event.previewValues)
		prepared.pointerOffsets=event.pointerOffsets and table.clone(event.pointerOffsets)
		event=prepared
		local entry={event=event,stages=stages(event),stage=0,choices={},results={},disconnected={}}
		table.insert(self.pending,entry)
		return true
	end
	local function choiceCount(entry) return if entry.event.kind=="crazy" then 3 elseif entry.event.kind=="duck" then #entry.event.values else 0 end
	function self:choose(userId,eventId,index)
		local entry=self.active
		if not entry or entry.event.id~=eventId or not entry.event.eligible[userId] or entry.phase~="Choice" or clock()>=entry.deadline
			or entry.choices[userId] or type(index)~="number" or index%1~=0 or index<1 or index>choiceCount(entry) then return false end
		entry.choices[userId]=index
		return true
	end
	function self:leave(userId)
		local entries=table.clone(self.pending);if self.active then table.insert(entries,self.active) end
		for _,entry in ipairs(entries) do
			if entry.event.eligible[userId] then
				entry.disconnected[userId]=true
				if choiceCount(entry)>0 and not entry.choices[userId] then entry.choices[userId]=random(1,choiceCount(entry)) end
			end
		end
	end
	function self:advance()
		if not self.active and #self.pending>0 then self.active=table.remove(self.pending,1) end
		local entry=self.active
		if not entry or entry.resolving or (entry.deadline and clock()<entry.deadline) then return end
		entry.stage+=1
		local stage=entry.stages[entry.stage]
		if not stage then
			self.active=nil
			local results={}
			for _,result in pairs(entry.results) do if result.committed then table.insert(results,result) end end
			if #results>0 then onComplete({id=entry.event.id,name=entry.event.name,at=clock(),results=results}) end
			self:advance()
			return
		end
		entry.phase,entry.startedAt,entry.deadline=stage.name,clock(),clock()+stage.seconds
		if stage.name=="Animate" then
			entry.resolving=true
			for userId in pairs(entry.event.eligible) do
				if choiceCount(entry)>0 and not entry.choices[userId] then entry.choices[userId]=random(1,choiceCount(entry)) end
				local ok,result=pcall(entry.event.resolve,userId,entry.choices[userId])
				if ok and entry.event.kind=="crazy" then
					ok=type(result)=="table" and result.stopIndex==entry.event.stopIndex
						and result.index==(entry.event.stopIndex-1+entry.event.pointerOffsets[entry.choices[userId]])%64+1
				end
				-- Presentation must never turn an estimated outcome into an awarded result.
				if ok and type(result)=="table" and result.committed==true and type(result.multiplier)=="string"
					and type(result.pesos)=="number" and result.pesos==result.pesos and math.abs(result.pesos)<math.huge
					and type(result.index)=="number" and result.index%1==0 and result.index>=1 and result.index<=#entry.event.values and result.multiplier==entry.event.values[result.index] then
					entry.results[userId]=table.clone(result)
				else entry.results[userId]={committed=false} end
			end
			entry.resolving=false
			entry.startedAt,entry.deadline=clock(),clock()+stage.seconds
		end
	end
	function self:view(userId)
		local entry=self.active
		if not entry or not entry.event.eligible[userId] then return nil end
		local values=entry.event.values
		if entry.event.kind=="duck" then values=if entry.phase=="Preview" then entry.event.previewValues elseif entry.phase=="Reveal" then entry.event.values else {} end
		return {id=entry.event.id,kind=entry.event.kind,name=entry.event.name,phase=if entry.resolving then "Resolving" else entry.phase,
			startedAt=entry.startedAt,deadline=entry.deadline,eligible=true,choice=entry.choices[userId],choiceCount=choiceCount(entry),
			values=values,pointerOffsets=entry.event.pointerOffsets,slotCount=#entry.event.values,result=if entry.phase=="Animate" or entry.phase=="Reveal" then entry.results[userId] else nil}
	end
	return self
end
return Queue
