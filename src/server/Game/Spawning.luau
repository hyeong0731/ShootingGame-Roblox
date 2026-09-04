local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.Parent.ZombieService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local Context = require(script.Parent.Context)

local ctx = Context
local Spawning = {}

function Spawning.currentUnitDamage(): number
	local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
	return Config.unitDamageForWave(wave)
end

function Spawning.delayBombAfterGate()
	ctx.lastBombSpawnAt = os.clock() - Config.BombCrate.SpawnInterval + Config.BombCrate.AfterGateDelay
	ctx.bombRoundArmed = true
end

function Spawning.markSidePathSpawn()
	ctx.lastSidePathSpawnAt = os.clock()
end

function Spawning.sidePathReady(now: number): boolean
	return (now - ctx.lastSidePathSpawnAt) >= Config.BombCrate.AfterGateDelay
end

function Spawning.chapter2HealthPerKill(): number
	if Config.chapter() ~= 2 then
		return Config.activeInfinite().HealthPerKill
	end
	local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
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

function Spawning.currentStats()
	local elapsed = math.max(0, os.clock() - ctx.matchStart)
	local z = Config.activeZombie()
	local inf = Config.activeInfinite()
	local scaledKills = math.max(0, ctx.kills - ctx.killBaseline)
	local health = z.Health + scaledKills * Spawning.chapter2HealthPerKill()
	local speed = z.WalkSpeed + elapsed * inf.SpeedPerSecond
	local spawnElapsed = elapsed
	local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
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
			local t = math.max(0, (os.clock() - ctx.matchStart) - Config.elapsedAtWaveStart(wave))
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
	if Config.chapter() == 3 then
		local r1 = Config.Chapter3.Round1
		local r2 = Config.Chapter3.Round2
		local r3 = Config.Chapter3.Round3
		local r5 = Config.Chapter3.Round5
		local localRound = Config.chapterRound(wave)
		local localElapsed = math.max(0, elapsed - Config.elapsedAtWaveStart(wave))
		if localRound <= r2.Round and localElapsed >= r1.SpawnEaseAt then
			gap *= Config.Chapter3.SpawnEaseGapScale
		end
		if localRound == r2.Round and localElapsed >= r2.SpawnEase2At then
			gap *= r2.SpawnEase2GapScale
		end
		if localRound == r3.Round then
			gap = math.max(inf.SpawnGapMin, r3.SpawnGap)
			maxAlive = r3.MaxAlive
			if localElapsed >= r3.HordeStartAt and localElapsed < r3.HordeEndAt then
				gap = r3.HordeSpawnGap
				maxAlive = r3.HordeMaxAlive
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
					maxAlive += inf.AllyMaxAliveBonus
				end
			elseif SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		if localRound == r5.Round then
			if localElapsed >= r5.HordeStartAt and localElapsed < r5.HordeEndAt then
				gap = r5.HordeSpawnGap
				maxAlive = r5.HordeMaxAlive
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
					maxAlive += inf.AllyMaxAliveBonus
				end
			elseif localElapsed >= r5.ThrowerWaveAt then
				gap *= r5.BossFocusGapScale
				maxAlive = math.min(maxAlive, r5.BossFocusMaxAlive)
			elseif SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r6 = Config.Chapter3.Round6
		if localRound == r6.Round then
			if localElapsed < r6.ClearGraceUntil then
				gap *= r6.ClearGraceGapScale
				maxAlive = math.min(maxAlive, r6.ClearGraceMaxAlive)
			elseif localElapsed >= r6.LateEaseFrom then
				gap *= r6.LateEaseGapScale
				maxAlive = math.min(maxAlive, r6.LateEaseMaxAlive)
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
					maxAlive += inf.AllyMaxAliveBonus
				end
			elseif SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r7 = Config.Chapter3.Round7
		if localRound == r7.Round then
			gap *= r7.SpawnGapScale
			maxAlive = math.min(maxAlive, r7.MaxAliveCap)
			if SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r8 = Config.Chapter3.Round8
		if localRound == r8.Round then
			gap *= r8.SpawnGapScale
			maxAlive = math.min(maxAlive, r8.MaxAliveCap)
			if SupplyService.hasRecruitedThisMatch() then
				gap *= inf.AllySpawnGapScale
				maxAlive += inf.AllyMaxAliveBonus
			end
		end
		local r9 = Config.Chapter3.Round9
		if localRound == r9.Round then
			if localElapsed < r9.ClearGraceUntil then
				gap *= r9.ClearGraceGapScale
				maxAlive = math.min(maxAlive, r9.ClearGraceMaxAlive)
			else
				maxAlive = math.min(maxAlive, r9.MaxAliveCap)
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
					maxAlive += inf.AllyMaxAliveBonus
				end
			end
		end
		local r10 = Config.Chapter3.Round10
		local fenceBreached = ctx.stateFolder ~= nil and ctx.stateFolder:GetAttribute("Ch3FenceBreached") == true
		if localRound == r10.Round then
			if localElapsed < r10.ClearGraceUntil then
				gap *= r10.ClearGraceGapScale
				maxAlive = math.min(maxAlive, r10.ClearGraceMaxAlive)
			elseif localElapsed >= (r10.EndEaseFrom or 50) then
				-- 50초~R11 직전: 도로끝 10
				maxAlive = math.min(maxAlive, r10.EndEaseRoadMaxAlive or 10)
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
				end
			else
				-- 도로끝 14 (LeftStream은 countForSpawnCap에서 제외)
				maxAlive = math.min(maxAlive, r10.LateMaxAliveCap)
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
				end
			end
		elseif fenceBreached and localRound > r10.Round then
			local r11 = Config.Chapter3.Round11
			local r12 = Config.Chapter3.Round12
			if localRound == r11.Round then
				if localElapsed < r11.ClearGraceUntil then
					gap *= r11.ClearGraceGapScale
					maxAlive = math.min(maxAlive, r11.ClearGraceMaxAlive)
				elseif localElapsed >= (r11.MidEaseFrom or 30)
					and localElapsed < (r11.MidEaseUntil or 45)
				then
					maxAlive = math.min(maxAlive, r11.MidEaseRoadMaxAlive or 10)
					if SupplyService.hasRecruitedThisMatch() then
						gap *= inf.AllySpawnGapScale
					end
				else
					-- 10~30초 · 45초~ : 도로 12
					maxAlive = math.min(maxAlive, r11.RoadMaxAlive or 12)
					if SupplyService.hasRecruitedThisMatch() then
						gap *= inf.AllySpawnGapScale
					end
				end
			elseif localRound == r12.Round then
				if localElapsed < r12.ClearGraceUntil then
					gap *= r12.ClearGraceGapScale
					maxAlive = math.min(maxAlive, r12.ClearGraceRoadMaxAlive or 6)
				else
					maxAlive = math.min(maxAlive, r12.RoadMaxAlive or 10)
					if SupplyService.hasRecruitedThisMatch() then
						gap *= inf.AllySpawnGapScale
					end
				end
			else
				-- R13~R15: R12 기본 도로 상한 유지
				maxAlive = math.min(maxAlive, r12.RoadMaxAlive or 10)
				if SupplyService.hasRecruitedThisMatch() then
					gap *= inf.AllySpawnGapScale
				end
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

function Spawning.waveLocalElapsed(wave: number): number
	return math.max(0, (os.clock() - ctx.matchStart) - Config.elapsedAtWaveStart(wave))
end

function Spawning.chapter2BigUnlocked(wave: number, elapsedLocal: number): boolean
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

function Spawning.spawnOne()
	local stats = Spawning.currentStats()
	local inf = Config.activeInfinite()
	local lane = Config.activeLane()
	local slots = inf.LaneSlots
	local x = slots[math.random(1, #slots)]
	local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
	local elapsed = math.max(0, os.clock() - ctx.matchStart)
	local elapsedLocal = Spawning.waveLocalElapsed(wave)
	local isBoss = Config.chapter() <= 1 and wave < Config.FinalBoss.Round and ctx.kills >= ctx.nextIsBossAt
	if isBoss then
		ctx.nextIsBossAt += Config.Boss.EveryNKills
		x = slots[math.ceil(#slots / 2)]
	end

	local dogCfg = Config.activeDog()
	local round = Config.chapterRound(wave)
	local ch3Round5 = Config.Chapter3.Round5
	local r5Horde = Config.chapter() == 3
		and round == ch3Round5.Round
		and elapsedLocal >= ch3Round5.HordeStartAt
		and elapsedLocal < ch3Round5.HordeEndAt
	local isDog = (not isBoss) and (
		(Config.chapter() ~= 3 and wave >= dogCfg.UnlockWave and math.random() < dogCfg.SpawnChance)
		or (r5Horde and math.random() < ch3Round5.DogSpawnChance)
	)

	local shieldCfg = Config.ShieldZombie
	local shieldUnlockAt = Config.elapsedAtWaveStart(Config.Chapter2.Waves.From + shieldCfg.UnlockRound - 1)
		- shieldCfg.LeadSeconds
	local r3 = Config.Chapter2.Round3
	local r4 = Config.Chapter2.Round4
	local r6 = Config.Chapter2.Round6
	local r7 = Config.Chapter2.Round7
	local r8 = Config.Chapter2.Round8
	local r9 = Config.Chapter2.Round9
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
	local ch3Round1 = Config.Chapter3.Round1
	local ch3Round3 = Config.Chapter3.Round3
	local ch3Round6Early = Config.Chapter3.Round6
	local ch3Round7 = Config.Chapter3.Round7
	local ch3Round8 = Config.Chapter3.Round8
	local ch3ShieldOpen = false
	if Config.chapter() == 3 then
		if round == ch3Round1.Round then
			ch3ShieldOpen = elapsedLocal >= ch3Round1.ShieldAt
		elseif round == ch3Round3.Round then
			ch3ShieldOpen = elapsedLocal >= ch3Round3.HordeStartAt and elapsedLocal < ch3Round3.HordeEndAt
		elseif round == ch3Round5.Round then
			ch3ShieldOpen = r5Horde
		elseif round > ch3Round1.Round then
			ch3ShieldOpen = true
		end
	end
	if ch3ShieldOpen then
		if round == ch3Round5.Round then
			shieldChance = ch3Round5.ShieldSpawnChance
		elseif round == ch3Round3.Round then
			shieldChance = ch3Round3.ShieldSpawnChance
		elseif round == ch3Round8.Round then
			if elapsedLocal >= ch3Round8.ShieldShiftAt then
				shieldChance = ch3Round8.ShieldSpawnChanceLate
			else
				shieldChance = ch3Round8.ShieldSpawnChance
			end
		elseif round == ch3Round7.Round
			and elapsedLocal >= ch3Round7.ShieldBoostAt
			and elapsedLocal < ch3Round7.ShieldBoostUntil
		then
			shieldChance = ch3Round7.ShieldBoostChance
		else
			shieldChance = ch3Round1.ShieldSpawnChance
		end
	end
	local isShield = (not isBoss)
		and (not isDog)
		and (ch3ShieldOpen or (Config.chapter() == 2 and elapsed >= shieldUnlockAt))
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
	if Config.chapter() == 3 then
		if round == ch3Round5.Round then
			shieldHitMin = ch3Round5.ShieldHitCountMin
			shieldHitMax = ch3Round5.ShieldHitCountMax
		elseif round >= ch3Round8.Round then
			-- R8부터 지속 (별도 언급 전까지)
			shieldHitMin = ch3Round8.ShieldHitCountMin
			shieldHitMax = ch3Round8.ShieldHitCountMax
		elseif round >= ch3Round6Early.Round then
			-- R6~R7
			shieldHitMin = Config.Chapter3.ShieldHitCountMin
			shieldHitMax = Config.Chapter3.ShieldHitCountMax
		else
			shieldHitMin = ch3Round1.ShieldHitCountMin
			shieldHitMax = ch3Round1.ShieldHitCountMax
		end
	end
	local shieldHits = if isShield then math.random(shieldHitMin, shieldHitMax) else nil

	local isBig = false
	local ch3Round6 = ch3Round6Early
	local r6BigOpen = Config.chapter() == 3
		and round == ch3Round6.Round
		and elapsedLocal >= ch3Round6.BigFromAt
	local r7BigOpen = Config.chapter() == 3
		and round == ch3Round7.Round
		and elapsedLocal >= ch3Round7.BigFromAt
	local r8BigOpen = Config.chapter() == 3
		and round == ch3Round8.Round
		and elapsedLocal >= ch3Round8.BigFromAt
	local ch3BigOpen = r5Horde or r6BigOpen or r7BigOpen or r8BigOpen
	if (not isBoss) and (not isDog) and (not isShield) then
		local wantBig = false
		if r5Horde then
			wantBig = math.random() < ch3Round5.BigSpawnChance
		elseif r6BigOpen then
			wantBig = math.random() < ch3Round6.BigSpawnChance
		elseif r7BigOpen then
			wantBig = math.random() < ch3Round7.BigSpawnChance
		elseif r8BigOpen then
			wantBig = math.random() < ch3Round8.BigSpawnChance
		elseif Config.chapter() ~= 3 and Spawning.chapter2BigUnlocked(wave, elapsedLocal) then
			local bigChance = Config.Chapter2.BigZombie.SpawnChance
			if round == r6.Round then
				bigChance = r6.BigZombieSpawnChance
			end
			wantBig = math.random() < bigChance
		end
		if wantBig then
			isBoss = true
			isBig = true
		end
	end

	local throwerCfg = Config.ThrowerZombie
	local isThrower = false
	if Config.chapter() == 3 and (not isBoss) and (not isDog) and (not isShield) then
		if round == ch3Round1.Round and elapsedLocal >= ch3Round1.ThrowerAt then
			isThrower = math.random() < throwerCfg.SpawnChance
		elseif round == ch3Round3.Round
			and elapsedLocal >= ch3Round3.ThrowerAt
			and elapsedLocal < ch3Round3.HordeEndAt
		then
			isThrower = math.random() < ch3Round3.ThrowerSpawnChance
		elseif r5Horde then
			isThrower = math.random() < ch3Round5.ThrowerSpawnChance
		elseif round == Config.Chapter3.Round10.Round then
			isThrower = math.random() < Config.Chapter3.Round10.ThrowerSpawnChance
		end
	end
	local throwerStopZ = if isThrower
		then lane.PlayerZ + (lane.SpawnZ - lane.PlayerZ) * throwerCfg.StopRatio
		else nil

	local ch3BigScale = if ch3BigOpen then ch3Round5.BigZombieSizeScale else nil
	local scale = if ch3BigScale and isBig
		then ch3BigScale
		elseif isBoss
		then Config.Boss.SizeMultiplier
		elseif isThrower then throwerCfg.SizeScale
		elseif isDog then dogCfg.SizeScale
		else 1
	local y = lane.CenterY + (if isDog then 1.35 else 2.4) * scale

	local health: number
	local walkSpeed: number
	local contactDamage: number
	if isBig and ch3BigOpen then
		health = stats.health * ch3Round5.BigZombieHealthMult
		walkSpeed = stats.speed * ch3Round5.BigZombieSpeedScale
		contactDamage = Config.Boss.ContactDamage
	elseif isBoss then
		health = stats.health * Config.Boss.HealthMultiplier
		walkSpeed = stats.speed * Config.Boss.SpeedMultiplier
		contactDamage = Config.Boss.ContactDamage
	elseif isDog then
		health = dogCfg.Health + math.max(0, ctx.kills - ctx.killBaseline) * Spawning.chapter2HealthPerKill() * 0.7
		walkSpeed = dogCfg.WalkSpeed + elapsed * dogCfg.SpeedPerSecond
		if Config.chapter() == 2 and round == Config.Chapter2.Round10.Round then
			walkSpeed *= Config.Chapter2.Round10.ZombieSpeedScale
		end
		contactDamage = dogCfg.ContactDamage
	elseif isThrower then
		health = throwerCfg.Health
		walkSpeed = throwerCfg.WalkSpeed
		contactDamage = 0
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
		isThrower = isThrower,
		stopZ = throwerStopZ,
		contactDamage = contactDamage,
		scale = scale,
		hitCount = shieldHits,
	})
	if isThrower then
		ZombieService.setAttackTarget(zombie, { kind = "player", ally = nil })
	else
		ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	end
end

function Spawning.spawnMegaBossAt(x: number, hitCount: number, elite: boolean, appearance: {
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

function Spawning.spawnMegaBoss()
	local slots = Config.Infinite.LaneSlots
	local x = slots[math.ceil(#slots / 2)]
	Spawning.spawnMegaBossAt(x, Config.MegaBoss.HitCount, false)
end

function Spawning.spawnFinalBoss()
	local cfg = Config.FinalBoss
	local hits = math.random(cfg.HitCountMin, cfg.HitCountMax)
	local slots = Config.Infinite.LaneSlots
	local x = slots[math.ceil(#slots / 2)]
	local zombie = Spawning.spawnMegaBossAt(x, hits, false, {
		scale = cfg.SizeScale,
		walkSpeed = cfg.WalkSpeed,
		contactDamage = cfg.ContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsFinalBoss", true)
	end
end

function Spawning.spawnEliteBosses()
	local cfg = Config.EliteBosses
	local minHits = math.max(1, math.floor(cfg.HitCountMin))
	local maxHits = math.max(minHits, math.floor(cfg.HitCountMax))
	local slots = Config.Infinite.LaneSlots
	local count = math.max(1, math.floor(cfg.Count))
	for i = 1, count do
		local t = if count == 1 then 0.5 else (i - 1) / (count - 1)
		local index = 1 + math.floor(t * (#slots - 1) + 0.5)
		local hits = math.random(minHits, maxHits)
		Spawning.spawnMegaBossAt(slots[index], hits, true)
	end
end

function Spawning.spawnChapter2MidBoss(spawnX: number, hitMin: number?, hitMax: number?)
	local r5 = Config.Chapter2.Round5
	local stats = Spawning.currentStats()
	local walkSpeed = stats.speed * r5.SpeedMultiplier
	local minH = math.max(1, math.floor(hitMin or r5.HitCountMin))
	local maxH = math.max(minH, math.floor(hitMax or r5.HitCountMax))
	local hits = math.random(minH, maxH)
	local zombie = Spawning.spawnMegaBossAt(spawnX, hits, false, {
		scale = r5.SizeScale,
		walkSpeed = walkSpeed,
		contactDamage = r5.ContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsMidBoss", true)
	end
end

function Spawning.spawnChapter2DogSwarm(count: number)
	local stats = Spawning.currentStats()
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
			walkSpeed = Config.activeDog().WalkSpeed + (os.clock() - ctx.matchStart) * Config.activeDog().SpeedPerSecond,
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

function Spawning.spawnChapter2FinalBoss()
	local r10 = Config.Chapter2.Round10
	local stats = Spawning.currentStats()
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

function Spawning.spawnChapter2OpeningSwarm()
	local r10 = Config.Chapter2.Round10
	local r9 = Config.Chapter2.Round9
	local stats = Spawning.currentStats()
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
				then (dogCfg.WalkSpeed + (os.clock() - ctx.matchStart) * dogCfg.SpeedPerSecond) * speedScale
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

function Spawning.spawnChapter2MidSwarm(count: number)
	local r10 = Config.Chapter2.Round10
	local stats = Spawning.currentStats()
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
			then (dogCfg.WalkSpeed + (os.clock() - ctx.matchStart) * dogCfg.SpeedPerSecond) * r10.ZombieSpeedScale
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

function Spawning.spawnChapter2FinalHorde(count: number)
	local stats = Spawning.currentStats()
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
			then (Config.activeDog().WalkSpeed + (os.clock() - ctx.matchStart) * Config.activeDog().SpeedPerSecond) * Config.Chapter2.Round10.ZombieSpeedScale
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

function Spawning.spawnChapter3BigZombie(
	spawnX: number,
	bigCfg: {
		BigZombieSizeScale: number,
		BigZombieHealthMult: number,
		BigZombieSpeedScale: number,
	}?
)
	local r = bigCfg or Config.Chapter3.Round2
	local stats = Spawning.currentStats()
	local lane = Config.activeLane()
	local scale = r.BigZombieSizeScale
	local y = lane.CenterY + 2.4 * scale
	local zombie = ZombieService.create(Vector3.new(spawnX, y, lane.SpawnZ), {
		health = stats.health * r.BigZombieHealthMult,
		walkSpeed = stats.speed * r.BigZombieSpeedScale,
		isBoss = true,
		isBig = true,
		isDog = false,
		isShield = false,
		contactDamage = Config.Boss.ContactDamage,
		scale = scale,
		hitCount = nil,
	})
	ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
end

function Spawning.spawnChapter3BigZombieSwarm(
	count: number,
	gap: number,
	bigCfg: {
		BigZombieSizeScale: number,
		BigZombieHealthMult: number,
		BigZombieSpeedScale: number,
	}?
)
	task.spawn(function()
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		local n = math.max(1, math.floor(count))
		for i = 1, n do
			if ctx.phase ~= "playing" then
				return
			end
			if i > 1 then
				task.wait(gap)
			end
			if ctx.phase ~= "playing" then
				return
			end
			local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
			x = math.clamp(x, minX, maxX)
			Spawning.spawnChapter3BigZombie(x, bigCfg)
		end
	end)
end

function Spawning.spawnChapter3DogSwarmEven(count: number, gap: number)
	local n = math.max(1, math.floor(count))
	task.spawn(function()
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local dogCfg = Config.activeDog()
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		for i = 1, n do
			if ctx.phase ~= "playing" then
				return
			end
			if i > 1 then
				task.wait(gap)
			end
			if ctx.phase ~= "playing" then
				return
			end
			local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
			x = math.clamp(x, minX, maxX)
			local z = lane.SpawnZ + math.random() * 12
			local elapsed = math.max(0, os.clock() - ctx.matchStart)
			local y = lane.CenterY + 1.35
			local zombie = ZombieService.create(Vector3.new(x, y, z), {
				health = dogCfg.Health,
				walkSpeed = dogCfg.WalkSpeed + elapsed * dogCfg.SpeedPerSecond,
				isBoss = false,
				isBig = false,
				isDog = true,
				isShield = false,
				contactDamage = dogCfg.ContactDamage,
				scale = dogCfg.SizeScale,
				hitCount = nil,
			})
			ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
		end
	end)
end

function Spawning.spawnChapter3DogSwarm(count: number, duration: number?, opts: {
	includeLeft: boolean?,
	ignoreSpawnCap: boolean?,
}?)
	local r2 = Config.Chapter3.Round2
	local r10 = Config.Chapter3.Round10
	local spread = duration or r2.DogSwarmDuration or 2
	local includeLeft = opts ~= nil and opts.includeLeft == true
	local ignoreCap = opts ~= nil and opts.ignoreSpawnCap == true
	local n = math.max(1, math.floor(count))
	task.spawn(function()
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local dogCfg = Config.activeDog()
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		local delays: { number } = table.create(n)
		for i = 1, n do
			delays[i] = math.random() * spread
		end
		table.sort(delays)
		local prev = 0
		for i = 1, n do
			if ctx.phase ~= "playing" then
				return
			end
			local waitTime = delays[i] - prev
			if waitTime > 0 then
				task.wait(waitTime)
			end
			prev = delays[i]
			if ctx.phase ~= "playing" then
				return
			end
			local x: number
			if includeLeft and math.random() < 0.45 then
				x = r10.OutsideSpawnXMin + math.random() * (r10.OutsideSpawnXMax - r10.OutsideSpawnXMin)
			else
				x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
				if not includeLeft then
					x = math.clamp(x, minX, maxX)
				else
					-- 도로 슬롯 + 살짝 왼쪽까지 허용
					x = math.clamp(x, minX - 6, maxX)
				end
			end
			local z = lane.SpawnZ + math.random() * 12
			local elapsed = math.max(0, os.clock() - ctx.matchStart)
			local y = lane.CenterY + 1.35
			local zombie = ZombieService.create(Vector3.new(x, y, z), {
				health = dogCfg.Health,
				walkSpeed = dogCfg.WalkSpeed + elapsed * dogCfg.SpeedPerSecond,
				isBoss = false,
				isBig = false,
				isDog = true,
				isShield = false,
				contactDamage = dogCfg.ContactDamage,
				scale = dogCfg.SizeScale,
				hitCount = nil,
			})
			if ignoreCap then
				zombie.model:SetAttribute("IgnoreSpawnCap", true)
			end
			ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
		end
	end)
end

function Spawning.spawnChapter2ShieldPack(count: number?, hitMin: number?, hitMax: number?)
	local r7 = Config.Chapter2.Round7
	local stats = Spawning.currentStats()
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

function Spawning.spawnChapter2SmallMidBoss()
	local r9 = Config.Chapter2.Round9
	local stats = Spawning.currentStats()
	local walkSpeed = stats.speed * r9.SpeedMultiplier
	local hits = math.random(r9.MidBossHitCountMin, r9.MidBossHitCountMax)
	local zombie = Spawning.spawnMegaBossAt(r9.SpawnX, hits, false, {
		scale = r9.SizeScale,
		walkSpeed = walkSpeed,
		contactDamage = r9.ContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsMidBoss", true)
	end
end

function Spawning.spawnChapter2ZombieSwarm()
	local r8 = Config.Chapter2.Round8
	local stats = Spawning.currentStats()
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

function Spawning.spawnChapter3MidBoss(hitMin: number?, hitMax: number?, appearance: {
	scale: number?,
	walkSpeed: number?,
	contactDamage: number?,
}?)
	local r5 = Config.Chapter3.Round5
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local x = slots[math.ceil(#slots / 2)]
	local minH = hitMin or r5.MidBossHitCountMin
	local maxH = hitMax or r5.MidBossHitCountMax
	if maxH < minH then
		maxH = minH
	end
	local hits = math.random(minH, maxH)
	local zombie = Spawning.spawnMegaBossAt(x, hits, false, {
		scale = if appearance and appearance.scale then appearance.scale else r5.MidBossSizeScale,
		walkSpeed = if appearance and appearance.walkSpeed then appearance.walkSpeed else r5.MidBossWalkSpeed,
		contactDamage = if appearance and appearance.contactDamage
			then appearance.contactDamage
			else r5.MidBossContactDamage,
	})
	if zombie then
		zombie.model:SetAttribute("IsMidBoss", true)
	end
end

function Spawning.spawnChapter3ThrowerWave(count: number, gap: number)
	local n = math.max(1, math.floor(count))
	task.spawn(function()
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local throwerCfg = Config.ThrowerZombie
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		local stopZ = lane.PlayerZ + (lane.SpawnZ - lane.PlayerZ) * throwerCfg.StopRatio
		for i = 1, n do
			if ctx.phase ~= "playing" then
				return
			end
			if i > 1 then
				task.wait(gap)
			end
			if ctx.phase ~= "playing" then
				return
			end
			local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
			x = math.clamp(x, minX, maxX)
			local scale = throwerCfg.SizeScale
			local y = lane.CenterY + 2.4 * scale
			local zombie = ZombieService.create(Vector3.new(x, y, lane.SpawnZ), {
				health = throwerCfg.Health,
				walkSpeed = throwerCfg.WalkSpeed,
				isBoss = false,
				isBig = false,
				isDog = false,
				isShield = false,
				isThrower = true,
				stopZ = stopZ,
				contactDamage = 0,
				scale = scale,
				hitCount = nil,
			})
			ZombieService.setAttackTarget(zombie, { kind = "player", ally = nil })
		end
	end)
end

function Spawning.spawnChapter3MineZombie()
	local mineCfg = Config.MineZombie
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
	local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 3.5
	x = math.clamp(x, minX, maxX)
	local scale = mineCfg.SizeScale
	local y = lane.CenterY + 2.4 * scale
	local health = Config.Chapter3.UnitDamage * mineCfg.HealthShots
	local zombie = ZombieService.create(Vector3.new(x, y, lane.SpawnZ), {
		health = health,
		walkSpeed = mineCfg.WalkSpeed,
		isBoss = false,
		isBig = false,
		isDog = false,
		isShield = false,
		isThrower = false,
		isMine = true,
		contactDamage = 0,
		scale = scale,
		hitCount = nil,
	})
	ZombieService.setAttackTarget(zombie, { kind = "player", ally = nil })
	return zombie
end

function Spawning.spawnChapter3MineWave(count: number)
	local n = math.max(1, math.floor(count))
	for _ = 1, n do
		Spawning.spawnChapter3MineZombie()
	end
end

function Spawning.spawnChapter3ShieldPack(count: number, gap: number, hitMin: number, hitMax: number)
	local n = math.max(1, math.floor(count))
	task.spawn(function()
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local stats = Spawning.currentStats()
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		for i = 1, n do
			if ctx.phase ~= "playing" then
				return
			end
			if i > 1 then
				task.wait(gap)
			end
			if ctx.phase ~= "playing" then
				return
			end
			local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
			x = math.clamp(x, minX, maxX)
			local hits = math.random(hitMin, hitMax)
			local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 2.4, lane.SpawnZ), {
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
	end)
end

-- 방패 좀비 일렬 (동시 스폰, 레인 균등 배치)
function Spawning.spawnChapter3ShieldLine(count: number, hitMin: number, hitMax: number)
	local n = math.max(1, math.floor(count))
	local lane = Config.activeLane()
	local slots = Config.activeInfinite().LaneSlots
	local stats = Spawning.currentStats()
	local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
	for i = 1, n do
		local t = if n == 1 then 0.5 else (i - 1) / (n - 1)
		local index = 1 + math.floor(t * (#slots - 1) + 0.5)
		local x = math.clamp(slots[index], minX, maxX)
		local lo = math.min(hitMin, hitMax)
		local hi = math.max(hitMin, hitMax)
		local hits = math.random(lo, hi)
		local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 2.4, lane.SpawnZ), {
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

function Spawning.spawnChapter3ThrowerAndDogWave(throwerCount: number, dogCount: number, gap: number)
	task.spawn(function()
		local total = math.max(0, math.floor(throwerCount)) + math.max(0, math.floor(dogCount))
		local kinds = {}
		for _ = 1, math.floor(throwerCount) do
			table.insert(kinds, "thrower")
		end
		for _ = 1, math.floor(dogCount) do
			table.insert(kinds, "dog")
		end
		-- shuffle
		for i = #kinds, 2, -1 do
			local j = math.random(1, i)
			kinds[i], kinds[j] = kinds[j], kinds[i]
		end
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local throwerCfg = Config.ThrowerZombie
		local dogCfg = Config.activeDog()
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		local stopZ = lane.PlayerZ + (lane.SpawnZ - lane.PlayerZ) * throwerCfg.StopRatio
		for i = 1, total do
			if ctx.phase ~= "playing" then
				return
			end
			if i > 1 then
				task.wait(gap)
			end
			if ctx.phase ~= "playing" then
				return
			end
			local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
			x = math.clamp(x, minX, maxX)
			if kinds[i] == "thrower" then
				local scale = throwerCfg.SizeScale
				local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 2.4 * scale, lane.SpawnZ), {
					health = throwerCfg.Health,
					walkSpeed = throwerCfg.WalkSpeed,
					isBoss = false,
					isDog = false,
					isShield = false,
					isThrower = true,
					stopZ = stopZ,
					contactDamage = 0,
					scale = scale,
					hitCount = nil,
				})
				ZombieService.setAttackTarget(zombie, { kind = "player", ally = nil })
			else
				local scale = dogCfg.SizeScale
				local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 1.35 * scale, lane.SpawnZ), {
					health = dogCfg.Health,
					walkSpeed = dogCfg.WalkSpeed,
					isBoss = false,
					isDog = true,
					isShield = false,
					contactDamage = dogCfg.ContactDamage,
					scale = scale,
					hitCount = nil,
				})
				ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
			end
		end
	end)
end

function Spawning.spawnChapter3TimedMix(
	normalCount: number,
	dogCount: number,
	bigCount: number,
	shieldCount: number,
	duration: number,
	shieldHitMin: number,
	shieldHitMax: number
)
	task.spawn(function()
		local kinds = {}
		for _ = 1, math.max(0, math.floor(normalCount)) do
			table.insert(kinds, "normal")
		end
		for _ = 1, math.max(0, math.floor(dogCount)) do
			table.insert(kinds, "dog")
		end
		for _ = 1, math.max(0, math.floor(bigCount)) do
			table.insert(kinds, "big")
		end
		for _ = 1, math.max(0, math.floor(shieldCount)) do
			table.insert(kinds, "shield")
		end
		for i = #kinds, 2, -1 do
			local j = math.random(1, i)
			kinds[i], kinds[j] = kinds[j], kinds[i]
		end
		local n = #kinds
		if n <= 0 then
			return
		end
		local spread = math.max(0.2, duration)
		local delays: { number } = table.create(n)
		for i = 1, n do
			delays[i] = math.random() * spread
		end
		table.sort(delays)
		local lane = Config.activeLane()
		local slots = Config.activeInfinite().LaneSlots
		local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
		local stats = Spawning.currentStats()
		local dogCfg = Config.activeDog()
		local r5 = Config.Chapter3.Round5
		local hitMin = math.max(1, math.floor(shieldHitMin))
		local hitMax = math.max(hitMin, math.floor(shieldHitMax))
		local prev = 0
		for i = 1, n do
			if ctx.phase ~= "playing" then
				return
			end
			local waitTime = delays[i] - prev
			if waitTime > 0 then
				task.wait(waitTime)
			end
			prev = delays[i]
			if ctx.phase ~= "playing" then
				return
			end
			local x = slots[math.random(1, #slots)] + (math.random() * 2 - 1) * 4.5
			x = math.clamp(x, minX, maxX)
			local kind = kinds[i]
			if kind == "dog" then
				local scale = dogCfg.SizeScale
				local elapsed = math.max(0, os.clock() - ctx.matchStart)
				local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 1.35 * scale, lane.SpawnZ), {
					health = dogCfg.Health,
					walkSpeed = dogCfg.WalkSpeed + elapsed * dogCfg.SpeedPerSecond,
					isBoss = false,
					isBig = false,
					isDog = true,
					isShield = false,
					contactDamage = dogCfg.ContactDamage,
					scale = scale,
					hitCount = nil,
				})
				ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
			elseif kind == "big" then
				Spawning.spawnChapter3BigZombie(x, r5)
			elseif kind == "shield" then
				local hits = math.random(hitMin, hitMax)
				local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 2.4, lane.SpawnZ), {
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
			else
				local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 2.4, lane.SpawnZ), {
					health = stats.health,
					walkSpeed = stats.speed,
					isBoss = false,
					isBig = false,
					isDog = false,
					isShield = false,
					contactDamage = Config.activeZombie().ContactDamage,
					scale = 1,
					hitCount = nil,
				})
				ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
			end
		end
	end)
end

function Spawning.spawnChapter3FenceApproachZombie()
	local r10 = Config.Chapter3.Round10
	local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
	local localElapsed = Spawning.waveLocalElapsed(wave)
	local localRound = Config.chapterRound(wave)
	local breached = ctx.stateFolder ~= nil and ctx.stateFolder:GetAttribute("Ch3FenceBreached") == true
	local leftCap = r10.LeftMaxAlive or 10
	if localRound == r10.Round and localElapsed >= (r10.EndEaseFrom or 50) then
		leftCap = r10.EndEaseLeftMaxAlive or 5
	elseif localRound == Config.Chapter3.Round11.Round then
		local r11 = Config.Chapter3.Round11
		if localElapsed >= (r11.LeftPauseFrom or 45) then
			return nil -- 45초~R12: 왼쪽 스폰 정지
		elseif localElapsed < r11.ClearGraceUntil then
			leftCap = r11.ClearGraceLeftMaxAlive or 4
		elseif localElapsed >= (r11.MidEaseFrom or 30)
			and localElapsed < (r11.MidEaseUntil or 45)
		then
			leftCap = r11.MidEaseLeftMaxAlive or 7
		else
			leftCap = r11.LeftMaxAlive or 8
		end
	elseif localRound == Config.Chapter3.Round12.Round then
		local r12 = Config.Chapter3.Round12
		if localElapsed < r12.ClearGraceUntil then
			leftCap = r12.ClearGraceLeftMaxAlive or 6
		else
			leftCap = r12.LeftMaxAlive or 10
		end
	elseif localRound > Config.Chapter3.Round12.Round then
		leftCap = Config.Chapter3.Round12.LeftMaxAlive or 10
	end
	if breached then
		if ZombieService.countLeftStream() >= leftCap then
			return nil
		end
	else
		-- 돌파 전에도 왼쪽은 왼쪽 상한만 (도로와 안 섞음)
		if ZombieService.countLeftStream() >= leftCap then
			return nil
		end
		if localElapsed < r10.ClearGraceUntil then
			-- 클리어 그레이스: 전체(도로+왼쪽) 합산 완화만
			if ZombieService.countForSpawnCap() + ZombieService.countLeftStream() >= r10.ClearGraceMaxAlive then
				return nil
			end
		end
	end
	local lane = Config.activeLane()
	local stats = Spawning.currentStats()
	-- 들판 쪽(동그라미)에서 스폰 → 철조망으로 대각선 접근
	local x = r10.OutsideSpawnXMin + math.random() * (r10.OutsideSpawnXMax - r10.OutsideSpawnXMin)
	local zJitter = r10.OutsideSpawnZJitter or 0
	local z = lane.SpawnZ + (r10.OutsideSpawnZPad or 0) + (math.random() * 2 - 1) * zJitter
	local pileX = r10.FencePileX + (math.random() * 2 - 1) * 0.8
	local pileZ = r10.FencePileZ + (math.random() * 2 - 1) * 2.5
	local walkSpeed = if breached then stats.speed else r10.ApproachWalkSpeed
	local zombie = ZombieService.create(Vector3.new(x, lane.CenterY + 2.4, z), {
		health = stats.health,
		walkSpeed = walkSpeed,
		isBoss = false,
		isBig = false,
		isDog = false,
		isShield = false,
		fenceApproach = true,
		fenceTargetX = pileX,
		fenceTargetZ = pileZ,
		fenceEnterX = r10.PostBreachEnterX,
		contactDamage = Config.activeZombie().ContactDamage,
		scale = 1,
		hitCount = nil,
	})
	if breached then
		zombie.fencePhase = "enter"
		zombie.stopZ = nil
	end
	ZombieService.setAttackTarget(zombie, SupplyService.pickAttackTarget())
	return zombie
end

function Spawning.startChapter3FenceApproachWave()
	local r10 = Config.Chapter3.Round10
	task.spawn(function()
		-- R10에서 시작 후 챕터3(R15) 종료까지 왼쪽 스트림 유지
		while true do
			if ctx.phase ~= "playing" then
				return
			end
			if Config.chapter() ~= 3 then
				return
			end
			local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
			local ch3 = Config.Chapter3.Waves
			if wave < ch3.From or wave > ch3.Until then
				return
			end
			local breached = ctx.stateFolder ~= nil and ctx.stateFolder:GetAttribute("Ch3FenceBreached") == true
			local gap = if breached
				then math.max(0.25, Spawning.currentStats().gap)
				else math.max(0.35, r10.OutsideSpawnGap)
			Spawning.spawnChapter3FenceApproachZombie()
			task.wait(gap)
		end
	end)
end

return Spawning
