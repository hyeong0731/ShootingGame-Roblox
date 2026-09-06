local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local SpikeTrap = require(script.Parent.Parent.Parent.SpikeTrap)
local Dmz = require(script.Parent.Parent.Parent.Dmz)
local ZombieService = require(script.Parent.Parent.Parent.ZombieService)
local Context = require(script.Parent.Parent.Context)
local StateSync = require(script.Parent.Parent.StateSync)
local Spawning = require(script.Parent.Parent.Spawning)
local EventFlags = require(script.Parent.Parent.EventFlags)

local ctx = Context
local setState = StateSync.setState
local waveLocalElapsed = Spawning.waveLocalElapsed
local Ev = EventFlags

local Chapter3 = {}

function Chapter3.tick(now: number, wave: number)
 			if Config.chapter() == 3 then
 				local r1 = Config.Chapter3.Round1
 				local r2 = Config.Chapter3.Round2
 				local r3 = Config.Chapter3.Round3
 				local r4 = Config.Chapter3.Round4
 				local round = Config.chapterRound(wave)
 				local t = waveLocalElapsed(wave)
 				if round ~= r3.Round and Ev.Ch3.R3FogActive then
 					Ev.Ch3.R3FogActive = false
 					setState("Ch3FogActive", false)
 				end
				-- 강풍 종료/라운드 이탈 시 연사·이동 반드시 원상복구
				local r9wind = Config.Chapter3.Round9
				local windStuck = Ev.Ch3.R9WindActive or (ctx.windSpeedScale or 1) < 0.99
				if windStuck then
					local endAt = if Ev.Ch3.R9WindEndAt > 0
						then Ev.Ch3.R9WindEndAt
						else r9wind.WindAt + r9wind.WindDuration
					if round ~= r9wind.Round or t >= endAt then
						Ev.Ch3.R9WindActive = false
						Ev.Ch3.R9WindEndAt = 0
						ctx.windSpeedScale = 1
						setState("Ch3WindActive", false)
						setState("Ch3WindLeft", 0)
					end
				end
 				if round == r1.Round then
 					if t >= r1.ShotgunAt and not Ev.Ch3.R1ShotgunSpawned then
 						Ev.Ch3.R1ShotgunSpawned = true
 						SupplyService.createShotgun(true, r1.ShotgunHitCountMin, r1.ShotgunHitCountMax)
 					end
 					if t >= r1.SpikeAt and not Ev.Ch3.R1SpikeSpawned then
 						Ev.Ch3.R1SpikeSpawned = true
 						SpikeTrap.create()
 					end
 					if t >= r1.SniperAt and not Ev.Ch3.R1SniperSpawned then
 						Ev.Ch3.R1SniperSpawned = true
 						SupplyService.createSniper(true, r1.SniperHitCountMin, r1.SniperHitCountMax)
 					end
 					if t >= r1.PlusAt and not Ev.Ch3.R1PlusSpawned then
 						Ev.Ch3.R1PlusSpawned = true
 						NumberGate.createPlus(r1.PlusHitCountMin, r1.PlusHitCountMax, true)
 					end
 					if t >= r1.Shotgun2At and not Ev.Ch3.R1Shotgun2Spawned then
 						Ev.Ch3.R1Shotgun2Spawned = true
 						SupplyService.createShotgun(true, r1.Shotgun2HitCountMin, r1.Shotgun2HitCountMax)
 					end
 				end
 				if round == r2.Round then
 					if t >= r2.MinusAt and not Ev.Ch3.R2MinusSpawned then
 						Ev.Ch3.R2MinusSpawned = true
 						NumberGate.createMinus(
 							r2.MinusHitCountMin,
 							r2.MinusHitCountMax,
 							true,
 							r2.MinusWalkSpeedScale
 						)
 					end
 					if t >= r2.BombAt and not Ev.Ch3.R2BombSpawned then
 						Ev.Ch3.R2BombSpawned = true
 						SupplyService.createBomb(true, r2.BombHitCountMin, r2.BombHitCountMax)
 					end
 					if t >= r2.BigZombieRightAt and not Ev.Ch3.R2BigRightSpawned then
 						Ev.Ch3.R2BigRightSpawned = true
 						Spawning.spawnChapter3BigZombie(r2.BigZombieRightX)
 					end
 					if t >= r2.BigZombieLeftAt and not Ev.Ch3.R2BigLeftSpawned then
 						Ev.Ch3.R2BigLeftSpawned = true
 						Spawning.spawnChapter3BigZombie(r2.BigZombieLeftX)
 					end
 					if t >= r2.MolotovAt and not Ev.Ch3.R2MolotovSpawned then
 						Ev.Ch3.R2MolotovSpawned = true
 						SupplyService.createMolotov(
 							true,
 							r2.MolotovHitCountMin,
 							r2.MolotovHitCountMax,
 							r2.MolotovGrantCount
 						)
 					end
 					if t >= r2.DogSwarmAt and not Ev.Ch3.R2DogSwarmSpawned then
 						Ev.Ch3.R2DogSwarmSpawned = true
 						Spawning.spawnChapter3DogSwarm(r2.DogSwarmCount)
 					end
 					if t >= r2.SpikeAt and not Ev.Ch3.R2SpikeSpawned then
 						Ev.Ch3.R2SpikeSpawned = true
 						SpikeTrap.create()
 					end
 					if t >= r2.SniperAt and not Ev.Ch3.R2SniperSpawned then
 						Ev.Ch3.R2SniperSpawned = true
 						SupplyService.createSniper(true, r2.SniperHitCountMin, r2.SniperHitCountMax)
 					end
 				end
 				if round == r3.Round then
 					local fogCfg = Config.Chapter3.Fog
 					if t >= r3.FogWarnAt and not Ev.Ch3.R3FogWarnShown then
 						Ev.Ch3.R3FogWarnShown = true
 						setState("Announce", fogCfg.WarnText)
 						task.delay(r3.FogStartAt - r3.FogWarnAt, function()
 							if (ctx.stateFolder:GetAttribute("Announce") or "") == fogCfg.WarnText then
 								setState("Announce", "")
 							end
 						end)
 					end
 					if t >= r3.FogStartAt and not Ev.Ch3.R3FogActive then
 						Ev.Ch3.R3FogActive = true
 						Ev.Ch3.R3FogEndAt = t + r3.FogDuration
 						setState("Ch3FogActive", true)
 					end
 					if Ev.Ch3.R3FogActive and t >= Ev.Ch3.R3FogEndAt then
 						Ev.Ch3.R3FogActive = false
 						setState("Ch3FogActive", false)
 					end
 					if t >= r3.SniperAt and not Ev.Ch3.R3SniperSpawned then
 						Ev.Ch3.R3SniperSpawned = true
 						SupplyService.createSniper(true, r3.SniperHitCountMin, r3.SniperHitCountMax)
 					end
 					if t >= r3.X2At and not Ev.Ch3.R3X2Spawned then
 						Ev.Ch3.R3X2Spawned = true
 						NumberGate.createX2(r3.X2HitCountMin, r3.X2HitCountMax, true)
 					end
 					if t >= r3.X2RetryAt and not Ev.Ch3.R3X2RetrySpawned and not Ev.Ch3.R3X2Collected then
 						Ev.Ch3.R3X2RetrySpawned = true
 						NumberGate.createX2(r3.X2HitCountMin, r3.X2HitCountMax, true)
 					end
 					if t >= r3.SpikeAt and not Ev.Ch3.R3SpikeSpawned then
 						Ev.Ch3.R3SpikeSpawned = true
 						local lane = Config.activeLane()
 						local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
 						local half = Config.SpikeTrap.Size * 0.5
 						SpikeTrap.create(minX + half * 0.4)
 						task.spawn(function()
 							task.wait(r3.SpikeRightDelay)
 							if ctx.phase ~= "playing" then
 								return
 							end
 							SpikeTrap.create(maxX - half * 0.4)
 						end)
 					end
 				end
 				if round == r4.Round then
 					if t >= r4.AllyAt and not Ev.Ch3.R4AllySpawned then
 						Ev.Ch3.R4AllySpawned = true
 						SupplyService.create(true, r4.AllyHitCountMin, r4.AllyHitCountMax)
 					end
 					if t >= r4.FireBoostAt and not Ev.Ch3.R4FireBoostSpawned then
 						Ev.Ch3.R4FireBoostSpawned = true
 						SupplyService.createFireBoost(true)
 					end
 					if t >= r4.BigZombieAt and not Ev.Ch3.R4BigSwarmStarted then
 						Ev.Ch3.R4BigSwarmStarted = true
 						Spawning.spawnChapter3BigZombieSwarm(r4.BigZombieCount, r4.BigZombieGap, r4)
 					end
 					if t >= r4.PlusAt and not Ev.Ch3.R4PlusSpawned then
 						Ev.Ch3.R4PlusSpawned = true
 						NumberGate.createPlus(r4.PlusHitCountMin, r4.PlusHitCountMax, true)
 					end
 					if t >= r4.DogSwarmAt and not Ev.Ch3.R4DogSwarmStarted then
 						Ev.Ch3.R4DogSwarmStarted = true
 						Spawning.spawnChapter3DogSwarmEven(r4.DogSwarmCount, r4.DogSwarmGap)
 					end
 				end
 				local r5 = Config.Chapter3.Round5
 				if round == r5.Round then
 					if t >= r5.FlashbangAt and not Ev.Ch3.R5FlashbangSpawned then
 						Ev.Ch3.R5FlashbangSpawned = true
 						SupplyService.createFlashbang(
 							true,
 							r5.FlashbangHitCountMin,
 							r5.FlashbangHitCountMax,
 							r5.FlashbangGrantCount
 						)
 					end
 					if t >= r5.SniperAt and not Ev.Ch3.R5SniperSpawned then
 						Ev.Ch3.R5SniperSpawned = true
 						SupplyService.createSniper(true, r5.SniperHitCount, r5.SniperHitCount)
 					end
 					if t >= r5.HordeStartAt and not Ev.Ch3.R5HordeActive then
 						Ev.Ch3.R5HordeActive = true
 					end
 					if t >= r5.ShotgunAt and not Ev.Ch3.R5ShotgunSpawned then
 						Ev.Ch3.R5ShotgunSpawned = true
 						SupplyService.createShotgun(true, r5.ShotgunHitCountMin, r5.ShotgunHitCountMax)
 					end
 					if t >= r5.MinusAt and not Ev.Ch3.R5MinusSpawned then
 						Ev.Ch3.R5MinusSpawned = true
 						NumberGate.createMinus(
 							r5.MinusHitCountMin,
 							r5.MinusHitCountMax,
 							true,
 							r5.MinusWalkSpeedScale
 						)
 					end
 					if t >= r5.MidBossAt and not Ev.Ch3.R5MidBossSpawned then
 						Ev.Ch3.R5MidBossSpawned = true
 						Spawning.spawnChapter3MidBoss()
 					end
 					if t >= r5.ThrowerWaveAt and not Ev.Ch3.R5ThrowerWaveStarted then
 						Ev.Ch3.R5ThrowerWaveStarted = true
 						Spawning.spawnChapter3ThrowerWave(r5.ThrowerWaveCount, r5.ThrowerWaveGap)
 					end
 					if t >= r5.SpikeAt and not Ev.Ch3.R5SpikeSpawned then
 						Ev.Ch3.R5SpikeSpawned = true
 						local lane = Config.activeLane()
 						local minX, _maxX = Config.zombieXBounds(lane.SpawnZ)
 						local half = Config.SpikeTrap.Size * 0.5
 						SpikeTrap.create(minX + half * 0.4)
 					end
 				end
 				local r6 = Config.Chapter3.Round6
 				if round == r6.Round then
 					if t >= r6.ShieldPackAt and not Ev.Ch3.R6ShieldPackStarted then
 						Ev.Ch3.R6ShieldPackStarted = true
 						Spawning.spawnChapter3ShieldPack(
 							r6.ShieldPackCount,
 							r6.ShieldPackGap,
 							Config.Chapter3.ShieldHitCountMin,
 							Config.Chapter3.ShieldHitCountMax
 						)
 					end
 					if t >= r6.PlusAt and not Ev.Ch3.R6PlusSpawned then
 						Ev.Ch3.R6PlusSpawned = true
 						NumberGate.createPlus(r6.PlusHitCount, r6.PlusHitCount, true)
 					end
 					if t >= r6.MineAt[1] and not Ev.Ch3.R6Mine0 then
 						Ev.Ch3.R6Mine0 = true
 						Spawning.spawnChapter3MineZombie()
 					end
 					if t >= r6.SniperAt and not Ev.Ch3.R6SniperSpawned then
 						Ev.Ch3.R6SniperSpawned = true
 						SupplyService.createSniper(true, r6.SniperHitCount, r6.SniperHitCount)
 					end
 					if t >= r6.MineAt[2] and not Ev.Ch3.R6Mine15 then
 						Ev.Ch3.R6Mine15 = true
 						Spawning.spawnChapter3MineZombie()
 					end
 					if t >= r6.MineAt[3] and not Ev.Ch3.R6Mine30 then
 						Ev.Ch3.R6Mine30 = true
 						Spawning.spawnChapter3MineZombie()
 					end
 					if t >= r6.MolotovAt and not Ev.Ch3.R6MolotovSpawned then
 						Ev.Ch3.R6MolotovSpawned = true
 						SupplyService.createMolotov(
 							true,
 							r6.MolotovHitCount,
 							r6.MolotovHitCount,
 							r6.MolotovGrantCount
 						)
 					end
 					if t >= r6.BombAt and not Ev.Ch3.R6BombSpawned then
 						Ev.Ch3.R6BombSpawned = true
 						SupplyService.createBomb(true, r6.BombHitCount, r6.BombHitCount)
 					end
 					if t >= r6.MinePairAt and not Ev.Ch3.R6Mine50 then
 						Ev.Ch3.R6Mine50 = true
 						Spawning.spawnChapter3MineWave(r6.MinePairCount)
 					end
					if t >= r6.ThrowerDogAt and not Ev.Ch3.R6ThrowerDogStarted then
						Ev.Ch3.R6ThrowerDogStarted = true
						Spawning.spawnChapter3ThrowerAndDogWave(
							r6.ThrowerCount,
							r6.DogCount,
							r6.ThrowerDogGap
						)
					end
				end
				local r7 = Config.Chapter3.Round7
				if round == r7.Round then
					if t >= r7.BombAt and not Ev.Ch3.R7BombSpawned then
						Ev.Ch3.R7BombSpawned = true
						SupplyService.createBomb(true, r7.BombHitCount, r7.BombHitCount)
					end
					if t >= r7.ShieldBoostAt and not Ev.Ch3.R7ShieldBoostActive then
						Ev.Ch3.R7ShieldBoostActive = true
					end
					if t >= r7.SpikeAt and not Ev.Ch3.R7SpikeSpawned then
						Ev.Ch3.R7SpikeSpawned = true
						SpikeTrap.create()
					end
					if t >= r7.MineAt[1] and not Ev.Ch3.R7Mine10 then
						Ev.Ch3.R7Mine10 = true
						Spawning.spawnChapter3MineZombie()
					end
					if t >= r7.MinusAt and not Ev.Ch3.R7MinusSpawned then
						Ev.Ch3.R7MinusSpawned = true
						NumberGate.createMinus(
							r7.MinusHitCount,
							r7.MinusHitCount,
							true,
							r7.MinusWalkSpeedScale
						)
					end
					if t >= r7.ThrowerWaveAt and not Ev.Ch3.R7ThrowerWaveStarted then
						Ev.Ch3.R7ThrowerWaveStarted = true
						Spawning.spawnChapter3ThrowerWave(r7.ThrowerWaveCount, r7.ThrowerWaveGap)
					end
					if t >= r7.MineAt[2] and not Ev.Ch3.R7Mine33 then
						Ev.Ch3.R7Mine33 = true
						Spawning.spawnChapter3MineZombie()
					end
					if t >= r7.MidBossAt and not Ev.Ch3.R7MidBossSpawned then
						Ev.Ch3.R7MidBossSpawned = true
						Spawning.spawnChapter3MidBoss(r7.MidBossHitCountMin, r7.MidBossHitCountMax)
					end
					if t >= r7.MidBoss2At and not Ev.Ch3.R7MidBoss2Spawned then
						Ev.Ch3.R7MidBoss2Spawned = true
						Spawning.spawnChapter3MidBoss(r7.MidBoss2HitCountMin, r7.MidBoss2HitCountMax)
					end
				end
				local r8 = Config.Chapter3.Round8
				if round == r8.Round then
					if t >= r8.AllyAt and not Ev.Ch3.R8AllySpawned then
						Ev.Ch3.R8AllySpawned = true
						SupplyService.create(true, r8.AllyHitCountMin, r8.AllyHitCountMax, true)
					end
					if t >= r8.X2At and not Ev.Ch3.R8X2Spawned then
						Ev.Ch3.R8X2Spawned = true
						NumberGate.createX2(r8.X2HitCountMin, r8.X2HitCountMax, true)
					end
					if t >= r8.SniperAt and not Ev.Ch3.R8SniperSpawned then
						Ev.Ch3.R8SniperSpawned = true
						SupplyService.createSniper(true, r8.SniperHitCount, r8.SniperHitCount)
					end
					if t >= r8.MineAt and not Ev.Ch3.R8Mine25 then
						Ev.Ch3.R8Mine25 = true
						Spawning.spawnChapter3MineZombie()
					end
					if t >= r8.X2RetryAt and not Ev.Ch3.R8X2RetrySpawned and not Ev.Ch3.R8X2Collected then
						Ev.Ch3.R8X2RetrySpawned = true
						NumberGate.createX2(r8.X2HitCountMin, r8.X2HitCountMax, true)
					end
					if t >= r8.PlusAt and not Ev.Ch3.R8PlusSpawned then
						Ev.Ch3.R8PlusSpawned = true
						NumberGate.createPlus(r8.PlusHitCountMin, r8.PlusHitCountMax, true)
					end
					if t >= r8.MolotovAt and not Ev.Ch3.R8MolotovSpawned then
						Ev.Ch3.R8MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							r8.MolotovHitCountMin,
							r8.MolotovHitCountMax,
							r8.MolotovGrantCount
						)
					end
					if t >= r8.MixedWaveAt and not Ev.Ch3.R8MixedWaveStarted then
						Ev.Ch3.R8MixedWaveStarted = true
						Spawning.spawnChapter3TimedMix(
							r8.MixedWaveNormal,
							r8.MixedWaveDog,
							r8.MixedWaveBig,
							r8.MixedWaveShield,
							r8.MixedWaveDuration,
							r8.ShieldHitCountMin,
							r8.ShieldHitCountMax
						)
					end
				end
				local r9 = Config.Chapter3.Round9
				if round == r9.Round then
					if t >= r9.FlashbangAt and not Ev.Ch3.R9FlashbangSpawned then
						Ev.Ch3.R9FlashbangSpawned = true
						SupplyService.createFlashbang(
							true,
							r9.FlashbangHitCountMin,
							r9.FlashbangHitCountMax,
							r9.FlashbangGrantCount
						)
					end
					if t >= r9.SniperAt and not Ev.Ch3.R9SniperSpawned then
						Ev.Ch3.R9SniperSpawned = true
						SupplyService.createSniper(true, r9.SniperHitCount, r9.SniperHitCount)
					end
					if t >= r9.WindWarnAt and not Ev.Ch3.R9WindWarned then
						Ev.Ch3.R9WindWarned = true
						setState("Announce", r9.WindWarnText)
						task.delay(r9.WindAt - r9.WindWarnAt, function()
							if (ctx.stateFolder:GetAttribute("Announce") or "") == r9.WindWarnText then
								setState("Announce", "")
							end
						end)
					end
					if t >= r9.WindAt and not Ev.Ch3.R9WindActive then
						Ev.Ch3.R9WindActive = true
						Ev.Ch3.R9WindEndAt = t + r9.WindDuration
						ctx.windSpeedScale = r9.WindSpeedScale
						setState("Ch3WindActive", true)
						setState("Ch3WindLeft", r9.WindDuration)
					end
					if Ev.Ch3.R9WindActive then
						local remaining = Ev.Ch3.R9WindEndAt - t
						if t >= Ev.Ch3.R9WindEndAt then
							Ev.Ch3.R9WindActive = false
							ctx.windSpeedScale = 1
							setState("Ch3WindActive", false)
							setState("Ch3WindLeft", 0)
						else
							setState("Ch3WindLeft", math.ceil(remaining))
						end
					end
					if t >= r9.MidBossAt and not Ev.Ch3.R9MidBossSpawned then
						Ev.Ch3.R9MidBossSpawned = true
						Spawning.spawnChapter3MidBoss(r9.MidBossHitCountMin, r9.MidBossHitCountMax)
					end
					if t >= r9.MineAt and not Ev.Ch3.R9Mine30 then
						Ev.Ch3.R9Mine30 = true
						Spawning.spawnChapter3MineZombie()
					end
					if t >= r9.MinusAt and not Ev.Ch3.R9MinusSpawned then
						Ev.Ch3.R9MinusSpawned = true
						NumberGate.createMinus(
							r9.MinusHitCount,
							r9.MinusHitCount,
							true,
							r9.MinusWalkSpeedScale
						)
					end
					if t >= r9.SpikeAt and not Ev.Ch3.R9SpikeSpawned then
						Ev.Ch3.R9SpikeSpawned = true
						SpikeTrap.create()
					end
					if t >= r9.MixedWaveAt and not Ev.Ch3.R9MixedWaveStarted then
						Ev.Ch3.R9MixedWaveStarted = true
						Spawning.spawnChapter3TimedMix(
							r9.MixedWaveNormal,
							r9.MixedWaveDog,
							r9.MixedWaveBig,
							r9.MixedWaveShield,
							r9.MixedWaveDuration,
							Config.Chapter3.Round8.ShieldHitCountMin,
							Config.Chapter3.Round8.ShieldHitCountMax
						)
					end
				end
				local r10 = Config.Chapter3.Round10
				if round == r10.Round then
					if t >= r10.Div2At and not Ev.Ch3.R10Div2Spawned then
						Ev.Ch3.R10Div2Spawned = true
						NumberGate.createDiv2(
							r10.Div2HitCount,
							r10.Div2HitCount,
							true,
							r10.Div2WalkSpeedScale
						)
					end
					if t >= r10.ShotgunAt and not Ev.Ch3.R10ShotgunSpawned then
						Ev.Ch3.R10ShotgunSpawned = true
						SupplyService.createShotgun(true, r10.ShotgunHitCount, r10.ShotgunHitCount)
					end
					if t >= r10.PlusAt and not Ev.Ch3.R10PlusSpawned then
						Ev.Ch3.R10PlusSpawned = true
						NumberGate.createPlus(r10.PlusHitCountMin, r10.PlusHitCountMax, true)
					end
					if t >= r10.MinePairAt and not Ev.Ch3.R10MinePairSpawned then
						Ev.Ch3.R10MinePairSpawned = true
						Spawning.spawnChapter3MineWave(r10.MinePairCount)
					end
					if t >= r10.FlashbangAt and not Ev.Ch3.R10FlashbangSpawned then
						Ev.Ch3.R10FlashbangSpawned = true
						SupplyService.createFlashbang(
							true,
							r10.FlashbangHitCountMin,
							r10.FlashbangHitCountMax,
							r10.FlashbangGrantCount
						)
					end
					if t >= r10.SpikeAt and not Ev.Ch3.R10SpikeSpawned then
						Ev.Ch3.R10SpikeSpawned = true
						SpikeTrap.create()
					end
					if t >= r10.DogSwarmAt and not Ev.Ch3.R10DogSwarmSpawned then
						Ev.Ch3.R10DogSwarmSpawned = true
						Spawning.spawnChapter3DogSwarm(r10.DogSwarmCount, r10.DogSwarmDuration, {
							includeLeft = true,
							ignoreSpawnCap = true,
						})
					end
					if t >= r10.OutsideSpawnAt and not Ev.Ch3.R10OutsideStarted then
						Ev.Ch3.R10OutsideStarted = true
						Spawning.startChapter3FenceApproachWave()
					end
					if t >= r10.BreachAt and not Ev.Ch3.R10FenceBreached then
						Ev.Ch3.R10FenceBreached = true
						setState("Ch3FenceBreached", true)
						setState("Announce", r10.BreachWarnText)
						task.delay(2.2, function()
							if (ctx.stateFolder:GetAttribute("Announce") or "") == r10.BreachWarnText then
								setState("Announce", "")
							end
						end)
						Dmz.breachLeftFence(r10.FencePileZ, r10.BreachGapHalf)
						ZombieService.releaseFencePiles()
					end
				end
				local r11 = Config.Chapter3.Round11
				if round == r11.Round then
					if t >= r11.BarricadeAt and not Ev.Ch3.R11BarricadeSpawned then
						Ev.Ch3.R11BarricadeSpawned = true
						SupplyService.createBarricade(
							true,
							r11.BarricadeHitCountMin,
							r11.BarricadeHitCountMax,
							r11.BarricadeGrantCount
						)
					end
					if t >= r11.BigAt and not Ev.Ch3.R11BigSpawned then
						Ev.Ch3.R11BigSpawned = true
						Spawning.spawnChapter3BigZombieSwarm(r11.BigCount, r11.BigGap, {
							BigZombieSizeScale = r11.BigZombieSizeScale,
							BigZombieHealthMult = r11.BigZombieHealthMult,
							BigZombieSpeedScale = r11.BigZombieSpeedScale,
						})
					end
					if t >= r11.SniperAt and not Ev.Ch3.R11SniperSpawned then
						Ev.Ch3.R11SniperSpawned = true
						SupplyService.createSniper(true, r11.SniperHitCountMin, r11.SniperHitCountMax)
					end
					if t >= r11.MineAt and not Ev.Ch3.R11MineSpawned then
						Ev.Ch3.R11MineSpawned = true
						Spawning.spawnChapter3MineWave(1)
					end
					if t >= r11.ShotgunAt and not Ev.Ch3.R11ShotgunSpawned then
						Ev.Ch3.R11ShotgunSpawned = true
						SupplyService.createShotgun(true, r11.ShotgunHitCountMin, r11.ShotgunHitCountMax)
					end
					if t >= r11.MidBossAt and not Ev.Ch3.R11MidBossSpawned then
						Ev.Ch3.R11MidBossSpawned = true
						Spawning.spawnChapter3MidBoss(r11.MidBossHitCountMin, r11.MidBossHitCountMax, {
							scale = r11.MidBossSizeScale,
							walkSpeed = r11.MidBossWalkSpeed,
							contactDamage = r11.MidBossContactDamage,
						})
					end
					if t >= r11.ShieldLineAt and not Ev.Ch3.R11ShieldLineSpawned then
						Ev.Ch3.R11ShieldLineSpawned = true
						Spawning.spawnChapter3ShieldLine(
							r11.ShieldLineCount,
							r11.ShieldLineHitCountMin,
							r11.ShieldLineHitCountMax
						)
					end
					if t >= r11.ThrowerWaveAt and not Ev.Ch3.R11ThrowerWaveSpawned then
						Ev.Ch3.R11ThrowerWaveSpawned = true
						Spawning.spawnChapter3ThrowerWave(r11.ThrowerWaveCount, r11.ThrowerWaveGap)
					end
					if t >= r11.DogWaveAt and not Ev.Ch3.R11DogWaveSpawned then
						Ev.Ch3.R11DogWaveSpawned = true
						Spawning.spawnChapter3DogSwarmEven(r11.DogWaveCount, r11.DogWaveGap)
					end
				end
				local r12 = Config.Chapter3.Round12
				if round == r12.Round then
					if t >= r12.Plus2At and not Ev.Ch3.R12Plus2Spawned then
						Ev.Ch3.R12Plus2Spawned = true
						NumberGate.createPlus2(r12.Plus2HitCount, r12.Plus2HitCount, true)
					end
					if t >= r12.MineAt and not Ev.Ch3.R12MineSpawned then
						Ev.Ch3.R12MineSpawned = true
						Spawning.spawnChapter3MineWave(1)
					end
					if t >= r12.SpikeAt and not Ev.Ch3.R12SpikeSpawned then
						Ev.Ch3.R12SpikeSpawned = true
						SpikeTrap.create()
					end
					if t >= r12.MolotovAt and not Ev.Ch3.R12MolotovSpawned then
						Ev.Ch3.R12MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							r12.MolotovHitCountMin,
							r12.MolotovHitCountMax,
							r12.MolotovGrantCount
						)
					end
					if t >= r12.ShotgunAt and not Ev.Ch3.R12ShotgunSpawned then
						Ev.Ch3.R12ShotgunSpawned = true
						SupplyService.createShotgun(true, r12.ShotgunHitCountMin, r12.ShotgunHitCountMax)
					end
					if t >= r12.Div2At and not Ev.Ch3.R12Div2Spawned then
						Ev.Ch3.R12Div2Spawned = true
						NumberGate.createDiv2(
							r12.Div2HitCount,
							r12.Div2HitCount,
							true,
							r12.Div2WalkSpeedScale
						)
					end
					if t >= r12.BarricadeAt and not Ev.Ch3.R12BarricadeSpawned then
						Ev.Ch3.R12BarricadeSpawned = true
						SupplyService.createBarricade(
							true,
							r12.BarricadeHitCountMin,
							r12.BarricadeHitCountMax,
							r12.BarricadeGrantCount
						)
					end
					if t >= r12.FlashbangAt and not Ev.Ch3.R12FlashbangSpawned then
						Ev.Ch3.R12FlashbangSpawned = true
						SupplyService.createFlashbang(
							true,
							r12.FlashbangHitCount,
							r12.FlashbangHitCount,
							r12.FlashbangGrantCount
						)
					end
				end
				local r13 = Config.Chapter3.Round13
				if round == r13.Round then
					if t >= r13.SniperAt and not Ev.Ch3.R13SniperSpawned then
						Ev.Ch3.R13SniperSpawned = true
						SupplyService.createSniper(true, r13.SniperHitCountMin, r13.SniperHitCountMax)
					end
					if t >= r13.DogSwarmAt and not Ev.Ch3.R13DogSwarmSpawned then
						Ev.Ch3.R13DogSwarmSpawned = true
						Spawning.spawnChapter3DogSwarm(r13.DogSwarmCount, r13.DogSwarmDuration, {
							includeLeft = true,
							ignoreSpawnCap = true,
						})
					end
				end
				local r14 = Config.Chapter3.Round14
				if round == r14.Round then
					if t >= r14.PlusAt and not Ev.Ch3.R14PlusSpawned then
						Ev.Ch3.R14PlusSpawned = true
						NumberGate.createPlus(r14.PlusHitCountMin, r14.PlusHitCountMax, true)
					end
					if t >= r14.BarricadeAt and not Ev.Ch3.R14BarricadeSpawned then
						Ev.Ch3.R14BarricadeSpawned = true
						SupplyService.createBarricade(
							true,
							r14.BarricadeHitCountMin,
							r14.BarricadeHitCountMax,
							r14.BarricadeGrantCount
						)
					end
					if t >= r14.MineAt and not Ev.Ch3.R14MineSpawned then
						Ev.Ch3.R14MineSpawned = true
						Spawning.spawnChapter3MineZombie()
						Spawning.spawnChapter3MineZombieFromLeft()
					end
					if t >= r14.MidBossAt and not Ev.Ch3.R14MidBossSpawned then
						Ev.Ch3.R14MidBossSpawned = true
						Spawning.spawnChapter3MidBoss(r14.MidBossHitCountMin, r14.MidBossHitCountMax, {
							scale = r14.MidBossSizeScale,
							walkSpeed = r14.MidBossWalkSpeed,
							contactDamage = r14.MidBossContactDamage,
						})
					end
					if t >= r14.BigAt and not Ev.Ch3.R14BigSpawned then
						Ev.Ch3.R14BigSpawned = true
						Spawning.spawnChapter3BigZombieSwarm(r14.BigCount, r14.BigGap, {
							BigZombieSizeScale = r14.BigZombieSizeScale,
							BigZombieHealthMult = r14.BigZombieHealthMult,
							BigZombieSpeedScale = r14.BigZombieSpeedScale,
						})
					end
					if t >= r14.SpikeAt and not Ev.Ch3.R14SpikeSpawned then
						Ev.Ch3.R14SpikeSpawned = true
						Spawning.spawnChapter3SpikeSCurve(r14.SpikeCount, r14.SpikeGap)
					end
				end
				local r15 = Config.Chapter3.Round15
				if round == r15.Round then
					if t >= r15.WarnAt and not Ev.Ch3.R15WarnShown then
						Ev.Ch3.R15WarnShown = true
						setState("Announce", r15.WarnText)
						task.delay(3.2, function()
							if (ctx.stateFolder:GetAttribute("Announce") or "") == r15.WarnText then
								setState("Announce", "")
							end
						end)
					end
					if t >= r15.BossAt and not Ev.Ch3.R15BossSpawned then
						Ev.Ch3.R15BossSpawned = true
						local FinalBossR15 = require(script.Parent.Parent.FinalBossR15)
						FinalBossR15.reset()
						Spawning.spawnChapter3FinalBoss(r15.BossHitCountMin, r15.BossHitCountMax, {
							scale = r15.BossSizeScale,
							walkSpeed = r15.BossWalkSpeed,
							contactDamage = r15.BossContactDamage,
						})
					end
					if t >= r15.SpikeAt and not Ev.Ch3.R15SpikeSpawned then
						Ev.Ch3.R15SpikeSpawned = true
						local lane = Config.activeLane()
						local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
						local half = Config.SpikeTrap.Size * 0.5
						-- 도로 왼쪽 끝 (+X)
						SpikeTrap.create(maxX - half * 0.35)
					end
					if t >= r15.ShotgunAt and not Ev.Ch3.R15ShotgunSpawned then
						Ev.Ch3.R15ShotgunSpawned = true
						SupplyService.createShotgun(true, r15.ShotgunHitCountMin, r15.ShotgunHitCountMax)
					end
					if t >= r15.MineAt and not Ev.Ch3.R15MineSpawned then
						Ev.Ch3.R15MineSpawned = true
						Spawning.spawnChapter3MineZombie()
					end
				end
			end
end

return Chapter3
