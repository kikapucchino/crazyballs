local Rules=require("../src/shared/GameRules")
local Config=require("../src/shared/Config")
local Patterns=require("../src/shared/PatternRules")
local Queue=require("../src/server/BonusQueue")
local passed=0
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name) end
local function count(t) local n=0;for _ in pairs(t) do n+=1 end;return n end
math.randomseed(1405)
test("2000 main cards have exactly 8–12 distinct immutable starting marks before any draw",function()
	local counts={}
	for i=1,1000 do
		local board=Rules.newCardState(Config,math.random)
		for index=1,#board.cards do assert(count(board.marks[index])==count(board.premarks[index])) end
		for index,card in ipairs(board.cards) do
			local n=count(board.premarks[index]);counts[n]=true;assert(n>=8 and n<=12)
			local before=table.clone(board.premarks[index]);local present={}
			for _,number in ipairs(card) do present[number]=true end
			for number in pairs(before) do assert(present[number]) end
			Rules.markAll(board,{[60]=true,[59]=true})
			assert(count(board.premarks[index])==n)
			for number in pairs(before) do assert(board.premarks[index][number]) end
			assert(board.multipliers[index]==1)
		end
	end
	for n=8,12 do assert(counts[n]) end
	assert(Config.NumberPool==60 and Config.DrawCount==20)
end)
test("all five rows, five columns, both diagonals and full house validate through one engine",function()
	local definitions=Patterns.expand({"row","column","diagonal","full"},5)
	assert(#definitions==13)
	for _,pattern in ipairs(definitions) do
		local marked={};for _,index in ipairs(pattern.cells) do marked[index]=true end
		local complete,highlight=Patterns.evaluate({pattern},marked)
		assert(#complete==1 and complete[1]==pattern.id)
		for _,index in ipairs(pattern.cells) do assert(highlight[index]) end
		marked[pattern.cells[1]]=nil;assert(#Patterns.evaluate({pattern},marked)==0)
	end
	assert(#Patterns.expand({"row","row"},5)==5)
end)
test("premarked pattern is detected without a reroll and unrelated patterns cannot win",function()
	local board=Rules.newCardState(Config,function(low) return low end)
	local numbers=table.clone(board.cards[1]);local marks={}
	for i=1,5 do marks[i]=true end;marks[25]=true
	local complete=Patterns.evaluate(Patterns.expand({"row"},5),marks)
	assert(complete[1]=="row1" and #Patterns.evaluate(Patterns.expand({"column","diagonal","full"},5),marks)==0)
	assert(next(board.claimed)==nil and not board.participated)
	for i=1,25 do assert(numbers[i]==board.cards[1][i]) end
	assert(Config.Main.StartingPatternPolicy=="pay" and Config.Main.LineBasePesos==15)
end)
test("bonus marks reject uncalled, forged and duplicate inputs and qualify only marked cards once",function()
	local board=Rules.newCardState(Config,math.random);local card=board.bonuses.coin;local drawn={}
	for _,number in ipairs(card.numbers) do drawn[number]=true end
	assert(#Rules.qualify(board,drawn)==0 and not card.qualified)
	assert(not Rules.markBonus(board,{},"coin",1))
	for _,bad in ipairs({0,4,1.5,math.huge,0/0,"1",{}}) do assert(not Rules.markBonus(board,drawn,"coin",bad)) end
	assert(not Rules.markBonus(board,drawn,{},1))
	for index,number in ipairs(card.numbers) do assert(Rules.markBonus(board,drawn,"coin",index)==(not card.premarks[number])) end
	assert(card.qualified and card.progress==3 and board.participated)
	assert(not Rules.markBonus(board,drawn,"coin",3) and #Rules.qualify(board)==0)
	assert(not board.bonuses.duck.qualified and not board.bonuses.crazy.qualified)
end)
test("Auto Mark covers main and bonus cards while preserving the small bonus counts and no starting qualification",function()
	local board=Rules.newCardState(Config,math.random);local drawn={}
	for _,card in pairs(board.bonuses) do assert(count(card.marks)<=math.max(0,#card.numbers-1) and not card.qualified);for _,number in ipairs(card.numbers) do drawn[number]=true end end
	Rules.markAll(board,drawn)
	assert(board.bonuses.coin.qualified and board.bonuses.duck.qualified and board.bonuses.pacinki.qualified and not board.bonuses.crazy.qualified)
	for i,card in ipairs(board.cards) do for _,number in ipairs(card) do assert((board.marks[i][number]==true)==(drawn[number]==true or board.premarks[i][number]==true)) end end
	assert(not board.participated)
end)
test("cell multipliers replace card factors, stack on each distinct line and pay starting lines",function()
	local board=Rules.newCardState(Config,math.random);board.multipliers={7,20}
	board.tiles={{[1]=20,[2]=50},{[1]=10}}
	local patterns=Patterns.expand({"row","column","diagonal"},5)
	local awards,held=Rules.lineAwards(board,{{"row1","row2","row2","column1"},{"row1"}},{{"row1"},{"row1"}},15,"pay",patterns,"replace")
	assert(#awards==4 and held==0)
	assert(awards[1].pesos==15000 and awards[1].multiplier==1000 and awards[1].patternId=="row1")
	assert(awards[2].pesos==15 and awards[3].pesos==300 and awards[4].pesos==150)
	local gated,heldStarting=Rules.lineAwards(board,{{"row1"},{}},{{"row1"},{}},15,"pending",patterns,"replace")
	assert(#gated==0 and heldStarting==1)
	assert(Rules.settle(board,Config.Rewards).total==0 and Rules.settle(board,Config.Rewards)==nil)
end)
test("bonus starting totals span zero to eight but never qualify any small card",function()
	local totals={};local tileCounts,values={},{}
	for _=1,1000 do
		local board=Rules.newCardState(Config,math.random);local total=0
		for _,card in pairs(board.bonuses) do
			local n=count(card.premarks);total+=n
			assert(n<=math.max(0,#card.numbers-1) and card.progress==n and not card.qualified)
		end
		assert(total<=8);totals[total]=true
		for _,tiles in ipairs(board.tiles) do
			local n=count(tiles);assert(n==1 or n==2);tileCounts[n]=true
			for index,value in pairs(tiles) do assert(index>=1 and index<=25 and table.find({10,20,50},value));values[value]=true end
		end
	end
	for n=0,8 do assert(totals[n]) end
	assert(tileCounts[1] and tileCounts[2] and values[10] and values[20] and values[50])
end)
local function environment()
	local now,completed,awards=0,{},{}
	local queue=Queue.new(function() return now end,function(low) return low end,function(event) table.insert(completed,event) end)
	local function advance(seconds) for _=1,seconds do now+=1;queue:advance() end end
	local function event(id,kind)
		local values=if kind=="coin" then {"-2","4"} elseif kind=="crazy" then table.create(64,"3") else {"1","2","3","4"}
		return {id=id,kind=kind,name=kind,values=values,previewValues={"4","3","2","1"},eligible={[1]=true,[2]=true},pointerOffsets={0,21,43},stopIndex=17,
			resolve=function(userId,choice)
				awards[userId]=(awards[userId] or 0)+1
				local index=if kind=="crazy" then (16+({0,21,43})[choice])%64+1 else choice or 2
				return {index=index,stopIndex=17,multiplier=values[index],pesos=tonumber(values[index])*20,playerName="User"..userId,committed=true}
			end}
	end
	return queue,advance,event,completed,awards
end
test("server bonus queue serializes different eligible events and blocks spectator choices",function()
	local q,advance,event,completed=environment();local first=event("a","coin");local second=event("b","pacinki");second.eligible={[2]=true}
	assert(q:enqueue(first));assert(not q:enqueue(first));q:enqueue(second);q:advance()
	assert(q:view(1).kind=="coin" and q:view(3)==nil and not q:choose(3,"a",1))
	advance(14);assert(#completed==1 and q:view(1)==nil and q:view(2).kind=="pacinki")
	advance(14);assert(#completed==2 and q:view(2)==nil)
end)
test("Duck previews then hides mappings, accepts one timed selection and gives timeout/departure fallback",function()
	local q,advance,event,completed,awards=environment();q:enqueue(event("duck","duck"));q:advance()
	assert(#q:view(1).values==0);advance(3);assert(q:view(1).phase=="Preview" and q:view(1).values[1]=="4")
	advance(4);assert(q:view(1).phase=="Cover" and #q:view(1).values==0)
	advance(4);assert(q:view(1).phase=="Choice")
	assert(not q:choose(1,"stale",2));assert(q:choose(1,"duck",3));assert(not q:choose(1,"duck",2))
	q:leave(2);advance(12);assert(q:view(1).result.multiplier=="3" and q:view(2).result.multiplier=="1")
	assert(not q:choose(1,"duck",4));advance(11);assert(#completed==1 and #completed[1].results==2 and awards[1]==1 and awards[2]==1)
end)
test("64-sector wheel uses the supplied shared stop and three confirmed pointer offsets",function()
	local q,advance,event=environment();q:enqueue(event("wheel","crazy"));q:advance();advance(3)
	assert(q:choose(1,"wheel",2));assert(q:choose(2,"wheel",3));advance(12)
	local a,b=q:view(1),q:view(2)
	assert(a.result.stopIndex==b.result.stopIndex and a.result.stopIndex==17)
	assert(a.result.index==38 and b.result.index==60 and #a.values==64)
end)
test("failed or inconsistent bonus settlements cannot display or announce an awarded payout",function()
	local q,advance,event,completed=environment();local item=event("fail","coin")
	item.resolve=function(userId) if userId==1 then error("save failed") end;return {committed=true,pesos=999,multiplier="99",index=2} end
	q:enqueue(item);q:advance();advance(3)
	assert(not q:view(1).result.committed and not q:view(2).result.committed)
	advance(11);assert(#completed==0)
end)
print("Premarks/patterns/manual bonus/queue: "..passed.." tests passed")
