local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)
local SupplyService = require(script.Parent.SupplyService)

local CombatService = {}
CombatService._remotes = nil :: any

local active = {} :: {
	{
		part: BasePart,
		direction: Vector3,
		speed: number,
		damage: number,
		born: number,
	}
}

local bombs = {} :: {
	{
		part: BasePart,
		velocity: Vector3,
		born: number,
	}
}

function CombatService.bind(remotes)
	CombatService._remotes = remotes
end

local function spawnBolt(origin: Vector3, direction: Vector3): BasePart
	local bolt = Instance.new("Part")
	bolt.Name = "Bolt"
	bolt.Shape = Enum.PartType.Block
	bolt.Size = Vector3.new(0.28, 0.28, 3.4)
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(255, 220, 70)
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.CastShadow = false
	bolt.CFrame = CFrame.lookAt(origin, origin + direction)
	bolt.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local tip = Instance.new("WedgePart")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.3, 0.3, 0.7)
	tip.Material = Enum.Material.Neon
	tip.Color = Color3.fromRGB(255, 245, 180)
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CastShadow = false
	tip.CFrame = bolt.CFrame * CFrame.new(0, 0, -2.0)
	tip.Parent = bolt

	return bolt
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

local function explodeAt(position: Vector3)
	local cfg = Config.BombCrate
	ZombieService.damageInRadius(position, cfg.Radius, cfg.Damage)
	if CombatService._remotes then
		CombatService._remotes.ExplodeFx:FireAllClients(position, cfg.Radius)
	end
end

function CombatService.throwBomb(origin: Vector3)
	local cfg = Config.BombCrate
	local part = spawnThrownBomb(origin)
	local target = Vector3.new(origin.X, Config.Lane.CenterY + 1.15, origin.Z + cfg.ThrowDistance)
	local flight = cfg.FlightTime
	local gravity = cfg.Gravity
	local disp = target - origin
	local velocity = Vector3.new(
		disp.X / flight,
		disp.Y / flight + 0.5 * gravity * flight,
		disp.Z / flight
	)
	table.insert(bombs, {
		part = part,
		velocity = velocity,
		born = os.clock(),
	})
end

function CombatService.fireStraight(origin: Vector3, damage: number)
	local direction = Vector3.new(0, 0, 1)
	local part = spawnBolt(origin, direction)
	table.insert(active, {
		part = part,
		direction = direction,
		speed = Config.Combat.ProjectileSpeed,
		damage = damage,
		born = os.clock(),
	})
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
local function proximityHit(from: Vector3, to: Vector3, damage: number): (boolean, Vector3?, boolean?)
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
					if dist <= 3.4 and dist < bestDist then
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
		local damaged = false
		if bestModel:GetAttribute("IsSupply") == true then
			damaged = SupplyService.damageModel(bestModel, damage)
		else
			damaged = ZombieService.damageModel(bestModel, damage)
		end
		return damaged, bestPos, bestBoss
	end
	return false, nil, nil
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
	params.FilterDescendantsInstances = filter

	local now = os.clock()
	for _, shot in active do
		if not shot.part.Parent then
			continue
		end
		if now - shot.born > Config.Combat.ProjectileLifetime then
			shot.part:Destroy()
			continue
		end

		local visual = shot.part.Position
		local nextPos = visual + shot.direction * shot.speed * dt
		local castFrom = visual - shot.direction * 1.5
		local castTravel = shot.direction * (shot.speed * dt + 3.4)
		local result = Workspace:Spherecast(castFrom, 1.35, castTravel, params)

		local hitPos: Vector3? = nil
		local hitBoss = false
		local damaged = false

		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			while model and model.Name == "Bolt" do
				model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
			end
			if model then
				if model:GetAttribute("IsSupply") == true then
					damaged = SupplyService.damageModel(model, shot.damage)
				else
					damaged = ZombieService.damageModel(model, shot.damage)
				end
				hitPos = result.Position
				hitBoss = model:GetAttribute("IsBoss") == true
			end
		end

		if not damaged then
			local ok, pos, boss = proximityHit(castFrom, nextPos + shot.direction * 2, shot.damage)
			if ok and pos then
				damaged = true
				hitPos = pos
				hitBoss = boss == true
			end
		end

		if damaged then
			shot.part:Destroy()
			continue
		end

		local look = CFrame.lookAt(nextPos, nextPos + shot.direction)
		shot.part.CFrame = look
		local tip = shot.part:FindFirstChild("Tip")
		if tip and tip:IsA("BasePart") then
			tip.CFrame = look * CFrame.new(0, 0, -2.0)
		end
		table.insert(keep, shot)
	end
	active = keep

	local groundY = Config.Lane.CenterY + Config.Lane.Thickness * 0.5 + 0.7
	local bombKeep = {}
	local bombParams = RaycastParams.new()
	bombParams.FilterType = Enum.RaycastFilterType.Include
	local bombFilter = {}
	local zombiesFolder2 = Workspace:FindFirstChild("Zombies")
	if zombiesFolder2 then
		table.insert(bombFilter, zombiesFolder2)
	end
	bombParams.FilterDescendantsInstances = bombFilter

	for _, bomb in bombs do
		if not bomb.part.Parent then
			continue
		end
		if now - bomb.born > 2.4 then
			local pos = bomb.part.Position
			bomb.part:Destroy()
			explodeAt(pos)
			continue
		end

		local nextVel = bomb.velocity + Vector3.new(0, -Config.BombCrate.Gravity, 0) * dt
		local nextPos = bomb.part.Position + nextVel * dt
		local travel = nextPos - bomb.part.Position
		local hit = Workspace:Spherecast(bomb.part.Position, 1.15, travel, bombParams)
		local landed = nextPos.Y <= groundY
		if hit or landed then
			local pos = if hit then hit.Position else Vector3.new(nextPos.X, groundY, nextPos.Z)
			bomb.part:Destroy()
			explodeAt(pos)
			continue
		end

		bomb.velocity = nextVel
		bomb.part.CFrame = CFrame.new(nextPos)
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
