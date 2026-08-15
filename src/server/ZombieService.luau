local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type ZombieMotors = {
	neck: Motor6D?,
	waist: Motor6D?,
	root: Motor6D?,
	leftShoulder: Motor6D?,
	rightShoulder: Motor6D?,
	leftElbow: Motor6D?,
	rightElbow: Motor6D?,
	leftHip: Motor6D?,
	rightHip: Motor6D?,
	leftKnee: Motor6D?,
	rightKnee: Motor6D?,
	-- R6
	leftArm: Motor6D?,
	rightArm: Motor6D?,
	leftLeg: Motor6D?,
	rightLeg: Motor6D?,
}

export type ZombieRecord = {
	model: Model,
	root: BasePart,
	humanoid: Humanoid,
	isBoss: boolean,
	isDog: boolean,
	walkSpeed: number,
	contactDamage: number,
	lastContact: number,
	attackUntil: number,
	baseY: number,
	phase: number,
	limp: number,
	leftArm: Weld?,
	rightArm: Weld?,
	leftLeg: Weld?,
	rightLeg: Weld?,
	motors: ZombieMotors?,
	attackTarget: { kind: string, ally: any? },
	alive: boolean,
}

local ZombieService = {}
ZombieService._alive = {} :: { ZombieRecord }
ZombieService._onDied = nil :: ((ZombieRecord) -> ())?
ZombieService._onReached = nil :: ((ZombieRecord) -> ())?

local kill: (ZombieRecord) -> ()

local function weldConstraint(root: BasePart, child: BasePart)
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
	limb.Anchored = false
	limb.CanCollide = false
	limb.Massless = true
	limb.Parent = parent
	return limb
end

local function attachWeld(root: BasePart, child: BasePart, c0: CFrame): Weld
	child.Anchored = false
	child.CanCollide = false
	child.Massless = true
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = child
	weld.C0 = c0
	weld.C1 = CFrame.identity
	weld.Parent = child
	return weld
end

local function motorIn(part: Instance?, name: string): Motor6D?
	if not part then
		return nil
	end
	local found = part:FindFirstChild(name)
	if found and found:IsA("Motor6D") then
		return found
	end
	return nil
end

local function collectMotors(model: Model): ZombieMotors
	return {
		neck = motorIn(model:FindFirstChild("Head"), "Neck")
			or motorIn(model:FindFirstChild("Torso"), "Neck"),
		waist = motorIn(model:FindFirstChild("UpperTorso"), "Waist"),
		root = motorIn(model:FindFirstChild("LowerTorso"), "Root")
			or motorIn(model:FindFirstChild("HumanoidRootPart"), "RootJoint"),
		leftShoulder = motorIn(model:FindFirstChild("LeftUpperArm"), "LeftShoulder"),
		rightShoulder = motorIn(model:FindFirstChild("RightUpperArm"), "RightShoulder"),
		leftElbow = motorIn(model:FindFirstChild("LeftLowerArm"), "LeftElbow"),
		rightElbow = motorIn(model:FindFirstChild("RightLowerArm"), "RightElbow"),
		leftHip = motorIn(model:FindFirstChild("LeftUpperLeg"), "LeftHip"),
		rightHip = motorIn(model:FindFirstChild("RightUpperLeg"), "RightHip"),
		leftKnee = motorIn(model:FindFirstChild("LeftLowerLeg"), "LeftKnee"),
		rightKnee = motorIn(model:FindFirstChild("RightLowerLeg"), "RightKnee"),
		leftArm = motorIn(model:FindFirstChild("Torso"), "Left Shoulder"),
		rightArm = motorIn(model:FindFirstChild("Torso"), "Right Shoulder"),
		leftLeg = motorIn(model:FindFirstChild("Torso"), "Left Hip"),
		rightLeg = motorIn(model:FindFirstChild("Torso"), "Right Hip"),
	}
end

local function findStorageModel(candidates: { string }): Model?
	for _, name in candidates do
		local found = ReplicatedStorage:FindFirstChild(name)
		if found and found:IsA("Model") then
			return found
		end
	end
	-- Studio names may differ only by case / spacing.
	for _, child in ReplicatedStorage:GetChildren() do
		if child:IsA("Model") then
			local lower = string.lower(child.Name)
			for _, name in candidates do
				if lower == string.lower(name) then
					return child
				end
			end
		end
	end
	return nil
end

local function getNormalPrototype(): Model?
	return findStorageModel({
		"zombieprototype",
		"ZombiePrototype",
		"Zombie Prototype",
	})
end

local function getBossPrototype(): Model?
	return findStorageModel({
		"killer BIG zombie",
		"killer big zombie",
		"Killer BIG zombie",
		"KillerBigZombie",
	})
end

local function attachHealthBar(head: BasePart, humanoid: Humanoid, scale: number, isDog: boolean)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(36, 4)
	billboard.StudsOffset = Vector3.new(0, (if isDog then 1.8 else 1.35) * scale, 0)
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
	end)
end

local function attachHitbox(model: Model, root: BasePart, scale: number, isDog: boolean)
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanQuery = true
	hitbox.Massless = true
	hitbox.Size = if isDog
		then Vector3.new(3.6 * scale, 4.8 * scale, 4.4 * scale)
		else Vector3.new(3.4 * scale, 5.2 * scale, 2.4 * scale)
	hitbox.CFrame = if isDog
		then root.CFrame * CFrame.new(0, 1.1 * scale, 0)
		else root.CFrame * CFrame.new(0, 0.4 * scale, 0)
	hitbox.Parent = model
	weldConstraint(root, hitbox)
end

local function finalizeModel(model: Model, root: BasePart, humanoid: Humanoid, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	isDog: boolean,
	scale: number,
}, head: BasePart)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	for _, track in humanoid:GetPlayingAnimationTracks() do
		track:Stop(0)
	end
	local animate = model:FindFirstChild("Animate")
	if animate then
		if animate:IsA("LocalScript") or animate:IsA("Script") then
			animate.Disabled = true
		end
		animate:Destroy()
	end

	attachHealthBar(head, humanoid, stats.scale, stats.isDog)
	attachHitbox(model, root, stats.scale, stats.isDog)

	model.PrimaryPart = root
	local hitRadius = if stats.isDog then Config.ZombieDog.HitRadius else Config.Zombie.HitRadius
	model:SetAttribute("HitRadius", hitRadius * stats.scale)
	if stats.isBoss then
		model:SetAttribute("IsBoss", true)
	end
	if stats.isDog then
		model:SetAttribute("IsDog", true)
	end

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Horde"
			desc.CanQuery = true
			if desc ~= root then
				desc.CanCollide = false
				desc.Massless = true
				desc.Anchored = false
			end
		end
	end
	root.Anchored = true
	root.CanCollide = true
end

local function createDog(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	scale: number,
	contactDamage: number,
}): ZombieRecord
	local scale = stats.scale
	local folder = Workspace:WaitForChild("Zombies")
	local model = Instance.new("Model")
	model.Name = "ZombieDog"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.4 * scale, 1.1 * scale, 3.2 * scale)
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	root.Color = Config.ZombieDog.BodyColor
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.Transparency = 1
	root.Parent = model

	local bodyColor = Config.ZombieDog.BodyColor
	local dark = Color3.fromRGB(40, 44, 36)

	weldConstraint(
		root,
		makeLimb(model, "Body", Vector3.new(1.6 * scale, 1.15 * scale, 2.8 * scale), bodyColor, root.CFrame * CFrame.new(0, 0.15 * scale, 0))
	)
	local head = makeLimb(
		model,
		"Head",
		Vector3.new(1.15 * scale, 0.95 * scale, 1.35 * scale),
		bodyColor,
		root.CFrame * CFrame.new(0, 0.45 * scale, -1.55 * scale)
	)
	weldConstraint(root, head)
	weldConstraint(
		root,
		makeLimb(model, "Snout", Vector3.new(0.7 * scale, 0.55 * scale, 0.85 * scale), dark, head.CFrame * CFrame.new(0, -0.1 * scale, -0.75 * scale))
	)

	local fl = makeLimb(model, "FrontLeft", Vector3.new(0.45 * scale, 1.35 * scale, 0.45 * scale), dark, root.CFrame)
	local fr = makeLimb(model, "FrontRight", Vector3.new(0.45 * scale, 1.35 * scale, 0.45 * scale), dark, root.CFrame)
	local leftArmWeld = attachWeld(root, fl, CFrame.new(-0.55 * scale, -0.85 * scale, -0.85 * scale))
	local rightArmWeld = attachWeld(root, fr, CFrame.new(0.55 * scale, -0.85 * scale, -0.85 * scale))
	local bl = makeLimb(model, "BackLeft", Vector3.new(0.5 * scale, 1.35 * scale, 0.5 * scale), dark, root.CFrame)
	local br = makeLimb(model, "BackRight", Vector3.new(0.5 * scale, 1.35 * scale, 0.5 * scale), dark, root.CFrame)
	local leftLegWeld = attachWeld(root, bl, CFrame.new(-0.55 * scale, -0.85 * scale, 0.95 * scale))
	local rightLegWeld = attachWeld(root, br, CFrame.new(0.55 * scale, -0.85 * scale, 0.95 * scale))

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	finalizeModel(model, root, humanoid, {
		health = stats.health,
		walkSpeed = stats.walkSpeed,
		isBoss = stats.isBoss,
		isDog = true,
		scale = scale,
	}, head)
	model.Parent = folder

	local record: ZombieRecord = {
		model = model,
		root = root,
		humanoid = humanoid,
		isBoss = stats.isBoss,
		isDog = true,
		walkSpeed = stats.walkSpeed,
		contactDamage = stats.contactDamage,
		lastContact = 0,
		attackUntil = 0,
		baseY = position.Y,
		phase = math.random() * math.pi * 2,
		limp = 0.7 + math.random() * 0.6,
		leftArm = leftArmWeld,
		rightArm = rightArmWeld,
		leftLeg = leftLegWeld,
		rightLeg = rightLegWeld,
		motors = nil,
		attackTarget = { kind = "player", ally = nil },
		alive = true,
	}
	humanoid.Died:Connect(function()
		kill(record)
	end)
	table.insert(ZombieService._alive, record)
	return record
end

local function createProceduralHuman(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	scale: number,
	contactDamage: number,
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
	weldConstraint(
		root,
		makeLimb(model, "Torso", Vector3.new(2.1 * scale, 2.2 * scale, 1.1 * scale), torsoColor, root.CFrame * CFrame.new(0, 0.1 * scale, 0))
	)
	local head = makeLimb(model, "Head", Vector3.new(1.3 * scale, 1.3 * scale, 1.3 * scale), skin, root.CFrame * CFrame.new(0, 1.7 * scale, 0))
	weldConstraint(root, head)

	local leftArm = makeLimb(model, "LeftArm", Vector3.new(0.7 * scale, 2 * scale, 0.7 * scale), skin, root.CFrame)
	local rightArm = makeLimb(model, "RightArm", Vector3.new(0.7 * scale, 2 * scale, 0.7 * scale), skin, root.CFrame)
	local leftArmWeld = attachWeld(
		root,
		leftArm,
		CFrame.new(-1.35 * scale, 0.85 * scale, -0.55 * scale) * CFrame.Angles(math.rad(-155), 0, math.rad(18))
	)
	local rightArmWeld = attachWeld(
		root,
		rightArm,
		CFrame.new(1.35 * scale, 0.85 * scale, -0.55 * scale) * CFrame.Angles(math.rad(-155), 0, math.rad(-18))
	)
	local leftLeg = makeLimb(model, "LeftLeg", Vector3.new(0.8 * scale, 2 * scale, 0.8 * scale), torsoColor, root.CFrame)
	local rightLeg = makeLimb(model, "RightLeg", Vector3.new(0.8 * scale, 2 * scale, 0.8 * scale), torsoColor, root.CFrame)
	local leftLegWeld = attachWeld(root, leftLeg, CFrame.new(-0.5 * scale, -2 * scale, 0))
	local rightLegWeld = attachWeld(root, rightLeg, CFrame.new(0.5 * scale, -2 * scale, 0))

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	finalizeModel(model, root, humanoid, {
		health = stats.health,
		walkSpeed = stats.walkSpeed,
		isBoss = stats.isBoss,
		isDog = false,
		scale = scale,
	}, head)
	model.Parent = folder

	local record: ZombieRecord = {
		model = model,
		root = root,
		humanoid = humanoid,
		isBoss = stats.isBoss,
		isDog = false,
		walkSpeed = stats.walkSpeed,
		contactDamage = stats.contactDamage,
		lastContact = 0,
		attackUntil = 0,
		baseY = position.Y,
		phase = math.random() * math.pi * 2,
		limp = 0.75 + math.random() * 0.55,
		leftArm = leftArmWeld,
		rightArm = rightArmWeld,
		leftLeg = leftLegWeld,
		rightLeg = rightLegWeld,
		motors = nil,
		attackTarget = { kind = "player", ally = nil },
		alive = true,
	}
	humanoid.Died:Connect(function()
		kill(record)
	end)
	table.insert(ZombieService._alive, record)
	return record
end

local function createFromPrototype(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	scale: number,
	contactDamage: number,
}): ZombieRecord?
	local bossProto = getBossPrototype()
	local normalProto = getNormalPrototype()
	local proto = if stats.isBoss then (bossProto or normalProto) else normalProto
	if not proto then
		return nil
	end

	local usingBossMesh = stats.isBoss and bossProto ~= nil and proto == bossProto

	local folder = Workspace:WaitForChild("Zombies")
	local model = proto:Clone()
	model.Name = if stats.isBoss then "BossZombie" else "Zombie"

	local root: BasePart? = nil
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		root = hrp
	elseif model.PrimaryPart then
		root = model.PrimaryPart
	else
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "HumanoidRootPart" or d.Name == "Torso" or d.Name == "UpperTorso") then
				root = d
				break
			end
		end
	end
	if not root then
		warn("[ZombieService] Prototype has no root part:", proto.Name)
		model:Destroy()
		return nil
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
	end

	local headInst = model:FindFirstChild("Head")
	local head: BasePart = if headInst and headInst:IsA("BasePart") then headInst else root

	-- Dedicated big-zombie mesh is already large — don't double ScaleTo.
	local applyScale = if usingBossMesh then 1 else stats.scale
	if math.abs(applyScale - 1) > 0.01 then
		pcall(function()
			model:ScaleTo(applyScale)
		end)
	end

	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	root.Anchored = true
	model.PrimaryPart = root
	model.Parent = folder

	-- Plant feet on the road (prototype pivot heights vary).
	local bboxCf, bboxSize = model:GetBoundingBox()
	local groundY = Config.Lane.CenterY + Config.Lane.Thickness * 0.5
	local bottomY = bboxCf.Position.Y - bboxSize.Y * 0.5
	local lift = groundY - bottomY
	if math.abs(lift) > 0.01 then
		root.CFrame = root.CFrame + Vector3.new(0, lift, 0)
	end

	local hitScale = if usingBossMesh then math.max(stats.scale, 2.0) else stats.scale
	finalizeModel(model, root, humanoid, {
		health = stats.health,
		walkSpeed = stats.walkSpeed,
		isBoss = stats.isBoss,
		isDog = false,
		scale = hitScale,
	}, head)

	local motors = collectMotors(model)

	local record: ZombieRecord = {
		model = model,
		root = root,
		humanoid = humanoid,
		isBoss = stats.isBoss,
		isDog = false,
		walkSpeed = stats.walkSpeed,
		contactDamage = stats.contactDamage,
		lastContact = 0,
		attackUntil = 0,
		baseY = root.Position.Y,
		phase = math.random() * math.pi * 2,
		limp = 0.7 + math.random() * 0.7,
		leftArm = nil,
		rightArm = nil,
		leftLeg = nil,
		rightLeg = nil,
		motors = motors,
		attackTarget = { kind = "player", ally = nil },
		alive = true,
	}
	humanoid.Died:Connect(function()
		kill(record)
	end)
	table.insert(ZombieService._alive, record)
	return record
end

function ZombieService.create(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	isDog: boolean?,
	contactDamage: number,
	scale: number,
}): ZombieRecord
	if stats.isDog == true then
		return createDog(position, {
			health = stats.health,
			walkSpeed = stats.walkSpeed,
			isBoss = stats.isBoss,
			scale = stats.scale,
			contactDamage = stats.contactDamage,
		})
	end

	local fromProto = createFromPrototype(position, {
		health = stats.health,
		walkSpeed = stats.walkSpeed,
		isBoss = stats.isBoss,
		scale = stats.scale,
		contactDamage = stats.contactDamage,
	})
	if fromProto then
		return fromProto
	end

	warn("[ZombieService] ReplicatedStorage zombieprototype / killer BIG zombie missing — using procedural zombie")
	return createProceduralHuman(position, {
		health = stats.health,
		walkSpeed = stats.walkSpeed,
		isBoss = stats.isBoss,
		scale = stats.scale,
		contactDamage = stats.contactDamage,
	})
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

function ZombieService.setAttackTarget(record: ZombieRecord, target: { kind: string, ally: any? })
	record.attackTarget = target
end

local function resolveTargetPosition(record: ZombieRecord, playerPosition: Vector3): Vector3
	local target = record.attackTarget
	if target.kind == "ally" then
		local ally = target.ally
		if ally and ally.alive and ally.model and ally.model.Parent and ally.root then
			return ally.root.Position
		end
		record.attackTarget = { kind = "player", ally = nil }
	end
	return playerPosition
end

local function applyPrototypePose(record: ZombieRecord, moving: boolean, attacking: boolean, lean: number)
	local m = record.motors
	if not m then
		return
	end

	local limp = record.limp
	local p = record.phase
	local swing = math.sin(p)
	local drag = math.sin(p * 0.55 + 0.4)
	local lurch = math.max(0, math.sin(p * 0.9))
	local moveScale = if moving then 1 else 0.35
	local attackReach = if attacking then 1 else 0

	-- R15 zombie shambling
	if m.rightShoulder then
		m.rightShoulder.Transform = CFrame.Angles(
			math.rad(-95 - 18 * attackReach + 10 * swing * moveScale),
			math.rad(-22 + 8 * drag),
			math.rad(12 + 6 * limp)
		)
	end
	if m.leftShoulder then
		m.leftShoulder.Transform = CFrame.Angles(
			math.rad(-88 - 22 * attackReach - 8 * swing * moveScale),
			math.rad(28 - 6 * drag),
			math.rad(-16 - 4 * limp)
		)
	end
	if m.rightElbow then
		m.rightElbow.Transform = CFrame.Angles(math.rad(-28 - 10 * lurch), math.rad(8), 0)
	end
	if m.leftElbow then
		m.leftElbow.Transform = CFrame.Angles(math.rad(-22 - 14 * lurch), math.rad(-6), 0)
	end
	if m.rightHip then
		m.rightHip.Transform = CFrame.Angles(
			math.rad(38 * swing * moveScale * limp) + math.rad(6),
			math.rad(4),
			math.rad(6)
		)
	end
	if m.leftHip then
		-- Heavier limp on one side
		m.leftHip.Transform = CFrame.Angles(
			math.rad(-22 * swing * moveScale) + math.rad(10 * limp),
			math.rad(-6),
			math.rad(-8)
		)
	end
	if m.rightKnee then
		m.rightKnee.Transform = CFrame.Angles(math.rad(-18 - 20 * math.max(0, swing) * moveScale), 0, 0)
	end
	if m.leftKnee then
		m.leftKnee.Transform = CFrame.Angles(math.rad(-28 - 12 * math.max(0, -swing) * moveScale), 0, 0)
	end
	if m.waist then
		m.waist.Transform = CFrame.Angles(
			math.rad(10 + 6 * lurch + lean * 20),
			math.rad(12 * drag),
			math.rad(-5 * swing)
		)
	end
	if m.neck then
		m.neck.Transform = CFrame.Angles(math.rad(14 + 8 * lurch), math.rad(-16 * drag), math.rad(8 * limp - 4))
	end
	if m.root then
		m.root.Transform = CFrame.Angles(math.rad(4 + 3 * lurch), math.rad(5 * drag), math.rad(3 * swing))
	end

	-- R6 fallback motors
	if m.rightArm then
		m.rightArm.Transform = CFrame.Angles(math.rad(-100 - 15 * attackReach + 8 * swing), 0, math.rad(20))
	end
	if m.leftArm then
		m.leftArm.Transform = CFrame.Angles(math.rad(-95 - 18 * attackReach - 6 * swing), 0, math.rad(-24))
	end
	if m.rightLeg then
		m.rightLeg.Transform = CFrame.Angles(math.rad(32 * swing * moveScale * limp), 0, math.rad(6))
	end
	if m.leftLeg then
		m.leftLeg.Transform = CFrame.Angles(math.rad(-20 * swing * moveScale) + math.rad(8), 0, math.rad(-8))
	end
end

local function applyWeldPose(record: ZombieRecord, moving: boolean, attacking: boolean)
	if not (record.leftArm and record.rightArm and record.leftLeg and record.rightLeg) then
		return
	end
	local swing = math.sin(record.phase)
	local swing2 = math.sin(record.phase * 1.35 + 0.6)
	local moveScale = if moving then 1 else 0.4
	local reach = if attacking then 1 else 0

	if record.isDog then
		record.leftArm.C1 = CFrame.Angles(math.rad(38) * swing, 0, 0)
		record.rightArm.C1 = CFrame.Angles(math.rad(-38) * swing, 0, 0)
		record.leftLeg.C1 = CFrame.Angles(math.rad(-38) * swing, 0, 0)
		record.rightLeg.C1 = CFrame.Angles(math.rad(38) * swing, 0, 0)
	else
		record.leftArm.C1 = CFrame.Angles(math.rad(18 * swing2 * moveScale - 12 * reach), math.rad(14) * swing, math.rad(-10) * swing)
		record.rightArm.C1 = CFrame.Angles(math.rad(-20 * swing2 * moveScale - 14 * reach), math.rad(-16) * swing, math.rad(10) * swing)
		record.leftLeg.C1 = CFrame.Angles(math.rad(34 * swing * moveScale * record.limp), 0, math.rad(-6))
		record.rightLeg.C1 = CFrame.Angles(math.rad(-26 * swing * moveScale) + math.rad(6), 0, math.rad(5))
	end
end

function ZombieService.update(dt: number, playerPosition: Vector3?)
	if not playerPosition then
		return
	end

	local now = os.clock()
	local stopZ = Config.Lane.PlayerZ + Config.Zombie.StopDistance

	for _, record in ZombieService.getAlive() do
		local pos = record.root.Position
		local focus = resolveTargetPosition(record, playerPosition)
		local targetX = pos.X
		if pos.Z <= Config.Zombie.ChaseStartZ then
			local chaseSpeed = record.walkSpeed * Config.Zombie.ChaseSpeedScale
			local dx = focus.X - pos.X
			local maxStep = chaseSpeed * dt
			if math.abs(dx) > 0.08 then
				targetX = pos.X + math.clamp(dx, -maxStep, maxStep)
			else
				targetX = focus.X
			end
			local half = Config.Lane.Width / 2 - 3
			targetX = math.clamp(targetX, -half, half)
		end

		local moving = pos.Z > stopZ + 0.15
		local nextZ = if moving then pos.Z - record.walkSpeed * dt else stopZ
		if nextZ < stopZ then
			nextZ = stopZ
		end

		local attacking = now < record.attackUntil
		local lean = 0
		if attacking then
			local t = 1 - (record.attackUntil - now) / Config.Zombie.AttackDuration
			lean = math.sin(t * math.pi) * math.rad(28)
		end

		local shamble = Config.Zombie.ShambleSpeed * (if moving then 1.15 else 0.55) * (if record.isDog then 1.45 else record.limp)
		record.phase += dt * shamble
		local swing = math.sin(record.phase)
		local sway = math.sin(record.phase * 0.55) * math.rad(if record.isDog then 3 else 10)
		local bob = math.abs(math.sin(record.phase * 0.5)) * (if record.isDog then 0.18 else 0.16)
		local lurch = math.max(0, math.sin(record.phase * 0.9)) * (if record.isDog then 0 else 0.08)

		if record.motors then
			applyPrototypePose(record, moving, attacking, lean)
		else
			applyWeldPose(record, moving, attacking)
		end

		local nextPos = Vector3.new(targetX, record.baseY + bob + lurch, nextZ)
		local lookAt = Vector3.new(focus.X, nextPos.Y, focus.Z)
		local base = if (lookAt - nextPos).Magnitude > 0.05
			then CFrame.lookAt(nextPos, lookAt)
			else CFrame.new(nextPos) * CFrame.Angles(0, math.pi, 0)
		local leanAmt = if record.isDog then math.rad(4) else math.rad(8)
		local roll = math.rad(if record.isDog then 2 else 5) * swing
		record.root.CFrame = base * CFrame.Angles(lean + leanAmt + lurch * 0.4, sway, roll)

		local inFront = pos.Z <= stopZ + 1.2
		local flatX = math.abs(pos.X - focus.X)
		local reachX = (record.model:GetAttribute("HitRadius") :: number) + 2.2
		if inFront and flatX <= reachX and now - record.lastContact >= Config.Zombie.ContactCooldown then
			record.lastContact = now
			record.attackUntil = now + Config.Zombie.AttackDuration
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
