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
	motorRest: { [Motor6D]: CFrame },
	attackTarget: { kind: string, ally: any? },
	alive: boolean,
	hp: number,
	maxHp: number,
	isMega: boolean?,
	isBig: boolean?,
	hitsLeft: number?,
	hitLabel: TextLabel?,
	hasShield: boolean?,
	shieldHits: number?,
	deathT: number,
	deathStart: CFrame,
	deathSide: number,
}

local FALL_TIME = 0.22
local FADE_START = 0.14
local DEATH_TIME = 0.42

local ZombieService = {}
ZombieService._alive = {} :: { ZombieRecord }
ZombieService._corpses = {} :: { ZombieRecord }
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

local function nameMatches(instanceName: string, names: { string }): boolean
	local lower = string.lower(instanceName)
	for _, name in names do
		if lower == string.lower(name) then
			return true
		end
	end
	return false
end

local function findMotor(model: Model, names: { string }): Motor6D?
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and nameMatches(d.Name, names) then
			return d
		end
	end
	return nil
end

local function findMotorForPart(model: Model, partNames: { string }): Motor6D?
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Part1 and nameMatches(d.Part1.Name, partNames) then
			return d
		end
	end
	return nil
end

local function collectMotors(model: Model): ZombieMotors?
	local motors: ZombieMotors = {
		neck = findMotor(model, { "Neck" }) or findMotorForPart(model, { "Head" }),
		waist = findMotor(model, { "Waist" }),
		root = findMotor(model, { "Root", "RootJoint" }),
		leftShoulder = findMotor(model, { "LeftShoulder" }) or findMotorForPart(model, { "LeftUpperArm" }),
		rightShoulder = findMotor(model, { "RightShoulder" }) or findMotorForPart(model, { "RightUpperArm" }),
		leftElbow = findMotor(model, { "LeftElbow" }) or findMotorForPart(model, { "LeftLowerArm" }),
		rightElbow = findMotor(model, { "RightElbow" }) or findMotorForPart(model, { "RightLowerArm" }),
		leftHip = findMotor(model, { "LeftHip" }) or findMotorForPart(model, { "LeftUpperLeg" }),
		rightHip = findMotor(model, { "RightHip" }) or findMotorForPart(model, { "RightUpperLeg" }),
		leftKnee = findMotor(model, { "LeftKnee" }) or findMotorForPart(model, { "LeftLowerLeg" }),
		rightKnee = findMotor(model, { "RightKnee" }) or findMotorForPart(model, { "RightLowerLeg" }),
		leftArm = findMotor(model, { "Left Shoulder" }) or findMotorForPart(model, { "Left Arm" }),
		rightArm = findMotor(model, { "Right Shoulder" }) or findMotorForPart(model, { "Right Arm" }),
		leftLeg = findMotor(model, { "Left Hip" }) or findMotorForPart(model, { "Left Leg" }),
		rightLeg = findMotor(model, { "Right Hip" }) or findMotorForPart(model, { "Right Leg" }),
	}
	if not (motors.rightShoulder or motors.rightArm) then
		local fallback: Motor6D? = nil
		for _, d in model:GetDescendants() do
			if d:IsA("Motor6D") and d.Part1 then
				local n = string.lower(d.Part1.Name .. " " .. d.Name)
				if string.find(n, "right", 1, true)
					and (string.find(n, "arm", 1, true) or string.find(n, "shoulder", 1, true) or string.find(n, "hand", 1, true))
				then
					fallback = d
					if string.find(n, "upper", 1, true) or string.find(n, "shoulder", 1, true) then
						break
					end
				end
			end
		end
		motors.rightShoulder = fallback
	end
	if not (motors.rightShoulder or motors.rightArm) then
		return nil
	end
	return motors
end

local function poseMotor(record: ZombieRecord, motor: Motor6D?, pose: CFrame)
	if not motor then
		return
	end
	local rest = record.motorRest[motor]
	if not rest then
		rest = motor.C0
		record.motorRest[motor] = rest
	end
	-- C0 replicates to clients; Motor6D.Transform does not.
	motor.C0 = rest * pose
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
	local existing = head:FindFirstChild("HealthBar")
	if existing then
		existing:Destroy()
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(24, 3)
	billboard.StudsOffset = Vector3.new(0, (if isDog then 1.8 else 1.45) * scale, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 0
	billboard.LightInfluence = 0
	billboard.Enabled = true
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

	humanoid.HealthChanged:Connect(function()
		local model = head.Parent
		local maxHp = if model then (model:GetAttribute("MaxHp") :: number?) else nil
		local hp = if model then (model:GetAttribute("Hp") :: number?) else nil
		local ratio = math.clamp((hp or humanoid.Health) / math.max(maxHp or humanoid.MaxHealth, 1), 0, 1)
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

local function attachHitCount(adornee: BasePart, hits: number, heightScale: number, sizeExtra: number?): TextLabel
	local s = Config.hitLabelScale(sizeExtra)
	local digits = math.max(1, #tostring(hits))
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HitCount"
	billboard.Size = UDim2.fromOffset(math.max(22, math.floor(18 * digits * s)), math.max(14, math.floor(28 * s)))
	billboard.StudsOffset = Vector3.new(0, 2.4 * heightScale, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 240
	billboard.LightInfluence = 0
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = tostring(hits)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(15, 12, 10)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = billboard
	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MaxTextSize = math.max(10, math.floor(22 * s))
	sizeConstraint.MinTextSize = math.max(8, math.floor(10 * s))
	sizeConstraint.Parent = label
	return label
end

local function setHealthBarVisible(record: ZombieRecord, visible: boolean)
	local bar = record.model:FindFirstChild("HealthBar", true)
	if bar and bar:IsA("BillboardGui") then
		bar.Enabled = visible
	end
end

local function attachShield(record: ZombieRecord, hits: number)
	record.hasShield = true
	record.shieldHits = math.max(1, math.floor(hits))
	record.model:SetAttribute("HasShield", true)
	record.model:SetAttribute("ShieldHits", record.shieldHits)

	local root = record.root
	local plate = Instance.new("Part")
	plate.Name = "Shield"
	plate.Size = Vector3.new(2.2, 2.75, 0.28)
	plate.Material = Enum.Material.Metal
	plate.Color = Color3.fromRGB(88, 92, 102)
	plate.CanCollide = false
	plate.Massless = true
	plate.CFrame = root.CFrame
	plate.Parent = record.model
	local weld = Instance.new("Weld")
	weld.Name = "ShieldWeld"
	weld.Part0 = root
	weld.Part1 = plate
	weld.C0 = CFrame.new(-0.55, 0.4, -1.42) * CFrame.Angles(0, 0, math.rad(-10))
	weld.Parent = plate

	local rim = Instance.new("Part")
	rim.Name = "ShieldRim"
	rim.Size = Vector3.new(2.38, 2.92, 0.12)
	rim.Material = Enum.Material.Metal
	rim.Color = Color3.fromRGB(48, 50, 56)
	rim.CanCollide = false
	rim.Massless = true
	rim.CFrame = plate.CFrame
	rim.Parent = record.model
	local rimWeld = Instance.new("Weld")
	rimWeld.Part0 = plate
	rimWeld.Part1 = rim
	rimWeld.C0 = CFrame.new(0, 0, 0.08)
	rimWeld.Parent = rim

	local boss = Instance.new("Part")
	boss.Name = "ShieldBoss"
	boss.Shape = Enum.PartType.Cylinder
	boss.Size = Vector3.new(0.22, 0.7, 0.7)
	boss.Material = Enum.Material.Metal
	boss.Color = Color3.fromRGB(160, 150, 70)
	boss.CanCollide = false
	boss.Massless = true
	boss.CFrame = plate.CFrame
	boss.Parent = record.model
	local bossWeld = Instance.new("Weld")
	bossWeld.Part0 = plate
	bossWeld.Part1 = boss
	bossWeld.C0 = CFrame.new(0, 0, -0.18) * CFrame.Angles(0, 0, math.rad(90))
	bossWeld.Parent = boss

	local head = record.model:FindFirstChild("Head")
	local adornee: BasePart = if head and head:IsA("BasePart") then head else record.root
	record.hitLabel = attachHitCount(adornee, record.shieldHits, 0.7, Config.HitLabel.ShieldScale)
	local billboard = adornee:FindFirstChild("HitCount")
	if billboard and billboard:IsA("BillboardGui") then
		billboard.StudsOffset = Vector3.new(0, 1.75, 0)
	end
	setHealthBarVisible(record, false)
end

local function breakShield(record: ZombieRecord)
	record.hasShield = false
	record.shieldHits = 0
	record.model:SetAttribute("HasShield", false)
	record.model:SetAttribute("ShieldHits", 0)
	for _, name in { "Shield", "ShieldRim", "ShieldBoss" } do
		local part = record.model:FindFirstChild(name)
		if part then
			part:Destroy()
		end
	end
	if record.hitLabel then
		local gui = record.hitLabel.Parent
		record.hitLabel = nil
		if gui then
			gui:Destroy()
		end
	end
	for _, desc in record.model:GetDescendants() do
		if desc.Name == "HitCount" and desc:IsA("BillboardGui") then
			desc:Destroy()
		end
	end
	setHealthBarVisible(record, true)
end

local function finalizeModel(model: Model, root: BasePart, humanoid: Humanoid, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	isDog: boolean,
	scale: number,
}, head: BasePart)
	for _, d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local description = model:FindFirstChildWhichIsA("HumanoidDescription", true)
	if description then
		description:Destroy()
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	model:SetAttribute("MaxHp", stats.health)
	model:SetAttribute("Hp", stats.health)
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
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		animator:Destroy()
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
	local hitRadius = if stats.isDog then Config.activeDog().HitRadius else Config.activeZombie().HitRadius
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

local function refreshHealthBar(record: ZombieRecord)
	record.model:SetAttribute("Hp", record.hp)
	record.model:SetAttribute("MaxHp", record.maxHp)
	local bar = record.model:FindFirstChild("HealthBar", true)
	if not bar then
		return
	end
	local fill = bar:FindFirstChild("Fill", true)
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.fromScale(math.clamp(record.hp / math.max(record.maxHp, 1), 0, 1), 1)
	end
end

local function bindHealthGuard(record: ZombieRecord)
	record.humanoid.HealthChanged:Connect(function(hp)
		if not record.alive then
			return
		end
		if record.humanoid.MaxHealth ~= record.maxHp then
			record.humanoid.MaxHealth = record.maxHp
		end
		if hp > record.hp + 0.05 then
			record.humanoid.Health = record.hp
			return
		end
		refreshHealthBar(record)
	end)
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
		motorRest = {},
		attackTarget = { kind = "player", ally = nil },
		alive = true,
		hp = stats.health,
		maxHp = stats.health,
		deathT = 0,
		deathStart = root.CFrame,
		deathSide = 1,
	}
	humanoid.Died:Connect(function()
		kill(record)
	end)
	bindHealthGuard(record)
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
		motorRest = {},
		attackTarget = { kind = "player", ally = nil },
		alive = true,
		hp = stats.health,
		maxHp = stats.health,
		deathT = 0,
		deathStart = root.CFrame,
		deathSide = 1,
	}
	humanoid.Died:Connect(function()
		kill(record)
	end)
	bindHealthGuard(record)
	table.insert(ZombieService._alive, record)
	return record
end

local function createFromPrototype(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	isMega: boolean?,
	isBig: boolean?,
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
	for _, d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	model.Name = if stats.isMega then "MegaBoss" elseif stats.isBoss then "BossZombie" else "Zombie"

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

	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	local headInst = model:FindFirstChild("Head")
	local head: BasePart = if headInst and headInst:IsA("BasePart") then headInst else root

	root.Anchored = true
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	model.PrimaryPart = root
	model.Parent = folder

	-- Scale after parenting so ScaleTo actually applies.
	local applyScale = if stats.isMega then stats.scale elseif usingBossMesh then 1 else stats.scale
	if math.abs(applyScale - 1) > 0.01 then
		pcall(function()
			model:ScaleTo(applyScale)
		end)
	end

	-- Plant feet on the road (prototype pivot heights vary).
	local bboxCf, bboxSize = model:GetBoundingBox()
	local groundY = Config.activeLane().CenterY + Config.activeLane().Thickness * 0.5
	local bottomY = bboxCf.Position.Y - bboxSize.Y * 0.5
	local lift = groundY - bottomY
	if math.abs(lift) > 0.01 then
		root.CFrame = root.CFrame + Vector3.new(0, lift, 0)
	end

	local hitScale = if stats.isMega
		then math.max(stats.scale * 2.2, 3.4)
		elseif usingBossMesh then math.max(stats.scale, 2.0)
		else stats.scale
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
		motorRest = {},
		attackTarget = { kind = "player", ally = nil },
		alive = true,
		hp = stats.health,
		maxHp = stats.health,
		deathT = 0,
		deathStart = root.CFrame,
		deathSide = 1,
	}
	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.Died:Connect(function()
		kill(record)
	end)
	bindHealthGuard(record)
	task.defer(function()
		if record.alive and record.model.Parent then
			record.humanoid.MaxHealth = record.maxHp
			record.humanoid.Health = record.hp
			refreshHealthBar(record)
		end
	end)
	table.insert(ZombieService._alive, record)
	return record
end

local function setupMegaHits(record: ZombieRecord, hitCount: number?, scale: number?)
	local hits = math.max(1, math.floor(hitCount or Config.MegaBoss.HitCount))
	local s = scale or Config.MegaBoss.SizeScale
	record.isMega = true
	record.hitsLeft = hits
	record.hp = 9999
	record.maxHp = 9999
	record.humanoid.MaxHealth = 9999
	record.humanoid.Health = 9999
	record.model:SetAttribute("HitsLeft", hits)
	record.model:SetAttribute("HitRadius", 8 + 2 * s)
	record.model:SetAttribute("IsBoss", true)

	local bar = record.model:FindFirstChild("HealthBar", true)
	if bar then
		bar:Destroy()
	end

	local head = record.model:FindFirstChild("Head")
	local adornee = if head and head:IsA("BasePart") then head else record.root
	-- 중간보스는 크기가 커서 hitLabel을 훨씬 높게, 크게 표시 (원거리에서도 보임)
	local labelHeightScale = s * 1.8
	record.hitLabel = attachHitCount(adornee, hits, labelHeightScale, s * 1.4)

	local hitbox = record.model:FindFirstChild("Hitbox")
	if hitbox and hitbox:IsA("BasePart") then
		hitbox.Size = Vector3.new(3.4 * s, 4.8 * s, 3.4 * s)
		hitbox.CanQuery = true
	end
end

function ZombieService.create(position: Vector3, stats: {
	health: number,
	walkSpeed: number,
	isBoss: boolean,
	isMega: boolean?,
	isBig: boolean?,
	isDog: boolean?,
	isShield: boolean?,
	contactDamage: number,
	scale: number,
	hitCount: number?,
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
		isBoss = stats.isBoss or stats.isMega == true,
		isMega = stats.isMega,
		isBig = stats.isBig,
		scale = stats.scale,
		contactDamage = stats.contactDamage,
	})
	if fromProto then
		if stats.isMega == true then
			setupMegaHits(fromProto, stats.hitCount, stats.scale)
		elseif stats.isShield == true then
			attachShield(fromProto, stats.hitCount or math.random(Config.ShieldZombie.HitCountMin, Config.ShieldZombie.HitCountMax))
		end
		if stats.isBig == true then
			fromProto.isBig = true
			fromProto.model:SetAttribute("IsBigZombie", true)
		end
		return fromProto
	end

	warn("[ZombieService] ReplicatedStorage zombieprototype / killer BIG zombie missing — using procedural zombie")
	local fallback = createProceduralHuman(position, {
		health = stats.health,
		walkSpeed = stats.walkSpeed,
		isBoss = stats.isBoss or stats.isMega == true,
		scale = stats.scale,
		contactDamage = stats.contactDamage,
	})
	if stats.isMega == true then
		setupMegaHits(fallback, stats.hitCount, stats.scale)
	elseif stats.isShield == true then
		attachShield(fallback, stats.hitCount or math.random(Config.ShieldZombie.HitCountMin, Config.ShieldZombie.HitCountMax))
	end
	if stats.isBig == true then
		fallback.isBig = true
		fallback.model:SetAttribute("IsBigZombie", true)
	end
	return fallback
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

	local model = record.model
	if not model.Parent then
		return
	end

	record.deathT = 0
	record.deathStart = record.root.CFrame
	record.deathSide = if math.random() < 0.5 then -1 else 1

	local bar = model:FindFirstChild("HealthBar", true)
	if bar then
		bar:Destroy()
	end

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc:SetAttribute("DeathBaseT", desc.Transparency)
			desc.CanQuery = false
			desc.CanCollide = false
		elseif desc:IsA("Decal") or desc:IsA("Texture") then
			desc:SetAttribute("DeathBaseT", desc.Transparency)
		end
	end

	table.insert(ZombieService._corpses, record)
end

local function easeOutCubic(t: number): number
	local u = 1 - t
	return 1 - u * u * u
end

local function applyDeathVisual(record: ZombieRecord)
	local t = math.clamp(record.deathT / FALL_TIME, 0, 1)
	local fall = easeOutCubic(t)
	local start = record.deathStart
	local side = record.deathSide
	local pitch: number
	local roll: number
	local drop: number
	if record.isDog then
		pitch = math.rad(-28) * fall
		roll = math.rad(82) * side * fall
		drop = 0.35 * fall
	else
		pitch = math.rad(-86) * fall
		roll = math.rad(16) * side * fall
		drop = (if record.isBoss then 1.8 else 1.15) * fall
	end

	record.root.CFrame = start * CFrame.Angles(pitch, 0, roll) + Vector3.new(0, -drop, 0)

	local fade = 0
	if record.deathT > FADE_START then
		fade = math.clamp((record.deathT - FADE_START) / (DEATH_TIME - FADE_START), 0, 1)
		fade = fade * fade
	end
	if fade <= 0 then
		return
	end
	for _, desc in record.model:GetDescendants() do
		if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
			local base = (desc:GetAttribute("DeathBaseT") :: number?) or 0
			desc.Transparency = base + (1 - base) * fade
		end
	end
end

local function updateCorpses(dt: number)
	local keep = {}
	for _, record in ZombieService._corpses do
		if not record.model.Parent then
			continue
		end
		record.deathT += dt
		if record.deathT >= DEATH_TIME then
			record.model:Destroy()
			continue
		end
		applyDeathVisual(record)
		table.insert(keep, record)
	end
	ZombieService._corpses = keep
end

function ZombieService.damageModel(model: Model, amount: number, hits: number?): boolean
	for _, record in ZombieService._alive do
		if record.model == model and record.alive then
			if record.hasShield == true and (record.shieldHits or 0) > 0 then
				local hitPower = math.max(1, math.floor(hits or 1))
				record.shieldHits = math.max(0, (record.shieldHits or 1) - hitPower)
				record.model:SetAttribute("ShieldHits", record.shieldHits)
				if record.shieldHits <= 0 then
					breakShield(record)
				elseif record.hitLabel then
					record.hitLabel.Text = tostring(record.shieldHits)
				end
				return true
			end
			if record.isMega == true then
				local hitPower = math.max(1, math.floor(hits or 1))
				record.hitsLeft = math.max(0, (record.hitsLeft or 1) - hitPower)
				model:SetAttribute("HitsLeft", record.hitsLeft)
				if record.hitLabel then
					record.hitLabel.Text = tostring(record.hitsLeft)
				end
				if record.hitsLeft <= 0 then
					kill(record)
				end
				return true
			end
			record.hp = math.max(0, record.hp - amount)
			record.humanoid.MaxHealth = record.maxHp
			record.humanoid.Health = record.hp
			refreshHealthBar(record)
			if record.hp <= 0 then
				kill(record)
			end
			return true
		end
	end
	return false
end

function ZombieService.damageInRadius(position: Vector3, radius: number, amount: number, hits: number?): number
	local hit = 0
	local snapshot = ZombieService.getAlive()
	for _, record in snapshot do
		local offset = record.root.Position - position
		local reach = radius + ((record.model:GetAttribute("HitRadius") :: number?) or 0) * 0.3
		if offset.X * offset.X + offset.Z * offset.Z <= reach * reach then
			if ZombieService.damageModel(record.model, amount, hits) then
				hit += 1
			end
		end
	end
	return hit
end

function ZombieService.retargetApproaching(assign: (ZombieRecord) -> { kind: string, ally: any? })
	local meleeZ = Config.activeLane().PlayerZ + Config.activeZombie().StopDistance + 6
	for _, record in ZombieService.getAlive() do
		if record.root.Position.Z > meleeZ then
			record.attackTarget = assign(record)
		end
	end
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

local function applyPrototypePose(record: ZombieRecord, moving: boolean, attacking: boolean, attackT: number)
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
	local t = math.clamp(attackT, 0, 1)
	local claw = if attacking then math.sin(t * math.pi) else 0
	-- 0 = arm cocked to the right, 1 = follow-through across the body.
	local sweep = if attacking then t else 0

	-- R15 zombie shambling; attack = right-hand rake, not a kick.
	-- Poses go through C0 so clients actually see them.
	poseMotor(
		record,
		m.rightShoulder,
		CFrame.Angles(
			math.rad(-70 + 10 * swing * moveScale - 85 * claw),
			math.rad(-18 + 8 * drag + 55 * claw - 130 * sweep),
			math.rad(14 + 6 * limp + 55 * claw)
		)
	)
	poseMotor(
		record,
		m.leftShoulder,
		if record.hasShield == true
			then CFrame.Angles(math.rad(-72), math.rad(42), math.rad(-22))
			else CFrame.Angles(
				math.rad(-88 - 8 * swing * moveScale - 10 * claw),
				math.rad(28 - 6 * drag),
				math.rad(-16 - 4 * limp)
			)
	)
	poseMotor(
		record,
		m.rightElbow,
		CFrame.Angles(math.rad(-22 - 10 * lurch - 20 * claw + 70 * sweep), math.rad(8 + 35 * claw), math.rad(-18 * claw))
	)
	poseMotor(record, m.leftElbow, if record.hasShield == true
		then CFrame.Angles(math.rad(-28), math.rad(-12), math.rad(-8))
		else CFrame.Angles(math.rad(-22 - 14 * lurch), math.rad(-6), 0))
	poseMotor(record, m.leftArm, if record.hasShield == true
		then CFrame.Angles(math.rad(-85), math.rad(12), math.rad(-32))
		else CFrame.Angles(math.rad(-95 - 6 * swing), 0, math.rad(-24)))
	poseMotor(
		record,
		m.rightHip,
		CFrame.Angles(math.rad(38 * swing * moveScale * limp) + math.rad(6), math.rad(4), math.rad(6))
	)
	poseMotor(
		record,
		m.leftHip,
		CFrame.Angles(math.rad(-22 * swing * moveScale) + math.rad(10 * limp), math.rad(-6), math.rad(-8))
	)
	poseMotor(record, m.rightKnee, CFrame.Angles(math.rad(-18 - 20 * math.max(0, swing) * moveScale), 0, 0))
	poseMotor(record, m.leftKnee, CFrame.Angles(math.rad(-28 - 12 * math.max(0, -swing) * moveScale), 0, 0))
	poseMotor(
		record,
		m.waist,
		CFrame.Angles(math.rad(10 + 6 * lurch + 12 * claw), math.rad(12 * drag - 28 * claw), math.rad(-5 * swing + 14 * claw))
	)
	poseMotor(
		record,
		m.neck,
		CFrame.Angles(math.rad(14 + 8 * lurch), math.rad(-16 * drag - 8 * claw), math.rad(8 * limp - 4))
	)
	poseMotor(record, m.root, CFrame.Angles(math.rad(4 + 3 * lurch), math.rad(5 * drag - 8 * claw), math.rad(3 * swing)))

	-- R6 fallback motors
	poseMotor(
		record,
		m.rightArm,
		CFrame.Angles(
			math.rad(-80 + 8 * swing - 70 * claw),
			math.rad(25 * claw - 95 * sweep),
			math.rad(22 + 50 * claw)
		)
	)
	poseMotor(record, m.leftArm, if record.hasShield == true
		then CFrame.Angles(math.rad(-85), math.rad(12), math.rad(-32))
		else CFrame.Angles(math.rad(-95 - 6 * swing), 0, math.rad(-24)))
	poseMotor(record, m.rightLeg, CFrame.Angles(math.rad(32 * swing * moveScale * limp), 0, math.rad(6)))
	poseMotor(record, m.leftLeg, CFrame.Angles(math.rad(-20 * swing * moveScale) + math.rad(8), 0, math.rad(-8)))
end

local function applyWeldPose(record: ZombieRecord, moving: boolean, attacking: boolean, attackT: number)
	if not (record.leftArm and record.rightArm and record.leftLeg and record.rightLeg) then
		return
	end
	local swing = math.sin(record.phase)
	local swing2 = math.sin(record.phase * 1.35 + 0.6)
	local moveScale = if moving then 1 else 0.4
	local claw = if attacking then math.sin(math.clamp(attackT, 0, 1) * math.pi) else 0

	if record.isDog then
		record.leftArm.C1 = CFrame.Angles(math.rad(38) * swing, 0, 0)
		record.rightArm.C1 = CFrame.Angles(math.rad(-38) * swing, 0, 0)
		record.leftLeg.C1 = CFrame.Angles(math.rad(-38) * swing, 0, 0)
		record.rightLeg.C1 = CFrame.Angles(math.rad(38) * swing, 0, 0)
	else
		record.leftArm.C1 = if record.hasShield == true
			then CFrame.Angles(math.rad(-8), math.rad(18), math.rad(-22))
			else CFrame.Angles(math.rad(18 * swing2 * moveScale), math.rad(14) * swing, math.rad(-10) * swing)
		record.rightArm.C1 = CFrame.Angles(
			math.rad(-20 * swing2 * moveScale - 95 * claw),
			math.rad(-16 * swing - 40 * claw),
			math.rad(10 * swing + 48 * claw)
		)
		record.leftLeg.C1 = CFrame.Angles(math.rad(34 * swing * moveScale * record.limp), 0, math.rad(-6))
		record.rightLeg.C1 = CFrame.Angles(math.rad(-26 * swing * moveScale) + math.rad(6), 0, math.rad(5))
	end
end

function ZombieService.update(dt: number, playerPosition: Vector3?)
	updateCorpses(dt)
	if not playerPosition then
		return
	end

	local now = os.clock()
	local zombieCfg = Config.activeZombie()

	for _, record in ZombieService.getAlive() do
		if record.humanoid.MaxHealth ~= record.maxHp or record.humanoid.Health > record.hp + 0.05 then
			record.humanoid.MaxHealth = record.maxHp
			record.humanoid.Health = record.hp
			refreshHealthBar(record)
		end

		local pos = record.root.Position
		local focus = resolveTargetPosition(record, playerPosition)
		local targetX = pos.X
		local stopZ = focus.Z + zombieCfg.StopDistance
		local moving = pos.Z > stopZ + 0.15
		local nextZ = if moving then pos.Z - record.walkSpeed * dt else stopZ
		if nextZ < stopZ then
			nextZ = stopZ
		end

		local minX, maxX = Config.zombieXBounds(nextZ)
		if pos.Z <= Config.chaseStartZ() then
			local chaseSpeed = record.walkSpeed * zombieCfg.ChaseStrafeScale
			if math.abs(focus.X - pos.X) > 6 then
				chaseSpeed = record.walkSpeed * zombieCfg.ChaseStrafeFarScale
			end
			local dx = focus.X - pos.X
			local maxStep = chaseSpeed * dt
			if math.abs(dx) > 0.08 then
				targetX = pos.X + math.clamp(dx, -maxStep, maxStep)
			else
				targetX = focus.X
			end
		end
		targetX = math.clamp(targetX, minX, maxX)

		local attacking = now < record.attackUntil
		local attackT = 0
		local lean = 0
		if attacking then
			attackT = 1 - (record.attackUntil - now) / zombieCfg.AttackDuration
			-- Slight lunge only; the claw is on the right arm, not a kick.
			lean = math.sin(math.clamp(attackT, 0, 1) * math.pi) * math.rad(if record.isDog then 16 else 6)
		end

		local shamble = zombieCfg.ShambleSpeed * (if moving then 1.15 else 0.55) * (if record.isDog then 1.45 else record.limp)
		record.phase += dt * shamble
		local swing = math.sin(record.phase)
		local sway = math.sin(record.phase * 0.55) * math.rad(if record.isDog then 3 else 10)
		local bob = math.abs(math.sin(record.phase * 0.5)) * (if record.isDog then 0.18 else 0.16)
		local lurch = math.max(0, math.sin(record.phase * 0.9)) * (if record.isDog then 0 else 0.08)

		if record.motors then
			applyPrototypePose(record, moving, attacking, attackT)
		else
			applyWeldPose(record, moving, attacking, attackT)
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
		if inFront and flatX <= reachX and now - record.lastContact >= zombieCfg.ContactCooldown then
			record.lastContact = now
			record.attackUntil = now + zombieCfg.AttackDuration
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
	for _, record in ZombieService._corpses do
		if record.model.Parent then
			record.model:Destroy()
		end
	end
	ZombieService._alive = {}
	ZombieService._corpses = {}
	local folder = Workspace:FindFirstChild("Zombies")
	if folder then
		folder:ClearAllChildren()
	end
end

return ZombieService
