local Config = {}

-- ============================================================
-- 밸런스 (여기 숫자만 바꾸면 됨)
-- ============================================================

-- 라운드
Config.Waves = {
	Countdown = 3, -- 시작 카운트(초)
	Duration = 40, -- 라운드 길이(초)
}

-- 좀비
Config.Zombie = {
	Health = 36, -- 체력
	WalkSpeed = 6.2, -- 이동 속도
	ContactDamage = 7, -- 닿으면 데미지
	ContactCooldown = 0.95, -- 공격 간격
	HitRadius = 3.1, -- 피격 판정
	SpawnGap = 0.9,
	ChaseStartZ = 74, -- 이 거리부터 플레이어 쪽으로 붙음
	ChaseSpeedScale = 0.34,
	StopDistance = 7.5, -- 플레이어 앞에서 멈추는 거리
	AttackDuration = 0.55, -- 할퀴기 시간
	ShambleSpeed = 2.4, -- 걷는 모션 속도
	BodyColor = Color3.fromRGB(72, 112, 58),
	ClothesColor = Color3.fromRGB(62, 48, 40),
}

-- 좀비 개 (4라운드부터)
Config.ZombieDog = {
	UnlockWave = 4, -- 등장 라운드
	SpawnChance = 0.32, -- 개로 나올 확률 (0~1)
	Health = 28,
	WalkSpeed = 9.4,
	ContactDamage = 6,
	HitRadius = 4.2,
	SizeScale = 0.85, -- 크기
	BodyColor = Color3.fromRGB(58, 72, 48),
	SpeedPerSecond = 0.028, -- 시간 지나며 빨라지는 양
}

-- 일반 보스 (킬 수마다)
Config.Boss = {
	EveryNKills = 25, -- 몇 킬마다 등장
	HealthMultiplier = 8, -- 체력 배수
	SizeMultiplier = 2.4, -- 크기 배수
	SpeedMultiplier = 0.45, -- 속도 배수
	ContactDamage = 14,
}

-- 5라운드 메가보스
Config.MegaBoss = {
	Round = 5, -- 등장 라운드
	HitCount = 150, -- 타수
	SizeScale = 2.9, -- 크기
	WalkSpeed = 3.2,
	ContactDamage = 18,
}

-- 스폰 (기본)
Config.Infinite = {
	MaxAlive = 10, -- 동시에 나올 수 있는 수
	SpawnGapStart = 1.15, -- 처음 스폰 간격(초)
	SpawnGapMin = 0.42, -- 최소 스폰 간격
	LaneSlots = { -12, -6, 0, 6, 12 }, -- 나오는 X 위치
	HealthPerKill = 0.55, -- 킬당 체력 증가
	SpeedPerSecond = 0.022, -- 시간당 속도 증가
	AllySpawnGapScale = 0.62, -- 지원군 뽑은 뒤 스폰 간격 배수 (낮을수록 빽빽)
	AllyMaxAliveBonus = 3, -- 지원군 뽑은 뒤 추가 마리 수
}

-- 7라운드부터 더 빡세게
Config.Pressure = {
	UnlockRound = 7, -- 적용 라운드
	SpawnGapScale = 0.58, -- 스폰 간격 배수 (낮을수록 자주)
	MaxAliveBonus = 5, -- 추가 마리 수
	DogSpawnChance = 0.52, -- 개 확률 (0~1)
}

-- 보급상자 (지원군)
Config.Supply = {
	FirstSpawnDelay = 28, -- 첫 등장까지(초)
	SpawnInterval = 40, -- 등장 간격(초)
	HitCountMin = 9, -- 타수 최소
	HitCountMax = 25, -- 타수 최대
	WalkSpeed = 7,
	SizeScale = 1.5, -- 상자 크기
	MaxAlive = 1, -- 동시에 1개
	MaxAllies = 6, -- 지원군 최대
	AllyFireInterval = 0.12, -- 지원군 연사 간격
	DespawnZ = -12, -- 이 위치 지나면 삭제
	MaxRecruitsPerMatch = 1, -- 한 판에 뽑는 횟수
	AllyHealth = 100, -- 지원군 체력
	HitLabelScale = 1, -- 위 타수 숫자 크기 (1 = 예시 통 숫자)
}

-- 폭탄상자 (4라운드부터)
Config.BombCrate = {
	UnlockRound = 4, -- 등장 라운드
	FirstSpawnDelay = 6, -- 라운드 진입 후 첫 등장(초)
	SpawnInterval = 32, -- 등장 간격(초)
	HitCount = 40, -- 타수
	MaxAlive = 1,
	Duration = 10, -- 폭탄 지속(초)
	ThrowInterval = 1, -- 투척 간격
	Damage = 320, -- 폭발 데미지
	Radius = 16, -- 폭발 범위
	ThrowDistance = 54, -- 던지는 거리
	FlightTime = 0.72,
	Gravity = 95,
	HitLabelScale = 1, -- 위 타수 숫자 크기 (1 = 예시 통 숫자)
}

-- x2 게이트 (6라운드)
Config.NumberGate = {
	UnlockRound = 6, -- 등장 라운드
	Multiplier = 2, -- 타수 배수
	HitCountMin = 20, -- 타수 최소
	HitCountMax = 30, -- 타수 최대
	WalkSpeed = 8,
	Width = 11, -- 가로
	Height = 7.2, -- 세로
	Depth = 0.85, -- 두께
	HitLabelOffset = 0.7, -- 타수 숫자와 게이트 사이 간격
	HitLabelScale = 1, -- 위 타수 숫자 크기 (1 = 예시 통 숫자)
	LabelScale = 1.5, -- x2 크기 (DEV 슬라이더 1.5로 고정)
	MaxAlive = 1,
}

-- 플레이어 / 총
Config.Player = {
	StartUnits = 1,
	MaxUnits = 1,
	StrafeSpeed = 22, -- A/D 이동 속도
	LobbyWalkSpeed = 16,
	Health = 100, -- 체력
	Height = 3,
}

Config.Combat = {
	FireInterval = 0.1, -- 연사 간격
	MaxShotsPerVolley = 1,
	UnitDamage = 14, -- 한 발 데미지
	ProjectileSpeed = 270, -- 탄속
	ProjectileLifetime = 0.9,
	MuzzleOffset = Vector3.new(0, 1.2, -2.2),
}

-- HUD
Config.Hud = {
	WeaponButtonSize = 78, -- 현재무기 버튼 크기
}

-- 개발용 (끝나면 Enabled = false)
Config.Debug = {
	Enabled = true,
	RoundButtons = { 1, 2, 3, 4, 5, 6, 7 },
}

-- ============================================================
-- 맵 / 카메라 (자주 안 건드림)
-- ============================================================

Config.Lane = {
	Width = 35, -- 본도로 폭
	Length = 195,
	Thickness = 1,
	CenterY = 0.5,
	PlayerZ = 8, -- 플레이어 위치
	SpawnZ = 175, -- 적/상자 등장 위치
	SidePathWidth = 12, -- 오른쪽 도로 폭
	GapWidth = 7, -- 본도로~오른쪽 도로 사이
	MergeUntilZ = 33, -- 초록 중앙분리대 시작 (작을수록 캐릭터에 가까움)
}

Config.Lobby = {
	Center = Vector3.new(0, 1, 4000),
	Size = Vector3.new(400, 1, 400),
	Spawn = Vector3.new(0, 5, 3990),
	StartPad = Vector3.new(0, 1.7, 4012),
}

Config.Squad = {
	ClusterRadius = 2.4,
	UnitHeight = 0.15,
}

Config.Camera = {
	Offset = Vector3.new(0, 30, -16),
	LookAhead = Vector3.new(0, 1.5, 28),
	LobbyOffset = Vector3.new(0, 16, -14),
	LobbyLookAhead = Vector3.new(0, 1, 16),
	FieldOfView = 64,
	Lerp = 1,
}

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

return Config
