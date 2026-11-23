--!strict
-- Shared football gameplay tuning. The server owns the actual rules and validation.

local Config = {
	Ball = {
		Radius = 1.1,
		ControlRange = 8,
		DribbleDistance = 2.75,
		DribbleHeightOffset = -1.48,
		DribbleResponsiveness = 34,
		FreeFriction = 0.985,
		MaxFreeSpeed = 105,
		ResetDelay = 1.2,
		OutOfBoundsX = 108,
		OutOfBoundsZ = 66,
	},

	Shot = {
		MinChargeTime = 0.1,
		MaxChargeTime = 1.35,
		MinSpeed = 48,
		MaxSpeed = 104,
		MinLift = 5,
		MaxLift = 22,
		Cooldown = 0.22,
	},

	Pass = {
		Speed = 42,
		Lift = 1.8,
		Cooldown = 0.16,
	},

	Tackle = {
		Range = 9,
		SlideSpeed = 27,
		SlideDuration = 0.36,
		Cooldown = 2.2,
	},
}

return Config
