local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type ZombieRecord = {
	model: Model,
	root: BasePart,
	humanoid: Humanoid,
	isBoss: boolean,
	walkSpeed: number,
	contactDamage: number,
	lastContact: number,
	alive: boolean,
}

local ZombieService = {}
ZombieService._alive = {} :: { ZombieRecord }
ZombieService._onDied = nil :: ((ZombieRecord) -> ())?
ZombieService._onReached = nil :: ((ZombieRecord) -> ())?

local kill: (ZombieRecord) -> ()

local function weldTo(root: BasePart, child: BasePart)
	child.Anchored = false
	child.CanCollide = false
	child.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = child
	weld.Parent = child
end

local function makeLimb(parent: Model, name: string, size: Vector3, color: Color3, cf: CFrame): Part
	local limb = Instance.new("Part")
	limb.Name = name
	limb.Size = size
	limb.Color = color
	limb.Material = Enum.Material.SmoothPlastic
	limb.CFrame = cf
	limb.Parent = parent
	return limb
end

function ZombieService.create(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	contactDamage: number,
	scale: number,
}): ZombieRecord
	local scale = stats.scale
	local folder = Workspace:WaitForChild("Zombies")

	local model = Instance.new("Model")
	model.Name = if stats.isBoss then "BossZombie" else "Zombie"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2 * scale, 2 * scale, 1.2 * scale)
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	root.Color = Config.Zombie.ClothesColor
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.Parent = model

	local torsoColor = if stats.isBoss then Color3.fromRGB(48, 52, 62) else Config.Zombie.ClothesColor
	local skin = if stats.isBoss then Color3.fromRGB(70, 74, 82) else Config.Zombie.BodyColor

	local torso = makeLimb(
		model,
		"Torso",
		Vector3.new(2.1 * scale, 2.2 * scale, 1.1 * scale),
		torsoColor,
		root.CFrame * CFrame.new(0, 0.1 * scale, 0)
	)
	weldTo(root, torso)

	local head = makeLimb(
		model,
		"Head",
		Vector3.new(1.3 * scale, 1.3 * scale, 1.3 * scale),
		skin,
		root.CFrame * CFrame.new(0, 1.7 * scale, 0)
	)
	head.Material = Enum.Material.SmoothPlastic
	weldTo(root, head)

	for _, side in { -1, 1 } do
		local arm = makeLimb(
			model,
			"Arm",
			Vector3.new(0.7 * scale, 2 * scale, 0.7 * scale),
			skin,
			root.CFrame * CFrame.new(side * 1.4 * scale, 0.05 * scale, 0)
		)
		weldTo(root, arm)

		local leg = makeLimb(
			model,
			"Leg",
			Vector3.new(0.8 * scale, 2 * scale, 0.8 * scale),
			torsoColor,
			root.CFrame * CFrame.new(side * 0.5 * scale, -2 * scale, 0)
		)
		weldTo(root, leg)
	end

	local leftEye = makeLimb(
		model,
		"Eye",
		Vector3.new(0.22 * scale, 0.18 * scale, 0.12 * scale),
		Color3.fromRGB(220, 40, 40),
		head.CFrame * CFrame.new(-0.28 * scale, 0.12 * scale, -0.62 * scale)
	)
	leftEye.Material = Enum.Material.Neon
	weldTo(root, leftEye)

	local rightEye = makeLimb(
		model,
		"Eye",
		Vector3.new(0.22 * scale, 0.18 * scale, 0.12 * scale),
		Color3.fromRGB(220, 40, 40),
		head.CFrame * CFrame.new(0.28 * scale, 0.12 * scale, -0.62 * scale)
	)
	rightEye.Material = Enum.Material.Neon
	weldTo(root, rightEye)

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanQuery = true
	hitbox.Massless = true
	hitbox.Size = Vector3.new(3.6 * scale, 3.8 * scale, 2.6 * scale)
	hitbox.CFrame = root.CFrame
	hitbox.Parent = model
	weldTo(root, hitbox)

	if stats.isBoss then
		local spike = makeLimb(
			model,
			"Flail",
			Vector3.new(1.4 * scale, 1.4 * scale, 1.4 * scale),
			Color3.fromRGB(30, 30, 32),
			root.CFrame * CFrame.new(2.4 * scale, 0.2 * scale, -1.6 * scale)
		)
		spike.Material = Enum.Material.Metal
		weldTo(root, spike)
		model:SetAttribute("IsBoss", true)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.WalkSpeed = stats.walkSpeed
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(36, 4)
	billboard.StudsOffset = Vector3.new(0, 2.55 * scale, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 180
	billboard.LightInfluence = 0
	billboard.Parent = head

	local bg = Instance.new("Frame")
	bg.Name = "Back"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	bg.BackgroundTransparency = 0.08
	bg.BorderSizePixel = 0
	bg.Parent = billboard
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 32, 32)
	fill.BorderSizePixel = 0
	fill.Parent = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	humanoid.HealthChanged:Connect(function(hp)
		local ratio = math.clamp(hp / math.max(humanoid.MaxHealth, 1), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = Color3.fromRGB(255, 32, 32)
	end)

	model.PrimaryPart = root
	model:SetAttribute("HitRadius", Config.Zombie.HitRadius * scale)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Horde"
		end
	end
	model.Parent = folder

	local record: ZombieRecord = {
		model = model,
		root = root,
		humanoid = humanoid,
		isBoss = stats.isBoss,
		walkSpeed = stats.walkSpeed,
		contactDamage = stats.contactDamage,
		lastContact = 0,
		alive = true,
	}

	humanoid.Died:Connect(function()
		kill(record)
	end)

	table.insert(ZombieService._alive, record)
	return record
end

kill = function(record: ZombieRecord)
	if not record.alive then
		return
	end
	record.alive = false
	record.humanoid.Health = 0
	if ZombieService._onDied then
		ZombieService._onDied(record)
	end
	if record.model.Parent then
		record.model:Destroy()
	end
end

function ZombieService.damageModel(model: Model, amount: number): boolean
	for _, record in ZombieService._alive do
		if record.model == model and record.alive then
			local nextHealth = record.humanoid.Health - amount
			record.humanoid.Health = nextHealth
			if nextHealth <= 0 then
				kill(record)
			end
			return true
		end
	end
	return false
end

function ZombieService.onDied(callback: (ZombieRecord) -> ())
	ZombieService._onDied = callback
end

function ZombieService.onReached(callback: (ZombieRecord) -> ())
	ZombieService._onReached = callback
end

function ZombieService.getAlive(): { ZombieRecord }
	local list = {}
	for _, record in ZombieService._alive do
		if record.alive and record.model.Parent and record.humanoid.Health > 0 then
			table.insert(list, record)
		end
	end
	ZombieService._alive = list
	return list
end

function ZombieService.nearest(fromPosition: Vector3): ZombieRecord?
	local best: ZombieRecord? = nil
	local bestDist = math.huge
	for _, record in ZombieService.getAlive() do
		local pos = record.root.Position
		if pos.Z <= fromPosition.Z then
			continue
		end
		local dist = (pos - fromPosition).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = record
		end
	end
	return best
end

function ZombieService.update(dt: number, playerPosition: Vector3?)
	if not playerPosition then
		return
	end

	local now = os.clock()
	for _, record in ZombieService.getAlive() do
		local pos = record.root.Position
		local targetX = pos.X
		if pos.Z <= Config.Zombie.ChaseStartZ then
			local chaseSpeed = record.walkSpeed * Config.Zombie.ChaseSpeedScale
			local dx = playerPosition.X - pos.X
			local maxStep = chaseSpeed * dt
			if math.abs(dx) > 0.08 then
				targetX = pos.X + math.clamp(dx, -maxStep, maxStep)
			else
				targetX = playerPosition.X
			end
			local half = Config.Lane.Width / 2 - 3
			targetX = math.clamp(targetX, -half, half)
		end

		local nextZ = pos.Z - record.walkSpeed * dt
		if nextZ < Config.Lane.PlayerZ then
			nextZ = Config.Lane.PlayerZ
		end
		local nextPos = Vector3.new(targetX, pos.Y, nextZ)
		local lookAt = if pos.Z <= Config.Zombie.ChaseStartZ
			then Vector3.new(playerPosition.X, nextPos.Y, Config.Lane.PlayerZ)
			else nextPos + Vector3.new(0, 0, -1)
		if (lookAt - nextPos).Magnitude > 0.05 then
			record.root.CFrame = CFrame.lookAt(nextPos, lookAt)
		else
			record.root.CFrame = CFrame.new(nextPos) * record.root.CFrame.Rotation
		end

		local flat = Vector3.new(pos.X - playerPosition.X, 0, pos.Z - playerPosition.Z)
		local reach = (record.model:GetAttribute("HitRadius") :: number) + 1.6
		if flat.Magnitude <= reach and now - record.lastContact >= Config.Zombie.ContactCooldown then
			record.lastContact = now
			if ZombieService._onReached then
				ZombieService._onReached(record)
			end
		end
	end
end

function ZombieService.clear()
	for _, record in ZombieService._alive do
		record.alive = false
		if record.model.Parent then
			record.model:Destroy()
		end
	end
	ZombieService._alive = {}
	local folder = Workspace:FindFirstChild("Zombies")
	if folder then
		folder:ClearAllChildren()
	end
end

return ZombieService
