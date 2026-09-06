local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BarricadeService = require(script.Parent.Parent.BarricadeService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local ZombieService = require(script.Parent.Parent.ZombieService)
local StateSync = require(script.Parent.StateSync)

local setState = StateSync.setState

local FinalBossR15 = {}

local state = {
	chargeWarned = false,
	chargeArmedAt = 0,
	charging = false,
	chargeDone = false,
	vomitWarned = false,
	vomitUntil = 0,
	vomitDone = false,
	savedWalkSpeed = nil :: number?,
}

local function progressZ(progress: number): number
	local lane = Config.activeLane()
	return lane.SpawnZ + (lane.PlayerZ - lane.SpawnZ) * progress
end

local function findBoss()
	for _, record in ZombieService.getAlive() do
		if record.model:GetAttribute("IsFinalBoss") == true then
			return record
		end
	end
	return nil
end

local function announce(text: string, clearAfter: number?)
	setState("Announce", text)
	if text == "" then
		return
	end
	local hold = clearAfter or 3.2
	task.delay(hold, function()
		local folder = ReplicatedStorage:FindFirstChild("GameState")
		if folder and (folder:GetAttribute("Announce") or "") == text then
			setState("Announce", "")
		end
	end)
end

local function restoreWalk(record)
	if state.savedWalkSpeed then
		record.walkSpeed = state.savedWalkSpeed
		state.savedWalkSpeed = nil
	else
		record.walkSpeed = Config.Chapter3.Round15.BossWalkSpeed
	end
	record.model:SetAttribute("BossCharging", false)
	record.model:SetAttribute("BossChanneling", false)
end

local function spawnVomitFx(fromPos: Vector3, toPos: Vector3)
	local fxFolder = Workspace:FindFirstChild("Fx") or Workspace
	local blob = Instance.new("Part")
	blob.Name = "BossVomit"
	blob.Shape = Enum.PartType.Ball
	blob.Size = Vector3.new(7.5, 7.5, 7.5)
	blob.Color = Color3.fromRGB(48, 190, 62)
	blob.Material = Enum.Material.Neon
	blob.Transparency = 0.12
	blob.Anchored = true
	blob.CanCollide = false
	blob.CanQuery = false
	blob.CFrame = CFrame.new(fromPos + Vector3.new(0, 6, 0))
	blob.Parent = fxFolder
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(70, 255, 90)
	light.Brightness = 4
	light.Range = 28
	light.Parent = blob
	local duration = 0.55
	local t0 = os.clock()
	task.spawn(function()
		while blob.Parent and os.clock() - t0 < duration do
			local u = (os.clock() - t0) / duration
			local p = fromPos:Lerp(toPos, u)
			local arc = math.sin(u * math.pi) * 14
			blob.CFrame = CFrame.new(p + Vector3.new(0, 4 + arc, 0))
			blob.Size = Vector3.new(7.5, 7.5, 7.5) * (1 + u * 0.85)
			task.wait()
		end
		if blob.Parent then
			blob:Destroy()
		end
		local splash = Instance.new("Part")
		splash.Name = "BossVomitSplash"
		splash.Shape = Enum.PartType.Ball
		splash.Size = Vector3.new(4, 4, 4)
		splash.Color = Color3.fromRGB(36, 160, 48)
		splash.Material = Enum.Material.Neon
		splash.Transparency = 0.2
		splash.Anchored = true
		splash.CanCollide = false
		splash.CanQuery = false
		splash.CFrame = CFrame.new(toPos + Vector3.new(0, 2, 0))
		splash.Parent = fxFolder
		task.delay(0.45, function()
			if splash.Parent then
				splash:Destroy()
			end
		end)
		task.spawn(function()
			local s0 = os.clock()
			while splash.Parent and os.clock() - s0 < 0.4 do
				local u = (os.clock() - s0) / 0.4
				local size = 4 + 22 * u
				splash.Size = Vector3.new(size, size * 0.45, size)
				splash.Transparency = 0.2 + 0.7 * u
				task.wait()
			end
			if splash.Parent then
				splash:Destroy()
			end
		end)
	end)
end

local function applyVomitDamage()
	local pct = (Config.Chapter3.Round15.VomitHpPercent or 60) / 100
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(humanoid.MaxHealth * pct)
		end
	end
	for _, ally in SupplyService.getAllies() do
		if ally.alive and ally.model.Parent and ally.humanoid.Health > 0 then
			SupplyService.damageAlly(ally, ally.humanoid.MaxHealth * pct)
		end
	end
end

function FinalBossR15.reset()
	state.chargeWarned = false
	state.chargeArmedAt = 0
	state.charging = false
	state.chargeDone = false
	state.vomitWarned = false
	state.vomitUntil = 0
	state.vomitDone = false
	state.savedWalkSpeed = nil
end

function FinalBossR15.isVomitChanneling(): boolean
	return state.vomitWarned and not state.vomitDone and os.clock() < state.vomitUntil
end

-- 섬광탄이 최종보스에 맞았을 때 기절 시간 반환. 토사물 채널 중이면 취소 + 5초.
function FinalBossR15.flashStunForBoss(record): number
	local r15 = Config.Chapter3.Round15
	if FinalBossR15.isVomitChanneling() then
		state.vomitDone = true
		state.vomitUntil = 0
		record.model:SetAttribute("BossChanneling", false)
		announce("", 0)
		setState("Announce", "")
		return r15.BossVomitFlashStun or 5
	end
	if state.charging then
		state.charging = false
		state.chargeDone = true
		restoreWalk(record)
	end
	return r15.BossFlashStun or 3
end

function FinalBossR15.tick(_dt: number)
	if Config.chapter() ~= 3 then
		return
	end
	local r15 = Config.Chapter3.Round15
	local waveFolder = ReplicatedStorage:FindFirstChild("GameState")
	local wave = if waveFolder then (waveFolder:GetAttribute("Wave") :: number?) or 1 else 1
	if Config.chapterRound(wave) ~= r15.Round then
		return
	end

	local boss = findBoss()
	if not boss then
		return
	end

	local now = os.clock()
	local z = boss.root.Position.Z
	local chargeWarnZ = progressZ(r15.ChargeWarnProgress or 0.45)
	local chargeEndZ = progressZ(r15.ChargeEndProgress or 1.04)
	local vomitZ = progressZ(r15.VomitProgress or 1.10)

	-- 돌진 준비
	if not state.chargeWarned and not state.chargeDone and z <= chargeWarnZ then
		state.chargeWarned = true
		state.chargeArmedAt = now + (r15.ChargeDelay or 3)
		announce(r15.ChargeWarnText, 3.5)
	end

	if state.chargeWarned and not state.charging and not state.chargeDone and now >= state.chargeArmedAt then
		state.charging = true
		state.savedWalkSpeed = boss.walkSpeed
		boss.walkSpeed = r15.ChargeSpeed or 52
		boss.model:SetAttribute("BossCharging", true)
		boss.attackUntil = 0
	end

	-- 돌진 중: 바리케이드 충돌 or 끝 지점
	if state.charging then
		local barZ = BarricadeService.getBlockZ()
		if barZ and BarricadeService.isAlive() and z <= barZ + 2.2 then
			BarricadeService.destroyInstant()
			state.charging = false
			state.chargeDone = true
			restoreWalk(boss)
			boss.stunUntil = math.max(boss.stunUntil or 0, now + (r15.BossBarricadeStun or 5))
			boss.model:SetAttribute("Stunned", true)
			return
		end
		if z <= chargeEndZ then
			state.charging = false
			state.chargeDone = true
			restoreWalk(boss)
			-- 끝 지점에 살짝 고정 후 느린 속도로 재개
			local pos = boss.root.Position
			boss.root.CFrame = CFrame.new(pos.X, pos.Y, math.max(z, chargeEndZ))
				* (boss.root.CFrame - boss.root.CFrame.Position)
		end
	end

	-- 토사물 (돌진 이후)
	if state.chargeDone and not state.vomitWarned and not state.vomitDone and z <= vomitZ then
		state.vomitWarned = true
		state.vomitUntil = now + (r15.VomitChannel or 7)
		boss.model:SetAttribute("BossChanneling", true)
		boss.attackUntil = 0
		announce(r15.VomitWarnText, 7.2)
	end

	if FinalBossR15.isVomitChanneling() then
		-- 채널 중 제자리
		boss.model:SetAttribute("BossChanneling", true)
		return
	end

	if state.vomitWarned and not state.vomitDone and now >= state.vomitUntil then
		state.vomitDone = true
		boss.model:SetAttribute("BossChanneling", false)
		local fromPos = boss.root.Position
		local toPos = fromPos
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				toPos = root.Position
				break
			end
		end
		spawnVomitFx(fromPos, toPos)
		task.delay(0.5, function()
			applyVomitDamage()
		end)
	end
end

return FinalBossR15
