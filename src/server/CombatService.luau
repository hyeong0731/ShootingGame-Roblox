local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)
local SupplyService = require(script.Parent.SupplyService)
local NumberGate = require(script.Parent.NumberGate)

local CombatService = {}
CombatService._remotes = nil :: any

local active = {} :: {
	{
		part: BasePart,
		direction: Vector3,
		speed: number,
		damage: number,
		hits: number,
		shieldHits: number?,
		born: number,
		pierce: boolean,
		oneshot: boolean,
		radius: number,
		endZ: number?,
		hitSet: { [Model]: boolean },
		tipOffset: number,
		falloffFromZ: number?,
		falloffFull: number?,
		falloffMax: number?,
		falloffMinScale: number?,
	}
}

local bombs = {} :: {
	{
		part: BasePart,
		direction: Vector3,
		speed: number,
		born: number,
		hits: number,
		startZ: number,
	}
}

local molotovs = {} :: {
	{
		part: BasePart,
		direction: Vector3,
		speed: number,
		born: number,
		startZ: number,
		targetPosition: Vector3,
	}
}

local flashbangs = {} :: {
	{
		part: BasePart,
		direction: Vector3,
		speed: number,
		born: number,
		startZ: number,
		targetZ: number,
	}
}

local groundFires = {} :: {
	{
		part: BasePart,
		position: Vector3,
		untilTime: number,
		nextTick: number,
	}
}

-- 투척 좀비가 던진 돌 (플레이어만 맞음)
local rocks = {} :: {
	{
		part: BasePart,
		origin: Vector3,
		target: Vector3,
		born: number,
		flight: number,
		damage: number,
		spin: Vector3,
	}
}

CombatService._onRockImpact = nil :: ((Vector3, number, number) -> ())?

function CombatService.bind(remotes)
	CombatService._remotes = remotes
end

local function spawnBolt(origin: Vector3, direction: Vector3, size: Vector3?, color: Color3?): (BasePart, number)
	local boltSize = size or Vector3.new(0.28, 0.28, 3.4)
	local bolt = Instance.new("Part")
	bolt.Name = "Bolt"
	bolt.Shape = Enum.PartType.Block
	bolt.Size = boltSize
	bolt.Material = Enum.Material.Neon
	bolt.Color = color or Color3.fromRGB(255, 220, 70)
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.CastShadow = false
	bolt.CFrame = CFrame.lookAt(origin, origin + direction)
	bolt.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local tipLen = math.max(0.5, boltSize.Z * 0.2)
	local tip = Instance.new("WedgePart")
	tip.Name = "Tip"
	tip.Size = Vector3.new(boltSize.X + 0.02, boltSize.Y + 0.02, tipLen)
	tip.Material = Enum.Material.Neon
	tip.Color = Color3.fromRGB(255, 245, 180)
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CastShadow = false
	local tipOffset = boltSize.Z * 0.5 + tipLen * 0.15
	tip.CFrame = bolt.CFrame * CFrame.new(0, 0, -tipOffset)
	tip.Parent = bolt

	return bolt, tipOffset
end

local function spawnThrownBomb(origin: Vector3): BasePart
	local bomb = Instance.new("Part")
	bomb.Name = "ThrownBomb"
	bomb.Shape = Enum.PartType.Ball
	bomb.Size = Vector3.new(1.35, 1.35, 1.35)
	bomb.Material = Enum.Material.Metal
	bomb.Color = Color3.fromRGB(48, 52, 44)
	bomb.Anchored = true
	bomb.CanCollide = false
	bomb.CanQuery = false
	bomb.CFrame = CFrame.new(origin)
	bomb.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local fuse = Instance.new("Part")
	fuse.Name = "Fuse"
	fuse.Size = Vector3.new(0.18, 0.18, 0.18)
	fuse.Shape = Enum.PartType.Ball
	fuse.Material = Enum.Material.Neon
	fuse.Color = Color3.fromRGB(255, 150, 40)
	fuse.Anchored = true
	fuse.CanCollide = false
	fuse.CanQuery = false
	fuse.CFrame = bomb.CFrame * CFrame.new(0, 0.7, 0)
	fuse.Parent = bomb

	return bomb
end

local function spawnThrownMolotov(origin: Vector3): BasePart
	local bottle = Instance.new("Part")
	bottle.Name = "ThrownMolotov"
	bottle.Size = Vector3.new(0.55, 1.15, 0.55)
	bottle.Material = Enum.Material.Glass
	bottle.Color = Color3.fromRGB(180, 40, 28)
	bottle.Transparency = 0.15
	bottle.Anchored = true
	bottle.CanCollide = false
	bottle.CanQuery = false
	bottle.CFrame = CFrame.new(origin)
	bottle.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local wick = Instance.new("Part")
	wick.Name = "Wick"
	wick.Size = Vector3.new(0.16, 0.16, 0.16)
	wick.Shape = Enum.PartType.Ball
	wick.Material = Enum.Material.Neon
	wick.Color = Color3.fromRGB(255, 140, 40)
	wick.Anchored = true
	wick.CanCollide = false
	wick.CanQuery = false
	wick.CFrame = bottle.CFrame * CFrame.new(0, 0.72, 0)
	wick.Parent = bottle

	return bottle
end

local function spawnGroundFire(position: Vector3)
	local cfg = Config.Molotov
	local lane = Config.activeLane()
	local y = lane.CenterY + lane.Thickness * 0.5 + 0.12
	local fire = Instance.new("Part")
	fire.Name = "GroundFire"
	fire.Anchored = true
	fire.CanCollide = false
	fire.CanQuery = false
	fire.Material = Enum.Material.Neon
	fire.Color = Color3.fromRGB(220, 40, 18)
	fire.Transparency = 0.25
	fire.Size = Vector3.new(cfg.GroundRadius * 1.7, 0.35, cfg.GroundRadius * 1.7)
	fire.CFrame = CFrame.new(position.X, y, position.Z)
	fire.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 90, 30)
	light.Brightness = 2.4
	light.Range = cfg.GroundRadius * 1.4
	light.Parent = fire

	table.insert(groundFires, {
		part = fire,
		position = Vector3.new(position.X, y, position.Z),
		untilTime = os.clock() + cfg.GroundDuration,
		nextTick = os.clock(),
	})
end

local function currentWave(): number
	local state = ReplicatedStorage:FindFirstChild("GameState")
	if state then
		return (state:GetAttribute("Wave") :: number?) or 1
	end
	return 1
end

local function explodeMolotovAt(position: Vector3)
	local cfg = Config.Molotov
	local hitDamage = Config.numberedWeaponHits("molotov", currentWave())
	ZombieService.damageInRadius(position, cfg.Radius, cfg.Damage, hitDamage)
	SupplyService.damageInRadius(position, cfg.Radius, hitDamage)
	NumberGate.damageInRadius(position, cfg.Radius, hitDamage)
	if CombatService._remotes then
		CombatService._remotes.ExplodeFx:FireAllClients(position, cfg.Radius)
	end
	spawnGroundFire(position)
end

local function explodeAt(position: Vector3, hits: number)
	local cfg = Config.BombCrate
	local bombHits = Config.numberedWeaponHits("bomb", currentWave())
	local numberedHits = math.max(bombHits, math.max(1, math.floor(hits)))
	local shieldHits = Config.bombShieldHits(currentWave())
	ZombieService.damageInRadius(position, cfg.Radius, cfg.Damage, numberedHits, shieldHits)
	SupplyService.damageInRadius(position, cfg.Radius, numberedHits)
	NumberGate.damageInRadius(position, cfg.Radius, numberedHits)
	if CombatService._remotes then
		CombatService._remotes.ExplodeFx:FireAllClients(position, cfg.Radius)
	end
end

function CombatService.throwBomb(origin: Vector3, hits: number?)
	local cfg = Config.BombCrate
	local part = spawnThrownBomb(origin)
	local direction = Vector3.new(0, 0, 1)
	local speed = cfg.ThrowDistance / math.max(0.05, cfg.FlightTime)
	table.insert(bombs, {
		part = part,
		direction = direction,
		speed = speed,
		born = os.clock(),
		hits = math.max(1, math.floor(hits or 1)),
		startZ = origin.Z,
	})
end

function CombatService.throwMolotov(origin: Vector3)
	local cfg = Config.Molotov
	local lane = Config.activeLane()
	local midZ = (lane.SpawnZ + lane.PlayerZ) / 2
	local targetPosition = Vector3.new(origin.X, lane.CenterY + lane.Thickness * 0.5, midZ)
	local throwDist = math.max(2, midZ - origin.Z)
	local part = spawnThrownMolotov(origin)
	local direction = Vector3.new(0, 0, 1)
	local speed = throwDist / math.max(0.05, cfg.FlightTime)
	table.insert(molotovs, {
		part = part,
		direction = direction,
		speed = speed,
		born = os.clock(),
		startZ = origin.Z,
		targetPosition = targetPosition,
	})
end

local function spawnThrownFlashbang(origin: Vector3): BasePart
	local can = Instance.new("Part")
	can.Name = "ThrownFlashbang"
	can.Size = Vector3.new(0.7, 1.05, 0.7)
	can.Material = Enum.Material.Metal
	can.Color = Color3.fromRGB(210, 210, 220)
	can.Anchored = true
	can.CanCollide = false
	can.CanQuery = false
	can.CFrame = CFrame.new(origin)
	can.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.55, 0.22, 0.55)
	tip.Material = Enum.Material.Neon
	tip.Color = Color3.fromRGB(255, 245, 160)
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CFrame = can.CFrame * CFrame.new(0, 0.58, 0)
	tip.Parent = can

	return can
end

local function explodeFlashbangAt(position: Vector3)
	local bombCfg = Config.BombCrate
	local stunDur = Config.Flashbang.StunDuration
	ZombieService.stunInRadius(position, bombCfg.Radius, stunDur)
	if CombatService._remotes then
		if CombatService._remotes.FlashFx then
			CombatService._remotes.FlashFx:FireAllClients(position, bombCfg.Radius)
		else
			CombatService._remotes.ExplodeFx:FireAllClients(position, bombCfg.Radius)
		end
	end
	-- 서버 측 번쩍 이펙트
	local fxFolder = Workspace:FindFirstChild("Fx") or Workspace
	local flash = Instance.new("Part")
	flash.Name = "FlashbangBurst"
	flash.Shape = Enum.PartType.Ball
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 255, 240)
	flash.Transparency = 0.05
	flash.Size = Vector3.new(2, 2, 2)
	flash.CFrame = CFrame.new(position)
	flash.Parent = fxFolder
	local light = Instance.new("PointLight")
	light.Brightness = 8
	light.Range = bombCfg.Radius * 1.6
	light.Color = Color3.fromRGB(255, 255, 220)
	light.Parent = flash
	task.delay(0.35, function()
		if flash.Parent then
			flash:Destroy()
		end
	end)
	task.spawn(function()
		local t0 = os.clock()
		while flash.Parent and os.clock() - t0 < 0.28 do
			local u = (os.clock() - t0) / 0.28
			local size = 2 + (bombCfg.Radius * 2 - 2) * u
			flash.Size = Vector3.new(size, size, size)
			flash.Transparency = 0.05 + 0.9 * u
			task.wait()
		end
		if flash.Parent then
			flash:Destroy()
		end
	end)
end

function CombatService.throwFlashbang(origin: Vector3)
	local bombCfg = Config.BombCrate
	local part = spawnThrownFlashbang(origin)
	local direction = Vector3.new(0, 0, 1)
	local speed = bombCfg.ThrowDistance / math.max(0.05, bombCfg.FlightTime)
	table.insert(flashbangs, {
		part = part,
		direction = direction,
		speed = speed,
		born = os.clock(),
		startZ = origin.Z,
		targetZ = origin.Z + bombCfg.ThrowDistance,
	})
end

local function spawnRock(origin: Vector3): BasePart
	local cfg = Config.ThrowerZombie
	local rock = Instance.new("Part")
	rock.Name = "ThrownRock"
	rock.Shape = Enum.PartType.Block
	rock.Size = Vector3.new(cfg.RockSize, cfg.RockSize * 0.82, cfg.RockSize * 0.92)
	rock.Material = Enum.Material.Slate
	rock.Color = Color3.fromRGB(96, 92, 86)
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanQuery = false
	rock.CastShadow = false
	rock.CFrame = CFrame.new(origin)
	rock.Parent = Workspace:FindFirstChild("Fx") or Workspace
	return rock
end

function CombatService.onRockImpact(callback: (Vector3, number, number) -> ())
	CombatService._onRockImpact = callback
end

function CombatService.throwRock(origin: Vector3, target: Vector3)
	local cfg = Config.ThrowerZombie
	local dist = (target - origin).Magnitude
	table.insert(rocks, {
		part = spawnRock(origin),
		origin = origin,
		target = target,
		born = os.clock(),
		flight = math.max(0.2, dist / cfg.RockSpeed),
		damage = cfg.RockDamage,
		spin = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1).Unit * 9,
	})
end

function CombatService.shiftTimers(duration: number)
	for _, shot in active do
		shot.born += duration
	end
	for _, bomb in bombs do
		bomb.born += duration
	end
	for _, molotov in molotovs do
		molotov.born += duration
	end
	for _, flash in flashbangs do
		flash.born += duration
	end
	for _, rock in rocks do
		rock.born += duration
	end
	for _, fire in groundFires do
		fire.untilTime += duration
		fire.nextTick += duration
	end
end

function CombatService.fireStraight(origin: Vector3, damage: number, hits: number?)
	local direction = Vector3.new(0, 0, 1)
	local part, tipOffset = spawnBolt(origin, direction)
	table.insert(active, {
		part = part,
		direction = direction,
		speed = Config.Combat.ProjectileSpeed,
		damage = damage,
		hits = math.max(1, math.floor(hits or 1)),
		born = os.clock(),
		pierce = false,
		oneshot = false,
		radius = 1.35,
		endZ = nil,
		hitSet = {},
		tipOffset = tipOffset,
	})
end

function CombatService.fireSniper(origin: Vector3, damage: number, hits: number?)
	local cfg = Config.SniperCrate
	local direction = Vector3.new(0, 0, 1)
	local part, tipOffset = spawnBolt(
		origin,
		direction,
		cfg.BoltSize,
		Color3.fromRGB(160, 230, 255)
	)
	table.insert(active, {
		part = part,
		direction = direction,
		speed = cfg.ProjectileSpeed,
		damage = damage,
		hits = math.max(1, math.floor(Config.numberedWeaponHits("sniper", currentWave()))),
		shieldHits = math.max(1, math.floor(Config.sniperShieldHits(currentWave()))),
		born = os.clock(),
		pierce = true,
		oneshot = true,
		radius = cfg.ProjectileRadius,
		endZ = Config.activeLane().SpawnZ + 12,
		hitSet = {},
		tipOffset = tipOffset,
	})
end

function CombatService.fireShotgun(origin: Vector3, damage: number, hits: number?)
	local cfg = Config.Shotgun
	local playerDps = math.max(1, math.floor(hits or 1))
	local pelletHits = math.max(1, math.floor(playerDps * cfg.HitsScale + 0.5))
	local pelletShieldHits = math.max(1, playerDps * (cfg.ShieldHitsPerPellet or 3))
	local unitDmg = cfg.ReferenceUnitDamage or damage
	local pelletDamage = math.max(1, unitDmg * cfg.DamageScale)
	local lane = Config.activeLane()
	local road = math.max(40, math.abs(lane.SpawnZ - lane.PlayerZ))
	local rangeMax = road * (cfg.RoadRangeRatio or 0.7)
	local rangeFull = road * (cfg.RoadFullRatio or 0.4)
	local endZ = lane.PlayerZ + rangeMax
	local yaws = cfg.SpreadYawDeg
	local count = math.min(cfg.PelletCount, #yaws)
	for i = 1, count do
		local yaw = math.rad(yaws[i])
		-- +Z 전방 기준 V자 확산 (yaw만 돌려 XZ 평면에서 벌어짐)
		local direction = Vector3.new(math.sin(yaw), 0, math.cos(yaw)).Unit
		local part, tipOffset = spawnBolt(
			origin,
			direction,
			cfg.BoltSize,
			Color3.fromRGB(255, 170, 70)
		)
		table.insert(active, {
			part = part,
			direction = direction,
			speed = cfg.ProjectileSpeed,
			damage = pelletDamage,
			hits = pelletHits,
			shieldHits = pelletShieldHits,
			born = os.clock(),
			pierce = false,
			oneshot = false,
			radius = cfg.ProjectileRadius,
			endZ = endZ,
			hitSet = {},
			tipOffset = tipOffset,
			falloffFromZ = lane.PlayerZ,
			falloffFull = rangeFull,
			falloffMax = rangeMax,
			falloffMinScale = cfg.FalloffMinScale,
		})
	end
end

local function shotFalloffScale(shot: typeof(active[1]), z: number): number
	if not shot.falloffFromZ or not shot.falloffFull or not shot.falloffMax then
		return 1
	end
	local dist = math.max(0, z - shot.falloffFromZ)
	if dist <= shot.falloffFull then
		return 1
	end
	local span = math.max(1, shot.falloffMax - shot.falloffFull)
	local t = math.clamp((dist - shot.falloffFull) / span, 0, 1)
	local minScale = shot.falloffMinScale or 0.25
	return 1 - t * (1 - minScale)
end

local function applyShot(model: Model, damage: number, hits: number, oneshot: boolean?, shieldHits: number?): boolean
	if model:GetAttribute("IsNumberGate") == true then
		return NumberGate.damageModel(model, hits)
	end
	if model:GetAttribute("IsSupply") == true then
		return SupplyService.damageModel(model, hits)
	end
	local amount = damage
	if oneshot then
		amount = 1e9
		if model:GetAttribute("IsBigZombie") == true and model:GetAttribute("IsMega") ~= true then
			for _, record in ZombieService.getAlive() do
				if record.model == model then
					amount = record.maxHp * (Config.SniperCrate.BigZombieHpRatio or 0.7)
					break
				end
			end
		end
	end
	local dpsHits = if model:GetAttribute("HasShield") == true and shieldHits then shieldHits else hits
	return ZombieService.damageModel(model, amount, dpsHits)
end

local function pointToSegmentDist(point: Vector3, a: Vector3, b: Vector3): (number, Vector3)
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		return (point - a).Magnitude, a
	end
	local t = math.clamp((point - a):Dot(ab) / len2, 0, 1)
	local closest = a + ab * t
	return (point - closest).Magnitude, closest
end

-- Backup when spherecast misses thin/low targets (esp. dogs).
local function proximityHit(from: Vector3, to: Vector3, damage: number, hits: number): (boolean, Vector3?, boolean?)
	local bestDist = math.huge
	local bestPos: Vector3? = nil
	local bestModel: Model? = nil
	local bestBoss = false

	for _, record in ZombieService.getAlive() do
		local radius = (record.model:GetAttribute("HitRadius") :: number?) or Config.Zombie.HitRadius
		-- Ignore height: lane shooter aims along Z at target X.
		local flatPoint = Vector3.new(record.root.Position.X, from.Y, record.root.Position.Z)
		local dist, closest = pointToSegmentDist(flatPoint, from, to)
		local pad = if record.isDog then 1.6 else 0.85
		if dist <= radius + pad and dist < bestDist then
			bestDist = dist
			bestPos = Vector3.new(closest.X, record.root.Position.Y + 1.2, closest.Z)
			bestModel = record.model
			bestBoss = record.isBoss
		end
	end

	local suppliesFolder = Workspace:FindFirstChild("Supplies")
	if suppliesFolder then
		for _, child in suppliesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsSupply") == true then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist, closest = pointToSegmentDist(flatPoint, from, to)
					if dist <= 3.4 * Config.Supply.SizeScale and dist < bestDist then
						bestDist = dist
						bestPos = closest
						bestModel = child
						bestBoss = false
					end
				end
			end
		end
	end

	local gatesFolder = Workspace:FindFirstChild("NumberGates")
	if gatesFolder then
		for _, child in gatesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsNumberGate") == true then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist, closest = pointToSegmentDist(flatPoint, from, to)
					local reach = Config.NumberGate.Width * 0.5 + 1.2
					if dist <= reach and dist < bestDist then
						bestDist = dist
						bestPos = closest
						bestModel = child
						bestBoss = false
					end
				end
			end
		end
	end

	if bestModel and bestPos then
		return applyShot(bestModel, damage, hits), bestPos, bestBoss
	end
	return false, nil, nil
end

local function pierceHitAll(from: Vector3, to: Vector3, shot: typeof(active[1]))
	for _, record in ZombieService.getAlive() do
		if shot.hitSet[record.model] then
			continue
		end
		local radius = (record.model:GetAttribute("HitRadius") :: number?) or Config.Zombie.HitRadius
		local flatPoint = Vector3.new(record.root.Position.X, from.Y, record.root.Position.Z)
		local dist = (pointToSegmentDist(flatPoint, from, to))
		local pad = if record.isDog then 1.6 else 0.85
		if dist <= radius + pad + shot.radius then
			shot.hitSet[record.model] = true
			applyShot(record.model, shot.damage, shot.hits, shot.oneshot, shot.shieldHits)
		end
	end

	-- 보급·게이트(옆길)는 관통 없이 가장 가까운 1개만
	local bestSideDist = math.huge
	local bestSideModel: Model? = nil

	local suppliesFolder = Workspace:FindFirstChild("Supplies")
	if suppliesFolder then
		for _, child in suppliesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsSupply") == true and not shot.hitSet[child] then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist = (pointToSegmentDist(flatPoint, from, to))
					if dist <= 3.4 * Config.Supply.SizeScale + shot.radius and dist < bestSideDist then
						bestSideDist = dist
						bestSideModel = child
					end
				end
			end
		end
	end

	local gatesFolder = Workspace:FindFirstChild("NumberGates")
	if gatesFolder then
		for _, child in gatesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsNumberGate") == true and not shot.hitSet[child] then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist = (pointToSegmentDist(flatPoint, from, to))
					local reach = Config.NumberGate.Width * 0.5 + 1.2 + shot.radius
					if dist <= reach and dist < bestSideDist then
						bestSideDist = dist
						bestSideModel = child
					end
				end
			end
		end
	end

	if bestSideModel then
		shot.hitSet[bestSideModel] = true
		applyShot(bestSideModel, shot.damage, shot.hits, shot.oneshot, shot.shieldHits)
	end
end

local function bombProximityHit(from: Vector3, to: Vector3): Vector3?
	local bestDist = math.huge
	local bestPos: Vector3? = nil

	for _, record in ZombieService.getAlive() do
		local radius = (record.model:GetAttribute("HitRadius") :: number?) or Config.Zombie.HitRadius
		local flatPoint = Vector3.new(record.root.Position.X, from.Y, record.root.Position.Z)
		local dist, closest = pointToSegmentDist(flatPoint, from, to)
		local pad = if record.isDog then 1.6 else 0.85
		if dist <= radius + pad and dist < bestDist then
			bestDist = dist
			bestPos = Vector3.new(closest.X, record.root.Position.Y + 1.2, closest.Z)
		end
	end

	local suppliesFolder = Workspace:FindFirstChild("Supplies")
	if suppliesFolder then
		for _, child in suppliesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsSupply") == true then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist, closest = pointToSegmentDist(flatPoint, from, to)
					if dist <= 3.4 * Config.Supply.SizeScale and dist < bestDist then
						bestDist = dist
						bestPos = closest
					end
				end
			end
		end
	end

	local gatesFolder = Workspace:FindFirstChild("NumberGates")
	if gatesFolder then
		for _, child in gatesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsNumberGate") == true then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist, closest = pointToSegmentDist(flatPoint, from, to)
					local reach = Config.NumberGate.Width * 0.5 + 1.2
					if dist <= reach and dist < bestDist then
						bestDist = dist
						bestPos = closest
					end
				end
			end
		end
	end

	return bestPos
end

function CombatService.update(dt: number)
	local keep = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local filter = {}
	local zombiesFolder = Workspace:FindFirstChild("Zombies")
	if zombiesFolder then
		table.insert(filter, zombiesFolder)
	end
	local suppliesFolder = Workspace:FindFirstChild("Supplies")
	if suppliesFolder then
		table.insert(filter, suppliesFolder)
	end
	local gatesFolder = Workspace:FindFirstChild("NumberGates")
	if gatesFolder then
		table.insert(filter, gatesFolder)
	end
	params.FilterDescendantsInstances = filter

	local now = os.clock()
	for _, shot in active do
		if not shot.part.Parent then
			continue
		end

		local visual = shot.part.Position
		local nextPos = visual + shot.direction * shot.speed * dt
		local reachedEnd = shot.endZ ~= nil and nextPos.Z >= shot.endZ
		local timedOut = if shot.pierce
			then (now - shot.born > 4)
			else (now - shot.born > Config.Combat.ProjectileLifetime)
		if timedOut or reachedEnd then
			shot.part:Destroy()
			continue
		end

		local castFrom = visual - shot.direction * 1.5
		local castTo = nextPos + shot.direction * 2

		if shot.pierce then
			pierceHitAll(castFrom, castTo, shot)
		else
			local scale = shotFalloffScale(shot, visual.Z)
			local dmg = math.max(1, shot.damage * scale)
			local hits = math.max(1, math.floor(shot.hits * scale + 0.5))
			local castTravel = shot.direction * (shot.speed * dt + 3.4)
			local result = Workspace:Spherecast(castFrom, shot.radius, castTravel, params)
			local damaged = false
			if result then
				local model = result.Instance:FindFirstAncestorOfClass("Model")
				while model and model.Name == "Bolt" do
					model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
				end
				if model then
					damaged = applyShot(model, dmg, hits, shot.oneshot, shot.shieldHits)
				end
			end
			if not damaged then
				local ok = proximityHit(castFrom, castTo, dmg, hits)
				damaged = ok
			end
			if damaged then
				shot.part:Destroy()
				continue
			end
		end

		local look = CFrame.lookAt(nextPos, nextPos + shot.direction)
		shot.part.CFrame = look
		local tip = shot.part:FindFirstChild("Tip")
		if tip and tip:IsA("BasePart") then
			tip.CFrame = look * CFrame.new(0, 0, -shot.tipOffset)
		end
		table.insert(keep, shot)
	end
	active = keep

	local bombKeep = {}
	local bombParams = RaycastParams.new()
	bombParams.FilterType = Enum.RaycastFilterType.Include
	local bombFilter = {}
	local zombiesFolder2 = Workspace:FindFirstChild("Zombies")
	if zombiesFolder2 then
		table.insert(bombFilter, zombiesFolder2)
	end
	local suppliesFolder2 = Workspace:FindFirstChild("Supplies")
	if suppliesFolder2 then
		table.insert(bombFilter, suppliesFolder2)
	end
	local gatesFolder2 = Workspace:FindFirstChild("NumberGates")
	if gatesFolder2 then
		table.insert(bombFilter, gatesFolder2)
	end
	bombParams.FilterDescendantsInstances = bombFilter

	for _, bomb in bombs do
		if not bomb.part.Parent then
			continue
		end
		if now - bomb.born > 2.4 then
			local pos = bomb.part.Position
			bomb.part:Destroy()
			explodeAt(pos, bomb.hits)
			continue
		end

		local nextPos = bomb.part.Position + bomb.direction * bomb.speed * dt
		local travel = nextPos - bomb.part.Position
		local hit = Workspace:Spherecast(bomb.part.Position, 1.35, travel, bombParams)
		local nearPos = bombProximityHit(bomb.part.Position, nextPos + bomb.direction * 2)
		local reachedEnd = nextPos.Z >= bomb.startZ + Config.BombCrate.ThrowDistance
		if hit or nearPos or reachedEnd then
			local pos = if hit then hit.Position elseif nearPos then nearPos else nextPos
			bomb.part:Destroy()
			explodeAt(pos, bomb.hits)
			continue
		end

		local spin = (now - bomb.born) * 10
		bomb.part.CFrame = CFrame.new(nextPos) * CFrame.Angles(spin, 0, spin * 0.35)
		local fuse = bomb.part:FindFirstChild("Fuse")
		if fuse and fuse:IsA("BasePart") then
			fuse.CFrame = bomb.part.CFrame * CFrame.new(0, 0.7, 0)
		end
		table.insert(bombKeep, bomb)
	end
	bombs = bombKeep

	local molotovKeep = {}
	for _, molotov in molotovs do
		if not molotov.part.Parent then
			continue
		end
		if now - molotov.born > 2.4 then
			molotov.part:Destroy()
			explodeMolotovAt(molotov.targetPosition)
			continue
		end
		local nextPos = molotov.part.Position + molotov.direction * molotov.speed * dt
		local reachedEnd = nextPos.Z >= molotov.targetPosition.Z
		if reachedEnd then
			molotov.part:Destroy()
			explodeMolotovAt(molotov.targetPosition)
			continue
		end
		local spin = (now - molotov.born) * 12
		molotov.part.CFrame = CFrame.new(nextPos) * CFrame.Angles(spin, 0, spin * 0.4)
		local wick = molotov.part:FindFirstChild("Wick")
		if wick and wick:IsA("BasePart") then
			wick.CFrame = molotov.part.CFrame * CFrame.new(0, 0.72, 0)
		end
		table.insert(molotovKeep, molotov)
	end
	molotovs = molotovKeep

	local flashKeep = {}
	for _, flash in flashbangs do
		if not flash.part.Parent then
			continue
		end
		if now - flash.born > 2.4 then
			local pos = flash.part.Position
			flash.part:Destroy()
			explodeFlashbangAt(pos)
			continue
		end
		local nextPos = flash.part.Position + flash.direction * flash.speed * dt
		local travel = nextPos - flash.part.Position
		local hit = Workspace:Spherecast(flash.part.Position, 1.1, travel, bombParams)
		local nearPos = bombProximityHit(flash.part.Position, nextPos + flash.direction * 2)
		local traveled = nextPos.Z - flash.startZ
		local reachedEnd = nextPos.Z >= flash.targetZ or traveled >= Config.BombCrate.ThrowDistance
		if hit or nearPos or reachedEnd then
			local pos = if hit then hit.Position elseif nearPos then nearPos else nextPos
			flash.part:Destroy()
			explodeFlashbangAt(pos)
			continue
		end
		local spin = (now - flash.born) * 14
		flash.part.CFrame = CFrame.new(nextPos) * CFrame.Angles(spin, spin * 0.3, 0)
		local tip = flash.part:FindFirstChild("Tip")
		if tip and tip:IsA("BasePart") then
			tip.CFrame = flash.part.CFrame * CFrame.new(0, 0.58, 0)
		end
		table.insert(flashKeep, flash)
	end
	flashbangs = flashKeep

	local rockCfg = Config.ThrowerZombie
	local rockKeep = {}
	for _, rock in rocks do
		if not rock.part.Parent then
			continue
		end
		local t = (now - rock.born) / rock.flight
		if t >= 1 then
			rock.part:Destroy()
			if CombatService._onRockImpact then
				CombatService._onRockImpact(rock.target, rockCfg.RockRadius, rock.damage)
			end
			continue
		end
		local flat = rock.origin:Lerp(rock.target, t)
		local arc = rockCfg.RockArc * 4 * t * (1 - t)
		local spin = (now - rock.born)
		rock.part.CFrame = CFrame.new(flat + Vector3.new(0, arc, 0))
			* CFrame.Angles(rock.spin.X * spin, rock.spin.Y * spin, rock.spin.Z * spin)
		table.insert(rockKeep, rock)
	end
	rocks = rockKeep

	local fireKeep = {}
	local cfg = Config.Molotov
	local tickHits = math.max(1, math.floor(cfg.GroundHitsPerSecond * 0.25 + 0.5))
	local tickHp = cfg.GroundHpPerSecond * 0.25
	for _, fire in groundFires do
		if not fire.part.Parent or now >= fire.untilTime then
			if fire.part.Parent then
				fire.part:Destroy()
			end
			continue
		end
		local left = math.clamp((fire.untilTime - now) / cfg.GroundDuration, 0, 1)
		fire.part.Transparency = 0.22 + 0.45 * (1 - left)
		if now >= fire.nextTick then
			fire.nextTick = now + 0.25
			ZombieService.damageInRadius(fire.position, cfg.GroundRadius, tickHp, tickHits)
			SupplyService.damageInRadius(fire.position, cfg.GroundRadius, tickHits)
			NumberGate.damageInRadius(fire.position, cfg.GroundRadius, tickHits)
		end
		table.insert(fireKeep, fire)
	end
	groundFires = fireKeep
end

function CombatService.clear()
	for _, shot in active do
		if shot.part.Parent then
			shot.part:Destroy()
		end
	end
	active = {}
	for _, bomb in bombs do
		if bomb.part.Parent then
			bomb.part:Destroy()
		end
	end
	bombs = {}
	for _, molotov in molotovs do
		if molotov.part.Parent then
			molotov.part:Destroy()
		end
	end
	molotovs = {}
	for _, flash in flashbangs do
		if flash.part.Parent then
			flash.part:Destroy()
		end
	end
	flashbangs = {}
	for _, rock in rocks do
		if rock.part.Parent then
			rock.part:Destroy()
		end
	end
	rocks = {}
	for _, fire in groundFires do
		if fire.part.Parent then
			fire.part:Destroy()
		end
	end
	groundFires = {}
	local fx = Workspace:FindFirstChild("Fx")
	if fx then
		fx:ClearAllChildren()
	end
end

return CombatService
