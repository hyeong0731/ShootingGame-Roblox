local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Arena = require(script.Parent.Parent.Arena)
local ZombieService = require(script.Parent.Parent.ZombieService)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local BarricadeService = require(script.Parent.Parent.BarricadeService)
local Gun = require(script.Parent.Parent.Gun)
local Context = require(script.Parent.Context)
local Api = require(script.Parent.Api)
local StateSync = require(script.Parent.StateSync)
local Character = require(script.Parent.Character)
local Debug = require(script.Parent.Debug)
local EventReset = require(script.Parent.EventReset)

local ctx = Context
local setState = StateSync.setState
local isLanePhase = Character.isLanePhase
local setHeroCollision = Character.setHeroCollision
local teleportToLobby = Character.teleportToLobby
local teleportToLane = Character.teleportToLane
local applyWalkCharacter = Character.applyWalkCharacter
local spawnChapterPad = Debug.spawnChapterPad
local destroyChapterPad = Debug.destroyChapterPad

local Lifecycle = {}

local function startChapter(chapter: number)
	destroyChapterPad()
	ctx.paused = false
	Config.setChapter(chapter)
	ctx.killBaseline = ctx.kills
	CombatService.clear()
	SpikeTrap.clear()
	BarricadeService.clear()
	ZombieService.clear()
	NumberGate.clear()
	SupplyService.clearCrates()
	Arena.applyChapterLook(chapter)
	setState("Chapter", chapter)
	setState("Wave", Config.chapterStartWave(chapter))
	setState("Elapsed", 0)
	setState("Announce", "")
	setState("HitPower", ctx.hitPower)
	ctx.megaBossSpawned = false
	ctx.eliteBossesSpawned = false
	ctx.finalBossSpawned = false
	ctx.chapter2PlusSpawned = false
	ctx.chapter2X2Spawned = false
	ctx.chapter2PlusDueAt = 0
	ctx.chapter2X2DueAt = 0
	EventReset.resetChapter2Round2Events()
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	setState("FlashbangLeft", 0)
	setState("BarricadeLeft", 0)
	setState("Paused", false)
	for _, data in ctx.playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.fireRateMult = 1
		data.lastFire = 0
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLane(player.Character)
		end
	end
	ctx.phase = "countdown"
	setState("Phase", "countdown")
	task.spawn(function()
		for i = Config.Waves.Countdown, 1, -1 do
			if ctx.phase ~= "countdown" then
				return
			end
			setState("Countdown", i)
			task.wait(1)
		end
		if ctx.phase == "countdown" then
			ctx.phase = "playing"
			ctx.paused = false
			ctx.matchStart = os.clock()
			ctx.lastSpawnAt = 0
			EventReset.resetChapter3Events(setState)
			setState("Phase", "playing")
			setState("Paused", false)
			setState("Countdown", 0)
			setState("Wave", Config.chapterStartWave(chapter))
			setState("HitPower", ctx.hitPower)
		end
	end)
end

Api.startChapter2 = function()
	startChapter(2)
end

Api.startChapter3 = function()
	startChapter(3)
end

function Lifecycle.beginChapterClear()
	if ctx.chapterClearArmed or ctx.phase ~= "playing" or Config.chapter() >= 3 then
		return
	end
	ctx.chapterClearArmed = true
	ctx.phase = "chapterClear"
	setState("Phase", "chapterClear")
	setState("Announce", `{Config.chapter()}챕터 클리어`)
	CombatService.clear()
	SpikeTrap.clear()
	BarricadeService.clear()
	NumberGate.clear()
	SupplyService.clearCrates()
	spawnChapterPad()
	for _, data in ctx.playerData do
		if data.character then
			applyWalkCharacter(data.character)
		end
	end
end

function Lifecycle.beginPlay()
	ctx.phase = "playing"
	ctx.paused = false
	ctx.matchStart = os.clock()
	ctx.lastSpawnAt = 0
	ctx.killBaseline = 0
	ctx.chapterClearArmed = false
	Config.setChapter(1)
	Arena.applyChapterLook(1)
	destroyChapterPad()
	setState("Chapter", 1)
	-- First crate at FirstSpawnDelay, then every SpawnInterval after that.
	ctx.lastSupplySpawnAt = 0
	ctx.lastBombSpawnAt = 0
	ctx.lastSidePathSpawnAt = 0
	ctx.supplyRoundArmed = false
	ctx.bombRoundArmed = false
	ctx.introGateSpawned = false
	ctx.introGateDueAt = 0
	ctx.extraX2Spawned = false
	ctx.extraX2DueAt = 0
	ctx.plusGateSpawned = false
	ctx.chapter2PlusSpawned = false
	ctx.chapter2X2Spawned = false
	ctx.chapter2PlusDueAt = 0
	ctx.chapter2X2DueAt = 0
	EventReset.resetChapter3Events(setState)
	EventReset.resetChapter2Round2Events()
	ctx.gatePlayArmed = false
	ctx.lastGateSpawnAt = 0
	ctx.hitPower = 1
	setState("Phase", "playing")
	setState("Paused", false)
	setState("Kills", ctx.kills)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	setState("FlashbangLeft", 0)
	setState("BarricadeLeft", 0)
	setState("HitPower", ctx.hitPower)
	for _, data in ctx.playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.fireRateMult = 1
		data.lastFire = 0
	end
end

function Lifecycle.startCountdown()
	ctx.phase = "countdown"
	setState("Phase", "countdown")
	setState("Elapsed", 0)
	task.spawn(function()
		for i = Config.Waves.Countdown, 1, -1 do
			if ctx.phase ~= "countdown" then
				return
			end
			setState("Countdown", i)
			task.wait(1)
		end
		if ctx.phase == "countdown" then
			setState("Countdown", 0)
			Lifecycle.beginPlay()
		end
	end)
end

function Lifecycle.returnToLobby()
	ctx.phase = "lobby"
	ctx.paused = false
	ctx.kills = 0
	ctx.killBaseline = 0
	ctx.chapterClearArmed = false
	Config.setChapter(1)
	Arena.applyChapterLook(1)
	destroyChapterPad()
	CombatService.clear()
	SpikeTrap.clear()
	BarricadeService.clear()
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
	setState("FlashbangLeft", 0)
	setState("BarricadeLeft", 0)
	setState("Paused", false)
	setState("HitPower", 1)
	setState("Announce", "")
	ctx.supplyRoundArmed = false
	ctx.bombRoundArmed = false
	ctx.megaBossSpawned = false
	ctx.eliteBossesSpawned = false
	ctx.finalBossSpawned = false
	ctx.introGateSpawned = false
	ctx.introGateDueAt = 0
	ctx.extraX2Spawned = false
	ctx.extraX2DueAt = 0
	ctx.plusGateSpawned = false
	ctx.chapter2PlusSpawned = false
	ctx.chapter2X2Spawned = false
	ctx.chapter2PlusDueAt = 0
	ctx.chapter2X2DueAt = 0
	EventReset.resetChapter3Events(setState)
	EventReset.resetChapter2Round2Events()
	ctx.gatePlayArmed = false
	ctx.hitPower = 1
	for _, data in ctx.playerData do
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.fireRateMult = 1
	end

	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLobby(player.Character)
		end
	end
end

function Lifecycle.startMatch()
	if isLanePhase() then
		return
	end

	ctx.kills = 0
	ctx.nextIsBossAt = Config.Boss.EveryNKills
	CombatService.clear()
	SpikeTrap.clear()
	BarricadeService.clear()
	ZombieService.clear()
	SupplyService.clear()
	NumberGate.clear()
	setState("Kills", 0)
	setState("HitPower", 1)
	ctx.hitPower = 1
	ctx.megaBossSpawned = false
	ctx.eliteBossesSpawned = false
	ctx.finalBossSpawned = false
	ctx.introGateSpawned = false
	ctx.introGateDueAt = 0
	ctx.extraX2Spawned = false
	ctx.extraX2DueAt = 0
	ctx.plusGateSpawned = false
	ctx.chapter2PlusSpawned = false
	ctx.chapter2X2Spawned = false
	ctx.chapter2PlusDueAt = 0
	ctx.chapter2X2DueAt = 0
	EventReset.resetChapter3Events(setState)
	EventReset.resetChapter2Round2Events()
	ctx.gatePlayArmed = false
	ctx.supplyRoundArmed = false
	ctx.bombRoundArmed = false

	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLane(player.Character)
		end
	end

	Lifecycle.startCountdown()
end

function Lifecycle.onPlayerDied(_player: Player)
	if ctx.phase == "gameOver" or ctx.phase == "lobby" then
		return
	end
	ctx.phase = "gameOver"
	setState("Phase", "gameOver")
	CombatService.clear()
	SpikeTrap.clear()
	BarricadeService.clear()
	ZombieService.clear()
	SupplyService.clear()

	task.delay(2.2, function()
		if ctx.phase == "gameOver" then
			Lifecycle.returnToLobby()
		end
	end)
end

function Lifecycle.setupCharacter(player: Player, character: Model)
	local data = ctx.playerData[player]
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
	elseif ctx.phase == "chapterClear" then
		applyWalkCharacter(character)
	else
		teleportToLobby(character)
	end

	humanoid.Died:Connect(function()
		Lifecycle.onPlayerDied(player)
	end)
end

function Lifecycle.setupPlayer(player: Player)
	ctx.playerData[player] = {
		strafe = 0,
		character = nil,
		lastFire = 0,
		bombUntil = 0,
		hadBomb = false,
		sniperUntil = 0,
		hadSniper = false,
		shotgunUntil = 0,
		hadShotgun = false,
		fireRateMult = 1,
	}

	player.CharacterAdded:Connect(function(character)
		Lifecycle.setupCharacter(player, character)
	end)
	if player.Character then
		Lifecycle.setupCharacter(player, player.Character)
	end
end

function Lifecycle.bindStartPad()
	task.spawn(function()
		local arena = Workspace:WaitForChild("Arena", 30)
		if not arena then
			warn("[GameService] Arena missing — StartPad not bound")
			return
		end
		local pad = arena:WaitForChild("StartPad", 15)
		if not pad or not pad:IsA("BasePart") then
			warn("[GameService] StartPad missing — lobby start disabled")
			return
		end

		pad.Touched:Connect(function(hit)
			if ctx.startPadDebounce or ctx.phase ~= "lobby" then
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

			ctx.startPadDebounce = true
			Lifecycle.startMatch()
			task.delay(1.5, function()
				ctx.startPadDebounce = false
			end)
		end)
	end)
end

Api.beginPlay = Lifecycle.beginPlay

return Lifecycle
