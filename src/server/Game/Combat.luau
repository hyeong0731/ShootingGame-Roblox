local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local Gun = require(script.Parent.Parent.Gun)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Spawning = require(script.Parent.Spawning)

local ctx = Context
local setState = StateSync.setState
local currentUnitDamage = Spawning.currentUnitDamage

local Combat = {}

function Combat.applySpikeDamage(dt: number)
	if SpikeTrap.aliveCount() == 0 then
		return
	end
	local perSecond = Config.SpikeTrap.DamagePercentPerSecond / 100
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
		if SpikeTrap.isInside(root.Position) then
			humanoid:TakeDamage(humanoid.MaxHealth * perSecond * dt)
		end
	end
end

-- 투척 좀비: 플레이어의 예측 위치 + 약간의 오차로 돌을 던진다.
function Combat.throwRockAt(record)
	local cfg = Config.ThrowerZombie
	local lane = Config.activeLane()

	local target: any = nil
	local targetStrafe = 0
	local best = math.huge
	for _, data in ctx.playerData do
		local character = data.character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
			local dist = math.abs(root.Position.X - record.root.Position.X)
			if dist < best then
				best = dist
				target = root
				targetStrafe = data.strafe
			end
		end
	end
	if not target then
		return
	end

	local hand = record.handRock
	local origin = if hand and hand.Parent
		then hand.Position
		else record.root.Position + Vector3.new(0, 2.2, 0)

	local standY = Config.playerStandY()
	local flight = math.max(0.2, (Vector3.new(target.Position.X, standY, lane.PlayerZ) - origin).Magnitude / cfg.RockSpeed)
	-- 카메라가 +Z를 보므로 strafe 양수는 -X 방향으로 이동한다.
	local predictedX = target.Position.X - targetStrafe * Config.Player.StrafeSpeed * flight
	predictedX += (math.random() * 2 - 1) * cfg.Spread

	local minX, maxX = Config.laneXBounds()
	predictedX = math.clamp(predictedX, minX, maxX)
	CombatService.throwRock(origin, Vector3.new(predictedX, standY - 1.2, lane.PlayerZ))
end

function Combat.damagePlayersNear(position: Vector3, radius: number, amount: number)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
			local delta = root.Position - position
			if math.abs(delta.X) <= radius and math.abs(delta.Z) <= radius + 2 then
				humanoid:TakeDamage(amount)
			end
		end
	end
end

function Combat.damagePlayers(amount: number)
	for _, player in Players:GetPlayers() do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(amount)
		end
	end
end

function Combat.restoreGun(data: PlayerData)
	if (data.hadBomb or data.hadSniper or data.hadShotgun) and data.character then
		Gun.attach(data.character)
	end
	data.hadBomb = false
	data.bombUntil = 0
	data.hadSniper = false
	data.sniperUntil = 0
	data.hadShotgun = false
	data.shotgunUntil = 0
	data.lastFire = 0
end

function Combat.grantBombs()
	local untilTime = os.clock() + Config.BombCrate.Duration
	for _, data in ctx.playerData do
		data.bombUntil = untilTime
		data.hadBomb = true
		data.sniperUntil = 0
		data.hadSniper = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.lastFire = 0
		if data.character then
			Gun.attachBomb(data.character)
		end
	end
	setState("BombLeft", Config.BombCrate.Duration)
	setState("SniperLeft", 0)
	setState("ShotgunLeft", 0)
end

function Combat.grantSniper()
	local untilTime = os.clock() + Config.SniperCrate.Duration
	for _, data in ctx.playerData do
		data.sniperUntil = untilTime
		data.hadSniper = true
		data.bombUntil = 0
		data.hadBomb = false
		data.shotgunUntil = 0
		data.hadShotgun = false
		data.lastFire = 0
		if data.character then
			Gun.attachSniper(data.character)
		end
	end
	setState("SniperLeft", Config.SniperCrate.Duration)
	setState("BombLeft", 0)
	setState("ShotgunLeft", 0)
end

function Combat.grantShotgun()
	local untilTime = os.clock() + Config.Shotgun.Duration
	for _, data in ctx.playerData do
		data.shotgunUntil = untilTime
		data.hadShotgun = true
		data.bombUntil = 0
		data.hadBomb = false
		data.sniperUntil = 0
		data.hadSniper = false
		data.lastFire = 0
		if data.character then
			Gun.attachShotgun(data.character)
		end
	end
	setState("ShotgunLeft", Config.Shotgun.Duration)
	setState("BombLeft", 0)
	setState("SniperLeft", 0)
end

function Combat.grantFireBoost()
	local mult = Config.Chapter3.FireBoostCrate.FireRateMultiplier
	for _, data in ctx.playerData do
		data.fireRateMult = mult
	end
end

function Combat.tryFire(now: number)
	if ctx.phase ~= "playing" then
		return
	end

	for _, data in ctx.playerData do
		local character = data.character
		if not character then
			continue
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			continue
		end

		local usingSniper = data.hadSniper and now < data.sniperUntil
		local usingBomb = data.hadBomb and now < data.bombUntil
		local usingShotgun = data.hadShotgun and now < data.shotgunUntil
		local interval = if usingSniper
			then Config.sniperFireInterval()
			elseif usingBomb then Config.BombCrate.ThrowInterval
			elseif usingShotgun then Config.Shotgun.FireInterval
			else Config.Combat.FireInterval
		if not usingBomb and not usingSniper then
			interval /= math.max(1, data.fireRateMult or 1)
		end
		interval /= math.max(0.05, ctx.windSpeedScale or 1)
		if now - data.lastFire < interval then
			continue
		end

		data.lastFire = now
		local muzzle = Gun.getMuzzlePosition(character)
			or (root.CFrame * CFrame.new(Config.Combat.MuzzleOffset)).Position
		local origin = Vector3.new(root.Position.X, muzzle.Y, muzzle.Z)
		if usingSniper then
			CombatService.fireSniper(origin, currentUnitDamage(), ctx.hitPower)
		elseif usingBomb then
			CombatService.throwBomb(origin, ctx.hitPower)
		elseif usingShotgun then
			CombatService.fireShotgun(origin, currentUnitDamage(), ctx.hitPower)
		else
			CombatService.fireStraight(origin, currentUnitDamage(), ctx.hitPower)
		end
	end

	for _, allyOrigin in SupplyService.allyMuzzlePoints(now) do
		CombatService.fireStraight(allyOrigin, currentUnitDamage(), 1)
	end
end

return Combat
