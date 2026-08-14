local Config = {}

Config.Lane = {
	Width = 28,
	Length = 160,
	Thickness = 1,
	CenterY = 0.5,
	PlayerZ = 8,
	SpawnZ = 140,
	SidePathWidth = 8,
	DividerWidth = 2.2,
}

-- Camera looks +Z, so screen-right is world -X.
function Config.laneXBounds(): (number, number)
	local lane = Config.Lane
	local minX = -(lane.Width / 2 + lane.DividerWidth + lane.SidePathWidth - 2)
	local maxX = lane.Width / 2 - 4
	return minX, maxX
end

Config.Lobby = {
	Center = Vector3.new(0, 1, 4000),
	Size = Vector3.new(400, 1, 400),
	Spawn = Vector3.new(0, 5, 3990),
	StartPad = Vector3.new(0, 1.7, 4012),
}

Config.Player = {
	StartUnits = 1,
	MaxUnits = 1,
	StrafeSpeed = 22,
	LobbyWalkSpeed = 16,
	Health = 100,
	Height = 3,
}

Config.Squad = {
	ClusterRadius = 2.4,
	UnitHeight = 0.15,
}

Config.Combat = {
	FireInterval = 0.1,
	MaxShotsPerVolley = 1,
	UnitDamage = 14,
	ProjectileSpeed = 270,
	ProjectileLifetime = 0.9,
	MuzzleOffset = Vector3.new(0, 1.2, -2.2),
}

Config.Zombie = {
	Health = 36,
	WalkSpeed = 8.5,
	ContactDamage = 7,
	ContactCooldown = 0.95,
	HitRadius = 3.1,
	SpawnGap = 0.9,
	ChaseStartZ = 74,
	ChaseSpeedScale = 0.34,
	BodyColor = Color3.fromRGB(72, 112, 58),
	ClothesColor = Color3.fromRGB(62, 48, 40),
}

Config.Boss = {
	EveryNKills = 25,
	HealthMultiplier = 8,
	SizeMultiplier = 2.4,
	SpeedMultiplier = 0.45,
	ContactDamage = 14,
}

Config.Infinite = {
	MaxAlive = 10,
	SpawnGapStart = 1.15,
	SpawnGapMin = 0.42,
	LaneSlots = { -9, -4.5, 0, 4.5, 9 },
	HealthPerKill = 0.55,
	SpeedPerSecond = 0.035,
}

Config.Waves = {
	Countdown = 3,
}

Config.Camera = {
	Offset = Vector3.new(0, 16.5, -13),
	LookAhead = Vector3.new(0, 4.2, 24),
	LobbyOffset = Vector3.new(0, 16, -14),
	LobbyLookAhead = Vector3.new(0, 1, 16),
	FieldOfView = 72,
	Lerp = 1,
}

return Config
