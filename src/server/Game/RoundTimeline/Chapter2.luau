local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local Context = require(script.Parent.Parent.Context)
local StateSync = require(script.Parent.Parent.StateSync)
local Spawning = require(script.Parent.Parent.Spawning)
local EventFlags = require(script.Parent.Parent.EventFlags)

local ctx = Context
local setState = StateSync.setState
local waveLocalElapsed = Spawning.waveLocalElapsed
local Ev = EventFlags

local Chapter2 = {}

function Chapter2.tick(now: number, wave: number)
 			if Config.chapter() == 2 then
 				local sniperCfg = Config.SniperCrate
 				if ctx.chapter2PlusDueAt > 0 and not ctx.chapter2PlusSpawned and now >= ctx.chapter2PlusDueAt then
 					ctx.chapter2PlusSpawned = true
 					NumberGate.createPlus(sniperCfg.PlusHitCountMin, sniperCfg.PlusHitCountMax, true)
 				end
 				if ctx.chapter2X2DueAt > 0 and not ctx.chapter2X2Spawned and now >= ctx.chapter2X2DueAt then
 					ctx.chapter2X2Spawned = true
 					NumberGate.createX2(sniperCfg.X2HitCountMin, sniperCfg.X2HitCountMax, true)
 				end

 				local r1 = Config.Chapter2.Round1
 				if Config.chapterRound(wave) == r1.Round then
 					local t = waveLocalElapsed(wave)
 					if t >= r1.SniperAt and not Ev.Ch2.R1SniperSpawned then
 						Ev.Ch2.R1SniperSpawned = true
 						SupplyService.createSniper(true)
 					end
 					if t >= r1.PlusAt and not Ev.Ch2.R1PlusSpawned then
 						Ev.Ch2.R1PlusSpawned = true
 						NumberGate.createPlus(r1.PlusHitCountMin, r1.PlusHitCountMax, true)
 					end
 					if t >= r1.X2At and not Ev.Ch2.R1X2Spawned then
 						Ev.Ch2.R1X2Spawned = true
 						NumberGate.createX2(r1.X2HitCountMin, r1.X2HitCountMax, true)
 					end
 				end

 				local r2 = Config.Chapter2.Round2
 				if Config.chapterRound(wave) == r2.Round then
 					local t = waveLocalElapsed(wave)
 					if t >= r2.MinusAt and not Ev.Ch2.R2MinusSpawned then
 						Ev.Ch2.R2MinusSpawned = true
 						NumberGate.createMinus(r2.MinusHitCountMin, r2.MinusHitCountMax, true)
 					end
 					if t >= r2.BombAt and not Ev.Ch2.R2BombSpawned then
 						Ev.Ch2.R2BombSpawned = true
 						SupplyService.createBomb(true)
 					end
 					if t >= r2.PlusAt and not Ev.Ch2.R2Plus1Spawned then
 						Ev.Ch2.R2Plus1Spawned = true
 						NumberGate.createPlus(r2.PlusHitCountMin, r2.PlusHitCountMax, true)
 					end
 				if t >= r2.SniperAt and not Ev.Ch2.R2SniperSpawned then
 					Ev.Ch2.R2SniperSpawned = true
 					SupplyService.createSniper(true, r2.SniperHitCountMin, r2.SniperHitCountMax)
 				end
 					if t >= r2.PlusAgainAt and not Ev.Ch2.R2Plus2Spawned then
 						Ev.Ch2.R2Plus2Spawned = true
 						NumberGate.createPlus(r2.PlusHitCountMin, r2.PlusHitCountMax, true)
 					end
 				end

 				local r3 = Config.Chapter2.Round3
 				if Config.chapterRound(wave) == r3.Round then
 					local t = waveLocalElapsed(wave)
 					if t >= r3.PlusAt and not Ev.Ch2.R3PlusSpawned then
 						Ev.Ch2.R3PlusSpawned = true
 						NumberGate.createPlus(r3.PlusHitCountMin, r3.PlusHitCountMax, true)
 					end
 					if t >= r3.AllyAt and not Ev.Ch2.R3AllySpawned then
 						Ev.Ch2.R3AllySpawned = true
 						SupplyService.create(true, r3.AllyHitCountMin, r3.AllyHitCountMax)
 					end
 					if t >= r3.CrateAt and not Ev.Ch2.R3Crate1Spawned then
 						Ev.Ch2.R3Crate1Spawned = true
 						SupplyService.createBomb(true)
 					end
 					if t >= r3.MinusAt and not Ev.Ch2.R3Minus1Spawned then
 						Ev.Ch2.R3Minus1Spawned = true
 						NumberGate.createMinus(r3.MinusHitCountMin, r3.MinusHitCountMax, true)
 					end
 				if t >= r3.CrateAgainAt and not Ev.Ch2.R3Crate2Spawned then
 					Ev.Ch2.R3Crate2Spawned = true
 					SupplyService.createSniper(true, r3.SniperHitCountMin, r3.SniperHitCountMax)
 				end
 					if t >= r3.MinusAgainAt and not Ev.Ch2.R3Minus2Spawned then
 						Ev.Ch2.R3Minus2Spawned = true
 						NumberGate.createMinus(r3.MinusHitCountMin, r3.MinusHitCountMax, true)
 					end
 				end

 				local r4 = Config.Chapter2.Round4
 				if Config.chapterRound(wave) == r4.Round then
 					local t = waveLocalElapsed(wave)
 					if t >= r4.AllyAt and not Ev.Ch2.R4AllySpawned then
 						Ev.Ch2.R4AllySpawned = true
 						if not SupplyService.hasRecruitedThisMatch() then
 							SupplyService.create(true, r4.AllyHitCountMin, r4.AllyHitCountMax)
 						end
 					end
 				if t >= r4.CrateAt and not Ev.Ch2.R4CrateSpawned then
 					Ev.Ch2.R4CrateSpawned = true
 					if math.random() < 0.5 then
 						SupplyService.createBomb(true, r4.CrateHitCountMin, r4.CrateHitCountMax)
 					else
 						SupplyService.createSniper(true, r4.CrateHitCountMin, r4.CrateHitCountMax)
 					end
 				end
 					if t >= r4.DogSwarmAt and not Ev.Ch2.R4DogSwarmSpawned then
 						Ev.Ch2.R4DogSwarmSpawned = true
 						Spawning.spawnChapter2DogSwarm(r4.DogSwarmCount)
 					end
 					if t >= r4.X2At and not Ev.Ch2.R4X2Spawned then
 						Ev.Ch2.R4X2Spawned = true
 						NumberGate.createX2(r4.X2HitCountMin, r4.X2HitCountMax, true)
 					end
 					if t >= r4.MinusAt and not Ev.Ch2.R4MinusSpawned then
 						Ev.Ch2.R4MinusSpawned = true
 						NumberGate.createMinus(r4.MinusHitCountMin, r4.MinusHitCountMax, true)
 					end
 				end

 				local r5 = Config.Chapter2.Round5
 				if Config.chapterRound(wave) == r5.Round then
 					local t = waveLocalElapsed(wave)
 					if t >= r5.X2RetryAt and not Ev.Ch2.R5X2RetrySpawned and not Ev.Ch2.R4X2Collected then
 						Ev.Ch2.R5X2RetrySpawned = true
 						NumberGate.createX2(r5.X2HitCountMin, r5.X2HitCountMax, true)
 					end
 					if t >= r5.MidBossAt and not Ev.Ch2.R5MidBoss1Spawned then
 						Ev.Ch2.R5MidBoss1Spawned = true
 						Spawning.spawnChapter2MidBoss(r5.FirstSpawnX)
 					end
 				if t >= r5.MidBossAgainAt and not Ev.Ch2.R5MidBoss2Spawned then
 					Ev.Ch2.R5MidBoss2Spawned = true
 					Spawning.spawnChapter2MidBoss(r5.SecondSpawnX, r5.HitCountMin2, r5.HitCountMax2)
 				end
 					if t >= r5.BombAt and not Ev.Ch2.R5BombSpawned then
 						Ev.Ch2.R5BombSpawned = true
 						SupplyService.createBomb(true, r5.BombHitCountMin, r5.BombHitCountMax)
 					end
 				end

 				local r6 = Config.Chapter2.Round6
 				if Config.chapterRound(wave) == r6.Round then
 					local t = waveLocalElapsed(wave)
 				if t >= r6.SniperAt and not Ev.Ch2.R6SniperSpawned then
 					Ev.Ch2.R6SniperSpawned = true
 					SupplyService.createSniper(true, r6.SniperHitCountMin, r6.SniperHitCountMax)
 				end
 					if t >= r6.Div2At and not Ev.Ch2.R6Div2Spawned then
 						Ev.Ch2.R6Div2Spawned = true
 						NumberGate.createDiv2(
 							r6.Div2HitCountMin,
 							r6.Div2HitCountMax,
 							true,
 							r6.Div2WalkSpeedScale
 						)
 					end
 				if t >= r6.BombAt and not Ev.Ch2.R6BombSpawned then
 					Ev.Ch2.R6BombSpawned = true
 					SupplyService.createBomb(true, r6.BombHitCountMin, r6.BombHitCountMax)
 				end
 					if t >= r6.PlusAt and not Ev.Ch2.R6PlusSpawned then
 						Ev.Ch2.R6PlusSpawned = true
 						NumberGate.createPlus(r6.PlusHitCountMin, r6.PlusHitCountMax, true)
 					end
 					if t >= r6.MolotovAt and not Ev.Ch2.R6MolotovSpawned then
 						Ev.Ch2.R6MolotovSpawned = true
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
 				if t >= r7.SniperAt and not Ev.Ch2.R7SniperSpawned then
 					Ev.Ch2.R7SniperSpawned = true
 					SupplyService.createSniper(true, r7.SniperHitCountMin, r7.SniperHitCountMax)
 				end
 					if t >= r7.PlusAt and not Ev.Ch2.R7PlusSpawned then
 						Ev.Ch2.R7PlusSpawned = true
 						NumberGate.createPlus(r7.PlusHitCountMin, r7.PlusHitCountMax, true)
 					end
 				if t >= r7.BombAt and not Ev.Ch2.R7BombSpawned then
 					Ev.Ch2.R7BombSpawned = true
 					SupplyService.createBomb(true, r7.BombHitCountMin, r7.BombHitCountMax)
 				end
 					if t >= r7.ShieldPackAt and not Ev.Ch2.R7ShieldPackSpawned then
 						Ev.Ch2.R7ShieldPackSpawned = true
 						Spawning.spawnChapter2ShieldPack()
 					end
 				end

 				local r8 = Config.Chapter2.Round8
 				if Config.chapterRound(wave) == r8.Round then
 					local t = waveLocalElapsed(wave)
 					if t >= r8.Div2At and not Ev.Ch2.R8Div2Spawned then
 						Ev.Ch2.R8Div2Spawned = true
 						NumberGate.createDiv2(
 							r8.Div2HitCountMin,
 							r8.Div2HitCountMax,
 							true,
 							r8.Div2WalkSpeedScale
 						)
 					end
 				if t >= r8.SniperAt and not Ev.Ch2.R8SniperSpawned then
 					Ev.Ch2.R8SniperSpawned = true
 					SupplyService.createSniper(true, r8.SniperHitCountMin, r8.SniperHitCountMax)
 				end
 					if t >= r8.X2At and not Ev.Ch2.R8X2Spawned then
 						Ev.Ch2.R8X2Spawned = true
 						NumberGate.createX2(r8.X2HitCountMin, r8.X2HitCountMax, true)
 					end
 				if t >= r8.SniperAgainAt and not Ev.Ch2.R8Sniper2Spawned then
 					Ev.Ch2.R8Sniper2Spawned = true
 					SupplyService.createSniper(true, r8.SniperHitCountMin, r8.SniperHitCountMax)
 				end
 					if t >= r8.MinusAt and not Ev.Ch2.R8MinusSpawned then
 						Ev.Ch2.R8MinusSpawned = true
 						NumberGate.createMinus(r8.MinusHitCountMin, r8.MinusHitCountMax, true)
 					end
 					if t >= r8.X2RetryAt and not Ev.Ch2.R8X2RetrySpawned and not Ev.Ch2.R8X2Collected then
 						Ev.Ch2.R8X2RetrySpawned = true
 						NumberGate.createX2(r8.X2HitCountMin, r8.X2HitCountMax, true)
 					end
 					if t >= r8.SwarmAt and not Ev.Ch2.R8SwarmSpawned then
 						Ev.Ch2.R8SwarmSpawned = true
 						Spawning.spawnChapter2ZombieSwarm()
 					end
 					if t >= r8.PlusAt and not Ev.Ch2.R8PlusSpawned then
 						Ev.Ch2.R8PlusSpawned = true
 						NumberGate.createPlus(r8.PlusHitCountMin, r8.PlusHitCountMax, true)
 					end
 				if t >= r8.BombAt and not Ev.Ch2.R8BombSpawned then
 					Ev.Ch2.R8BombSpawned = true
 					SupplyService.createBomb(true, r8.BombHitCountMin, r8.BombHitCountMax)
 				end
 					if t >= r8.MolotovAt and not Ev.Ch2.R8MolotovSpawned then
 						Ev.Ch2.R8MolotovSpawned = true
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
 					if t >= r9.MidBossAt and not Ev.Ch2.R9MidBossSpawned then
 						Ev.Ch2.R9MidBossSpawned = true
 						Spawning.spawnChapter2SmallMidBoss()
 					end
 					if t >= r9.SniperAt and not Ev.Ch2.R9SniperSpawned then
 						Ev.Ch2.R9SniperSpawned = true
 						SupplyService.createSniper(true, r9.SniperHitCountMin, r9.SniperHitCountMax)
 					end
 					if t >= r9.MinusAt and not Ev.Ch2.R9MinusSpawned then
 						Ev.Ch2.R9MinusSpawned = true
 						NumberGate.createMinus(r9.MinusHitCountMin, r9.MinusHitCountMax, true)
 					end
 					if t >= r9.PlusAt and not Ev.Ch2.R9PlusSpawned then
 						Ev.Ch2.R9PlusSpawned = true
 						NumberGate.createPlus(r9.PlusHitCountMin, r9.PlusHitCountMax, true)
 					end
 					if t >= r9.BombAt and not Ev.Ch2.R9BombSpawned then
 						Ev.Ch2.R9BombSpawned = true
 						SupplyService.createBomb(true, r9.BombHitCountMin, r9.BombHitCountMax)
 					end
 					if t >= r9.ShieldPackAt and not Ev.Ch2.R9ShieldPackSpawned then
 						Ev.Ch2.R9ShieldPackSpawned = true
 						Spawning.spawnChapter2ShieldPack(r9.ShieldPackCount, r9.ShieldHitCountMin, r9.ShieldHitCountMax)
 					end
 				if t >= r9.SniperAgainAt and not Ev.Ch2.R9Sniper2Spawned then
 					Ev.Ch2.R9Sniper2Spawned = true
 					SupplyService.createSniper(true, r9.SniperHitCountMin, r9.SniperHitCountMax)
 				end
 			end

 			local r10 = Config.Chapter2.Round10
 			if Config.chapterRound(wave) == r10.Round then
 				local t = waveLocalElapsed(wave)
 				if not Ev.Ch2.R10IntroShown then
 					Ev.Ch2.R10IntroShown = true
 					setState("Announce", r10.IntroText)
 					task.delay(r10.IntroDuration, function()
 						if (ctx.stateFolder:GetAttribute("Announce") or "") == r10.IntroText then
 							setState("Announce", "")
 						end
 					end)
 				end
 				if t >= r10.OpeningSwarmAt and not Ev.Ch2.R10OpeningSpawned then
 					Ev.Ch2.R10OpeningSpawned = true
 					Spawning.spawnChapter2OpeningSwarm()
 				end
 				if t >= r10.BossAt and not Ev.Ch2.R10BossSpawned then
 					Ev.Ch2.R10BossSpawned = true
 					Spawning.spawnChapter2FinalBoss()
 				end
 				if t >= r10.MidSwarmAt and not Ev.Ch2.R10MidSwarmSpawned then
 					Ev.Ch2.R10MidSwarmSpawned = true
 					Spawning.spawnChapter2MidSwarm(r10.MidSwarmCount)
 				end
 				if t >= r10.SniperAt and not Ev.Ch2.R10SniperSpawned then
 					Ev.Ch2.R10SniperSpawned = true
 					SupplyService.createSniper(true, r10.SniperHitCountMin, r10.SniperHitCountMax)
 				end
 				if t >= r10.HordeAt and not Ev.Ch2.R10HordeSpawned then
 					Ev.Ch2.R10HordeSpawned = true
 					Spawning.spawnChapter2FinalHorde(r10.HordeCount)
 				end
 				if t >= r10.LateHordeAt and not Ev.Ch2.R10LateHordeSpawned then
 					Ev.Ch2.R10LateHordeSpawned = true
 					Spawning.spawnChapter2FinalHorde(r10.LateHordeCount)
 				end
 			end
 		end
end

return Chapter2
