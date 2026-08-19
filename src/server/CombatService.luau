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
		born: number,
		pierce: boolean,
		oneshot: boolean,
		radius: number,
		endZ: number?,
		hitSet: { [Model]: boolean },
		tipOffset: number,
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

local groundFires = {} :: {
	{
		part: BasePart,
		position: Vector3,
		untilTime: number,
		nextTick: number,
	}
}

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
	ZombieService.damageInRadius(position, cfg.Radius, cfg.Damage, numberedHits)
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
		born = os.clock(),
		pierce = true,
		oneshot = true,
		radius = cfg.ProjectileRadius,
		endZ = Config.activeLane().SpawnZ + 12,
		hitSet = {},
		tipOffset = tipOffset,
	})
end

local function applyShot(model: Model, damage: number, hits: number, oneshot: boolean?): boolean
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
	return ZombieService.damageModel(model, amount, hits)
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
			applyShot(record.model, shot.damage, shot.hits, shot.oneshot)
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
		applyShot(bestSideModel, shot.damage, shot.hits, shot.oneshot)
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
			local castTravel = shot.direction * (shot.speed * dt + 3.4)
			local result = Workspace:Spherecast(castFrom, shot.radius, castTravel, params)
			local damaged = false
			if result then
				local model = result.Instance:FindFirstAncestorOfClass("Model")
				while model and model.Name == "Bolt" do
					model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
				end
				if model then
					damaged = applyShot(model, shot.damage, shot.hits, shot.oneshot)
				end
			end
			if not damaged then
				local ok = proximityHit(castFrom, castTo, shot.damage, shot.hits)
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
