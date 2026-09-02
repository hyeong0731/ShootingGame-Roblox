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
local Context = require(script.Parent.Context)
local Api = require(script.Parent.Api)
local StateSync = require(script.Parent.StateSync)
local Character = require(script.Parent.Character)
local Gates = require(script.Parent.Gates)
local EventReset = require(script.Parent.EventReset)

local ctx = Context
local setState = StateSync.setState
local teleportToChapterWalk = Character.teleportToChapterWalk
local teleportToLane = Character.teleportToLane
local applyRoundFeatures = Gates.applyRoundFeatures

local Debug = {}

function Debug.destroyChapterPad()
	local arena = Workspace:FindFirstChild("Arena")
	if not arena then
		return
	end
	local pad = arena:FindFirstChild("ChapterPad")
	if pad then
		pad:Destroy()
	end
end

function Debug.debugEnterChapter(chapter: number)
	chapter = math.clamp(math.floor(chapter), 2, 3)
	destroyChapterPad()
	ctx.paused = false
	ctx.chapterClearArmed = false
	Config.setChapter(chapter)
	CombatService.clear()
	SpikeTrap.clear()
	ZombieService.clear()
	SupplyService.clear()
	NumberGate.clear()
	Arena.applyChapterLook(chapter)
	ctx.phase = "chapterClear"
	setState("Chapter", chapter)
	setState("Wave", Config.chapterStartWave(chapter))
	setState("Elapsed", 0)
	setState("Phase", "chapterClear")
	setState("Paused", false)
	setState("Countdown", 0)
	setState("Announce", `{chapter}챕터`)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	EventReset.resetChapter3Events(setState)
	EventReset.resetChapter2Round2Events()
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
			teleportToChapterWalk(player.Character)
		end
	end
end

function Debug.spawnChapterPad()
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
		if ctx.chapterPadDebounce or ctx.phase ~= "chapterClear" then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		if not Players:GetPlayerFromCharacter(character) then
			return
		end
		ctx.chapterPadDebounce = true
		if Config.chapter() <= 1 then
			Api.startChapter2()
		elseif Config.chapter() == 2 then
			Api.startChapter3()
		end
		task.delay(1.5, function()
			ctx.chapterPadDebounce = false
		end)
	end)
end

function Debug.jumpToRound(localRound: number)
	local maxRound = if Config.chapter() >= 3 then 15 else 10
	localRound = math.clamp(math.floor(localRound), 1, maxRound)
	local keptHitPower = ctx.hitPower
	if ctx.phase == "lobby" then
		ctx.kills = 0
		ctx.nextIsBossAt = Config.Boss.EveryNKills
		CombatService.clear()
		SpikeTrap.clear()
		ZombieService.clear()
		SupplyService.clear()
		NumberGate.clear()
		ctx.hitPower = 1
		ctx.megaBossSpawned = false
		ctx.eliteBossesSpawned = false
		ctx.finalBossSpawned = false
		ctx.introGateSpawned = false
		ctx.introGateDueAt = 0
		ctx.extraX2Spawned = false
		ctx.extraX2DueAt = 0
		ctx.plusGateSpawned = false
		ctx.gatePlayArmed = false
		ctx.supplyRoundArmed = false
		ctx.bombRoundArmed = false
		setState("Kills", 0)
		setState("HitPower", 1)
		for _, player in Players:GetPlayers() do
			if player.Character then
				teleportToLane(player.Character)
			end
		end
		Api.beginPlay()
	elseif ctx.phase == "chapterClear" then
		for _, player in Players:GetPlayers() do
			if player.Character then
				teleportToLane(player.Character)
			end
		end
		ctx.phase = "playing"
		ctx.paused = false
		ctx.matchStart = os.clock()
		ctx.lastSpawnAt = 0
		setState("Phase", "playing")
		setState("Countdown", 0)
		setState("Wave", Config.chapterStartWave())
		setState("Elapsed", 0)
		setState("HitPower", ctx.hitPower)
		setState("Announce", "")
	elseif ctx.phase == "countdown" then
		-- 챕터2 카운트다운에서 Api.beginPlay()를 호출하면 챕터1로 리셋됨
		ctx.phase = "playing"
		setState("Phase", "playing")
		setState("Countdown", 0)
		if Config.chapter() < 2 then
			Api.beginPlay()
		else
			ctx.matchStart = os.clock()
			ctx.lastSpawnAt = 0
			setState("Wave", Config.chapterStartWave())
			setState("Elapsed", 0)
			setState("HitPower", ctx.hitPower)
		end
	end
	if ctx.phase ~= "playing" then
		return
	end

	local wave = localRound
	if Config.chapter() >= 2 then
		wave = Config.chapterStartWave() + localRound - 1
	end

	ctx.hitPower = math.max(1, math.floor(keptHitPower))
	setState("HitPower", ctx.hitPower)
	ctx.matchStart = os.clock() - Config.elapsedAtWaveStart(wave)
	setState("Elapsed", math.floor(Config.elapsedAtWaveStart(wave)))
	setState("Wave", wave)

	NumberGate.clear()
	ctx.introGateSpawned = false
	ctx.introGateDueAt = 0
	ctx.extraX2Spawned = false
	ctx.extraX2DueAt = 0
	ctx.plusGateSpawned = false
	ctx.chapter2PlusSpawned = false
	ctx.chapter2X2Spawned = false
	ctx.chapter2PlusDueAt = 0
	ctx.chapter2X2DueAt = 0
	EventReset.resetChapter2Round2Events()
	ctx.gatePlayArmed = false
	setState("MolotovLeft", 0)
	EventReset.resetChapter3Events(setState)
	applyRoundFeatures(wave)
end

function Debug.onZombieDied()
	if ctx.phase ~= "playing" then
		return
	end
	ctx.kills += 1
	setState("Kills", ctx.kills)
	setState("ZombiesAlive", #ZombieService.getAlive())
end

return Debug
