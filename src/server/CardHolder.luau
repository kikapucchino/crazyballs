-- Server-created tool replicates to everybody. It never changes camera or movement.
local CardHolder = {}
function CardHolder.give(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack or not player.Parent then return end
	if backpack:FindFirstChild("Cards") or (player.Character and player.Character:FindFirstChild("Cards")) then return end
	local tool = Instance.new("Tool")
	tool.Name, tool.ToolTip, tool.CanBeDropped = "Cards", "Open your cards", false
	local handle = Instance.new("Part")
	handle.Name, handle.Size = "Handle", Vector3.new(1.65, 2, 0.16)
	handle.Color, handle.Material = Color3.fromRGB(26, 58, 99), Enum.Material.SmoothPlastic
	handle.CanCollide, handle.Massless, handle.Parent = false, true, tool
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local surface = Instance.new("SurfaceGui")
		surface.Face, surface.CanvasSize, surface.Parent = face, Vector2.new(165, 200), handle
		local title = Instance.new("TextLabel")
		title.Size, title.BackgroundTransparency = UDim2.new(1, 0, 0, 35), 1
		title.Text, title.TextSize, title.Font = "CLOUDPOP", 16, Enum.Font.GothamBold
		title.TextColor3, title.Parent = Color3.fromRGB(222, 241, 255), surface
		for index = 1, 25 do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.fromOffset(23, 23)
			cell.Position = UDim2.fromOffset(14 + (index - 1) % 5 * 28, 40 + math.floor((index - 1) / 5) * 28)
			cell.BackgroundColor3, cell.BorderSizePixel = Color3.fromRGB(120, 198, 225), 0
			cell.Parent = surface
		end
	end
	tool.Parent = backpack
end
return CardHolder
