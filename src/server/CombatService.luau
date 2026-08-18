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

local function explodeAt(position: Vector3, hits: number)
	local cfg = Config.BombCrate
	local numberedHits = math.max(cfg.HitDamage, math.max(1, math.floor(hits)))
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
		hits = math.max(1, math.floor(cfg.HitDamage or hits or 1)),
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
	local amount = if oneshot then 1e9 else damage
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

	local suppliesFolder = Workspace:FindFirstChild("Supplies")
	if suppliesFolder then
		for _, child in suppliesFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("IsSupply") == true and not shot.hitSet[child] then
				local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flatPoint = Vector3.new(root.Position.X, from.Y, root.Position.Z)
					local dist = (pointToSegmentDist(flatPoint, from, to))
					if dist <= 3.4 * Config.Supply.SizeScale + shot.radius then
						shot.hitSet[child] = true
						applyShot(child, shot.damage, shot.hits, shot.oneshot)
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
					if dist <= reach then
						shot.hitSet[child] = true
						applyShot(child, shot.damage, shot.hits, shot.oneshot)
					end
				end
			end
		end
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
	local fx = Workspace:FindFirstChild("Fx")
	if fx then
		fx:ClearAllChildren()
	end
end

return CombatService
