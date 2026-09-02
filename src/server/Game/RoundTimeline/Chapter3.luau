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
 						SupplyService.createMolotov(true, nil, nil, r2.MolotovGrantCount)
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
 			end
end

return Chapter3
