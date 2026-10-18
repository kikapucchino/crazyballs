local DataStoreService=game:GetService("DataStoreService")
local MessagingService=game:GetService("MessagingService")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Cloudpop")
local Rules=require(Shared.PayoutRules)
local Store=require(script.Parent.PayoutStore)
local Global={}
function Global.new(onRecord)
	local self={leader=nil,status="Loading global payout records",pending={},running=false,nextScan=0,candidates={},notifications={}}
	local enabled=not RunService:IsStudio()
	local store
	if not enabled then self.status="Studio test payouts are excluded" end
	local function publish(data) pcall(function() MessagingService:PublishAsync("CloudpopPayouts_v1",data) end) end
	function self:submit(record,ack)
		if not enabled or not Rules.valid(record,os.time()) then return end
		if not self.pending[record.id] then self.pending[record.id]={record=record,ack=ack,attemptAt=0,attempts=0} end
	end
	function self:view()
		local leader=self.leader
		if leader and not Rules.valid(leader,os.time()) then leader=nil;self.nextScan=0;self.status="Refreshing expired payout record" end
		return {leader=leader,status=self.status}
	end
	function self:pump()
		if not enabled or self.running then return end
		self.running=true
		if not store then
			local ok,result=pcall(Store.new,DataStoreService,Rules,os.time)
			if not ok then self.status="Payout record service unavailable; retrying";self.running=false;return end
			store=result
		end
		local now=os.time()
		local readCount=0
		for id,at in pairs(self.notifications) do
			if readCount>=4 then break end
			readCount+=1
			local record=store:read(id)
			if record and record.announcementToken then onRecord(record);self.notifications[id]=nil
			elseif now-at>30 then self.notifications[id]=nil end
		end
		local processed=0
		for id,entry in pairs(self.pending) do
			if processed>=4 then break end -- batch writes; no remote can flood this queue
			if entry.attemptAt>now then continue end
			processed+=1
			if now-entry.record.at>=86400 then self.pending[id]=nil; if entry.ack then entry.ack() end;continue end
			local ok=store:put(entry.record)
			if ok then
				self.pending[id]=nil
				self.candidates[id]=now
				self.nextScan=0
				if entry.ack then entry.ack() end
				publish({kind="changed",id=id})
			else
				entry.attempts+=1
				entry.attemptAt=now+math.min(120,5*2^math.min(entry.attempts,5))
				self.status="Payout record service delayed; retrying"
			end
		end
		if now>=self.nextScan then
			local leader,problem=store:leader()
			self.nextScan=now+60
			if problem then self.status="Payout record service delayed; retrying"
			else
				self.leader,self.status=leader,"Updated "..now
				if leader and self.candidates[leader.id] and now-leader.at<=120 then
					local token=HttpService:GenerateGUID(false)
					if store:claimAnnouncement(leader.id,token) then onRecord(leader);publish({kind="record",id=leader.id}) end
				end
			end
		end
		for id,at in pairs(self.candidates) do if now-at>120 then self.candidates[id]=nil end end
		self.running=false
	end
	if enabled then
		task.spawn(function()
			-- Subscription failure does not block gameplay; minute polling is the fallback.
			pcall(function()
				MessagingService:SubscribeAsync("CloudpopPayouts_v1",function(message)
					local data=message.Data
					if type(data)~="table" or type(data.id)~="string" or #data.id>80 then return end
					if data.kind=="changed" then
						self.candidates[data.id]=os.time()
						self.nextScan=math.min(self.nextScan,os.time()+10)
					elseif data.kind=="record" then
						self.notifications[data.id]=os.time()
					end
				end)
			end)
		end)
	end
	return self
end
return Global
