local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local Context = require(script.Parent.Parent.Context)
local Spawning = require(script.Parent.Parent.Spawning)

local ctx = Context
local markSidePathSpawn = Spawning.markSidePathSpawn
local delayBombAfterGate = Spawning.delayBombAfterGate
local sidePathReady = Spawning.sidePathReady

local Chapter1 = {}

function Chapter1.tick(now: number, wave: number)
 			if Config.chapter() <= 1 then
 			local supplyCfg = Config.Supply
 			if wave >= supplyCfg.UnlockRound then
 				if not ctx.supplyRoundArmed then
 					ctx.supplyRoundArmed = true
 					ctx.lastSupplySpawnAt = now - supplyCfg.SpawnInterval + supplyCfg.FirstSpawnDelay
 				end
 				if (now - ctx.lastSupplySpawnAt) >= supplyCfg.SpawnInterval and SupplyService.canSpawn() then
 					ctx.lastSupplySpawnAt = now
 					SupplyService.create()
 				end
 			end
 			if wave >= Config.NumberGate.PlayRound then
 				if not ctx.gatePlayArmed then
 					ctx.gatePlayArmed = true
 					if NumberGate.createRandom() then
 						ctx.lastGateSpawnAt = now
 						markSidePathSpawn()
 						delayBombAfterGate()
 					else
 						ctx.lastGateSpawnAt = now - Config.NumberGate.SpawnInterval
 					end
 				elseif (now - ctx.lastGateSpawnAt) >= Config.NumberGate.SpawnInterval
 					and sidePathReady(now)
 					and NumberGate.canSpawn()
 				then
 					ctx.lastGateSpawnAt = now
 					markSidePathSpawn()
 					NumberGate.createRandom()
 				end
 			end

 			if wave >= Config.BombCrate.UnlockRound and wave < Config.FinalBoss.Round then
 				if not ctx.bombRoundArmed then
 					ctx.bombRoundArmed = true
 					ctx.lastBombSpawnAt = now - Config.BombCrate.SpawnInterval + Config.BombCrate.FirstSpawnDelay
 				end
 				if (now - ctx.lastBombSpawnAt) >= Config.BombCrate.SpawnInterval
 					and sidePathReady(now)
 					and SupplyService.canSpawnBomb()
 				then
 					ctx.lastBombSpawnAt = now
 					markSidePathSpawn()
 					SupplyService.createBomb()
 				end
 			end
 			end
end

return Chapter1
