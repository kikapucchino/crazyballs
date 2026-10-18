-- 23,296 square studs: 89% more floor space than the preceding three-room lobby.
return {
	Height = 28,
	Bounds = {x1=-64,x2=144,z1=-56,z2=56},
	Rooms = {
		{ id = "DrawHall", name = "DRAW HALL", x1 = -64, x2 = 64, z1 = -56, z2 = 56 },
		{ id = "SocialLounge", name = "SOCIAL LOUNGE", x1 = 64, x2 = 144, z1 = -56, z2 = 0 },
		{ id = "ViewingRoom", name = "VIEWING ROOM", x1 = 64, x2 = 144, z1 = 0, z2 = 56 },
	},
	Doors = {
		{ axis = "z", fixed = 64, start = -56, finish = 56, centers = { -24, 24 }, width = 14, height = 14 },
		{ axis = "x", fixed = 0, start = 64, finish = 144, centers = { 104 }, width = 14, height = 14 },
	},
}
