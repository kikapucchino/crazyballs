-- Minimal Roblox doubles for executing real startup/controller code, not rendering.
local Mock = {}
function Mock.signal()
	local handlers = {}
	return {
		Connect = function(_, callback)
			table.insert(handlers, callback)
			return { Disconnect = function() local i = table.find(handlers, callback); if i then table.remove(handlers, i) end end }
		end,
		Fire = function(_, ...) for _, callback in ipairs(table.clone(handlers)) do callback(...) end end,
	}
end
function Mock.instances()
	local all, methods = {}, {}
	local function new(class, name, parent)
		local children, properties = {}, { ClassName = class, Name = name or class, AbsoluteSize = { X = 420, Y = 800 }, Visible = true,
			Ended = Mock.signal(), Activated = Mock.signal(), OnClientEvent = Mock.signal(), OnServerEvent = Mock.signal(), ChildAdded = Mock.signal(), CharacterAdded = Mock.signal() }
		local object = setmetatable({}, {
			__index = function(_, key)
				if key == "children" then return children end
				if methods[key] or properties[key] ~= nil then return methods[key] or properties[key] end
				for _, child in ipairs(children) do if child.Name == key then return child end end
				return nil
			end,
			__newindex = function(self, key, value)
				if key == "Parent" then
					if properties.Parent and properties.Parent.children then
						local index = table.find(properties.Parent.children, self)
						if index then table.remove(properties.Parent.children, index) end
					end
					if value then
						if value.children then table.insert(value.children, self) else value[self.Name] = self end
					end
				end
				properties[key] = value
			end,
		})
		table.insert(all, object)
		if parent then object.Parent = parent end
		return object
	end
	function methods:FindFirstChild(name, recursive)
		for _, child in ipairs(self.children) do
			if child.Name == name then return child end
			if recursive then local found = child:FindFirstChild(name, true); if found then return found end end
		end
		return nil
	end
	function methods:WaitForChild(name) return self:FindFirstChild(name) end
	function methods:GetChildren() return table.clone(self.children) end
	function methods:GetFullName() return self.Name end
	function methods:GetPropertyChangedSignal() return Mock.signal() end
	function methods:IsA(class) return self.ClassName == class end
	function methods:Play() self.IsPlaying = true end
	function methods:Stop() self.IsPlaying = false end
	return new, all, methods
end
function Mock.globals()
	local function tuple(...) return { ... } end
	local function vector(x,y,z) return {X=x,Y=y,Z=z,x,y,z} end
	local enum = setmetatable({}, { __index = function(self, key)
		local group = setmetatable({}, { __index = function(_, value) return key .. "." .. value end })
		rawset(self, key, group)
		return group
	end })
	return { Enum = enum, Vector3 = { new = vector }, Vector2 = { new = vector }, Color3 = { fromRGB = tuple },
		UDim = { new = tuple }, UDim2 = { new = tuple, fromOffset = tuple, fromScale = tuple }, TweenInfo = { new = tuple } }
end
return Mock
