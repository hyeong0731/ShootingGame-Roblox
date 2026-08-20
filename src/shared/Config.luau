local Config = {}

-- ============================================================
-- 밸런스 (여기 숫자만 바꾸면 됨)
-- ============================================================

-- 라운드
Config.Waves = {
	Countdown = 3, -- 시작 카운트(초)
	Duration = 50, -- 1~6라운드 길이(초)
	Round7Duration = 55, -- 7라운드 길이(초)
	LongFrom = 8, -- 긴 라운드 시작
	LongUntil = 9, -- 긴 라운드 끝
	LongDuration = 60, -- 8~9라운드 길이(초)
}

-- 좀비
Config.Zombie = {
	Health = 36, -- 체력
	WalkSpeed = 6.2, -- 이동 속도
	ContactDamage = 7, -- 닿으면 데미지
	ContactCooldown = 0.95, -- 공격 간격
	HitRadius = 3.1, -- 피격 판정
	SpawnGap = 0.9,
	ChaseProgress = 0.8, -- 스폰부터 플레이어까지 이 비율 지나면 따라옴
	ChaseStrafeScale = 0.22, -- 따라올 때 좌우(A/D) 속도 (WalkSpeed 배수)
	ChaseStrafeFarScale = 0.42, -- 옆으로 많이 벌어졌을 때 좌우 속도
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

-- 8라운드부터 메가보스 무리 (시작하자마자)
Config.EliteBosses = {
	UnlockRound = 8, -- 등장 라운드
	Count = 3, -- 시작 시 나오는 수
	HitCountMin = 120, -- 보스 타수 최소 (무작위)
	HitCountMax = 200, -- 보스 타수 최대 (무작위)
}

-- 10라운드 최종보스
Config.FinalBoss = {
	Round = 10,
	HitCountMin = 7200,
	HitCountMax = 8200,
	SizeScale = 4.0,
	WalkSpeed = 2.4,
	ContactDamage = 24,
	IntroText = "약한 총알은 통하지 않습니다. 준비되셨나요?",
	IntroDuration = 5, -- 멘트 표시 시간(초)
	MaxAlive = 7, -- 보스 포함 동시 최대 (일반 좀비/개는 조금)
	SpawnGap = 2.8, -- 일반 좀비 스폰 간격
}

-- 스폰 (기본)
Config.Infinite = {
	MaxAlive = 10, -- 동시에 나올 수 있는 수
	SpawnGapStart = 1.15, -- 처음 스폰 간격(초)
	SpawnGapMin = 0.42, -- 최소 스폰 간격
	LaneSlots = { -12, -6, 0, 6, 12 }, -- 나오는 X 위치
	HealthPerKill = 0.3, -- 킬당 체력 증가
	SpeedPerSecond = 0.022, -- 시간당 속도 증가
	AllySpawnGapScale = 0.62, -- 지원군 뽑은 뒤 스폰 간격 배수 (낮을수록 빽빽)
	AllyMaxAliveBonus = 3, -- 지원군 뽑은 뒤 추가 마리 수
}

-- 7~9라운드는 스폰율·개 비율 그대로
Config.Pressure = {
	UnlockRound = 7, -- 적용 라운드
	SpawnGapScale = 1, -- 스폰 간격 유지
	MaxAliveBonus = 0, -- 추가 마리 없음
	DogSpawnChance = 0.32, -- 개 확률 (ZombieDog와 동일)
}

-- 보급상자 (지원군)
Config.Supply = {
	UnlockRound = 2, -- 등장 라운드
	FirstSpawnDelay = 2, -- 라운드 진입 후 첫 등장(초)
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
	AllyRegenDelay = 5, -- 피격 후 이 시간(초) 지나야 회복
	AllyRegenPerSecond = 8, -- 초당 회복량
	HitLabelScale = 1, -- 위 타수 숫자 크기 (1 = 예시 통 숫자)
	PickupGraceSeconds = 0.5, -- 상자 획득 직후 다른 상자 타수 무적 시간
}

-- 폭탄상자 (4라운드부터)
Config.BombCrate = {
	UnlockRound = 4, -- 등장 라운드
	FirstSpawnDelay = 6, -- 게이트 없는 라운드(4) 첫 등장(초)
	AfterGateDelay = 3, -- 게이트 나온 뒤 폭탄 등장까지(초)
	SpawnInterval = 32, -- 등장 간격(초)
	HitCountMin = 30, -- 상자 타수 최소
	HitCountMax = 50, -- 상자 타수 최대
	MaxAlive = 1,
	Duration = 10, -- 폭탄 지속(초)
	ThrowInterval = 1, -- 투척 간격
	Damage = 320, -- 폭발 데미지 (체력형 좀비)
	HitDamage = 40, -- 폭발 시 깎는 타수 (숫자 뜨는 대상)
	Radius = 16, -- 폭발 범위
	ThrowDistance = 90, -- 던지는 거리
	FlightTime = 0.95,
	Gravity = 95,
	HitLabelScale = 1, -- 위 타수 숫자 크기 (1 = 예시 통 숫자)
}

-- 스나이퍼 상자 (챕터2만, 라운드 타임라인에서 등장)
Config.SniperCrate = {
	Chapter = 2, -- 이 챕터에서만 등장
	HitCount = 40, -- 상자 타수
	HitDamage = 40, -- 스나이퍼 한 발이 깎는 타수 (방패/숫자 대상)
	MaxAlive = 1,
	WalkSpeed = 10, -- 스나이퍼 상자 이동 속도 (Supply.WalkSpeed보다 빠름)
	Duration = 10, -- 스나이퍼 지속(초)
	FireInterval = 0.7, -- 연사 간격
	AfterDurationPlusDelay = 5, -- 스나이퍼 끝난 뒤 +1까지
	AfterPlusX2Delay = 3, -- +1 나온 뒤 x2까지
	PlusHitCountMin = 20,
	PlusHitCountMax = 32,
	X2HitCountMin = 40,
	X2HitCountMax = 55,
	ProjectileSpeed = 320, -- 탄속
	ProjectileRadius = 0.7, -- 피격 가로 두께
	BoltSize = Vector3.new(0.48, 0.48, 6.4), -- 총알 크기
	HitLabelScale = 1,
	BigZombieHpRatio = 0.7, -- 큰 좀비 한 발에 깎는 최대체력 비율 (2대에 죽음)
}

-- 화염병 (챕터2 라운드6). 클릭해서 던짐. 총은 계속 나감
Config.Molotov = {
	Count = 3,
	CrateHitCountMin = 60,
	CrateHitCountMax = 80,
	WalkSpeed = 10, -- 화염병 상자 이동 속도 (Supply.WalkSpeed보다 빠름)
	Damage = 90, -- 착탄 폭발 (폭탄 320보다 약함)
	HitDamage = 60, -- 착탄 시 숫자 타수
	Radius = 11,
	ThrowDistance = 72,
	FlightTime = 0.8,
	GroundDuration = 7, -- 바닥 화염 지속
	GroundRadius = 12,
	GroundHpPerSecond = 22,
	GroundHitsPerSecond = 40,
}

-- 타수 게이트 (5라운드 x2, 6라운드 +1, 8라운드부터 x2/+1/-1 랜덤)
Config.NumberGate = {
	UnlockRound = 5, -- 첫 x2 등장
	PlusRound = 6, -- 첫 +1 등장
	ExtraX2Delay = 10, -- 6라운드 시작 후 추가 x2
	PlayRound = 8, -- x2 / +1 / -1 랜덤 시작
	WalkSpeed = 8,
	Width = 11, -- 가로
	Height = 7.2, -- 세로
	Depth = 0.85, -- 두께
	HitLabelOffset = 0.7, -- 타수 숫자와 게이트 사이 간격
	HitLabelScale = 1, -- 위 타수 숫자 크기 (1 = 예시 통 숫자)
	LabelScale = 1.5, -- 글자 크기 (DEV 슬라이더 1.5로 고정)
	MaxAlive = 1,
	SpawnInterval = 14, -- 8라운드부터 등장 간격
	FirstSpawnDelay = 0, -- 라운드 시작 즉시 등장
	IntroAfterBombDelay = 5, -- 5라운드: 폭탄 먼저, 이 시간 뒤 x2
	IntroHitCountMin = 40, -- 5라운드 첫 x2 타수 최소
	IntroHitCountMax = 50, -- 5라운드 첫 x2 타수 최대
	ExtraX2HitCountMin = 55, -- 6라운드 추가 x2 타수 최소
	ExtraX2HitCountMax = 75, -- 6라운드 추가 x2 타수 최대
	PlusIntroHitCountMin = 20, -- 6라운드 첫 +1 타수 최소
	PlusIntroHitCountMax = 30, -- 6라운드 첫 +1 타수 최대
	Kinds = {
		{
			Id = "x2",
			Op = "mul",
			Value = 2,
			Label = "x2",
			HitCountMin = 80,
			HitCountMax = 100,
			Weight = 34,
			WalkSpeedScale = 1,
			PanelColor = Color3.fromRGB(110, 185, 230),
			FrameColor = Color3.fromRGB(22, 72, 175),
			GlowColor = Color3.fromRGB(150, 220, 255),
			StrokeColor = Color3.fromRGB(16, 48, 130),
			BoltColor = Color3.fromRGB(210, 230, 255),
			LightColor = Color3.fromRGB(110, 185, 230),
		},
		{
			Id = "plus",
			Op = "add",
			Value = 1,
			Label = "+1",
			HitCountMin = 70,
			HitCountMax = 90,
			Weight = 40,
			WalkSpeedScale = 1,
			PanelColor = Color3.fromRGB(96, 210, 130),
			FrameColor = Color3.fromRGB(18, 120, 62),
			GlowColor = Color3.fromRGB(170, 255, 190),
			StrokeColor = Color3.fromRGB(12, 80, 40),
			BoltColor = Color3.fromRGB(210, 255, 220),
			LightColor = Color3.fromRGB(90, 220, 130),
		},
		{
			Id = "minus",
			Op = "add",
			Value = -1,
			Label = "-1",
			HitCountMin = 35,
			HitCountMax = 45,
			Weight = 26,
			WalkSpeedScale = 2.6, -- 함정: 더 빠름
			PanelColor = Color3.fromRGB(220, 72, 68),
			FrameColor = Color3.fromRGB(150, 22, 22),
			GlowColor = Color3.fromRGB(255, 150, 140),
			StrokeColor = Color3.fromRGB(90, 10, 10),
			BoltColor = Color3.fromRGB(255, 200, 190),
			LightColor = Color3.fromRGB(255, 80, 70),
		},
		{
			Id = "div2",
			Op = "div",
			Value = 2,
			Label = "÷2",
			HitCountMin = 50,
			HitCountMax = 70,
			Weight = 0, -- 챕터1 랜덤에는 안 나옴
			WalkSpeedScale = 3.4, -- 매우 빠름
			PanelColor = Color3.fromRGB(255, 170, 40),
			FrameColor = Color3.fromRGB(160, 70, 10),
			GlowColor = Color3.fromRGB(255, 210, 90),
			StrokeColor = Color3.fromRGB(120, 50, 0),
			BoltColor = Color3.fromRGB(255, 230, 160),
			LightColor = Color3.fromRGB(255, 160, 40),
		},
	},
}

-- 7~9라운드 폭탄/게이트 타수
Config.LatePickup = {
	FromRound = 7,
	UntilRound = 9,
	HitCountMin = 150,
	HitCountMax = 220,
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
	UnitDamage = 14, -- 한 발 데미지 (1~4라운드)
	DamageByRound = {
		{ Round = 5, Damage = 18 }, -- 5~6라운드
		{ Round = 7, Damage = 20 }, -- 7라운드
		{ Round = 8, Damage = 24 }, -- 8라운드부터
	},
	ProjectileSpeed = 270, -- 탄속
	ProjectileLifetime = 0.9,
	MuzzleOffset = Vector3.new(0, 1.2, -2.2),
}

-- HUD
Config.Hud = {
	WeaponButtonSize = 78, -- 현재무기 버튼 크기
}

-- 타수 숫자 (상자/게이트/보스/방패)
Config.HitLabel = {
	Scale = 0.48, -- 1 = 예전 크기, 낮출수록 작아짐
	CrateFront = Vector3.new(0, 0.35, -2.8), -- 상자 앞면 (로컬, -Z가 플레이어 쪽)
	ShieldScale = 0.62, -- 방패 타수 추가 배수 (전체 Scale에 곱함)
}

-- 개발용 (끝나면 Enabled = false)
Config.Debug = {
	Enabled = true,
	RoundButtons = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
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

-- 방패 좀비 (챕터2, 라운드2 시작 10초 전부터)
Config.ShieldZombie = {
	Chapter = 2,
	UnlockRound = 2, -- 챕터 안 라운드
	LeadSeconds = 10, -- 그 라운드 시작 이만큼 전부터
	HitCountMin = 30, -- 방패 내구도 최소
	HitCountMax = 50, -- 방패 내구도 최대
	SpawnChance = 0.28, -- 일반 좀비 중 방패 확률
}

-- 2챕터 (표시는 1~10) — 좀비 숫자는 1챕터와 같게 시작, 여기만 바꿔서 조절
Config.Chapter2 = {
	Waves = {
		From = 11,
		Until = 20,
		Duration = 60, -- 각 라운드 1분
	},
	MaxHitPower = 34, -- -1·/2 안 먹고 타수 1로 시작 (라운드9 +1까지)

	Zombie = {
		Health = 36,
		WalkSpeed = 6.2,
		ContactDamage = 7,
		ContactCooldown = 0.95,
		HitRadius = 3.1,
		SpawnGap = 0.9,
		ChaseProgress = 0.8,
		ChaseStrafeScale = 0.22,
		ChaseStrafeFarScale = 0.42,
		StopDistance = 7.5,
		AttackDuration = 0.55,
		ShambleSpeed = 2.4,
		BodyColor = Color3.fromRGB(72, 112, 58),
		ClothesColor = Color3.fromRGB(62, 48, 40),
	},
	ZombieDog = {
		UnlockWave = 11,
		SpawnChance = 0.32,
		Health = 28,
		WalkSpeed = 9.4,
		ContactDamage = 6,
		HitRadius = 4.2,
		SizeScale = 0.85,
		BodyColor = Color3.fromRGB(58, 72, 48),
		SpeedPerSecond = 0.028,
	},
	Infinite = {
		MaxAlive = 20, -- 1챕터보다 많이
		SpawnGapStart = 0.5, -- 스폰 간격(초), 낮을수록 빽빽
		SpawnGapMin = 0.2,
		LaneSlots = { -10, -5, 0, 5, 10 },
		HealthPerKill = 0.17, -- 킬당 체력 증가
		SpeedPerSecond = 0.022,
		AllySpawnGapScale = 0.62,
		AllyMaxAliveBonus = 4,
	},
	Lane = {
		Width = 28,
		Length = 210,
		Thickness = 1.6,
		CenterY = 36,
		PlayerZ = 6512,
		SpawnZ = 6690,
		SidePathWidth = 8,
		GapWidth = 4,
		MergeUntilZ = 6538,
	},
	-- 챕터2 로컬 라운드1. 시각은 그 라운드 시작 기준
	Round1 = {
		Round = 1,
		SniperAt = 15,
		PlusAt = 30,
		X2At = 40,
		PlusHitCountMin = 20,
		PlusHitCountMax = 32,
		X2HitCountMin = 40,
		X2HitCountMax = 55,
	},
	-- 챕터2 로컬 라운드2 (내부 wave 12). 시각은 그 라운드 시작 기준
	Round2 = {
		Round = 2,
		MinusAt = 5,
		BombAt = 14,
		PlusAt = 30,
		BigZombieAt = 45, -- 이때부터 1챕터식 큰 좀비 섞임
		SniperAt = 35, -- 스나이퍼 상자
		SniperHitCountMin = 50,
		SniperHitCountMax = 60,
		PlusAgainAt = 55,
		MinusHitCountMin = 18,
		MinusHitCountMax = 28,
		PlusHitCountMin = 20,
		PlusHitCountMax = 32,
	},
	-- 개/방패가 아닌 일반 중 큰 좀비 확률 (크기·체력은 Config.Boss)
	BigZombie = {
		SpawnChance = 0.12,
	},
	-- 챕터2 로컬 라운드3. 시각은 그 라운드 시작 기준
	Round3 = {
		Round = 3,
		SpawnGap = 0.75, -- 기본(0.5)보다 느리게 시작 (스폰율 낮춤)
		MaxAlive = 16, -- 기본(20)보다 적게
		PlusAt = 50,
		AllyAt = 3,
		CrateAt = 12, -- 폭탄
		CrateAgainAt = 40, -- 스나이퍼
		MinusAgainAt = 44,
		ShieldBoostAt = 50,
		AllyHitCountMin = 120,
		AllyHitCountMax = 150,
		ShieldHitCountMin = 50,
		ShieldHitCountMax = 70,
		ShieldSpawnChance = 0.25, -- 전체 스폰 중 방패 비율
		PlusHitCountMin = 40,
		PlusHitCountMax = 50,
		MinusAt = 20,
		MinusHitCountMin = 50,
		MinusHitCountMax = 60,
		SniperHitCountMin = 50,
		SniperHitCountMax = 60,
	},
	-- 챕터2 로컬 라운드4. 스폰율은 라운드3과 같고, 킬당 체력 증가는 잠시 끔
	Round4 = {
		Round = 4,
		MatchSpawnRound = 3, -- 스폰 간격은 이 라운드 끝 시점과 동일
		HealthPerKill = 0,
		ShieldSpawnChance = 0.20, -- 라운드3보다 방패 좀비를 조금 적게
		AllyAt = 8, -- 라운드3에서 지원군 못 먹었을 때만
		AllyHitCountMin = 120,
		AllyHitCountMax = 150,
		CrateAt = 10, -- 폭탄 또는 스나이퍼
		CrateHitCountMin = 60,
		CrateHitCountMax = 80,
		DogSwarmAt = 21,
		DogSwarmCount = 10,
		X2At = 34,
		MinusAt = 55,
		X2HitCountMin = 60,
		X2HitCountMax = 80,
		MinusHitCountMin = 37,
		MinusHitCountMax = 50,
	},
	-- 챕터2 로컬 라운드5. 중간보스 2마리(0초·25초), 잡몹은 덜 나오게
	Round5 = {
		Round = 5,
		X2RetryAt = 0, -- 라운드4 x2를 못 먹었을 때만
		X2HitCountMin = 40,
		X2HitCountMax = 55,
		MidBossAt = 0,
		MidBossAgainAt = 25,
		BombAt = 14,
		BombHitCountMin = 40,
		BombHitCountMax = 50,
		FirstSpawnX = 0,
		SecondSpawnX = 0,
		HitCountMin = 850,
		HitCountMax = 1000,
		HitCountMin2 = 900,
		HitCountMax2 = 1100,
		SizeScale = 2.9, -- 메가보스 크기, 속도만 큰 좀비와 동일
		SpeedMultiplier = 0.45, -- Config.Boss와 동일
		ContactDamage = 18,
		MaxAlive = 8, -- 보스 포함
		SpawnGap = 1.2, -- 기본 0.2보다 느리게
	},
	-- 챕터2 로컬 라운드6
	Round6 = {
		Round = 6,
		HealthPerKill = 0,
		BigZombieSpawnChance = 0.03, -- 개/방패 아닌 일반 중
		ShieldSpawnChance = 0.30, -- 전체 스폰 중 방패
		ShieldHitCountMin = 65,
		ShieldHitCountMax = 80,
		MaxAlive = 17,
		SniperAt = 3,
		SniperHitCount = 75, -- 스나이퍼 상자 타수 (70~80 평균)
		SniperHitCountMin = 70,
		SniperHitCountMax = 80,
		Div2At = 20,
		Div2HitCountMin = 50,
		Div2HitCountMax = 70,
		Div2WalkSpeedScale = 6,
		MolotovAt = 30,
		BombAt = 45,
		BombHitCountMin = 70,
		BombHitCountMax = 80,
		PlusAt = 35,
		PlusHitCountMin = 70,
		PlusHitCountMax = 80,
	},
	-- 챕터2 로컬 라운드7
	Round7 = {
		Round = 7,
		HealthPerKill = 0,
		ShieldSpawnChance = 0.30,
		MaxAlive = 17,
		SniperAt = 5,
		SniperHitCountMin = 70,
		SniperHitCountMax = 80,
		PlusAt = 20,
		BombAt = 30,
		BombHitCountMin = 70,
		BombHitCountMax = 100,
		ShieldPackAt = 50,
		PlusHitCountMin = 80,
		PlusHitCountMax = 100,
		ShieldPackCount = 5,
		ShieldPackHitCountMin = 65,
		ShieldPackHitCountMax = 80,
	},
	-- 챕터2 로컬 라운드8
	Round8 = {
		Round = 8,
		HealthPerKill = 0,
		ShieldSpawnChance = 0.30,
		MaxAlive = 19,
		SpawnGap = 0.14,
		Div2At = 0,
		SniperAt = 6,
		X2At = 0,
		ShieldBoostAt = 30, -- 이때부터 방패 타수 증가
		SniperAgainAt = 30,
		MinusAt = 35,
		X2RetryAt = 25, -- 시작 x2를 못 먹었을 때만
		SwarmAt = 42,
		PlusAt = 45,
		BombAt = 50,
		BombHitCountMin = 55,
		BombHitCountMax = 80,
		MolotovAt = 55,
		Div2HitCountMin = 50,
		Div2HitCountMax = 70,
		Div2WalkSpeedScale = 12, -- 6초 스나이퍼와 겹치지 않게 매우 빠름
		X2HitCountMin = 40,
		X2HitCountMax = 55,
		SniperHitCountMin = 70,
		SniperHitCountMax = 80,
		MinusHitCountMin = 90,
		MinusHitCountMax = 99,
		PlusHitCountMin = 70,
		PlusHitCountMax = 80,
		ShieldHitCountMin = 80,
		ShieldHitCountMax = 100,
		ShieldHitCountMin2 = 110,
		ShieldHitCountMax2 = 125,
		SwarmCount = 18,
		SwarmZStep = 3.2,
		MolotovGrant = 3,
	},
	-- 챕터2 로컬 라운드9. 스나이퍼/폭탄 착탄 타수는 이후 라운드도 동일
	Round9 = {
		Round = 9,
		HealthPerKill = 0,
		MaxAlive = 18,
		MidBossAt = 5,
		SniperAt = 10,
		SniperHitCountMin = 85,
		SniperHitCountMax = 100,
		MinusAt = 20,
		PlusAt = 24,
		BombAt = 30,
		BombHitCountMin = 85,
		BombHitCountMax = 100,
		ShieldPackAt = 34,
		SniperAgainAt = 44,
		MidBossHitCountMin = 600,
		MidBossHitCountMax = 700,
		SizeScale = 2.35,
		SpeedMultiplier = 0.45,
		ContactDamage = 14,
		SpawnX = 0,
		MinusHitCountMin = 80,
		MinusHitCountMax = 100,
		PlusHitCountMin = 140,
		PlusHitCountMax = 160,
		ShieldHitCountMin = 140,
		ShieldHitCountMax = 160,
		ShieldPackCount = 8,
		SniperHitDamage = 100,
		BombHitDamage = 100,
		MolotovHitDamage = 100,
	},
	-- 챕터2 로컬 라운드10. 챕터2 최종보스 + 대규모 혼합 무리
	Round10 = {
		Round = 10,
		HealthPerKill = 0,
		IntroText = "땅이 흔들리고 있습니다... 거대한 무언가가 올 것입니다.",
		IntroDuration = 5,
		OpeningSwarmAt = 0,
		OpeningShield = 6,
		OpeningNormal = 4,
		OpeningDog = 3,
		BossAt = 3,
		BossHitCountMin = 3200,
		BossHitCountMax = 3300,
		SizeScale = 4.2,
		SpeedMultiplier = 0.4, -- 최종보스 이동
		ZombieSpeedScale = 0.72, -- 라운드10 일반/개/방패 속도
		ContactDamage = 22,
		-- 0~20초: 기본 압력
		PreHordeMaxAlive = 20,
		PreHordeSpawnGap = 0.7,
		-- 20초~: R1식 밀도 상승 + 중간 무리
		RampAt = 20,
		RampMaxAlive = 28,
		RampSpawnGap = 0.48,
		MidSwarmAt = 20,
		MidSwarmCount = 14, -- 개·일반 위주 중간 파동
		SniperAt = 30,
		SniperHitCountMin = 250,
		SniperHitCountMax = 290,
		-- 40초~: 피날레
		HordeAt = 40,
		HordeCount = 30,
		LateHordeAt = 50,
		LateHordeCount = 40,
		ShieldSpawnChance = 0.05,
		MaxAlive = 30,
		SpawnGap = 0.4,
	},
}

-- 3챕터 — 폐쇄된 군사통제구역 / DMZ (라운드 설계는 이후)
Config.Chapter3 = {
	Waves = {
		From = 21,
		Until = 30,
		Duration = 60,
	},
	MaxHitPower = 34,

	Zombie = {
		Health = 36,
		WalkSpeed = 6.2,
		ContactDamage = 7,
		ContactCooldown = 0.95,
		HitRadius = 3.1,
		SpawnGap = 0.9,
		ChaseProgress = 0.8,
		ChaseStrafeScale = 0.22,
		ChaseStrafeFarScale = 0.42,
		StopDistance = 7.5,
		AttackDuration = 0.55,
		ShambleSpeed = 2.4,
		BodyColor = Color3.fromRGB(72, 112, 58),
		ClothesColor = Color3.fromRGB(62, 48, 40),
	},
	ZombieDog = {
		UnlockWave = 21,
		SpawnChance = 0.32,
		Health = 28,
		WalkSpeed = 9.4,
		ContactDamage = 6,
		HitRadius = 4.2,
		SizeScale = 0.85,
		BodyColor = Color3.fromRGB(58, 72, 48),
		SpeedPerSecond = 0.028,
	},
	Infinite = {
		MaxAlive = 20,
		SpawnGapStart = 0.5,
		SpawnGapMin = 0.2,
		LaneSlots = { -10, -5, 0, 5, 10 },
		HealthPerKill = 0.17,
		SpeedPerSecond = 0.022,
		AllySpawnGapScale = 0.62,
		AllyMaxAliveBonus = 4,
	},
	Lane = {
		Width = 32,
		Length = 220,
		Thickness = 1,
		CenterY = 0.5,
		PlayerZ = 12512,
		SpawnZ = 12700,
		SidePathWidth = 10,
		GapWidth = 6,
		MergeUntilZ = 12542,
	},
}

Config._chapter = 1

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
	-- 캐릭터는 화면 아래 끝, 위쪽에는 도로가 끝까지 보이는 눕힌 시야
	Offset = Vector3.new(0, 23, -27), -- 카메라 위치 (Y 올리면 위에서 보고, Z 뒤일수록 등이 안 잘림)
	LookAhead = Vector3.new(0, 2, 22), -- 보는 지점 (Z 멀수록 캐릭터가 아래로 내려가고 멀리 보임)
	LobbyOffset = Vector3.new(0, 16, -14),
	LobbyLookAhead = Vector3.new(0, 1, 16),
	FieldOfView = 42, -- 낮을수록 줌인 (41 아래로 내리면 발이 잘림)
	Distance = 1, -- 앞뒤 거리 배수 (낮출수록 가까이)
	Height = 1, -- 높이 배수 (낮출수록 더 눕음)
	Lerp = 1,
}

function Config.setChapter(chapter: number)
	Config._chapter = math.max(1, math.floor(chapter))
end

function Config.chapter(): number
	return Config._chapter
end

function Config.activeLane()
	if Config._chapter >= 3 then
		return Config.Chapter3.Lane
	end
	if Config._chapter >= 2 then
		return Config.Chapter2.Lane
	end
	return Config.Lane
end

function Config.activeZombie()
	if Config._chapter >= 3 then
		return Config.Chapter3.Zombie
	end
	if Config._chapter >= 2 then
		return Config.Chapter2.Zombie
	end
	return Config.Zombie
end

function Config.activeDog()
	if Config._chapter >= 3 then
		return Config.Chapter3.ZombieDog
	end
	if Config._chapter >= 2 then
		return Config.Chapter2.ZombieDog
	end
	return Config.ZombieDog
end

function Config.activeInfinite()
	if Config._chapter >= 3 then
		return Config.Chapter3.Infinite
	end
	if Config._chapter >= 2 then
		return Config.Chapter2.Infinite
	end
	return Config.Infinite
end

function Config.chapterStartWave(chapter: number?): number
	local ch = chapter or Config._chapter
	if ch >= 3 then
		return Config.Chapter3.Waves.From
	end
	if ch >= 2 then
		return Config.Chapter2.Waves.From
	end
	return 1
end

function Config.playerStandY(): number
	local lane = Config.activeLane()
	if Config._chapter <= 1 then
		return Config.Player.Height
	end
	return lane.CenterY + lane.Thickness * 0.5 + 2.2
end

function Config.crateDespawnZ(): number
	return Config.activeLane().PlayerZ - 20
end

function Config.unitDamageForWave(wave: number): number
	local damage = Config.Combat.UnitDamage
	for _, step in Config.Combat.DamageByRound do
		if wave >= step.Round then
			damage = step.Damage
		end
	end
	return damage
end

function Config.pickupHitsForWave(wave: number, fallbackMin: number, fallbackMax: number): (number, number)
	local late = Config.LatePickup
	if wave >= late.FromRound and wave <= late.UntilRound then
		return late.HitCountMin, late.HitCountMax
	end
	return fallbackMin, fallbackMax
end

function Config.chaseStartZ(): number
	local lane = Config.activeLane()
	local zombie = Config.activeZombie()
	return lane.SpawnZ + (lane.PlayerZ - lane.SpawnZ) * zombie.ChaseProgress
end

function Config.hitLabelScale(extra: number?): number
	local base = Config.HitLabel.Scale
	return math.clamp(base * (extra or 1), 0.15, 3)
end

function Config.numberedWeaponHits(kind: string, wave: number?): number
	local r9 = Config.Chapter2.Round9
	local w = wave or 1
	local late = Config.chapter() == 2 and Config.chapterRound(w) >= r9.Round
	if kind == "sniper" then
		return if late then r9.SniperHitDamage else Config.SniperCrate.HitDamage
	elseif kind == "bomb" then
		return if late then r9.BombHitDamage else Config.BombCrate.HitDamage
	elseif kind == "molotov" then
		return if late then r9.MolotovHitDamage else Config.Molotov.HitDamage
	end
	return 1
end

function Config.maxHitPower(chapter: number?): number
	local ch = chapter or Config.chapter()
	if ch >= 3 then
		return Config.Chapter3.MaxHitPower
	end
	if ch >= 2 then
		return Config.Chapter2.MaxHitPower
	end
	return 6
end

function Config.chapterRound(wave: number, chapter: number?): number
	local ch = chapter or Config.chapter()
	if ch >= 3 then
		return math.max(1, math.floor(wave) - Config.Chapter3.Waves.From + 1)
	end
	if ch >= 2 then
		return math.max(1, math.floor(wave) - Config.Chapter2.Waves.From + 1)
	end
	return math.max(1, math.floor(wave))
end

function Config.durationForWave(wave: number): number
	if wave >= Config.Chapter3.Waves.From then
		if wave > Config.Chapter3.Waves.Until then
			return 1e9
		end
		return Config.Chapter3.Waves.Duration
	end
	if wave >= Config.Chapter2.Waves.From then
		if wave > Config.Chapter2.Waves.Until then
			return 1e9
		end
		return Config.Chapter2.Waves.Duration
	end
	if wave >= Config.FinalBoss.Round then
		return 1e9
	end
	if wave >= Config.Waves.LongFrom and wave <= Config.Waves.LongUntil then
		return Config.Waves.LongDuration
	end
	if wave == 7 then
		return Config.Waves.Round7Duration
	end
	return Config.Waves.Duration
end

function Config.elapsedAtWaveStart(wave: number): number
	local startWave = 1
	if wave >= Config.Chapter3.Waves.From then
		startWave = Config.Chapter3.Waves.From
	elseif wave >= Config.Chapter2.Waves.From then
		startWave = Config.Chapter2.Waves.From
	else
		startWave = 1
	end
	local total = 0
	for w = startWave, math.max(startWave, math.floor(wave)) - 1 do
		total += Config.durationForWave(w)
	end
	return total
end

function Config.waveFromElapsed(elapsed: number, chapter: number?): number
	local ch = chapter or Config.chapter()
	if ch >= 3 then
		local from = Config.Chapter3.Waves.From
		local last = Config.Chapter3.Waves.Until
		local t = 0
		for w = from, last do
			local d = Config.durationForWave(w)
			if elapsed < t + d then
				return w
			end
			t += d
		end
		return last
	end
	if ch >= 2 then
		local from = Config.Chapter2.Waves.From
		local last = Config.Chapter2.Waves.Until
		local t = 0
		for w = from, last do
			local d = Config.durationForWave(w)
			if elapsed < t + d then
				return w
			end
			t += d
		end
		return last
	end
	local t = 0
	local last = Config.FinalBoss.Round
	for w = 1, last - 1 do
		local d = Config.durationForWave(w)
		if elapsed < t + d then
			return w
		end
		t += d
	end
	return last
end

function Config.laneXBounds(): (number, number)
	local lane = Config.activeLane()
	local minX = -(lane.Width / 2 + lane.GapWidth + lane.SidePathWidth - 2)
	local maxX = lane.Width / 2 - 4
	return minX, maxX
end

function Config.sidePathCenterX(): number
	local lane = Config.activeLane()
	return -(lane.Width / 2 + lane.GapWidth + lane.SidePathWidth / 2)
end

function Config.zombieXBounds(z: number): (number, number)
	local lane = Config.activeLane()
	local mainMin = -(lane.Width / 2 - 2.4)
	local mainMax = lane.Width / 2 - 3
	if z <= lane.MergeUntilZ then
		local mergeMin = -(lane.Width / 2 + lane.GapWidth + lane.SidePathWidth) + 2.6
		return mergeMin, mainMax
	end
	return mainMin, mainMax
end

return Config
