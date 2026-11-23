--!strict
-- Shared tuning values for the football pitch, player movement, and ball actions.

local Config = {
	Field = {
		Length = 180,
		Width = 110,
		GoalWidth = 36,
		GoalHeight = 14,
		GoalDepth = 7,
		GrassHeight = 1,
	},

	Player = {
		WalkSpeed = 16,
		SprintSpeed = 24,
		SpawnHeight = 5,
	},

	Ball = {
		Radius = 2.2,
		ControlRadius = 10,
		ResetHeight = -20,
		ResetDelay = 1.25,
		KickCooldown = 0.32,
	},

	Kicks = {
		Pass = {
			Speed = 48,
			Lift = 4,
		},
		Kick = {
			Speed = 70,
			Lift = 9,
		},
		Shoot = {
			Speed = 94,
			Lift = 15,
		},
	},
}

return Config
