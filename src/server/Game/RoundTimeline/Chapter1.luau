local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local SpikeTrap = require(script.Parent.Parent.Parent.SpikeTrap)
local Context = require(script.Parent.Parent.Context)
local StateSync = require(script.Parent.Parent.StateSync)
local Spawning = require(script.Parent.Parent.Spawning)
local EventFlags = require(script.Parent.Parent.EventFlags)

local ctx = Context
local setState = StateSync.setState
local Ev = EventFlags
local waveLocalElapsed = Spawning.waveLocalElapsed
local markSidePathSpawn = Spawning.markSidePathSpawn

local Chapter1 = {}

local function announce(text: string, clearAfter: number?)
	setState("Announce", text)
	task.delay(clearAfter or 3.2, function()
		if (ctx.stateFolder:GetAttribute("Announce") or "") == text then
			setState("Announce", "")
		end
	end)
end

function Chapter1.tick(now: number, wave: number)
	if Config.chapter() > 1 then
		return
	end
	local t = waveLocalElapsed(wave)
	local round = wave -- chapter 1 local == absolute wave

	local r1 = Config.Chapter1.Round1
	if round == r1.Round then
		if t >= r1.PlusAt and not Ev.Ch1.R1PlusSpawned then
			Ev.Ch1.R1PlusSpawned = true
			NumberGate.createPlus(r1.PlusHitCountMin, r1.PlusHitCountMax, true)
			markSidePathSpawn()
		end
		return
	end

	local r2 = Config.Chapter1.Round2
	if round == r2.Round then
		if t >= r2.X2At and not Ev.Ch1.R2X2Spawned then
			Ev.Ch1.R2X2Spawned = true
			NumberGate.createX2(r2.X2HitCountMin, r2.X2HitCountMax, true)
			markSidePathSpawn()
		end
		if t >= r2.X2RetryAt and not Ev.Ch1.R2X2RetrySpawned and not Ev.Ch1.R2X2Collected then
			Ev.Ch1.R2X2RetrySpawned = true
			NumberGate.createX2(r2.X2HitCountMin, r2.X2HitCountMax, true)
			markSidePathSpawn()
		end
		return
	end

	local r3 = Config.Chapter1.Round3
	if round == r3.Round then
		if t >= r3.BombAt and not Ev.Ch1.R3BombSpawned then
			Ev.Ch1.R3BombSpawned = true
			SupplyService.createBomb(true, r3.BombHitCountMin, r3.BombHitCountMax)
			markSidePathSpawn()
		end
		return
	end

	-- R4: dog chance only (spawnOne)
	if round == Config.Chapter1.Round4.Round then
		return
	end

	local r5 = Config.Chapter1.Round5
	if round == r5.Round then
		if t >= r5.BossAt and not Ev.Ch1.R5BossSpawned then
			Ev.Ch1.R5BossSpawned = true
			ctx.megaBossSpawned = true
			local hits = math.random(r5.BossHitCountMin, r5.BossHitCountMax)
			local slots = Config.Infinite.LaneSlots
			Spawning.spawnMegaBossAt(slots[math.ceil(#slots / 2)], hits, false)
		end
		if t >= r5.BombAt and not Ev.Ch1.R5BombSpawned then
			Ev.Ch1.R5BombSpawned = true
			SupplyService.createBomb(true, r5.BombHitCountMin, r5.BombHitCountMax)
			markSidePathSpawn()
		end
		return
	end

	local r6 = Config.Chapter1.Round6
	if round == r6.Round then
		if t >= r6.MinusAt and not Ev.Ch1.R6MinusSpawned then
			Ev.Ch1.R6MinusSpawned = true
			NumberGate.createMinus(r6.MinusHitCountMin, r6.MinusHitCountMax, true, r6.MinusWalkSpeedScale)
			markSidePathSpawn()
		end
		if t >= r6.PlusAt and not Ev.Ch1.R6PlusSpawned then
			Ev.Ch1.R6PlusSpawned = true
			NumberGate.createPlus(r6.PlusHitCountMin, r6.PlusHitCountMax, true)
			markSidePathSpawn()
		end
		return
	end

	local r7 = Config.Chapter1.Round7
	if round == r7.Round then
		if t >= r7.BombAt and not Ev.Ch1.R7BombSpawned then
			Ev.Ch1.R7BombSpawned = true
			SupplyService.createBomb(true, r7.BombHitCountMin, r7.BombHitCountMax)
			markSidePathSpawn()
		end
		for i, at in r7.LogAt do
			local key = if i == 1 then "R7Log1Spawned" else "R7Log2Spawned"
			if t >= at and not Ev.Ch1[key] then
				Ev.Ch1[key] = true
				SpikeTrap.createLog()
			end
		end
		return
	end

	local r8 = Config.Chapter1.Round8
	if round == r8.Round then
		if t >= r8.PlusAt and not Ev.Ch1.R8PlusSpawned then
			Ev.Ch1.R8PlusSpawned = true
			NumberGate.createPlus(r8.PlusHitCountMin, r8.PlusHitCountMax, true)
			markSidePathSpawn()
		end
		for i, at in r8.EliteAt do
			local key = `R8Elite{i}Spawned`
			if t >= at and not Ev.Ch1[key] then
				Ev.Ch1[key] = true
				ctx.eliteBossesSpawned = true
				ctx.megaBossSpawned = true
				local slots = Config.Infinite.LaneSlots
				local index = 1 + ((i - 1) % #slots)
				local hits = math.random(r8.EliteHitCountMin, r8.EliteHitCountMax)
				Spawning.spawnMegaBossAt(slots[index], hits, true)
			end
		end
		if t >= r8.LogAt and not Ev.Ch1.R8LogSpawned then
			Ev.Ch1.R8LogSpawned = true
			SpikeTrap.createLog()
		end
		return
	end

	-- R9: mix only in spawnOne
	if round == Config.Chapter1.Round9.Round then
		return
	end

	local r10 = Config.Chapter1.Round10
	if round == r10.Round then
		if t >= r10.BossAt and not Ev.Ch1.R10BossSpawned then
			Ev.Ch1.R10BossSpawned = true
			ctx.finalBossSpawned = true
			ctx.eliteBossesSpawned = true
			ctx.megaBossSpawned = true
			announce(Config.FinalBoss.IntroText, Config.FinalBoss.IntroDuration)
			local slots = Config.Infinite.LaneSlots
			local zombie = Spawning.spawnMegaBossAt(
				slots[math.ceil(#slots / 2)],
				r10.BossHitCount,
				false,
				{
					scale = Config.FinalBoss.SizeScale,
					walkSpeed = r10.BossWalkSpeed or Config.FinalBoss.WalkSpeed,
					contactDamage = Config.FinalBoss.ContactDamage,
				}
			)
			if zombie then
				zombie.model:SetAttribute("IsFinalBoss", true)
			end
		end
		if t >= r10.LogAt and not Ev.Ch1.R10LogSpawned then
			Ev.Ch1.R10LogSpawned = true
			SpikeTrap.createLog()
		end
	end
end

return Chapter1
