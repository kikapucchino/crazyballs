-- Geometry in studs; shared by construction and collision/accessibility regression checks.
return {
	Height = 26,
	Rooms = {
		{ id = "DrawHall", name = "DRAW HALL", x1 = -48, x2 = 48, z1 = -40, z2 = 40 },
		{ id = "SocialLounge", name = "SOCIAL LOUNGE", x1 = 48, x2 = 106, z1 = -40, z2 = 0 },
		{ id = "ViewingRoom", name = "VIEWING ROOM", x1 = 48, x2 = 106, z1 = 0, z2 = 40 },
	},
	Doors = {
		{ axis = "z", fixed = 48, start = -40, finish = 40, centers = { -17, 17 }, width = 12, height = 12 },
		{ axis = "x", fixed = 0, start = 48, finish = 106, centers = { 77 }, width = 12, height = 12 },
	},
}
