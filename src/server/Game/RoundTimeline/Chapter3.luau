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
 					if t >= r4.MolotovAt and not Ev.Ch3.R4MolotovSpawned then
 						Ev.Ch3.R4MolotovSpawned = true
 						SupplyService.createMolotov(true, nil, nil, r4.MolotovGrantCount)
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
					if t >= r7.MolotovAt and not Ev.Ch3.R7MolotovSpawned then
						Ev.Ch3.R7MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							r7.MolotovHitCount,
							r7.MolotovHitCount,
							r7.MolotovGrantCount
						)
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
						NumberGate.createX2(r8.X2HitCount, r8.X2HitCount, true)
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
						NumberGate.createX2(r8.X2HitCount, r8.X2HitCount, true)
					end
					if t >= r8.PlusAt and not Ev.Ch3.R8PlusSpawned then
						Ev.Ch3.R8PlusSpawned = true
						NumberGate.createPlus(r8.PlusHitCount, r8.PlusHitCount, true)
					end
					if t >= r8.MolotovAt and not Ev.Ch3.R8MolotovSpawned then
						Ev.Ch3.R8MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							r8.MolotovHitCount,
							r8.MolotovHitCount,
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
					if t >= r9.MolotovAt and not Ev.Ch3.R9MolotovSpawned then
						Ev.Ch3.R9MolotovSpawned = true
						SupplyService.createMolotov(
							true,
							r9.MolotovHitCount,
							r9.MolotovHitCount,
							r9.MolotovGrantCount
						)
					end
					if t >= r9.FlashbangAt and not Ev.Ch3.R9FlashbangSpawned then
						Ev.Ch3.R9FlashbangSpawned = true
						SupplyService.createFlashbang(
							true,
							r9.FlashbangHitCount,
							r9.FlashbangHitCount,
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
					end
					if Ev.Ch3.R9WindActive and t >= Ev.Ch3.R9WindEndAt then
						Ev.Ch3.R9WindActive = false
						ctx.windSpeedScale = 1
						setState("Ch3WindActive", false)
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
			end
end

return Chapter3
