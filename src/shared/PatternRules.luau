-- Reusable cell-index patterns. Caller supplies the configured active groups and marked cells.
local Patterns={Labels={row="Rows",column="Columns",diagonal="Diagonals",full="Full house"}}
function Patterns.expand(groups,grid)
	grid=grid or 5
	local result,seen={},{}
	local function add(id,label,cells) table.insert(result,{id=id,label=label,cells=cells}) end
	for _,group in ipairs(groups) do
		assert(Patterns.Labels[group],"Unknown pattern group: "..tostring(group))
		if seen[group] then continue end
		seen[group]=true
		if group=="row" or group=="column" then
			for index=1,grid do
				local cells={}
				for offset=1,grid do table.insert(cells,if group=="row" then (index-1)*grid+offset else (offset-1)*grid+index) end
				add(group..index,(if group=="row" then "Row " else "Column ")..index,cells)
			end
		elseif group=="diagonal" then
			for direction=1,2 do
				local cells={}
				for index=1,grid do table.insert(cells,(index-1)*grid+(if direction==1 then index else grid-index+1)) end
				add("diagonal"..direction,"Diagonal "..direction,cells)
			end
		elseif group=="full" then
			local cells={};for index=1,grid*grid do cells[index]=index end
			add("full","Full house",cells)
		end
	end
	return result
end
function Patterns.evaluate(patterns,marked)
	local completed,highlight={},{}
	for _,pattern in ipairs(patterns) do
		local complete=true
		for _,index in ipairs(pattern.cells) do if not marked[index] then complete=false;break end end
		if complete then
			table.insert(completed,pattern.id)
			for _,index in ipairs(pattern.cells) do highlight[index]=true end
		end
	end
	return completed,highlight
end
function Patterns.description(groups)
	local names={};for _,group in ipairs(groups) do table.insert(names,assert(Patterns.Labels[group])) end
	return if #names>0 then table.concat(names," / ") else "Pattern schedule and rewards awaiting confirmation"
end
return Patterns
