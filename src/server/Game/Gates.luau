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
		Gates.spawnPlusGate()
	elseif wave >= Config.NumberGate.UnlockRound then
		ctx.introGateSpawned = false
		Gates.spawnIntroGate()
	end
end

function Gates.applyRoundFeatures(_wave: number)
	-- 챕터1은 RoundTimeline/Chapter1, 챕터2+는 각 Chapter 타임라인이 담당
	if Config.chapter() >= 1 then
		return
	end
end

return Gates
