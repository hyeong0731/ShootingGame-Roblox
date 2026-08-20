local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Arena = require(script.Parent.Arena)
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
	sniperUntil: number,
	hadSniper: boolean,
	shotgunUntil: number,
	hadShotgun: boolean,
}

local GameService = {}

local stateFolder: Folder
local playerData: { [Player]: PlayerData } = {}
local phase = "lobby"
local paused = false
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
local chapter2PlusSpawned = false
local chapter2X2Spawned = false
local chapter2PlusDueAt = 0
local chapter2X2DueAt = 0
local ch2R1SniperSpawned = false
local ch2R1PlusSpawned = false
local ch2R1X2Spawned = false
local ch2R2MinusSpawned = false
local ch2R2BombSpawned = false
local ch2R2Plus1Spawned = false
local ch2R2SniperSpawned = false
local ch2R2Plus2Spawned = false
local ch2R3PlusSpawned = false
local ch2R3AllySpawned = false
local ch2R3Crate1Spawned = false
local ch2R3Minus1Spawned = false
local ch2R3Crate2Spawned = false
local ch2R3Minus2Spawned = false
local ch2R4CrateSpawned = false
local ch2R4X2Spawned = false
local ch2R4X2Collected = false
local ch2R4MinusSpawned = false
local ch2R4AllySpawned = false
local ch2R4DogSwarmSpawned = false
local ch2R5MidBoss1Spawned = false
local ch2R5MidBoss2Spawned = false
local ch2R5X2RetrySpawned = false
local ch2R5BombSpawned = false
local ch2R6SniperSpawned = false
local ch2R6Div2Spawned = false
local ch2R6BombSpawned = false
local ch2R6PlusSpawned = false
local ch2R6MolotovSpawned = false
local ch2R7SniperSpawned = false
local ch2R7MinusSpawned = false
local ch2R7PlusSpawned = false
local ch2R7BombSpawned = false
local ch2R7ShieldPackSpawned = false
local ch2R8Div2Spawned = false
local ch2R8SniperSpawned = false
local ch2R8X2Spawned = false
local ch2R8X2Collected = false
local ch2R8Sniper2Spawned = false
local ch2R8MinusSpawned = false
local ch2R8X2RetrySpawned = false
local ch2R8SwarmSpawned = false
local ch2R8PlusSpawned = false
local ch2R8BombSpawned = false
local ch2R8MolotovSpawned = false
local ch2R9MidBossSpawned = false
local ch2R9SniperSpawned = false
local ch2R9MinusSpawned = false
local ch2R9PlusSpawned = false
local ch2R9BombSpawned = false
local ch2R9ShieldPackSpawned = false
local ch2R9Sniper2Spawned = false
local ch2R9MolotovSpawned = false
local ch2R10BossSpawned = false
local ch2R10SniperSpawned = false
local ch2R10HordeSpawned = false
local ch2R10LateHordeSpawned = false
local ch2R10OpeningSpawned = false
local ch2R10MidSwarmSpawned = false
local ch2R10IntroShown = false
local gatePlayArmed = false
local chapterClearArmed = false
local chapterPadDebounce = false
local killBaseline = 0
local hitPower = 1
local nextIsBossAt = Config.Boss.EveryNKills
local heartbeatConn: RBXScriptConnection?
local startPadDebounce = false
local grantBombs: () -> ()
local grantSniper: () -> ()
local grantShotgun: () -> ()
local startChapter2: () -> ()
local startChapter3: () -> ()
local lastMolotovAt = 0
local ch3R1ShotgunSpawned = false

local function setState(key: string, value: any)
	stateFolder:SetAttribute(key, value)
end

local function shiftPausedTimers(duration: number)
	matchStart += duration
	if lastSpawnAt > 0 then lastSpawnAt += duration end
	if lastSupplySpawnAt > 0 then lastSupplySpawnAt += duration end
	if lastBombSpawnAt > 0 then lastBombSpawnAt += duration end
	if lastGateSpawnAt > 0 then lastGateSpawnAt += duration end
	if lastSidePathSpawnAt > 0 then lastSidePathSpawnAt += duration end
	if introGateDueAt > 0 then introGateDueAt += duration end
	if extraX2DueAt > 0 then extraX2DueAt += duration end
	if chapter2PlusDueAt > 0 then chapter2PlusDueAt += duration end
	if chapter2X2DueAt > 0 then chapter2X2DueAt += duration end
	if lastMolotovAt > 0 then lastMolotovAt += duration end
	for _, data in playerData do
		if data.lastFire > 0 then data.lastFire += duration end
		if data.bombUntil > 0 then data.bombUntil += duration end
		if data.sniperUntil > 0 then data.sniperUntil += duration end
		if data.shotgunUntil > 0 then data.shotgunUntil += duration end
	end
	ZombieService.shiftTimers(duration)
	SupplyService.shiftTimers(duration)
	CombatService.shiftTimers(duration)
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
	local lane = Config.activeLane()
	local pad = Instance.new("Part")
	pad.Name = "ChapterPad"
	pad.Anchored = true
	pad.CanCollide = true
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(70, 160, 220)
	pad.Size = Vector3.new(12, 1.2, 12)
	pad.CFrame = CFrame.new(0, lane.CenterY + lane.Thickness * 0.5 + 0.6, lane.SpawnZ - 6)
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
		if Config.chapter() <= 1 then
			startChapter2()
		elseif Config.chapter() == 2 then
			startChapter3()
		end
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

local function chapter2HealthPerKill(): number
	if Config.chapter() ~= 2 then
		return Config.activeInfinite().HealthPerKill
	end
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	local r4 = Config.Chapter2.Round4
	local r6 = Config.Chapter2.Round6
	local r7 = Config.Chapter2.Round7
	local localRound = Config.chapterRound(wave)
	if localRound == r4.Round then
		return r4.HealthPerKill
	end
	if localRound == r6.Round then
		return r6.HealthPerKill
	end
	if localRound == r7.Round then
		return r7.HealthPerKill
	end
	local r8 = Config.Chapter2.Round8
	if localRound == r8.Round then
		return r8.HealthPerKill
	end
	local r9 = Config.Chapter2.Round9
	if localRound == r9.Round then
		return r9.HealthPerKill
	end
	local r10 = Config.Chapter2.Round10
	if localRound == r10.Round then
		return r10.HealthPerKill
	end
	return Config.activeInfinite().HealthPerKill
end

local function currentStats()
	local elapsed = math.max(0, os.clock() - matchStart)
	local z = Config.activeZombie()
	local inf = Config.activeInfinite()
	local scaledKills = math.max(0, kills - killBaseline)
	local health = z.Health + scaledKills * chapter2HealthPerKill()
	local speed = z.WalkSpeed + elapsed * inf.SpeedPerSecond
	local spawnElapsed = elapsed
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	if Config.chapter() == 2 then
		local r4 = Config.Chapter2.Round4
		if Config.chapterRound(wave) == r4.Round then
			local capWave = Config.Chapter2.Waves.From + r4.MatchSpawnRound
			spawnElapsed = math.min(elapsed, Config.elapsedAtWaveStart(capWave))
		end
	end
	local gap = math.max(
		inf.SpawnGapMin,
		inf.SpawnGapStart - spawnElapsed * 0.018
	)
	local maxAlive = inf.MaxAlive
	if SupplyService.hasRecruitedThisMatch() then
		gap *= inf.AllySpawnGapScale
		maxAlive += inf.AllyMaxAliveBonus
	end
	if Config.chapter() <= 1 and wave >= Config.Pressure.UnlockRound then
		gap *= Config.Pressure.SpawnGapScale
		maxAlive += Config.Pressure.MaxAliveBonus
	end
	if Config.chapter() <= 1 and wave >= Config.FinalBoss.Round then
		maxAlive = Config.FinalBoss.MaxAlive
		gap = Config.FinalBoss.SpawnGap
	end
	if Config.chapter() == 2 then
		local r3 = Config.Chapter2.Round3
		if Config.chapterRound(wave) == r3.Round then
			gap = math.max(inf.SpawnGapMin, r3.SpawnGap - spawnElapsed * 0.018)
			maxAlive = r3.MaxAlive
			if SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r5 = Config.Chapter2.Round5
		if Config.chapterRound(wave) == r5.Round then
			gap = r5.SpawnGap
			maxAlive = r5.MaxAlive
			if SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r6 = Config.Chapter2.Round6
		local r7 = Config.Chapter2.Round7
		local r9 = Config.Chapter2.Round9
		local localRound = Config.chapterRound(wave)
		if localRound == r6.Round then
			maxAlive = r6.MaxAlive
		elseif localRound == r7.Round then
			maxAlive = r7.MaxAlive
		elseif localRound == r9.Round then
			maxAlive = r9.MaxAlive
		end
		local r10 = Config.Chapter2.Round10
		if localRound == r10.Round then
			local t = math.max(0, (os.clock() - matchStart) - Config.elapsedAtWaveStart(wave))
			speed *= r10.ZombieSpeedScale
			if t >= r10.HordeAt then
				maxAlive = r10.MaxAlive
				gap = r10.SpawnGap
			elseif t >= r10.RampAt then
				maxAlive = r10.RampMaxAlive
				gap = r10.RampSpawnGap
			else
				maxAlive = r10.PreHordeMaxAlive
				gap = r10.PreHordeSpawnGap
			end
			if SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r8 = Config.Chapter2.Round8
		if Config.chapterRound(wave) == r8.Round then
			gap = r8.SpawnGap
			maxAlive = r8.MaxAlive
			if SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
	end
	return {
		health = health,
		speed = speed,
		gap = gap,
		maxAlive = maxAlive,
	}
end

local function waveLocalElapsed(wave: number): number
	return math.max(0, (os.clock() - matchStart) - Config.elapsedAtWaveStart(wave))
end

local function chapter2BigUnlocked(wave: number, elapsedLocal: number): boolean
	if Config.chapter() ~= 2 then
		return false
	end
	local r2 = Config.Chapter2.Round2
	local round = Config.chapterRound(wave)
	if round == 3 then
		return false -- 라운드3: 큰 좀비 없음
	end
	return round > r2.Round or (round == r2.Round and elapsedLocal >= r2.BigZombieAt)
end

local function resetChapter2Round2Events()
	ch2R1SniperSpawned = false
	ch2R1PlusSpawned = false
	ch2R1X2Spawned = false
	ch2R2MinusSpawned = false
	ch2R2BombSpawned = false
	ch2R2Plus1Spawned = false
	ch2R2SniperSpawned = false
	ch2R2Plus2Spawned = false
	ch2R3PlusSpawned = false
	ch2R3AllySpawned = false
	ch2R3Crate1Spawned = false
	ch2R3Minus1Spawned = false
	ch2R3Crate2Spawned = false
	ch2R3Minus2Spawned = false
	ch2R4CrateSpawned = false
	ch2R4X2Spawned = false
	ch2R4X2Collected = false
	ch2R4MinusSpawned = false
	ch2R4AllySpawned = false
	ch2R4DogSwarmSpawned = false
	ch2R5MidBoss1Spawned = false
	ch2R5MidBoss2Spawned = false
	ch2R5X2RetrySpawned = false
	ch2R5BombSpawned = false
	ch2R6SniperSpawned = false
	ch2R6Div2Spawned = false
	ch2R6BombSpawned = false
	ch2R6PlusSpawned = false
	ch2R6MolotovSpawned = false
	ch2R7SniperSpawned = false
	ch2R7MinusSpawned = false
	ch2R7PlusSpawned = false
	ch2R7BombSpawned = false
	ch2R7ShieldPackSpawned = false
	ch2R8Div2Spawned = false
	ch2R8SniperSpawned = false
	ch2R8X2Spawned = false
	ch2R8X2Collected = false
	ch2R8Sniper2Spawned = false
	ch2R8MinusSpawned = false
	ch2R8X2RetrySpawned = false
	ch2R8SwarmSpawned = false
	ch2R8PlusSpawned = false
	ch2R8BombSpawned = false
	ch2R8MolotovSpawned = false
	ch2R9MidBossSpawned = false
	ch2R9SniperSpawned = false
	ch2R9MinusSpawned = false
	ch2R9PlusSpawned = false
	ch2R9BombSpawned = false
	ch2R9ShieldPackSpawned = false
	ch2R9Sniper2Spawned = false
	ch2R9MolotovSpawned = false
	ch2R10BossSpawned = false
	ch2R10SniperSpawned = false
	ch2R10HordeSpawned = false
	ch2R10LateHordeSpawned = false
	ch2R10OpeningSpawned = false
	ch2R10MidSwarmSpawned = false
	ch2R10IntroShown = false
end

local function spawnOne()
	local stats = currentStats()
	local inf = Config.activeInfinite()
	local lane = Config.activeLane()
	local slots = inf.LaneSlots
	local x = slots[math.random(1, #slots)]
	local wave = (stateFolder:GetAttribute("Wave") :: number?) or 1
	local elapsed = math.max(0, os.clock() - matchStart)
	local elapsedLocal = waveLocalElapsed(wave)
	local isBoss = Config.chapter() <= 1 and wave < Config.FinalBoss.Round and kills >= nextIsBossAt
	if isBoss then
		nextIsBossAt += Config.Boss.EveryNKills
		x = slots[math.ceil(#slots / 2)]
	end

	local dogCfg = Config.activeDog()
	local isDog = Config.chapter() ~= 3
		and (not isBoss)
		and wave >= dogCfg.UnlockWave
		and math.random() < dogCfg.SpawnChance

	local shieldCfg = Config.ShieldZombie
	local shieldUnlockAt = Config.elapsedAtWaveStart(Config.Chapter2.Waves.From + shieldCfg.UnlockRound - 1)
		- shieldCfg.LeadSeconds
	local r3 = Config.Chapter2.Round3
	local r4 = Config.Chapter2.Round4
	local r6 = Config.Chapter2.Round6
	local r7 = Config.Chapter2.Round7
	local r8 = Config.Chapter2.Round8
	local r9 = Config.Chapter2.Round9
	local round = Config.chapterRound(wave)
	local shieldChance = shieldCfg.SpawnChance
	if Config.chapter() == 2 and round == r4.Round then
		local leftover = math.max(0.01, 1 - dogCfg.SpawnChance)
		shieldChance = r4.ShieldSpawnChance / leftover
	elseif Config.chapter() == 2 and round == Config.Chapter2.Round10.Round then
		local r10 = Config.Chapter2.Round10
		local leftover = math.max(0.01, 1 - dogCfg.SpawnChance)
		shieldChance = r10.ShieldSpawnChance / leftover
	elseif Config.chapter() == 2 and (round == r6.Round or round == r7.Round or round == r8.Round) then
		local chance = if round == r8.Round then r8.ShieldSpawnChance
			elseif round == r7.Round then r7.ShieldSpawnChance
			else r6.ShieldSpawnChance
		local leftover = math.max(0.01, 1 - dogCfg.SpawnChance)
		shieldChance = chance / leftover
	elseif Config.chapter() == 2 and (round > r3.Round or (round == r3.Round and elapsedLocal >= r3.ShieldBoostAt)) then
		local leftover = math.max(0.01, 1 - dogCfg.SpawnChance)
		shieldChance = r3.ShieldSpawnChance / leftover
	end
	local isShield = (not isBoss)
		and (not isDog)
		and Config.chapter() == 2
		and elapsed >= shieldUnlockAt
		and math.random() < shieldChance
	local shieldHitMin = shieldCfg.HitCountMin
	local shieldHitMax = shieldCfg.HitCountMax
	if Config.chapter() == 2 and round >= r9.Round then
		shieldHitMin = r9.ShieldHitCountMin
		shieldHitMax = r9.ShieldHitCountMax
	elseif Config.chapter() == 2 and round == r8.Round then
		local r8inner = Config.Chapter2.Round8
		if elapsedLocal >= r8inner.ShieldBoostAt then
			shieldHitMin = r8inner.ShieldHitCountMin2
			shieldHitMax = r8inner.ShieldHitCountMax2
		else
			shieldHitMin = r8inner.ShieldHitCountMin
			shieldHitMax = r8inner.ShieldHitCountMax
		end
	elseif Config.chapter() == 2 and round > r8.Round then
		shieldHitMin = r8.ShieldHitCountMin
		shieldHitMax = r8.ShieldHitCountMax
	elseif Config.chapter() == 2 and round == r6.Round then
		shieldHitMin = r6.ShieldHitCountMin
		shieldHitMax = r6.ShieldHitCountMax
	elseif Config.chapter() == 2 and round >= r3.Round then
		shieldHitMin = r3.ShieldHitCountMin
		shieldHitMax = r3.ShieldHitCountMax
	end
	local shieldHits = if isShield then math.random(shieldHitMin, shieldHitMax) else nil

	local isBig = false
	if Config.chapter() ~= 3
		and (not isBoss)
		and (not isDog)
		and (not isShield)
		and chapter2BigUnlocked(wave, elapsedLocal)
	then
		local bigChance = Config.Chapter2.BigZombie.SpawnChance
		if round == r6.Round then
			bigChance = r6.BigZombieSpawnChance
		end
		if math.random() < bigChance then
			isBoss = true
			isBig = true
		end
	end

	local scale = if isBoss then Config.Boss.SizeMultiplier elseif isDog then dogCfg.SizeScale else 1
	local y = lane.CenterY + (if isDog then 1.35 else 2.4) * scale

	local health: number
	local walkSpeed: number
	local contactDamage: number
	if isBoss then
		health = stats.health * Config.Boss.HealthMultiplier
		walkSpeed = stats.speed * Config.Boss.SpeedMultiplier
		contactDamage = Config.Boss.ContactDamage
	elseif isDog then
		health = dogCfg.Health + math.max(0, kills - killBaseline) * chapter2HealthPerKill() * 0.7
		walkSpeed = dogCfg.WalkSpeed + elapsed * dogCfg.SpeedPerSecond
		if Config.chapter() == 2 and round == Config.Chapter2.Round10.Round then
			walkSpeed *= Config.Chapter2.Round10.ZombieSpeedScale
		end
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
		isBig = isBig,
		isDog = isDog,
		isShield = isShield,
		contactDamage = contactDamage,
		scale = scale,
		hitCount = shieldHits,
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

local function spawnChapter2MidBoss(spawnX: number, hitMin: number?, hitMax: number?)
	local r5 = Config.Chapter2.Round5
	local stats = currentStats()
	local walkSpeed = stats.speed * r5.SpeedMultiplier
	local minH = math.max(1, math.floor(hitMin or r5.HitCountMin))
	local maxH = math.max(minH, math.floor(hitMax or r5.HitCountMax))
	local hits = math.random(minH, maxH)
	local zombie = spawnMegaBossAt(spawnX, hits, false, {
		scale = r5.SizeScale,
		walkSpeed = walkSpeed,
		contactDamage = r5.ContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsMidBoss", true)
	end
end

local function spawnChapter2DogSwarm(count: number)
	local stats = currentStats()
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local n = math.max(1, math.floor(count))
	for i = 1, n do
		local x = slots[((i - 1) % #slots) + 1]
		local row = math.floor((i - 1) / #slots)
		local z = lane.SpawnZ + row * 2.8
		local y = lane.CenterY + 1.35
		local zombie = ZombieService.create(Vector3.new(x, y, z), {
			health = stats.health,
			walkSpeed = Config.activeDog().WalkSpeed + (os.clock() - matchStart) * Config.activeDog().SpeedPerSecond,
			isBoss = false,
			isBig = false,
			isDog = true,
			isShield = false,
			contactDamage = Config.activeDog().ContactDamage,
			scale = Config.activeDog().SizeScale,
			hitCount = nil,
		})
		ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	end
end

local function spawnChapter2FinalBoss()
	local r10 = Config.Chapter2.Round10
	local stats = currentStats()
	local walkSpeed = stats.speed * r10.SpeedMultiplier
	local hits = math.random(r10.BossHitCountMin, r10.BossHitCountMax)
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local x = slots[math.ceil(#slots / 2)]
	local y = lane.CenterY + 2.4 * r10.SizeScale
	local zombie = ZombieService.create(Vector3.new(x, y, lane.SpawnZ), {
		health = hits,
		walkSpeed = walkSpeed,
		isBoss = true,
		isMega = true,
		isDog = false,
		contactDamage = r10.ContactDamage,
		scale = r10.SizeScale,
		hitCount = hits,
	})
	if zombie then
		zombie.model:SetAttribute("IsFinalBoss", true)
	end
	ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
end

local function spawnChapter2OpeningSwarm()
	local r10 = Config.Chapter2.Round10
	local r9 = Config.Chapter2.Round9
	local stats = currentStats()
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local dogCfg = Config.activeDog()
	local speedScale = r10.ZombieSpeedScale
	local compositions = {
		{ count = r10.OpeningShield, isShield = true, isDog = false },
		{ count = r10.OpeningNormal, isShield = false, isDog = false },
		{ count = r10.OpeningDog, isShield = false, isDog = true },
	}
	local index = 0
	for _, comp in compositions do
		for _ = 1, math.max(0, math.floor(comp.count)) do
			index += 1
			local x = slots[((index - 1) % #slots) + 1]
			local row = math.floor((index - 1) / #slots)
			local z = lane.SpawnZ + row * 2.8
			local y = lane.CenterY + (if comp.isDog then 1.35 else 2.4)
			local walkSpeed = if comp.isDog
				then (dogCfg.WalkSpeed + (os.clock() - matchStart) * dogCfg.SpeedPerSecond) * speedScale
				else stats.speed
			local zombie = ZombieService.create(Vector3.new(x, y, z), {
				health = stats.health,
				walkSpeed = walkSpeed,
				isBoss = false,
				isBig = false,
				isDog = comp.isDog,
				isShield = comp.isShield,
				contactDamage = if comp.isDog then dogCfg.ContactDamage else Config.activeZombie().ContactDamage,
				scale = if comp.isDog then dogCfg.SizeScale else 1,
				hitCount = if comp.isShield then math.random(r9.ShieldHitCountMin, r9.ShieldHitCountMax) else nil,
			})
			ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
		end
	end
end

local function spawnChapter2MidSwarm(count: number)
	local r10 = Config.Chapter2.Round10
	local stats = currentStats()
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local dogCfg = Config.activeDog()
	local n = math.max(1, math.floor(count))
	-- R1식: 개·일반 위주 (방패는 아주 적게)
	for i = 1, n do
		local x = slots[((i - 1) % #slots) + 1]
		local row = math.floor((i - 1) / #slots)
		local z = lane.SpawnZ + row * 2.6
		local roll = i % 10
		local isDog = roll <= 4 -- 50%
		local isShield = roll == 9 -- 10%
		local y = lane.CenterY + (if isDog then 1.35 else 2.4)
		local walkSpeed = if isDog
			then (dogCfg.WalkSpeed + (os.clock() - matchStart) * dogCfg.SpeedPerSecond) * r10.ZombieSpeedScale
			else stats.speed
		local zombie = ZombieService.create(Vector3.new(x, y, z), {
			health = stats.health,
			walkSpeed = walkSpeed,
			isBoss = false,
			isBig = false,
			isDog = isDog,
			isShield = isShield,
			contactDamage = if isDog then dogCfg.ContactDamage else Config.activeZombie().ContactDamage,
			scale = if isDog then dogCfg.SizeScale else 1,
			hitCount = if isShield
				then math.random(Config.Chapter2.Round9.ShieldHitCountMin, Config.Chapter2.Round9.ShieldHitCountMax)
				else nil,
		})
		ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	end
end

local function spawnChapter2FinalHorde(count: number)
	local stats = currentStats()
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local n = math.max(1, math.floor(count))
	-- 혼합 비율: 방패 30%, 일반 30%, 큰 좀비 20%, 개 20%
	for i = 1, n do
		local x = slots[((i - 1) % #slots) + 1]
		local row = math.floor((i - 1) / #slots)
		local z = lane.SpawnZ + row * 2.8
		local roll = i % 10
		local isShield = roll == 0 or roll == 1 or roll == 2  -- 30%
		local isBig = roll == 3 or roll == 4                  -- 20%
		local isDog = roll == 5 or roll == 6                  -- 20%
		-- roll 7,8,9 → 일반 30%
		local y = lane.CenterY + (if isBig then 2.4 * 1.8 elseif isDog then 1.35 else 2.4)
		local walkSpeed = if isDog
			then (Config.activeDog().WalkSpeed + (os.clock() - matchStart) * Config.activeDog().SpeedPerSecond) * Config.Chapter2.Round10.ZombieSpeedScale
			else stats.speed
		local scale = if isBig then Config.Chapter2.BigZombie.SizeScale else (if isDog then Config.activeDog().SizeScale else 1)
		local zombie = ZombieService.create(Vector3.new(x, y, z), {
			health = stats.health,
			walkSpeed = walkSpeed,
			isBoss = false,
			isBig = isBig,
			isDog = isDog,
			isShield = isShield,
			contactDamage = stats.contactDamage,
			scale = scale,
			hitCount = if isShield then math.random(Config.Chapter2.Round9.ShieldHitCountMin, Config.Chapter2.Round9.ShieldHitCountMax) else nil,
		})
		ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	end
end

local function spawnChapter2ShieldPack(count: number?, hitMin: number?, hitMax: number?)
	local r7 = Config.Chapter2.Round7
	local stats = currentStats()
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local n = math.max(1, math.floor(count or r7.ShieldPackCount))
	local minHits = math.max(1, math.floor(hitMin or r7.ShieldPackHitCountMin))
	local maxHits = math.max(minHits, math.floor(hitMax or r7.ShieldPackHitCountMax))
	for i = 1, n do
		local t = if n == 1 then 0.5 else (i - 1) / (n - 1)
		local index = 1 + math.floor(t * (#slots - 1) + 0.5)
		local x = slots[index]
		local hits = math.random(minHits, maxHits)
		local y = lane.CenterY + 2.4
		local zombie = ZombieService.create(Vector3.new(x, y, lane.SpawnZ), {
			health = stats.health,
			walkSpeed = stats.speed,
			isBoss = false,
			isBig = false,
			isDog = false,
			isShield = true,
			contactDamage = Config.activeZombie().ContactDamage,
			scale = 1,
			hitCount = hits,
		})
		ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	end
end

local function spawnChapter2SmallMidBoss()
	local r9 = Config.Chapter2.Round9
	local stats = currentStats()
	local walkSpeed = stats.speed * r9.SpeedMultiplier
	local hits = math.random(r9.MidBossHitCountMin, r9.MidBossHitCountMax)
	local zombie = spawnMegaBossAt(r9.SpawnX, hits, false, {
		scale = r9.SizeScale,
		walkSpeed = walkSpeed,
		contactDamage = r9.ContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsMidBoss", true)
	end
end

local function spawnChapter2ZombieSwarm()
	local r8 = Config.Chapter2.Round8
	local stats = currentStats()
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local count = math.max(1, math.floor(r8.SwarmCount))
	local zStep = r8.SwarmZStep
	for i = 1, count do
		local x = slots[((i - 1) % #slots) + 1]
		local row = math.floor((i - 1) / #slots)
		local z = lane.SpawnZ + row * zStep
		local roll = math.random()
		local isDog = roll < 0.28
		local isShield = (not isDog) and roll < 0.58
		local hits = if isShield
			then math.random(r8.ShieldHitCountMin, r8.ShieldHitCountMax)
			else nil
		local y = lane.CenterY + (if isDog then 1.35 else 2.4)
		local zombie = ZombieService.create(Vector3.new(x, y, z), {
			health = stats.health,
			walkSpeed = stats.speed,
			isBoss = false,
			isBig = false,
			isDog = isDog,
			isShield = isShield,
			contactDamage = Config.activeZombie().ContactDamage,
			scale = 1,
			hitCount = hits,
		})
		ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
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

local function startChapter(chapter: number)
	destroyChapterPad()
	paused = false
	Config.setChapter(chapter)
	killBaseline = kills
	CombatService.clear()
	ZombieService.clear()
	NumberGate.clear()
	SupplyService.clearCrates()
	Arena.applyChapterLook(chapter)
	setState("Chapter", chapter)
	setState("Wave", Config.chapterStartWave(chapter))
	setState("Elapsed", 0)
	setState("Announce", "")
	setState("HitPower", hitPower)
	megaBossSpawned = false
	eliteBossesSpawned = false
	finalBossSpawned = false
	chapter2PlusSpawned = false
	chapter2X2Spawned = false
	chapter2PlusDueAt = 0
	chapter2X2DueAt = 0
	resetChapter2Round2Events()
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	setState("Paused", false)
	for _, data in playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.lastFire = 0
	end
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
			paused = false
			matchStart = os.clock()
			lastSpawnAt = 0
			ch3R1ShotgunSpawned = false
			setState("Phase", "playing")
			setState("Paused", false)
			setState("Countdown", 0)
			setState("Wave", Config.chapterStartWave(chapter))
			setState("HitPower", hitPower)
		end
	end)
end

startChapter2 = function()
	startChapter(2)
end

startChapter3 = function()
	startChapter(3)
end

local function beginChapterClear()
	if chapterClearArmed or phase ~= "playing" or Config.chapter() >= 3 then
		return
	end
	chapterClearArmed = true
	phase = "chapterClear"
	setState("Phase", "chapterClear")
	setState("Announce", `{Config.chapter()}챕터 클리어`)
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
	paused = false
	matchStart = os.clock()
	lastSpawnAt = 0
	killBaseline = 0
	chapterClearArmed = false
	Config.setChapter(1)
	Arena.applyChapterLook(1)
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
	chapter2PlusSpawned = false
	chapter2X2Spawned = false
	chapter2PlusDueAt = 0
	chapter2X2DueAt = 0
	ch3R1ShotgunSpawned = false
	resetChapter2Round2Events()
	gatePlayArmed = false
	lastGateSpawnAt = 0
	hitPower = 1
	setState("Phase", "playing")
	setState("Paused", false)
	setState("Kills", kills)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	setState("HitPower", hitPower)
	for _, data in playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.lastFire = 0
	end
end

local function jumpToRound(localRound: number)
	local maxRound = if Config.chapter() >= 3 then 15 else 10
	localRound = math.clamp(math.floor(localRound), 1, maxRound)
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
		-- 챕터2 카운트다운에서 beginPlay()를 호출하면 챕터1로 리셋됨
		phase = "playing"
		setState("Phase", "playing")
		setState("Countdown", 0)
		if Config.chapter() < 2 then
			beginPlay()
		else
			matchStart = os.clock()
			lastSpawnAt = 0
			setState("Wave", Config.chapterStartWave())
			setState("Elapsed", 0)
			setState("HitPower", hitPower)
		end
	end
	if phase ~= "playing" then
		return
	end

	local wave = localRound
	if Config.chapter() >= 2 then
		wave = Config.chapterStartWave() + localRound - 1
	end

	hitPower = math.max(1, math.floor(keptHitPower))
	setState("HitPower", hitPower)
	matchStart = os.clock() - Config.elapsedAtWaveStart(wave)
	setState("Elapsed", math.floor(Config.elapsedAtWaveStart(wave)))
	setState("Wave", wave)

	NumberGate.clear()
	introGateSpawned = false
	introGateDueAt = 0
	extraX2Spawned = false
	extraX2DueAt = 0
	plusGateSpawned = false
	chapter2PlusSpawned = false
	chapter2X2Spawned = false
	chapter2PlusDueAt = 0
	chapter2X2DueAt = 0
	resetChapter2Round2Events()
	gatePlayArmed = false
	setState("MolotovLeft", 0)
	ch3R1ShotgunSpawned = false
	applyRoundFeatures(wave)
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
	paused = false
	kills = 0
	killBaseline = 0
	chapterClearArmed = false
	Config.setChapter(1)
	Arena.applyChapterLook(1)
	destroyChapterPad()
	CombatService.clear()
	ZombieService.clear()
	SupplyService.clear()
	NumberGate.clear()
	setState("Phase", "lobby")
	setState("Paused", false)
	setState("Kills", 0)
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("Chapter", 1)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	setState("Paused", false)
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
	chapter2PlusSpawned = false
	chapter2X2Spawned = false
	chapter2PlusDueAt = 0
	chapter2X2DueAt = 0
	ch3R1ShotgunSpawned = false
	resetChapter2Round2Events()
	gatePlayArmed = false
	hitPower = 1
	for _, data in playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
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
	chapter2PlusSpawned = false
	chapter2X2Spawned = false
	chapter2PlusDueAt = 0
	chapter2X2DueAt = 0
	ch3R1ShotgunSpawned = false
	resetChapter2Round2Events()
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
		sniperUntil = 0,
		hadSniper = false,
		shotgunUntil = 0,
		hadShotgun = false,
	}

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

local function restoreGun(data: PlayerData)
	if (data.hadBomb or data.hadSniper or data.hadShotgun) and data.character then
		Gun.attach(data.character)
	end
	data.hadBomb = false
	data.bombUntil = 0
	data.hadSniper = false
	data.sniperUntil = 0
	data.hadShotgun = false
	data.shotgunUntil = 0
	data.lastFire = 0
end

grantBombs = function()
	local untilTime = os.clock() + Config.BombCrate.Duration
	for _, data in playerData do
		data.bombUntil = untilTime
		data.hadBomb = true
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.lastFire = 0
		if data.character then
			Gun.attachBomb(data.character)
		end
	end
	setState("BombLeft", Config.BombCrate.Duration)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
end

grantSniper = function()
	local untilTime = os.clock() + Config.SniperCrate.Duration
	for _, data in playerData do
		data.sniperUntil = untilTime
		data.hadSniper = true
		data.bombUntil = 0
		data.hadBomb = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.lastFire = 0
		if data.character then
			Gun.attachSniper(data.character)
		end
	end
	setState("SniperLeft", Config.SniperCrate.Duration)
	setState("BombLeft", 0)
	setState("ShotgunLeft", 0)
end

grantShotgun = function()
	local untilTime = os.clock() + Config.Shotgun.Duration
	for _, data in playerData do
		data.shotgunUntil = untilTime
		data.hadShotgun = true
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.lastFire = 0
		if data.character then
			Gun.attachShotgun(data.character)
		end
	end
	setState("ShotgunLeft", Config.Shotgun.Duration)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
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

		local usingSniper = data.hadSniper and now < data.sniperUntil
		local usingBomb = data.hadBomb and now < data.bombUntil
		local usingShotgun = data.hadShotgun and now < data.shotgunUntil
		local interval = if usingSniper
			then Config.SniperCrate.FireInterval
			elseif usingBomb then Config.BombCrate.ThrowInterval
			elseif usingShotgun then Config.Shotgun.FireInterval
			else Config.Combat.FireInterval
		if now - data.lastFire < interval then
			continue
		end

		data.lastFire = now
		local muzzle = Gun.getMuzzlePosition(character)
			or (root.CFrame * CFrame.new(Config.Combat.MuzzleOffset)).Position
		local origin = Vector3.new(root.Position.X, muzzle.Y, muzzle.Z)
		if usingSniper then
			CombatService.fireSniper(origin, currentUnitDamage(), hitPower)
		elseif usingBomb then
			CombatService.throwBomb(origin, hitPower)
		elseif usingShotgun then
			CombatService.fireShotgun(origin, currentUnitDamage(), hitPower)
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
	setState("Paused", false)
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("Chapter", 1)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
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
	SupplyService.onSniperPicked(function()
		if phase == "playing" then
			grantSniper()
		end
	end)
	SupplyService.onShotgunPicked(function()
		if phase == "playing" then
			grantShotgun()
		end
	end)
	SupplyService.onMolotovPicked(function(count: number)
		if phase == "playing" then
			local left = (stateFolder:GetAttribute("MolotovLeft") :: number?) or 0
			setState("MolotovLeft", left + count)
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
			local waveNow = (stateFolder:GetAttribute("Wave") :: number?) or 1
			if Config.chapter() == 2 then
				local localRound = Config.chapterRound(waveNow)
				if localRound == Config.Chapter2.Round4.Round then
					ch2R4X2Collected = true
				elseif localRound == Config.Chapter2.Round8.Round then
					ch2R8X2Collected = true
				end
			end
		elseif id == "div2" or kind.Op == "div" then
			hitPower = math.max(1, math.floor(hitPower / math.max(1, value)))
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

	remotes.TogglePause.OnServerEvent:Connect(function()
		if phase ~= "playing" then
			return
		end
		paused = not paused
		setState("Paused", paused)
	end)

	remotes.UseMolotov.OnServerEvent:Connect(function(_player: Player)
		if phase ~= "playing" or paused then
			return
		end
		local left = (stateFolder:GetAttribute("MolotovLeft") :: number?) or 0
		if left <= 0 then
			return
		end
		local now = os.clock()
		if now - lastMolotovAt < 0.35 then
			return
		end
		lastMolotovAt = now
		setState("MolotovLeft", left - 1)
		local origins = SupplyService.allyThrowOrigins()
		local playerThrowing = #origins == 0
		if playerThrowing then
			for _, data in playerData do
				local character = data.character
				if not character then
					continue
				end
				local muzzle = Gun.getMuzzlePosition(character)
				local root = character:FindFirstChild("HumanoidRootPart")
				if muzzle then
					table.insert(origins, muzzle)
				elseif root and root:IsA("BasePart") then
					table.insert(origins, root.Position + Vector3.new(0, 1.2, 1.4))
				end
				break
			end
		end
		if origins[1] then
			if playerThrowing and remotes.MolotovThrowAnim then
				remotes.MolotovThrowAnim:FireAllClients()
			end
			CombatService.throwMolotov(origins[1])
		end
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
			if (value :: number) >= 3 then
				startChapter3()
			elseif (value :: number) >= 2 then
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

		if phase == "playing" and paused then
			shiftPausedTimers(dt)
			return
		end

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
			if (Config.chapter() <= 1
					and wave >= Config.FinalBoss.Round
					and finalBossSpawned
					and #ZombieService.getAlive() == 0)
				or (Config.chapter() == 2
					and Config.chapterRound(wave) == Config.Chapter2.Round10.Round
					and ch2R10BossSpawned
					and #ZombieService.getAlive() == 0)
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
			local holdSpawns = (Config.chapter() <= 1
					and waveNow >= Config.FinalBoss.Round
					and finalBossSpawned
					and (function()
						for _, record in ZombieService.getAlive() do
							if record.model:GetAttribute("IsFinalBoss") == true then
								return false
							end
						end
						return true
					end)())
				or (Config.chapter() == 2
					and Config.chapterRound(waveNow) == Config.Chapter2.Round10.Round
					and ch2R10BossSpawned
					and (function()
						for _, record in ZombieService.getAlive() do
							if record.model:GetAttribute("IsFinalBoss") == true then
								return false
							end
						end
						return true
					end)())
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

			if Config.chapter() == 2 then
				local sniperCfg = Config.SniperCrate
				if chapter2PlusDueAt > 0 and not chapter2PlusSpawned and now >= chapter2PlusDueAt then
					chapter2PlusSpawned = true
					NumberGate.createPlus(sniperCfg.PlusHitCountMin, sniperCfg.PlusHitCountMax, true)
				end
				if chapter2X2DueAt > 0 and not chapter2X2Spawned and now >= chapter2X2DueAt then
					chapter2X2Spawned = true
					NumberGate.createX2(sniperCfg.X2HitCountMin, sniperCfg.X2HitCountMax, true)
				end

				local r1 = Config.Chapter2.Round1
				if Config.chapterRound(wave) == r1.Round then
					local t = waveLocalElapsed(wave)
					if t >= r1.SniperAt and not ch2R1SniperSpawned then
						ch2R1SniperSpawned = true
						SupplyService.createSniper(true)
					end
					if t >= r1.PlusAt and not ch2R1PlusSpawned then
						ch2R1PlusSpawned = true
						NumberGate.createPlus(r1.PlusHitCountMin, r1.PlusHitCountMax, true)
					end
					if t >= r1.X2At and not ch2R1X2Spawned then
						ch2R1X2Spawned = true
						NumberGate.createX2(r1.X2HitCountMin, r1.X2HitCountMax, true)
					end
				end

				local r2 = Config.Chapter2.Round2
				if Config.chapterRound(wave) == r2.Round then
					local t = waveLocalElapsed(wave)
					if t >= r2.MinusAt and not ch2R2MinusSpawned then
						ch2R2MinusSpawned = true
						NumberGate.createMinus(r2.MinusHitCountMin, r2.MinusHitCountMax, true)
					end
					if t >= r2.BombAt and not ch2R2BombSpawned then
						ch2R2BombSpawned = true
						SupplyService.createBomb(true)
					end
					if t >= r2.PlusAt and not ch2R2Plus1Spawned then
						ch2R2Plus1Spawned = true
						NumberGate.createPlus(r2.PlusHitCountMin, r2.PlusHitCountMax, true)
					end
				if t >= r2.SniperAt and not ch2R2SniperSpawned then
					ch2R2SniperSpawned = true
					SupplyService.createSniper(true, r2.SniperHitCountMin, r2.SniperHitCountMax)
				end
					if t >= r2.PlusAgainAt and not ch2R2Plus2Spawned then
						ch2R2Plus2Spawned = true
						NumberGate.createPlus(r2.PlusHitCountMin, r2.PlusHitCountMax, true)
					end
				end

				local r3 = Config.Chapter2.Round3
				if Config.chapterRound(wave) == r3.Round then
					local t = waveLocalElapsed(wave)
					if t >= r3.PlusAt and not ch2R3PlusSpawned then
						ch2R3PlusSpawned = true
						NumberGate.createPlus(r3.PlusHitCountMin, r3.PlusHitCountMax, true)
					end
					if t >= r3.AllyAt and not ch2R3AllySpawned then
						ch2R3AllySpawned = true
						SupplyService.create(true, r3.AllyHitCountMin, r3.AllyHitCountMax)
					end
					if t >= r3.CrateAt and not ch2R3Crate1Spawned then
						ch2R3Crate1Spawned = true
						SupplyService.createBomb(true)
					end
					if t >= r3.MinusAt and not ch2R3Minus1Spawned then
						ch2R3Minus1Spawned = true
						NumberGate.createMinus(r3.MinusHitCountMin, r3.MinusHitCountMax, true)
					end
				if t >= r3.CrateAgainAt and not ch2R3Crate2Spawned then
					ch2R3Crate2Spawned = true
					SupplyService.createSniper(true, r3.SniperHitCountMin, r3.SniperHitCountMax)
				end
					if t >= r3.MinusAgainAt and not ch2R3Minus2Spawned then
						ch2R3Minus2Spawned = true
						NumberGate.createMinus(r3.MinusHitCountMin, r3.MinusHitCountMax, true)
					end
				end

				local r4 = Config.Chapter2.Round4
				if Config.chapterRound(wave) == r4.Round then
					local t = waveLocalElapsed(wave)
					if t >= r4.AllyAt and not ch2R4AllySpawned then
						ch2R4AllySpawned = true
						if not SupplyService.hasRecruitedThisMatch() then
							SupplyService.create(true, r4.AllyHitCountMin, r4.AllyHitCountMax)
						end
					end
				if t >= r4.CrateAt and not ch2R4CrateSpawned then
					ch2R4CrateSpawned = true
					if math.random() < 0.5 then
						SupplyService.createBomb(true, r4.CrateHitCountMin, r4.CrateHitCountMax)
					else
						SupplyService.createSniper(true, r4.CrateHitCountMin, r4.CrateHitCountMax)
					end
				end
					if t >= r4.DogSwarmAt and not ch2R4DogSwarmSpawned then
						ch2R4DogSwarmSpawned = true
						spawnChapter2DogSwarm(r4.DogSwarmCount)
					end
					if t >= r4.X2At and not ch2R4X2Spawned then
						ch2R4X2Spawned = true
						NumberGate.createX2(r4.X2HitCountMin, r4.X2HitCountMax, true)
					end
					if t >= r4.MinusAt and not ch2R4MinusSpawned then
						ch2R4MinusSpawned = true
						NumberGate.createMinus(r4.MinusHitCountMin, r4.MinusHitCountMax, true)
					end
				end

				local r5 = Config.Chapter2.Round5
				if Config.chapterRound(wave) == r5.Round then
					local t = waveLocalElapsed(wave)
					if t >= r5.X2RetryAt and not ch2R5X2RetrySpawned and not ch2R4X2Collected then
						ch2R5X2RetrySpawned = true
						NumberGate.createX2(r5.X2HitCountMin, r5.X2HitCountMax, true)
					end
					if t >= r5.MidBossAt and not ch2R5MidBoss1Spawned then
						ch2R5MidBoss1Spawned = true
						spawnChapter2MidBoss(r5.FirstSpawnX)
					end
				if t >= r5.MidBossAgainAt and not ch2R5MidBoss2Spawned then
					ch2R5MidBoss2Spawned = true
					spawnChapter2MidBoss(r5.SecondSpawnX, r5.HitCountMin2, r5.HitCountMax2)
				end
					if t >= r5.BombAt and not ch2R5BombSpawned then
						ch2R5BombSpawned = true
						SupplyService.createBomb(true, r5.BombHitCountMin, r5.BombHitCountMax)
					end
				end

				local r6 = Config.Chapter2.Round6
				if Config.chapterRound(wave) == r6.Round then
					local t = waveLocalElapsed(wave)
				if t >= r6.SniperAt and not ch2R6SniperSpawned then
					ch2R6SniperSpawned = true
					SupplyService.createSniper(true, r6.SniperHitCountMin, r6.SniperHitCountMax)
				end
					if t >= r6.Div2At and not ch2R6Div2Spawned then
						ch2R6Div2Spawned = true
						NumberGate.createDiv2(
							r6.Div2HitCountMin,
							r6.Div2HitCountMax,
							true,
							r6.Div2WalkSpeedScale
						)
					end
				if t >= r6.BombAt and not ch2R6BombSpawned then
					ch2R6BombSpawned = true
					SupplyService.createBomb(true, r6.BombHitCountMin, r6.BombHitCountMax)
				end
					if t >= r6.PlusAt and not ch2R6PlusSpawned then
						ch2R6PlusSpawned = true
						NumberGate.createPlus(r6.PlusHitCountMin, r6.PlusHitCountMax, true)
					end
					if t >= r6.MolotovAt and not ch2R6MolotovSpawned then
						ch2R6MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							Config.Molotov.CrateHitCountMin,
							Config.Molotov.CrateHitCountMax,
							Config.Molotov.Count
						)
					end
				end

				local r7 = Config.Chapter2.Round7
				if Config.chapterRound(wave) == r7.Round then
					local t = waveLocalElapsed(wave)
				if t >= r7.SniperAt and not ch2R7SniperSpawned then
					ch2R7SniperSpawned = true
					SupplyService.createSniper(true, r7.SniperHitCountMin, r7.SniperHitCountMax)
				end
					if t >= r7.PlusAt and not ch2R7PlusSpawned then
						ch2R7PlusSpawned = true
						NumberGate.createPlus(r7.PlusHitCountMin, r7.PlusHitCountMax, true)
					end
				if t >= r7.BombAt and not ch2R7BombSpawned then
					ch2R7BombSpawned = true
					SupplyService.createBomb(true, r7.BombHitCountMin, r7.BombHitCountMax)
				end
					if t >= r7.ShieldPackAt and not ch2R7ShieldPackSpawned then
						ch2R7ShieldPackSpawned = true
						spawnChapter2ShieldPack()
					end
				end

				local r8 = Config.Chapter2.Round8
				if Config.chapterRound(wave) == r8.Round then
					local t = waveLocalElapsed(wave)
					if t >= r8.Div2At and not ch2R8Div2Spawned then
						ch2R8Div2Spawned = true
						NumberGate.createDiv2(
							r8.Div2HitCountMin,
							r8.Div2HitCountMax,
							true,
							r8.Div2WalkSpeedScale
						)
					end
				if t >= r8.SniperAt and not ch2R8SniperSpawned then
					ch2R8SniperSpawned = true
					SupplyService.createSniper(true, r8.SniperHitCountMin, r8.SniperHitCountMax)
				end
					if t >= r8.X2At and not ch2R8X2Spawned then
						ch2R8X2Spawned = true
						NumberGate.createX2(r8.X2HitCountMin, r8.X2HitCountMax, true)
					end
				if t >= r8.SniperAgainAt and not ch2R8Sniper2Spawned then
					ch2R8Sniper2Spawned = true
					SupplyService.createSniper(true, r8.SniperHitCountMin, r8.SniperHitCountMax)
				end
					if t >= r8.MinusAt and not ch2R8MinusSpawned then
						ch2R8MinusSpawned = true
						NumberGate.createMinus(r8.MinusHitCountMin, r8.MinusHitCountMax, true)
					end
					if t >= r8.X2RetryAt and not ch2R8X2RetrySpawned and not ch2R8X2Collected then
						ch2R8X2RetrySpawned = true
						NumberGate.createX2(r8.X2HitCountMin, r8.X2HitCountMax, true)
					end
					if t >= r8.SwarmAt and not ch2R8SwarmSpawned then
						ch2R8SwarmSpawned = true
						spawnChapter2ZombieSwarm()
					end
					if t >= r8.PlusAt and not ch2R8PlusSpawned then
						ch2R8PlusSpawned = true
						NumberGate.createPlus(r8.PlusHitCountMin, r8.PlusHitCountMax, true)
					end
				if t >= r8.BombAt and not ch2R8BombSpawned then
					ch2R8BombSpawned = true
					SupplyService.createBomb(true, r8.BombHitCountMin, r8.BombHitCountMax)
				end
					if t >= r8.MolotovAt and not ch2R8MolotovSpawned then
						ch2R8MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							Config.Molotov.CrateHitCountMin,
							Config.Molotov.CrateHitCountMax,
							r8.MolotovGrant
						)
					end
				end

				local r9 = Config.Chapter2.Round9
				if Config.chapterRound(wave) == r9.Round then
					local t = waveLocalElapsed(wave)
					if t >= r9.MidBossAt and not ch2R9MidBossSpawned then
						ch2R9MidBossSpawned = true
						spawnChapter2SmallMidBoss()
					end
					if t >= r9.SniperAt and not ch2R9SniperSpawned then
						ch2R9SniperSpawned = true
						SupplyService.createSniper(true, r9.SniperHitCountMin, r9.SniperHitCountMax)
					end
					if t >= r9.MinusAt and not ch2R9MinusSpawned then
						ch2R9MinusSpawned = true
						NumberGate.createMinus(r9.MinusHitCountMin, r9.MinusHitCountMax, true)
					end
					if t >= r9.PlusAt and not ch2R9PlusSpawned then
						ch2R9PlusSpawned = true
						NumberGate.createPlus(r9.PlusHitCountMin, r9.PlusHitCountMax, true)
					end
					if t >= r9.BombAt and not ch2R9BombSpawned then
						ch2R9BombSpawned = true
						SupplyService.createBomb(true, r9.BombHitCountMin, r9.BombHitCountMax)
					end
					if t >= r9.ShieldPackAt and not ch2R9ShieldPackSpawned then
						ch2R9ShieldPackSpawned = true
						spawnChapter2ShieldPack(r9.ShieldPackCount, r9.ShieldHitCountMin, r9.ShieldHitCountMax)
					end
				if t >= r9.SniperAgainAt and not ch2R9Sniper2Spawned then
					ch2R9Sniper2Spawned = true
					SupplyService.createSniper(true, r9.SniperHitCountMin, r9.SniperHitCountMax)
				end
			end

			local r10 = Config.Chapter2.Round10
			if Config.chapterRound(wave) == r10.Round then
				local t = waveLocalElapsed(wave)
				if not ch2R10IntroShown then
					ch2R10IntroShown = true
					setState("Announce", r10.IntroText)
					task.delay(r10.IntroDuration, function()
						if (stateFolder:GetAttribute("Announce") or "") == r10.IntroText then
							setState("Announce", "")
						end
					end)
				end
				if t >= r10.OpeningSwarmAt and not ch2R10OpeningSpawned then
					ch2R10OpeningSpawned = true
					spawnChapter2OpeningSwarm()
				end
				if t >= r10.BossAt and not ch2R10BossSpawned then
					ch2R10BossSpawned = true
					spawnChapter2FinalBoss()
				end
				if t >= r10.MidSwarmAt and not ch2R10MidSwarmSpawned then
					ch2R10MidSwarmSpawned = true
					spawnChapter2MidSwarm(r10.MidSwarmCount)
				end
				if t >= r10.SniperAt and not ch2R10SniperSpawned then
					ch2R10SniperSpawned = true
					SupplyService.createSniper(true, r10.SniperHitCountMin, r10.SniperHitCountMax)
				end
				if t >= r10.HordeAt and not ch2R10HordeSpawned then
					ch2R10HordeSpawned = true
					spawnChapter2FinalHorde(r10.HordeCount)
				end
				if t >= r10.LateHordeAt and not ch2R10LateHordeSpawned then
					ch2R10LateHordeSpawned = true
					spawnChapter2FinalHorde(r10.LateHordeCount)
				end
			end
		end

			if Config.chapter() == 3 then
				local r1 = Config.Chapter3.Round1
				if Config.chapterRound(wave) == r1.Round then
					local t = waveLocalElapsed(wave)
					if t >= r1.ShotgunAt and not ch3R1ShotgunSpawned then
						ch3R1ShotgunSpawned = true
						SupplyService.createShotgun(true, r1.ShotgunHitCountMin, r1.ShotgunHitCountMax)
					end
				end
			end

			local bombLeft = 0
			local sniperLeft = 0
			local shotgunLeft = 0
			for _, data in playerData do
				if data.hadBomb then
					if now >= data.bombUntil then
						restoreGun(data)
					else
						bombLeft = math.max(bombLeft, math.ceil(data.bombUntil - now))
					end
				end
				if data.hadSniper then
					if now >= data.sniperUntil then
						restoreGun(data)
					else
						sniperLeft = math.max(sniperLeft, math.ceil(data.sniperUntil - now))
					end
				end
				if data.hadShotgun then
					if now >= data.shotgunUntil then
						restoreGun(data)
					else
						shotgunLeft = math.max(shotgunLeft, math.ceil(data.shotgunUntil - now))
					end
				end
			end
			if (stateFolder:GetAttribute("BombLeft") or 0) ~= bombLeft then
				setState("BombLeft", bombLeft)
			end
			if (stateFolder:GetAttribute("SniperLeft") or 0) ~= sniperLeft then
				setState("SniperLeft", sniperLeft)
			end
			if (stateFolder:GetAttribute("ShotgunLeft") or 0) ~= shotgunLeft then
				setState("ShotgunLeft", shotgunLeft)
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
