local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.Parent.ZombieService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local CombatService = require(script.Parent.Parent.CombatService)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Character = require(script.Parent.Character)
local Spawning = require(script.Parent.Spawning)
local Gates = require(script.Parent.Gates)
local Lifecycle = require(script.Parent.Lifecycle)
local Combat = require(script.Parent.Combat)
local EventFlags = require(script.Parent.EventFlags)
local Chapter1 = require(script.Parent.RoundTimeline.Chapter1)
local Chapter2 = require(script.Parent.RoundTimeline.Chapter2)
local Chapter3 = require(script.Parent.RoundTimeline.Chapter3)
local FinalBossR15 = require(script.Parent.FinalBossR15)

local ctx = Context
local setState = StateSync.setState
local shiftPausedTimers = StateSync.shiftPausedTimers
local getLeaderPosition = Character.getLeaderPosition
local isLanePhase = Character.isLanePhase
local currentStats = Spawning.currentStats
local spawnOne = Spawning.spawnOne
local applyRoundFeatures = Gates.applyRoundFeatures
local beginChapterClear = Lifecycle.beginChapterClear
local restoreGun = Combat.restoreGun
local tryFire = Combat.tryFire
local applySpikeDamage = Combat.applySpikeDamage
local Ev = EventFlags

local Heartbeat = {}

function Heartbeat.connect()
	if ctx.heartbeatConn then
		ctx.heartbeatConn:Disconnect()
	end

	ctx.heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local playerPos = getLeaderPosition()

		if ctx.phase == "playing" and ctx.paused then
  			shiftPausedTimers(dt)
  			return
  		end
		if ctx.phase == "reviveChoice" then
			shiftPausedTimers(dt)
			return
		end

  		if ctx.phase == "playing" then
  			local elapsed = math.floor(now - ctx.matchStart)
  			if (ctx.stateFolder:GetAttribute("Elapsed") or 0) ~= elapsed then
  				setState("Elapsed", elapsed)
  			end
  			local wave = Config.waveFromElapsed(elapsed, Config.chapter())
  			if (ctx.stateFolder:GetAttribute("Wave") or 1) ~= wave then
  				setState("Wave", wave)
  			end
  			applyRoundFeatures(wave)
  			if (Config.chapter() <= 1
  					and wave >= Config.FinalBoss.Round
  					and ctx.finalBossSpawned
  					and #ZombieService.getAlive() == 0)
  				or (Config.chapter() == 2
  					and Config.chapterRound(wave) == Config.Chapter2.Round10.Round
  					and Ev.Ch2.R10BossSpawned
  					and #ZombieService.getAlive() == 0)
  			then
  				beginChapterClear()
  			elseif Config.chapter() == 3
  				and Config.chapterRound(wave) == Config.Chapter3.Round15.Round
  				and Ev.Ch3.R15BossSpawned
  				and not Ev.Ch3.R15Cleared
  			then
  				local bossAlive = false
  				for _, record in ZombieService.getAlive() do
  					if record.model:GetAttribute("IsFinalBoss") == true then
  						bossAlive = true
  						break
  					end
  				end
  				if not bossAlive then
  					Ev.Ch3.R15Cleared = true
  					ZombieService.clear()
  					beginChapterClear()
  				end
  			end
  		end

  		if isLanePhase() then
  			for _, data in ctx.playerData do
  				local character = data.character
  				if not character then
  					continue
  				end
  				local root = character:FindFirstChild("HumanoidRootPart")
  				local humanoid = character:FindFirstChildOfClass("Humanoid")
  				if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
  					continue
  				end

  				humanoid.WalkSpeed = 0
  				humanoid.JumpPower = 0
  				humanoid.JumpHeight = 0
  				humanoid.AutoRotate = false

  				local lane = Config.activeLane()
  				local standY = Config.playerStandY()
  				local minX, maxX = Config.laneXBounds()
  				-- Camera looks toward +Z, so D (screen-right) moves toward world -X / side path.
  				local x = math.clamp(
  					root.Position.X - data.strafe * Config.Player.StrafeSpeed * math.max(0.05, ctx.windSpeedScale or 1) * dt,
  					minX,
  					maxX
  				)
  				root.CFrame = CFrame.lookAt(
  					Vector3.new(x, standY, lane.PlayerZ),
  					Vector3.new(x, standY, lane.PlayerZ + 12)
  				)
  			end
  		end

  		if ctx.phase == "playing" then
  			local stats = currentStats()
  			local waveNow = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
  			local holdSpawns = (Config.chapter() <= 1
  					and waveNow >= Config.FinalBoss.Round
  					and ctx.finalBossSpawned
  					and (function()
  						for _, record in ZombieService.getAlive() do
  							if record.model:GetAttribute("IsFinalBoss") == true then
  								return false
  							end
  						end
  						return true
  					end)())
  				or (Config.chapter() == 2
  					and Config.chapterRound(waveNow) == Config.Chapter2.Round10.Round
  					and Ev.Ch2.R10BossSpawned
  					and (function()
  						for _, record in ZombieService.getAlive() do
  							if record.model:GetAttribute("IsFinalBoss") == true then
  								return false
  							end
  						end
  						return true
  					end)())
  			if not holdSpawns and ZombieService.countForSpawnCap() < stats.maxAlive and now - ctx.lastSpawnAt >= stats.gap then
  				ctx.lastSpawnAt = now
  				spawnOne()
  			end


			local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
			if Config.chapter() <= 1 then
				Chapter1.tick(now, wave)
			end
			if Config.chapter() == 2 then
				Chapter2.tick(now, wave)
			end
			if Config.chapter() == 3 then
				Chapter3.tick(now, wave)
			end

  			local bombLeft = 0
  			local sniperLeft = 0
  			local shotgunLeft = 0
  			for _, data in ctx.playerData do
  				if data.hadBomb then
  					if now >= data.bombUntil then
  						restoreGun(data)
  					else
  						bombLeft = math.max(bombLeft, math.ceil(data.bombUntil - now))
  					end
  				end
  				if data.hadSniper then
  					if now >= data.sniperUntil then
  						restoreGun(data)
  					else
  						sniperLeft = math.max(sniperLeft, math.ceil(data.sniperUntil - now))
  					end
  				end
  				if data.hadShotgun then
  					if now >= data.shotgunUntil then
  						restoreGun(data)
  					else
  						shotgunLeft = math.max(shotgunLeft, math.ceil(data.shotgunUntil - now))
  					end
  				end
  			end
  			if (ctx.stateFolder:GetAttribute("BombLeft") or 0) ~= bombLeft then
  				setState("BombLeft", bombLeft)
  			end
  			if (ctx.stateFolder:GetAttribute("SniperLeft") or 0) ~= sniperLeft then
  				setState("SniperLeft", sniperLeft)
  			end
  			if (ctx.stateFolder:GetAttribute("ShotgunLeft") or 0) ~= shotgunLeft then
  				setState("ShotgunLeft", shotgunLeft)
  			end

  			local leaderStrafe = 0
  			for _, data in ctx.playerData do
  				if math.abs(data.strafe) > math.abs(leaderStrafe) then
  					leaderStrafe = data.strafe
  				end
  			end

  			FinalBossR15.tick(dt)
  			ZombieService.update(dt, playerPos)
  			SupplyService.update(dt, playerPos, leaderStrafe)
  			NumberGate.update(dt, playerPos)
  			SpikeTrap.update(dt)
  			applySpikeDamage(dt)
  			tryFire(now)
  			CombatService.update(dt)
		elseif ctx.phase == "chapterClear" then
			SupplyService.update(dt, playerPos, 0)
		end
	end)
end

return Heartbeat
