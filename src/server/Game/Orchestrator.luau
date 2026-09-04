local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.Parent.ZombieService)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local Gun = require(script.Parent.Parent.Gun)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Lifecycle = require(script.Parent.Lifecycle)
local Combat = require(script.Parent.Combat)
local Debug = require(script.Parent.Debug)
local EventFlags = require(script.Parent.EventFlags)
local Heartbeat = require(script.Parent.Heartbeat)

local ctx = Context
local setState = StateSync.setState
local Ev = EventFlags

local Orchestrator = {}

function Orchestrator.start(remotes)
	CombatService.bind(remotes)

	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if existing and existing:IsA("Folder") then
		ctx.stateFolder = existing
	else
		ctx.stateFolder = Instance.new("Folder")
		ctx.stateFolder.Name = "GameState"
		ctx.stateFolder.Parent = ReplicatedStorage
	end

	setState("Kills", 0)
	setState("Phase", "lobby")
	setState("Paused", false)
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)
	setState("Wave", 1)
	setState("Chapter", 1)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
	setState("MolotovLeft", 0)
	setState("FlashbangLeft", 0)
	setState("HitPower", 1)
	setState("GateLabelScale", Config.NumberGate.LabelScale)
	setState("Announce", "")
	setState("Ch3FogActive", false)
	setState("Ch3WindActive", false)
	setState("Ch3FenceBreached", false)
	ctx.windSpeedScale = 1

	ctx.nextIsBossAt = Config.Boss.EveryNKills

	ZombieService.onDied(function()
		Debug.onZombieDied()
	end)
	ZombieService.onMineExplode(function(position: Vector3)
		local cfg = Config.MineZombie
		if remotes.ExplodeFx then
			remotes.ExplodeFx:FireAllClients(position, cfg.Radius)
		end
		local playerDamageRatio = cfg.PlayerHpPercent / 100
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local delta = root.Position - position
				if delta.X * delta.X + delta.Z * delta.Z <= cfg.Radius * cfg.Radius then
					humanoid:TakeDamage(humanoid.MaxHealth * playerDamageRatio)
				end
			end
		end
		-- 지원군도 플레이어와 동일 비율 피해
		for _, ally in SupplyService.getAllies() do
			if not ally.alive or not ally.model.Parent then
				continue
			end
			local delta = ally.root.Position - position
			if delta.X * delta.X + delta.Z * delta.Z <= cfg.Radius * cfg.Radius then
				SupplyService.damageAlly(ally, ally.humanoid.MaxHealth * playerDamageRatio)
			end
		end
	end)
	ZombieService.onThrow(function(record)
		if ctx.phase ~= "playing" then
			return
		end
		Combat.throwRockAt(record)
	end)
	CombatService.onRockImpact(function(position, radius, damage)
		if ctx.phase ~= "playing" then
			return
		end
		Combat.damagePlayersNear(position, radius, damage)
		SupplyService.damageAlliesNear(position, radius, damage)
	end)
	ZombieService.onReached(function(record)
		if ctx.phase ~= "playing" then
			return
		end
		local target = record.attackTarget
		if target and target.kind == "ally" and target.ally then
			local hit = SupplyService.damageAlly(target.ally, record.contactDamage)
			if not hit then
				Combat.damagePlayers(record.contactDamage)
			end
		else
			Combat.damagePlayers(record.contactDamage)
		end
	end)
	SupplyService.onRecruited(function()
		ZombieService.retargetApproaching(function()
			return SupplyService.pickAttackTarget()
		end)
	end)
	SupplyService.onAllyDied(function(dead)
		for _, record in ZombieService.getAlive() do
			local target = record.attackTarget
			if target.kind == "ally" and target.ally == dead then
				ZombieService.setAttackTarget(record, SupplyService.pickAttackTarget())
			end
		end
	end)
	SupplyService.onBombPicked(function()
		if ctx.phase == "playing" then
			Combat.grantBombs()
		end
	end)
	SupplyService.onSniperPicked(function()
		if ctx.phase == "playing" then
			Combat.grantSniper()
		end
	end)
	SupplyService.onShotgunPicked(function()
		if ctx.phase == "playing" then
			Combat.grantShotgun()
		end
	end)
	SupplyService.onMolotovPicked(function(count: number)
		if ctx.phase == "playing" then
			local left = (ctx.stateFolder:GetAttribute("MolotovLeft") :: number?) or 0
			setState("MolotovLeft", left + count)
		end
	end)
	SupplyService.onFlashbangPicked(function(count: number)
		if ctx.phase == "playing" then
			local left = (ctx.stateFolder:GetAttribute("FlashbangLeft") :: number?) or 0
			setState("FlashbangLeft", left + count)
		end
	end)
	SupplyService.onFireBoostPicked(function()
		if ctx.phase == "playing" then
			Combat.grantFireBoost()
		end
	end)
	NumberGate.onCollected(function(kind)
		if ctx.phase ~= "playing" then
			return
		end
		local id = kind.Id
		local value = kind.Value or 0
		if id == "x2" or kind.Op == "mul" then
			ctx.hitPower = math.max(1, math.floor(ctx.hitPower * math.max(1, value)))
			local waveNow = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
			if Config.chapter() == 2 then
				local localRound = Config.chapterRound(waveNow)
				if localRound == Config.Chapter2.Round4.Round then
					Ev.Ch2.R4X2Collected = true
				elseif localRound == Config.Chapter2.Round8.Round then
					Ev.Ch2.R8X2Collected = true
				end
			elseif Config.chapter() == 3 then
				local localRound = Config.chapterRound(waveNow)
				if localRound == Config.Chapter3.Round3.Round then
					Ev.Ch3.R3X2Collected = true
				elseif localRound == Config.Chapter3.Round8.Round then
					Ev.Ch3.R8X2Collected = true
				end
			end
		elseif id == "div2" or kind.Op == "div" then
			ctx.hitPower = math.max(1, math.floor(ctx.hitPower / math.max(1, value)))
		elseif id == "plus" then
			ctx.hitPower = math.max(1, math.floor(ctx.hitPower + math.max(1, value)))
		else
			ctx.hitPower = math.max(1, math.floor(ctx.hitPower + value))
		end
		setState("HitPower", ctx.hitPower)
	end)

	remotes.Strafe.OnServerEvent:Connect(function(player: Player, value: unknown)
		local data = ctx.playerData[player]
		if not data or typeof(value) ~= "number" then
			return
		end
		data.strafe = math.clamp(value :: number, -1, 1)
	end)

	remotes.TogglePause.OnServerEvent:Connect(function()
		if ctx.phase ~= "playing" then
			return
		end
		ctx.paused = not ctx.paused
		setState("Paused", ctx.paused)
	end)

	remotes.UseMolotov.OnServerEvent:Connect(function(_player: Player)
		if ctx.phase ~= "playing" or ctx.paused then
			return
		end
		local left = (ctx.stateFolder:GetAttribute("MolotovLeft") :: number?) or 0
		if left <= 0 then
			return
		end
		local now = os.clock()
		if now - ctx.lastMolotovAt < 0.35 then
			return
		end
		local origins = SupplyService.allyThrowOrigins()
		local playerThrowing = #origins == 0
		if playerThrowing then
			for _, data in ctx.playerData do
				local character = data.character
				if not character then
					continue
				end
				local root = character:FindFirstChild("HumanoidRootPart")
				local muzzle = Gun.getMuzzlePosition(character)
				if muzzle then
					table.insert(origins, muzzle)
				elseif root and root:IsA("BasePart") then
					table.insert(origins, root.Position + Vector3.new(0, 1.2, 1.4))
				end
				break
			end
		end
		if not origins[1] then
			return
		end
		ctx.lastMolotovAt = now
		setState("MolotovLeft", left - 1)
		if playerThrowing and remotes.MolotovThrowAnim then
			remotes.MolotovThrowAnim:FireAllClients()
		end
		CombatService.throwMolotov(origins[1])
	end)

	remotes.UseFlashbang.OnServerEvent:Connect(function(_player: Player)
		if ctx.phase ~= "playing" or ctx.paused then
			return
		end
		local left = (ctx.stateFolder:GetAttribute("FlashbangLeft") :: number?) or 0
		if left <= 0 then
			return
		end
		local now = os.clock()
		if now - ctx.lastFlashbangAt < 0.35 then
			return
		end
		local origins = SupplyService.allyThrowOrigins()
		local playerThrowing = #origins == 0
		if playerThrowing then
			for _, data in ctx.playerData do
				local character = data.character
				if not character then
					continue
				end
				local root = character:FindFirstChild("HumanoidRootPart")
				local muzzle = Gun.getMuzzlePosition(character)
				if muzzle then
					table.insert(origins, muzzle)
				elseif root and root:IsA("BasePart") then
					table.insert(origins, root.Position + Vector3.new(0, 1.2, 1.4))
				end
				break
			end
		end
		if not origins[1] then
			return
		end
		ctx.lastFlashbangAt = now
		setState("FlashbangLeft", left - 1)
		CombatService.throwFlashbang(origins[1])
	end)

	if Config.Debug.Enabled then
		remotes.DebugSetRound.OnServerEvent:Connect(function(_player: Player, value: unknown)
			if not Config.Debug.Enabled or typeof(value) ~= "number" then
				return
			end
			Debug.jumpToRound(value :: number)
		end)
		remotes.DebugSetChapter.OnServerEvent:Connect(function(_player: Player, value: unknown)
			if not Config.Debug.Enabled or typeof(value) ~= "number" then
				return
			end
			if (value :: number) >= 3 then
				Debug.debugEnterChapter(3)
			elseif (value :: number) >= 2 then
				Debug.debugEnterChapter(2)
			end
		end)
		remotes.DebugHitPower.OnServerEvent:Connect(function(_player: Player, value: unknown)
			if not Config.Debug.Enabled or typeof(value) ~= "number" then
				return
			end
			ctx.hitPower = math.clamp(math.floor(value :: number), 1, 999)
			setState("HitPower", ctx.hitPower)
		end)
	end

	Players.RespawnTime = 2
	Players.PlayerAdded:Connect(Lifecycle.setupPlayer)
	for _, player in Players:GetPlayers() do
		Lifecycle.setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ctx.playerData[player] = nil
	end)

	Lifecycle.bindStartPad()
	Heartbeat.connect()
end

return Orchestrator
