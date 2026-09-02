local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.SupplyService)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Spawning = require(script.Parent.Spawning)

local ctx = Context
local setState = StateSync.setState
local markSidePathSpawn = Spawning.markSidePathSpawn
local delayBombAfterGate = Spawning.delayBombAfterGate
local spawnFinalBoss = Spawning.spawnFinalBoss
local spawnEliteBosses = Spawning.spawnEliteBosses
local spawnMegaBoss = Spawning.spawnMegaBoss

local Gates = {}

function Gates.spawnIntroGate()
	if ctx.introGateSpawned then
		return
	end
	if NumberGate.createIntro() then
		ctx.introGateSpawned = true
		markSidePathSpawn()
	end
end

function Gates.spawnPlusGate()
	if ctx.plusGateSpawned then
		return
	end
	if NumberGate.createPlusIntro() then
		ctx.plusGateSpawned = true
		markSidePathSpawn()
		delayBombAfterGate()
	end
end

function Gates.spawnExtraX2()
	if ctx.extraX2Spawned then
		return
	end
	if NumberGate.createExtraIntro() then
		ctx.extraX2Spawned = true
		markSidePathSpawn()
	end
end

function Gates.respawnNumberGate()
	NumberGate.clear()
	local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
	if wave >= Config.NumberGate.PlayRound then
		NumberGate.createRandom()
	elseif wave >= Config.NumberGate.PlusRound then
		ctx.plusGateSpawned = false
		spawnPlusGate()
	elseif wave >= Config.NumberGate.UnlockRound then
		ctx.introGateSpawned = false
		spawnIntroGate()
	end
end

function Gates.applyRoundFeatures(wave: number)
	if Config.chapter() >= 2 then
		return
	end
	if wave >= Config.FinalBoss.Round then
		if not ctx.finalBossSpawned then
			ctx.finalBossSpawned = true
			ctx.eliteBossesSpawned = true
			ctx.megaBossSpawned = true
			setState("Announce", Config.FinalBoss.IntroText)
			spawnFinalBoss()
			task.delay(Config.FinalBoss.IntroDuration, function()
				if (ctx.stateFolder:GetAttribute("Announce") or "") == Config.FinalBoss.IntroText then
					setState("Announce", "")
				end
			end)
		end
	elseif wave >= Config.EliteBosses.UnlockRound then
		if not ctx.eliteBossesSpawned then
			ctx.eliteBossesSpawned = true
			ctx.megaBossSpawned = true
			spawnEliteBosses()
		end
	elseif wave >= Config.MegaBoss.Round and not ctx.megaBossSpawned then
		ctx.megaBossSpawned = true
		spawnMegaBoss()
	end
	if wave >= Config.NumberGate.PlayRound then
		if not ctx.gatePlayArmed then
			ctx.gatePlayArmed = true
			if NumberGate.createRandom() then
				ctx.lastGateSpawnAt = os.clock()
				markSidePathSpawn()
				delayBombAfterGate()
			else
				ctx.lastGateSpawnAt = os.clock() - Config.NumberGate.SpawnInterval
			end
		end
	elseif wave >= Config.NumberGate.PlusRound then
		spawnPlusGate()
		if ctx.extraX2DueAt == 0 and not ctx.extraX2Spawned then
			ctx.extraX2DueAt = os.clock() + Config.NumberGate.ExtraX2Delay
		end
		if not ctx.extraX2Spawned and ctx.extraX2DueAt > 0 and os.clock() >= ctx.extraX2DueAt then
			spawnExtraX2()
		end
	elseif wave >= Config.NumberGate.UnlockRound then
		if ctx.introGateDueAt == 0 and not ctx.introGateSpawned then
			if SupplyService.canSpawnBomb() then
				SupplyService.createBomb()
				ctx.lastBombSpawnAt = os.clock()
				markSidePathSpawn()
			end
			ctx.bombRoundArmed = true
			ctx.introGateDueAt = os.clock() + Config.NumberGate.IntroAfterBombDelay
		end
		if not ctx.introGateSpawned and ctx.introGateDueAt > 0 and os.clock() >= ctx.introGateDueAt then
			spawnIntroGate()
		end
	end
	if wave >= Config.Supply.UnlockRound and not ctx.supplyRoundArmed then
		ctx.supplyRoundArmed = true
		ctx.lastSupplySpawnAt = os.clock() - Config.Supply.SpawnInterval + Config.Supply.FirstSpawnDelay
	end
	if wave >= Config.BombCrate.UnlockRound and not ctx.bombRoundArmed then
		ctx.bombRoundArmed = true
		ctx.lastBombSpawnAt = os.clock() - Config.BombCrate.SpawnInterval + Config.BombCrate.FirstSpawnDelay
	end
end

return Gates
