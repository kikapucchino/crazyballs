-- Responsive geometry in pixels. No scaling the 44px cell targets to fit narrow screens.
local Layout = { CardWidth = 244, CardHeight = 276, BonusWidth = 396, Gap = 12 }
function Layout.compute(width, height, touch, count)
	local landscape = width > height
	local footer = if not touch then 78 elseif landscape then 72 else math.min(230, height * 0.30)
	local margin = if touch and landscape then 150 else 12
	local contentWidth = math.max(1, count) * (Layout.CardWidth + Layout.Gap) + Layout.BonusWidth
	return {
		width = math.min(contentWidth + 20, math.max(200, width - margin * 2)),
		height = math.min(334, math.max(150, height * (if touch then 0.45 else 0.50))),
		footer = footer, contentWidth = contentWidth, bonusX = math.max(1, count) * (Layout.CardWidth + Layout.Gap),
	}
end
return Layout
