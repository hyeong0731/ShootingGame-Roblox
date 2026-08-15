local Config = {}

Config.Lane = {
	Width = 35,
	Length = 195,
	Thickness = 1,
	CenterY = 0.5,
	PlayerZ = 8,
	SpawnZ = 175,
	SidePathWidth = 8,
	-- Flat ground strip between main road and right path (not a dirt wall).
	GapWidth = 7,
	-- Green ruined strip (median) starts at this Z and runs away from the player.
	-- Smaller = green closer to the character = narrower asphalt merge.
	-- Player stands at PlayerZ. Tweak this often (try 28~40).
	MergeUntilZ = 33,
}

-- Camera looks +Z, so screen-right is world -X.
function Config.laneXBounds(): (number, number)
	local lane = Config.Lane
	local minX = -(lane.Width / 2 + lane.GapWidth + lane.SidePathWidth - 2)
	local maxX = lane.Width / 2 - 4
	return minX, maxX
end

function Config.sidePathCenterX(): number
	local lane = Config.Lane
	return -(lane.Width / 2 + lane.GapWidth + lane.SidePathWidth / 2)
end

-- Zombies stay on asphalt only: main road, or the near merge onto the right path.
function Config.zombieXBounds(z: number): (number, number)
	local lane = Config.Lane
	local mainMin = -(lane.Width / 2 - 2.4)
	local mainMax = lane.Width / 2 - 3
	if z <= lane.MergeUntilZ then
		local mergeMin = -(lane.Width / 2 + lane.GapWidth + lane.SidePathWidth) + 2.6
		return mergeMin, mainMax
	end
	return mainMin, mainMax
end

-- Tunables for supply crates on the right path (change freely later).
Config.Supply = {
	FirstSpawnDelay = 28,
	SpawnInterval = 40,
	HitCountMin = 9,
	HitCountMax = 25,
	WalkSpeed = 7,
	MaxAlive = 1,
	MaxAllies = 6,
	AllyFireInterval = 0.12,
	DespawnZ = -12,
	-- After this many successful recruits, stop spawning crates (editable later).
	MaxRecruitsPerMatch = 1,
	AllyHealth = 100,
}

-- Bomb crate on the right path from round 4 (same crate look, bomb on top).
Config.BombCrate = {
	UnlockRound = 4,
	FirstSpawnDelay = 6,
	SpawnInterval = 32,
	HitCountMin = 35,
	HitCountMax = 55,
	MaxAlive = 1,
	Duration = 10,
	ThrowInterval = 1,
	Damage = 320,
	Radius = 16,
	ThrowDistance = 54,
	FlightTime = 0.72,
	Gravity = 95,
}

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
	WalkSpeed = 6.2,
	ContactDamage = 7,
	ContactCooldown = 0.95,
	HitRadius = 3.1,
	SpawnGap = 0.9,
	ChaseStartZ = 74,
	ChaseSpeedScale = 0.34,
	-- Stop this many studs in front of the player (so they stay shootable).
	StopDistance = 7.5,
	AttackDuration = 0.55,
	ShambleSpeed = 2.4,
	BodyColor = Color3.fromRGB(72, 112, 58),
	ClothesColor = Color3.fromRGB(62, 48, 40),
}

-- Zombie dogs (editable spawn tunables).
Config.ZombieDog = {
	UnlockWave = 4,
	-- Chance to spawn a dog instead of a normal zombie once unlocked (0~1).
	SpawnChance = 0.32,
	Health = 28,
	WalkSpeed = 9.4,
	ContactDamage = 6,
	HitRadius = 4.2,
	SizeScale = 0.85,
	BodyColor = Color3.fromRGB(58, 72, 48),
	SpeedPerSecond = 0.028,
}

Config.Boss = {
	EveryNKills = 25,
	HealthMultiplier = 8,
	SizeMultiplier = 2.4,
	SpeedMultiplier = 0.45,
	ContactDamage = 14,
}

-- One extra-large boss on this round (editable).
Config.MegaBoss = {
	Round = 5,
	HitCount = 150,
	SizeScale = 2.9,
	WalkSpeed = 3.2,
	ContactDamage = 18,
}

Config.Infinite = {
	MaxAlive = 10,
	SpawnGapStart = 1.15,
	SpawnGapMin = 0.42,
	LaneSlots = { -12, -6, 0, 6, 12 },
	HealthPerKill = 0.55,
	SpeedPerSecond = 0.022,
	-- After recruiting an ally once: spawn gap *= this (lower = denser). Editable.
	AllySpawnGapScale = 0.62,
	AllyMaxAliveBonus = 3,
}

Config.Waves = {
	Countdown = 3,
	-- Seconds between wave number increases (editable).
	Duration = 40,
}

Config.Camera = {
	-- High angle, but framed so the player stays visible at the bottom.
	Offset = Vector3.new(0, 30, -16),
	LookAhead = Vector3.new(0, 1.5, 28),
	LobbyOffset = Vector3.new(0, 16, -14),
	LobbyLookAhead = Vector3.new(0, 1, 16),
	FieldOfView = 64,
	Lerp = 1,
}

Config.Hud = {
	-- Current-weapon button size in pixels.
	WeaponButtonSize = 78,
}

return Config
