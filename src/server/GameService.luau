local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)
local CombatService = require(script.Parent.CombatService)
local SupplyService = require(script.Parent.SupplyService)
local NumberGate = require(script.Parent.NumberGate)
local Gun = require(script.Parent.Gun)

type PlayerData = {
	strafe: number,
	character: Model?,
	lastFire: number,
	bombUntil: number,
	hadBomb: boolean,
}

local GameService = {}

local stateFolder: Folder
local playerData: { [Player]: PlayerData } = {}
local phase = "lobby"
local kills = 0
local matchStart = 0
local lastSpawnAt = 0
local lastSupplySpawnAt = 0
local lastBombSpawnAt = 0
local lastGateSpawnAt = 0
local lastSidePathSpawnAt = 0
local supplyRoundArmed = false
local bombRoundArmed = false
local megaBossSpawned = false
local eliteBossesSpawned = false
local finalBossSpawned = false
local introGateSpawned = false
local introGateDueAt = 0
local extraX2Spawned = false
local extraX2DueAt = 0
local plusGateSpawned = false
local gatePlayArmed = false
local chapterClearArmed = false
local chapterPadDebounce = false
local killBaseline = 0
local hitPower = 1
local nextIsBossAt = Config.Boss.EveryNKills
local heartbeatConn: RBXScriptConnection?
local startPadDebounce = false
local grantBombs: () -> ()
local startChapter2: () -> ()

local function setState(key: string, value: any)
	stateFolder:SetAttribute(key, value)
end

local function isLanePhase(): boolean
	return phase == "playing" or phase == "countdown"
end

local function getLeaderPosition(): Vector3?
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
	end
	return nil
end

local function setHeroCollision(character: Model)
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Hero"
		end
	end
end

local function applyLobbyCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	Gun.remove(character)
	humanoid.WalkSpeed = Config.Player.LobbyWalkSpeed
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
	humanoid.AutoRotate = true
	root.Anchored = false
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		pcall(function()
			root:SetNetworkOwner(player)
		end)
	end
end

local function teleportToLobby(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	root.CFrame = CFrame.lookAt(Config.Lobby.Spawn, Vector3.new(Config.Lobby.StartPad.X, Config.Lobby.Spawn.Y, Config.Lobby.StartPad.Z))
	applyLobbyCharacter(character)
end

local function teleportToLane(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	local lane = Config.activeLane()
	local standY = Config.playerStandY()
	root.CFrame = CFrame.lookAt(
		Vector3.new(0, standY, lane.PlayerZ),
		Vector3.new(0, standY, lane.PlayerZ + 10)
	)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	humanoid.MaxHealth = Config.Player.Health
	humanoid.Health = Config.Player.Health
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	root.Anchored = true
	Gun.attach(character)
end

local function applyWalkCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	humanoid.WalkSpeed = Config.Player.LobbyWalkSpeed
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
	humanoid.AutoRotate = true
	humanoid.Health = humanoid.MaxHealth
	root.Anchored = false
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		pcall(function()
			root:SetNetworkOwner(player)
		end)
	end
end

local function destroyChapterPad()
	local arena = Workspace:FindFirstChild("Arena")
	if not arena then
		return
	end
	local pad = arena:FindFirstChild("ChapterPad")
	if pad then
		pad:Destroy()
	end
end

local function spawnChapterPad()
	destroyChapterPad()
	local arena = Workspace:FindFirstChild("Arena")
	if not arena then
		return
	end
	local lane = Config.Lane
	local pad = Instance.new("Part")
	pad.Name = "ChapterPad"
	pad.Anchored = true
	pad.CanCollide = true
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(70, 160, 220)
	pad.Size = Vector3.new(12, 1.2, 12)
	pad.CFrame = CFrame.new(0, lane.CenterY + 1.1, lane.SpawnZ - 6)
	pad:SetAttribute("IsChapterPad", true)
	pad.Parent = arena

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ChapterLabel"
	billboard.Size = UDim2.new(0, 240, 0, 56)
	billboard.StudsOffset = Vector3.new(0, 4.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pad
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = "다음 장소"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = billboard

	pad.Touched:Connect(function(hit)
		if chapterPadDebounce or phase ~= "chapterClear" then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		if not Players:GetPlayerFromCharacter(character) then
			return
		end
		chapterPadDebounce = true
		startChapter2()
		task.delay(1.5, function()
			chapterPadDebounce = false
		end)
	end)
end

local function currentUnitDamage(): number
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	return Config.unitDamageForWave(wave)
end

local function delayBombAfterGate()
	lastBombSpawnAt = os.clock() - Config.BombCrate.SpawnInterval + Config.BombCrate.AfterGateDelay
	bombRoundArmed = true
end

local function markSidePathSpawn()
	lastSidePathSpawnAt = os.clock()
end

local function sidePathReady(now: number): boolean
	return (now - lastSidePathSpawnAt) >= Config.BombCrate.AfterGateDelay
end

local function currentStats()
	local elapsed = math.max(0, os.clock() - matchStart)
	local z = Config.activeZombie()
	local inf = Config.activeInfinite()
	local scaledKills = math.max(0, kills - killBaseline)
	local health = z.Health + scaledKills * inf.HealthPerKill
	local speed = z.WalkSpeed + elapsed * inf.SpeedPerSecond
	local gap = math.max(
		inf.SpawnGapMin,
		inf.SpawnGapStart - elapsed * 0.018
	)
	local maxAlive = inf.MaxAlive
	if SupplyService.hasRecruitedThisMatch() then
		gap *= inf.AllySpawnGapScale
		maxAlive += inf.AllyMaxAliveBonus
	end
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	if Config.chapter() <= 1 and wave >= Config.Pressure.UnlockRound then
		gap *= Config.Pressure.SpawnGapScale
		maxAlive += Config.Pressure.MaxAliveBonus
	end
	if Config.chapter() <= 1 and wave >= Config.FinalBoss.Round then
		maxAlive = Config.FinalBoss.MaxAlive
		gap = Config.FinalBoss.SpawnGap
	end
	return {
		health = health,
		speed = speed,
		gap = gap,
		maxAlive = maxAlive,
	}
end

local function spawnOne()
	local stats = currentStats()
	local inf = Config.activeInfinite()
	local lane = Config.activeLane()
	local slots = inf.LaneSlots
	local x = slots[math.random(1, #slots)]
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	local isBoss = Config.chapter() <= 1 and wave < Config.FinalBoss.Round and kills >= nextIsBossAt
	if isBoss then
		nextIsBossAt += Config.Boss.EveryNKills
		x = slots[math.ceil(#slots / 2)]
	end

	local dogCfg = Config.activeDog()
	local isDog = (not isBoss)
		and wave >= dogCfg.UnlockWave
		and math.random() < dogCfg.SpawnChance

	local scale = if isBoss then Config.Boss.SizeMultiplier elseif isDog then dogCfg.SizeScale else 1
	local y = lane.CenterY + (if isDog then 1.35 else 2.4) * scale
	local elapsed = math.max(0, os.clock() - matchStart)

	local health: number
	local walkSpeed: number
	local contactDamage: number
	if isBoss then
		health = stats.health * Config.Boss.HealthMultiplier
		walkSpeed = stats.speed * Config.Boss.SpeedMultiplier
		contactDamage = Config.Boss.ContactDamage
	elseif isDog then
		health = dogCfg.Health + math.max(0, kills - killBaseline) * inf.HealthPerKill * 0.7
		walkSpeed = dogCfg.WalkSpeed + elapsed * dogCfg.SpeedPerSecond
		contactDamage = dogCfg.ContactDamage
	else
		health = stats.health
		walkSpeed = stats.speed
		contactDamage = Config.activeZombie().ContactDamage
	end

	local zombie = ZombieService.create(Vector3.new(x, y, lane.SpawnZ), {
		health = health,
		walkSpeed = walkSpeed,
		isBoss = isBoss,
		isDog = isDog,
		contactDamage = contactDamage,
		scale = scale,
	})
	ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
end

local function spawnMegaBossAt(x: number, hitCount: number, elite: boolean, appearance: {
	scale: number?,
	walkSpeed: number?,
	contactDamage: number?,
}?)
	local cfg = Config.MegaBoss
	local scale = if appearance and appearance.scale then appearance.scale else cfg.SizeScale
	local walkSpeed = if appearance and appearance.walkSpeed then appearance.walkSpeed else cfg.WalkSpeed
	local contactDamage = if appearance and appearance.contactDamage then appearance.contactDamage else cfg.ContactDamage
	local lane = Config.activeLane()
	local spawnZ = lane.SpawnZ
	local y = lane.CenterY + 2.4 * scale
	local zombie = ZombieService.create(Vector3.new(x, y, spawnZ), {
		health = hitCount,
		walkSpeed = walkSpeed,
		isBoss = true,
		isMega = true,
		isDog = false,
		contactDamage = contactDamage,
		scale = scale,
		hitCount = hitCount,
	})
	if elite then
		zombie.model:SetAttribute("IsEliteBoss", true)
	end
	ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	return zombie
end

local function spawnMegaBoss()
	local slots = Config.Infinite.LaneSlots
	local x = slots[math.ceil(#slots / 2)]
	spawnMegaBossAt(x, Config.MegaBoss.HitCount, false)
end

local function spawnFinalBoss()
	local cfg = Config.FinalBoss
	local hits = math.random(cfg.HitCountMin, cfg.HitCountMax)
	local slots = Config.Infinite.LaneSlots
	local x = slots[math.ceil(#slots / 2)]
	local zombie = spawnMegaBossAt(x, hits, false, {
		scale = cfg.SizeScale,
		walkSpeed = cfg.WalkSpeed,
		contactDamage = cfg.ContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsFinalBoss", true)
	end
end

local function spawnEliteBosses()
	local cfg = Config.EliteBosses
	local minHits = math.max(1, math.floor(cfg.HitCountMin))
	local maxHits = math.max(minHits, math.floor(cfg.HitCountMax))
	local slots = Config.Infinite.LaneSlots
	local count = math.max(1, math.floor(cfg.Count))
	for i = 1, count do
		local t = if count == 1 then 0.5 else (i - 1) / (count - 1)
		local index = 1 + math.floor(t * (#slots - 1) + 0.5)
		local hits = math.random(minHits, maxHits)
		spawnMegaBossAt(slots[index], hits, true)
	end
end

local function spawnIntroGate()
	if introGateSpawned then
		return
	end
	if NumberGate.createIntro() then
		introGateSpawned = true
		markSidePathSpawn()
	end
end

local function spawnPlusGate()
	if plusGateSpawned then
		return
	end
	if NumberGate.createPlusIntro() then
		plusGateSpawned = true
		markSidePathSpawn()
		delayBombAfterGate()
	end
end

local function spawnExtraX2()
	if extraX2Spawned then
		return
	end
	if NumberGate.createExtraIntro() then
		extraX2Spawned = true
		markSidePathSpawn()
	end
end

local function respawnNumberGate()
	NumberGate.clear()
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	if wave >= Config.NumberGate.PlayRound then
		NumberGate.createRandom()
	elseif wave >= Config.NumberGate.PlusRound then
		plusGateSpawned = false
		spawnPlusGate()
	elseif wave >= Config.NumberGate.UnlockRound then
		introGateSpawned = false
		spawnIntroGate()
	end
end

local function applyRoundFeatures(wave: number)
	if Config.chapter() >= 2 then
		return
	end
	if wave >= Config.FinalBoss.Round then
		if not finalBossSpawned then
			finalBossSpawned = true
			eliteBossesSpawned = true
			megaBossSpawned = true
			setState("Announce", Config.FinalBoss.IntroText)
			spawnFinalBoss()
			task.delay(Config.FinalBoss.IntroDuration, function()
				if (stateFolder:GetAttribute("Announce") or "") == Config.FinalBoss.IntroText then
					setState("Announce", "")
				end
			end)
		end
	elseif wave >= Config.EliteBosses.UnlockRound then
		if not eliteBossesSpawned then
			eliteBossesSpawned = true
			megaBossSpawned = true
			spawnEliteBosses()
		end
	elseif wave >= Config.MegaBoss.Round and not megaBossSpawned then
		megaBossSpawned = true
		spawnMegaBoss()
	end
	if wave >= Config.NumberGate.PlayRound then
		if not gatePlayArmed then
			gatePlayArmed = true
			if NumberGate.createRandom() then
				lastGateSpawnAt = os.clock()
				markSidePathSpawn()
				delayBombAfterGate()
			else
				lastGateSpawnAt = os.clock() - Config.NumberGate.SpawnInterval
			end
		end
	elseif wave >= Config.NumberGate.PlusRound then
		spawnPlusGate()
		if extraX2DueAt == 0 and not extraX2Spawned then
			extraX2DueAt = os.clock() + Config.NumberGate.ExtraX2Delay
		end
		if not extraX2Spawned and extraX2DueAt > 0 and os.clock() >= extraX2DueAt then
			spawnExtraX2()
		end
	elseif wave >= Config.NumberGate.UnlockRound then
		if introGateDueAt == 0 and not introGateSpawned then
			if SupplyService.canSpawnBomb() then
				SupplyService.createBomb()
				lastBombSpawnAt = os.clock()
				markSidePathSpawn()
			end
			bombRoundArmed = true
			introGateDueAt = os.clock() + Config.NumberGate.IntroAfterBombDelay
		end
		if not introGateSpawned and introGateDueAt > 0 and os.clock() >= introGateDueAt then
			spawnIntroGate()
		end
	end
	if wave >= Config.Supply.UnlockRound and not supplyRoundArmed then
		supplyRoundArmed = true
		lastSupplySpawnAt = os.clock() - Config.Supply.SpawnInterval + Config.Supply.FirstSpawnDelay
	end
	if wave >= Config.BombCrate.UnlockRound and not bombRoundArmed then
		bombRoundArmed = true
		lastBombSpawnAt = os.clock() - Config.BombCrate.SpawnInterval + Config.BombCrate.FirstSpawnDelay
	end
end

startChapter2 = function()
	destroyChapterPad()
	Config.setChapter(2)
	killBaseline = kills
	CombatService.clear()
	ZombieService.clear()
	NumberGate.clear()
	SupplyService.clearCrates()
	setState("Chapter", 2)
	setState("Wave", Config.Chapter2.Waves.From)
	setState("Elapsed", 0)
	setState("Announce", "")
	setState("HitPower", hitPower)
	megaBossSpawned = false
	eliteBossesSpawned = false
	finalBossSpawned = false
	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLane(player.Character)
		end
	end
	phase = "countdown"
	setState("Phase", "countdown")
	task.spawn(function()
		for i = Config.Waves.Countdown, 1, -1 do
			if phase ~= "countdown" then
				return
			end
			setState("Countdown", i)
			task.wait(1)
		end
		if phase == "countdown" then
			phase = "playing"
			matchStart = os.clock()
			lastSpawnAt = 0
			setState("Phase", "playing")
			setState("Countdown", 0)
			setState("Wave", Config.Chapter2.Waves.From)
			setState("HitPower", hitPower)
		end
	end)
end

local function beginChapterClear()
	if chapterClearArmed or phase ~= "playing" or Config.chapter() >= 2 then
		return
	end
	chapterClearArmed = true
	phase = "chapterClear"
	setState("Phase", "chapterClear")
	setState("Announce", "1챕터 클리어")
	CombatService.clear()
	NumberGate.clear()
	SupplyService.clearCrates()
	spawnChapterPad()
	for _, data in playerData do
		if data.character then
			applyWalkCharacter(data.character)
		end
	end
end

local function beginPlay()
	phase = "playing"
	matchStart = os.clock()
	lastSpawnAt = 0
	killBaseline = 0
	chapterClearArmed = false
	Config.setChapter(1)
	destroyChapterPad()
	setState("Chapter", 1)
	-- First crate at FirstSpawnDelay, then every SpawnInterval after that.
	lastSupplySpawnAt = 0
	lastBombSpawnAt = 0
	lastSidePathSpawnAt = 0
	supplyRoundArmed = false
	bombRoundArmed = false
	introGateSpawned = false
	introGateDueAt = 0
	extraX2Spawned = false
	extraX2DueAt = 0
	plusGateSpawned = false
	gatePlayArmed = false
	lastGateSpawnAt = 0
	hitPower = 1
	setState("Phase", "playing")
	setState("Kills", kills)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("BombLeft", 0)
	setState("HitPower", hitPower)
	for _, data in playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.lastFire = 0
	end
end

local function jumpToRound(round: number)
	round = math.clamp(math.floor(round), 1, 20)
	local keptHitPower = hitPower
	if phase == "lobby" then
		kills = 0
		nextIsBossAt = Config.Boss.EveryNKills
		CombatService.clear()
		ZombieService.clear()
		SupplyService.clear()
		NumberGate.clear()
		hitPower = 1
		megaBossSpawned = false
		eliteBossesSpawned = false
		finalBossSpawned = false
		introGateSpawned = false
		introGateDueAt = 0
		extraX2Spawned = false
		extraX2DueAt = 0
		plusGateSpawned = false
		gatePlayArmed = false
		supplyRoundArmed = false
		bombRoundArmed = false
		setState("Kills", 0)
		setState("HitPower", 1)
		for _, player in Players:GetPlayers() do
			if player.Character then
				teleportToLane(player.Character)
			end
		end
		beginPlay()
	elseif phase == "countdown" then
		beginPlay()
	end
	if phase ~= "playing" then
		return
	end

	hitPower = math.max(1, math.floor(keptHitPower))
	setState("HitPower", hitPower)
	matchStart = os.clock() - Config.elapsedAtWaveStart(round)
	setState("Elapsed", math.floor(Config.elapsedAtWaveStart(round)))
	setState("Wave", round)

	NumberGate.clear()
	introGateSpawned = false
	introGateDueAt = 0
	extraX2Spawned = false
	extraX2DueAt = 0
	plusGateSpawned = false
	gatePlayArmed = false
	applyRoundFeatures(round)
end

local startCountdown: () -> ()

local function onZombieDied()
	if phase ~= "playing" then
		return
	end
	kills += 1
	setState("Kills", kills)
	setState("ZombiesAlive", #ZombieService.getAlive())
end

startCountdown = function()
	phase = "countdown"
	setState("Phase", "countdown")
	setState("Elapsed", 0)
	task.spawn(function()
		for i = Config.Waves.Countdown, 1, -1 do
			if phase ~= "countdown" then
				return
			end
			setState("Countdown", i)
			task.wait(1)
		end
		if phase == "countdown" then
			setState("Countdown", 0)
			beginPlay()
		end
	end)
end

local function damagePlayers(amount: number)
	for _, player in Players:GetPlayers() do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(amount)
		end
	end
end

local function returnToLobby()
	phase = "lobby"
	kills = 0
	killBaseline = 0
	chapterClearArmed = false
	Config.setChapter(1)
	destroyChapterPad()
	CombatService.clear()
	ZombieService.clear()
	SupplyService.clear()
	NumberGate.clear()
	setState("Phase", "lobby")
	setState("Kills", 0)
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("Chapter", 1)
	setState("BombLeft", 0)
	setState("HitPower", 1)
	setState("Announce", "")
	supplyRoundArmed = false
	bombRoundArmed = false
	megaBossSpawned = false
	eliteBossesSpawned = false
	finalBossSpawned = false
	introGateSpawned = false
	introGateDueAt = 0
	extraX2Spawned = false
	extraX2DueAt = 0
	plusGateSpawned = false
	gatePlayArmed = false
	hitPower = 1
	for _, data in playerData do
		data.bombUntil = 0
		data.hadBomb = false
	end

	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLobby(player.Character)
		end
	end
end

local function startMatch()
	if isLanePhase() then
		return
	end

	kills = 0
	nextIsBossAt = Config.Boss.EveryNKills
	CombatService.clear()
	ZombieService.clear()
	SupplyService.clear()
	NumberGate.clear()
	setState("Kills", 0)
	setState("HitPower", 1)
	hitPower = 1
	megaBossSpawned = false
	eliteBossesSpawned = false
	finalBossSpawned = false
	introGateSpawned = false
	introGateDueAt = 0
	extraX2Spawned = false
	extraX2DueAt = 0
	plusGateSpawned = false
	gatePlayArmed = false
	supplyRoundArmed = false
	bombRoundArmed = false

	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLane(player.Character)
		end
	end

	startCountdown()
end

local function onPlayerDied(_player: Player)
	if phase == "gameOver" or phase == "lobby" then
		return
	end
	phase = "gameOver"
	setState("Phase", "gameOver")
	CombatService.clear()
	ZombieService.clear()
	SupplyService.clear()

	task.delay(2.2, function()
		if phase == "gameOver" then
			returnToLobby()
		end
	end)
end

local function setupCharacter(player: Player, character: Model)
	local data = playerData[player]
	if not data then
		return
	end
	data.character = character

	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local _ = root

	humanoid.MaxHealth = Config.Player.Health
	humanoid.Health = Config.Player.Health
	setHeroCollision(character)

	if isLanePhase() then
		teleportToLane(character)
	elseif phase == "chapterClear" then
		applyWalkCharacter(character)
	else
		teleportToLobby(character)
	end

	humanoid.Died:Connect(function()
		onPlayerDied(player)
	end)
end

local function setupPlayer(player: Player)
	playerData[player] = {
		strafe = 0,
		character = nil,
		lastFire = 0,
		bombUntil = 0,
		hadBomb = false,
	}

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

local function restoreGun(data: PlayerData)
	if data.hadBomb and data.character then
		Gun.attach(data.character)
	end
	data.hadBomb = false
	data.bombUntil = 0
	data.lastFire = 0
end

grantBombs = function()
	local untilTime = os.clock() + Config.BombCrate.Duration
	for _, data in playerData do
		data.bombUntil = untilTime
		data.hadBomb = true
		data.lastFire = 0
		if data.character then
			Gun.attachBomb(data.character)
		end
	end
	setState("BombLeft", Config.BombCrate.Duration)
end

local function tryFire(now: number)
	if phase ~= "playing" then
		return
	end

	for _, data in playerData do
		local character = data.character
		if not character then
			continue
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			continue
		end

		local usingBomb = data.hadBomb and now < data.bombUntil
		local interval = if usingBomb then Config.BombCrate.ThrowInterval else Config.Combat.FireInterval
		if now - data.lastFire < interval then
			continue
		end

		data.lastFire = now
		local muzzle = Gun.getMuzzlePosition(character)
			or (root.CFrame * CFrame.new(Config.Combat.MuzzleOffset)).Position
		local origin = Vector3.new(root.Position.X, muzzle.Y, muzzle.Z)
		if usingBomb then
			CombatService.throwBomb(origin, hitPower)
		else
			CombatService.fireStraight(origin, currentUnitDamage(), hitPower)
		end
	end

	for _, allyOrigin in SupplyService.allyMuzzlePoints(now) do
		CombatService.fireStraight(allyOrigin, currentUnitDamage(), 1)
	end
end

local function bindStartPad()
	local arena = Workspace:WaitForChild("Arena")
	local pad = arena:WaitForChild("StartPad")
	if not pad:IsA("BasePart") then
		return
	end

	pad.Touched:Connect(function(hit)
		if startPadDebounce or phase ~= "lobby" then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		startPadDebounce = true
		startMatch()
		task.delay(1.5, function()
			startPadDebounce = false
		end)
	end)
end

function GameService.start(remotes)
	CombatService.bind(remotes)

	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if existing and existing:IsA("Folder") then
		stateFolder = existing
	else
		stateFolder = Instance.new("Folder")
		stateFolder.Name = "GameState"
		stateFolder.Parent = ReplicatedStorage
	end

	setState("Kills", 0)
	setState("Phase", "lobby")
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("Chapter", 1)
	setState("BombLeft", 0)
	setState("HitPower", 1)
	setState("GateLabelScale", Config.NumberGate.LabelScale)
	setState("Announce", "")

	ZombieService.onDied(function()
		onZombieDied()
	end)
	ZombieService.onReached(function(record)
		if phase ~= "playing" then
			return
		end
		local target = record.attackTarget
		if target and target.kind == "ally" and target.ally then
			local hit = SupplyService.damageAlly(target.ally, record.contactDamage)
			if not hit then
				damagePlayers(record.contactDamage)
			end
		else
			damagePlayers(record.contactDamage)
		end
	end)
	SupplyService.onRecruited(function()
		ZombieService.retargetApproaching(function()
			return SupplyService.pickAttackTarget()
		end)
	end)
	SupplyService.onAllyDied(function(dead)
		for _, record in ZombieService.getAlive() do
			local target = record.attackTarget
			if target.kind == "ally" and target.ally == dead then
				ZombieService.setAttackTarget(record, SupplyService.pickAttackTarget())
			end
		end
	end)
	SupplyService.onBombPicked(function()
		if phase == "playing" then
			grantBombs()
		end
	end)
	NumberGate.onCollected(function(kind)
		if phase ~= "playing" then
			return
		end
		local id = kind.Id
		local value = kind.Value or 0
		if id == "x2" or kind.Op == "mul" then
			hitPower = math.max(1, math.floor(hitPower * math.max(1, value)))
		elseif id == "plus" then
			hitPower = math.max(1, math.floor(hitPower + math.max(1, value)))
		else
			hitPower = math.max(1, math.floor(hitPower + value))
		end
		setState("HitPower", hitPower)
	end)

	remotes.Strafe.OnServerEvent:Connect(function(player: Player, value: unknown)
		local data = playerData[player]
		if not data or typeof(value) ~= "number" then
			return
		end
		data.strafe = math.clamp(value :: number, -1, 1)
	end)

	if Config.Debug.Enabled then
		remotes.DebugSetRound.OnServerEvent:Connect(function(_player: Player, value: unknown)
			if not Config.Debug.Enabled or typeof(value) ~= "number" then
				return
			end
			jumpToRound(value :: number)
		end)
		remotes.DebugSetChapter.OnServerEvent:Connect(function(_player: Player, value: unknown)
			if not Config.Debug.Enabled or typeof(value) ~= "number" then
				return
			end
			if (value :: number) >= 2 then
				startChapter2()
			end
		end)
		remotes.DebugHitPower.OnServerEvent:Connect(function(_player: Player, value: unknown)
			if not Config.Debug.Enabled or typeof(value) ~= "number" then
				return
			end
			hitPower = math.clamp(math.floor(value :: number), 1, 999)
			setState("HitPower", hitPower)
		end)
	end

	Players.RespawnTime = 2
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		playerData[player] = nil
	end)

	bindStartPad()

	if heartbeatConn then
		heartbeatConn:Disconnect()
	end

	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local playerPos = getLeaderPosition()

		if phase == "playing" then
			local elapsed = math.floor(now - matchStart)
			if (stateFolder:GetAttribute("Elapsed") or 0) ~= elapsed then
				setState("Elapsed", elapsed)
			end
			local wave = Config.waveFromElapsed(elapsed, Config.chapter())
			if (stateFolder:GetAttribute("Wave") or 1) ~= wave then
				setState("Wave", wave)
			end
			applyRoundFeatures(wave)
			if Config.chapter() <= 1
				and wave >= Config.FinalBoss.Round
				and finalBossSpawned
				and #ZombieService.getAlive() == 0
			then
				beginChapterClear()
			end
		end

		if isLanePhase() then
			for _, data in playerData do
				local character = data.character
				if not character then
					continue
				end
				local root = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
					continue
				end

				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid.JumpHeight = 0
				humanoid.AutoRotate = false

				local lane = Config.activeLane()
				local standY = Config.playerStandY()
				local minX, maxX = Config.laneXBounds()
				-- Camera looks toward +Z, so D (screen-right) moves toward world -X / side path.
				local x = math.clamp(root.Position.X - data.strafe * Config.Player.StrafeSpeed * dt, minX, maxX)
				root.CFrame = CFrame.lookAt(
					Vector3.new(x, standY, lane.PlayerZ),
					Vector3.new(x, standY, lane.PlayerZ + 12)
				)
			end
		end

		if phase == "playing" then
			local stats = currentStats()
			local waveNow = (stateFolder:GetAttribute("Wave") :: number?) or 1
			local holdSpawns = Config.chapter() <= 1
				and waveNow >= Config.FinalBoss.Round
				and finalBossSpawned
				and (function()
					for _, record in ZombieService.getAlive() do
						if record.model:GetAttribute("IsFinalBoss") == true then
							return false
						end
					end
					return true
				end)()
			if not holdSpawns and #ZombieService.getAlive() < stats.maxAlive and now - lastSpawnAt >= stats.gap then
				lastSpawnAt = now
				spawnOne()
			end

			local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
			if Config.chapter() <= 1 then
			local supplyCfg = Config.Supply
			if wave >= supplyCfg.UnlockRound then
				if not supplyRoundArmed then
					supplyRoundArmed = true
					lastSupplySpawnAt = now - supplyCfg.SpawnInterval + supplyCfg.FirstSpawnDelay
				end
				if (now - lastSupplySpawnAt) >= supplyCfg.SpawnInterval and SupplyService.canSpawn() then
					lastSupplySpawnAt = now
					SupplyService.create()
				end
			end
			if wave >= Config.NumberGate.PlayRound then
				if not gatePlayArmed then
					gatePlayArmed = true
					if NumberGate.createRandom() then
						lastGateSpawnAt = now
						markSidePathSpawn()
						delayBombAfterGate()
					else
						lastGateSpawnAt = now - Config.NumberGate.SpawnInterval
					end
				elseif (now - lastGateSpawnAt) >= Config.NumberGate.SpawnInterval
					and sidePathReady(now)
					and NumberGate.canSpawn()
				then
					lastGateSpawnAt = now
					markSidePathSpawn()
					NumberGate.createRandom()
				end
			end

			if wave >= Config.BombCrate.UnlockRound and wave < Config.FinalBoss.Round then
				if not bombRoundArmed then
					bombRoundArmed = true
					lastBombSpawnAt = now - Config.BombCrate.SpawnInterval + Config.BombCrate.FirstSpawnDelay
				end
				if (now - lastBombSpawnAt) >= Config.BombCrate.SpawnInterval
					and sidePathReady(now)
					and SupplyService.canSpawnBomb()
				then
					lastBombSpawnAt = now
					markSidePathSpawn()
					SupplyService.createBomb()
				end
			end
			end

			local bombLeft = 0
			for _, data in playerData do
				if data.hadBomb then
					if now >= data.bombUntil then
						restoreGun(data)
					else
						bombLeft = math.max(bombLeft, math.ceil(data.bombUntil - now))
					end
				end
			end
			if (stateFolder:GetAttribute("BombLeft") or 0) ~= bombLeft then
				setState("BombLeft", bombLeft)
			end

			local leaderStrafe = 0
			for _, data in playerData do
				if math.abs(data.strafe) > math.abs(leaderStrafe) then
					leaderStrafe = data.strafe
				end
			end

			ZombieService.update(dt, playerPos)
			SupplyService.update(dt, playerPos, leaderStrafe)
			NumberGate.update(dt, playerPos)
			tryFire(now)
			CombatService.update(dt)
		elseif phase == "chapterClear" then
			SupplyService.update(dt, playerPos, 0)
		end
	end)
end

return GameService
