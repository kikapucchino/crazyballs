local Pass=require("../src/server/PassService")
local Economy=require("../src/shared/Economy")
local Config=require("../src/shared/Config")
local Chest=require("../src/shared/ChestRules")
local Rules=require("../src/shared/GameRules")
local Payout=require("../src/shared/PayoutRules")
local Store=require("../src/server/PayoutStore")
local Feed=require("../src/server/ResultFeed")
local Mock=require("./mock")
local loadPet=require("./.generated/PetBuilderHarness")
local loadPets=require("./.generated/PetServiceHarness")
local loadGlobal=require("./.generated/GlobalPayoutsHarness")
local passed=0
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name) end
local function copy(value)
	if type(value)~="table" then return value end
	local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
end
local function dbEnvironment()
	local now=1800050000
	local metadata,indexes={},{}
	local failures={write=false,read=false,index=false,acquire=false}
	local database={}
	function database:UpdateAsync(key,fn)
		if failures.write then error("write unavailable") end
		local value=fn(copy(metadata[key]));if value then metadata[key]=copy(value) end;return copy(value)
	end
	function database:GetAsync(key) if failures.read then error("read unavailable") end;return copy(metadata[key]) end
	local ds={}
	function ds:GetDataStore() if failures.acquire then error("acquisition unavailable") end;return database end
	function ds:GetOrderedDataStore(name)
		indexes[name]=indexes[name] or {};local values=indexes[name]
		return {
			SetAsync=function(_,key,value) if failures.index then error("index unavailable") end;values[key]=value end,
			GetSortedAsync=function(_,descending,size)
				if failures.read then error("query unavailable") end
				assert(descending==false)
				local entries={};for key,value in pairs(values) do table.insert(entries,{key=key,value=value}) end
				table.sort(entries,function(a,b) return a.value>b.value or a.value==b.value and a.key>b.key end)
				local cursor=1
				local pages={IsFinished=#entries<=size}
				function pages:GetCurrentPage() local page={};for i=cursor,math.min(#entries,cursor+size-1) do table.insert(page,entries[i]) end;return page end
				function pages:AdvanceToNextPageAsync() cursor+=size;self.IsFinished=cursor+size-1>=#entries end
				return pages
			end,
		}
	end
	return {ds=ds,metadata=metadata,failures=failures,clock=function() return now end,advance=function(delta) now+=delta end,
		record=function(id,pesos,age) return {id=id,userId=1,playerName="User1",source="Round participation",multiplier="1",pesos=pesos,at=now-(age or 0)} end}
end

test("Auto Mark access fails closed without a pass ID and restores verified ownership",function()
	local now,calls,owned,fail=0,0,false,false
	local marketplace={UserOwnsGamePassAsync=function(_,userId,id) calls+=1;assert(userId==1 and id==123);if fail then error("unavailable") end;return owned end}
	local config={Id=0,IntendedPrice=60};local pass=Pass.new(marketplace,config,function() return now end);local player={UserId=1}
	pass:check(player);assert(calls==0 and not pass:owns(player))
	config.Id=123;pass:check(player);assert(calls==1 and not pass:owns(player))
	owned=true;pass:check(player);assert(calls==1)
	now=16;pass:check(player);assert(pass:owns(player))
	fail=true;now=32;pass:check(player);assert(pass:owns(player) and string.find(pass:view(player).status,"unavailable"))
	pass:forget(player);pass:check(player);assert(not pass:owns(player))
	fail=false;pass:check(player,true);assert(pass:owns(player))
end)
test("automatic marking only marks drawn numbers without changing cards or multipliers",function()
	local board=Rules.newCardState(Config,function(low) return low end)
	local before=copy(board);local drawn={[board.cards[1][1]]=true,[board.cards[2][7]]=true}
	Rules.markAll(board,drawn);Rules.markAll(board,drawn)
	for i,card in ipairs(board.cards) do
		assert(board.multipliers[i]==before.multipliers[i])
		for j,number in ipairs(card) do assert(number==before.cards[i][j] and (board.marks[i][number]==true)==(drawn[number]==true)) end
	end
	assert(not board.participated)
end)
test("pet purchases charge exactly once, persist and equip only one companion",function()
	local profile=Economy.defaults();profile.pesos=1000
	assert(Economy.purchase(profile,Config.Catalog,"pet_lumen"));assert(Economy.purchase(profile,Config.Catalog,"pet_lumen"));assert(profile.pesos==500)
	assert(Economy.purchase(profile,Config.Catalog,"pet_prism"));assert(profile.pesos==0 and profile.equipped.pet=="pet_prism")
	assert(not Economy.purchase(profile,Config.Catalog,"pet_tassel"))
	profile=Economy.normalize(profile,Config.Catalog);assert(profile.owned.pet_lumen and profile.owned.pet_prism and profile.equipped.pet=="pet_prism")
	Economy.unequipPet(profile);assert(profile.equipped.pet==nil and profile.owned.pet_prism)
end)
test("real pet models replicate one owner-tagged noncolliding companion and clean up",function()
	local env=Mock.globals();local new=Mock.instances();env.Instance={new=new}
	local builder=loadPet(env);local world=new("Workspace");local service=loadPets(env).new(builder,world)
	local player={UserId=7}
	for _,id in ipairs({"pet_lumen","pet_prism","pet_tassel"}) do
		service:sync(player,id);service:sync(player,id)
		local children=world.CloudpopPets:GetChildren();assert(#children==1 and children[1]:GetAttribute("OwnerUserId")==7)
		for _,part in ipairs(children[1]:GetChildren()) do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery) end
	end
	service:remove(player);assert(#world.CloudpopPets:GetChildren()==0)
end)
test("unconfirmed chest stays disabled; rolling claims cannot duplicate or reset permanent progress",function()
	local data=Economy.defaults().chest
	assert(Config.Chest.Permanent and not Chest.claim(data,Config.Chest,1800000000))
	local config={ClaimRulesConfirmed=true,ResetMode="rolling",RewardMode="fixed",RewardUnits=2}
	assert(Chest.claim(data,config,1800000000));assert(not Chest.claim(data,config,1800000000));assert(not Chest.claim(data,config,1800086399))
	assert(Chest.claim(data,config,1800086400));assert(data.rewardUnits==4 and data.claims==2)
	assert(Chest.claim(data,config,1801000000));assert(data.rewardUnits==6)
	local profile=Economy.defaults();profile.chest=data;assert(Economy.normalize(profile,Config.Catalog).chest.rewardUnits==6)
end)
test("fixed daily reset uses configured UTC offset and one saved receipt per day",function()
	local config={ClaimRulesConfirmed=true,ResetMode="fixed",ResetOffsetSeconds=3600,RewardMode="fixed",RewardUnits=1}
	local data=Economy.defaults().chest;local before=20000*86400+3599
	assert(Chest.claim(data,config,before));assert(not Chest.claim(data,config,before));assert(Chest.claim(data,config,before+1))
	assert(not Chest.claim(data,config,before+2) and data.claims==2)
end)
test("payout eligibility excludes negative, future, old, test and invalid transactions",function()
	local h=dbEnvironment();local record=h.record("a",20)
	assert(Payout.valid(record,h.clock()))
	for key,value in pairs({test=true,pesos=-1,at=h.clock()+1,id=string.rep("x",40)}) do local bad=copy(record);bad[key]=value;assert(not Payout.valid(bad,h.clock())) end
	assert(not Payout.valid(h.record("old",20,86400),h.clock()))
end)
test("global indexes rank transactions across servers and reject conflicting duplicate IDs",function()
	local h=dbEnvironment();local a=Store.new(h.ds,Payout,h.clock);local b=Store.new(h.ds,Payout,h.clock)
	local record=h.record("a",100,10);assert(a:put(record));assert(b:put(record))
	local changed=copy(record);changed.pesos=999;assert(not b:put(changed))
	assert(b:put(h.record("b",60)));assert(a:leader().id=="a" and b:leader().id=="a")
	assert(h.metadata.a.pesos==100)
end)
test("rolling window crosses midnight and expiration promotes the next eligible payout",function()
	local h=dbEnvironment();local store=Store.new(h.ds,Payout,h.clock)
	assert(store:put(h.record("old",900,86390)));assert(store:put(h.record("next",500,20)));assert(store:put(h.record("small",40)))
	assert(store:leader().id=="old");h.advance(11);assert(store:leader().id=="next")
	assert(not store:claimAnnouncement("next","expiry-must-be-quiet"))
	h.advance(86400);local leader,problem=store:leader();assert(not leader and not problem)
end)
test("equal payout ties scan multiple pages and select the earlier award",function()
	local h=dbEnvironment();local store=Store.new(h.ds,Payout,h.clock)
	for i=1,130 do assert(store:put(h.record("tie"..i,200,i))) end
	assert(store:leader().id=="tie130")
end)
test("expired high values do not hide lower live records on later pages",function()
	local h=dbEnvironment();local store=Store.new(h.ds,Payout,h.clock)
	for i=1,110 do assert(store:put(h.record("expired"..i,900+i,86399))) end
	assert(store:put(h.record("eligible",20,10)));h.advance(2);assert(store:leader().id=="eligible")
end)
test("metadata and index failures retry idempotently and never fabricate an empty result",function()
	local h=dbEnvironment();local store=Store.new(h.ds,Payout,h.clock);local record=h.record("a",30)
	h.failures.write=true;assert(not store:put(record) and h.metadata.a==nil)
	h.failures.write=false;h.failures.index=true;assert(not store:put(record) and h.metadata.a)
	h.failures.index=false;assert(store:put(record));assert(store:leader().id=="a")
	h.failures.read=true;local leader,problem=store:leader();assert(not leader and problem)
end)
test("new record announcement has a single cross-server claim",function()
	local h=dbEnvironment();local a=Store.new(h.ds,Payout,h.clock);local b=Store.new(h.ds,Payout,h.clock)
	assert(a:put(h.record("new",50)));assert(a:claimAnnouncement("new","serverA"));assert(not b:claimAnnouncement("new","serverB"))
	assert(b:read("new").announcementToken=="serverA")
end)
test("bonus feed groups four EVENTS, preserves negative outcomes and rejects uncommitted results",function()
	local feed=Feed.new(function() return 100 end)
	local results={{playerName="User1",multiplier="2",pesos=40,committed=true},{playerName="User2",multiplier="-1",pesos=-20,committed=true}}
	for i=1,5 do assert(feed:completeBonus({id=tostring(i),name="Duck hunt",at=100,results=results})) end
	assert(#feed.recent==4 and #feed.recent[1].results==2 and feed.recent[1].id=="5")
	assert(string.find(feed.messages[1].text,"-20 Pesos") and string.find(feed.messages[1].text,"+40 Pesos"))
	assert(not feed:completeBonus({id="5",name="Duck hunt",at=100,results=results}))
	local ok=pcall(function() feed:completeBonus({id="fake",name="Fake",results={{pesos=999,committed=false}}}) end);assert(not ok)
end)
test("two live server controllers synchronize durable receipts and deduplicate notifications",function()
	local h=dbEnvironment();local listeners={};local serial=0
	local messaging={PublishAsync=function(_,_,data) for _,fn in ipairs(listeners) do fn({Data=copy(data)}) end end,
		SubscribeAsync=function(_,_,fn) table.insert(listeners,fn) end}
	local function server(studio)
		local feed=Feed.new(h.clock)
		local services={DataStoreService=h.ds,MessagingService=messaging,HttpService={GenerateGUID=function() serial+=1;return "guid"..serial end},
			RunService={IsStudio=function() return studio end},ReplicatedStorage={WaitForChild=function() return {PayoutRules="rules"} end}}
		local module=loadGlobal({game={GetService=function(_,name) return services[name] end},script={Parent={PayoutStore="store"}},os={time=h.clock},
			require=function(name) return if name=="rules" then Payout else Store end,task={spawn=function(fn) fn() end}})
		return module.new(function(record) feed:record(record) end),feed
	end
	local a,feedA=server(false);local b,feedB=server(false);local studio=server(true)
	local record=h.record("cross",75);local ack=0
	a:submit(record,function() ack+=1 end);a:submit(record,function() ack+=100 end);studio:submit(record,function() ack+=1000 end)
	a:pump();b:pump();a:pump()
	assert(ack==1 and a:view().leader.id=="cross" and b:view().leader.id=="cross")
	assert(#feedA.messages==1 and #feedB.messages==1 and studio:view().leader==nil)
	h.failures.read=true;h.advance(61);b:pump();assert(b:view().leader.id=="cross" and string.find(b:view().status,"delayed"))
	h.advance(86400);assert(b:view().leader==nil and string.find(b:view().status,"expired"))
	h.failures.read=false;b:pump();assert(b:view().leader==nil and string.sub(b:view().status,1,7)=="Updated")
end)
test("global service acquisition failures cannot prevent startup and recover on a later pump",function()
	local h=dbEnvironment();h.failures.acquire=true
	local services={DataStoreService=h.ds,MessagingService={SubscribeAsync=function() end},HttpService={},RunService={IsStudio=function() return false end},ReplicatedStorage={WaitForChild=function() return {PayoutRules="rules"} end}}
	local module=loadGlobal({game={GetService=function(_,name) return services[name] end},script={Parent={PayoutStore="store"}},os={time=h.clock},require=function(name) return if name=="rules" then Payout else Store end,task={spawn=function(fn) fn() end}})
	local global=module.new(function() error("no announcements expected") end)
	global:pump();assert(not global.running and string.find(global:view().status,"unavailable"))
	h.failures.acquire=false;global:pump();assert(string.sub(global:view().status,1,7)=="Updated")
end)
print("Pass/pets/chest/feed/global payouts: "..passed.." tests passed")
