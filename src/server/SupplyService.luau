local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gun = require(script.Parent.Gun)

local function liveConfig()
	local module = ReplicatedStorage:FindFirstChild("Shared")
	local scriptInst = if module then module:FindFirstChild("Config") else nil
	if not (scriptInst and scriptInst:IsA("ModuleScript")) then
		return Config
	end
	local clone = scriptInst:Clone()
	clone.Parent = scriptInst.Parent
	local ok, fresh = pcall(require, clone)
	clone:Destroy()
	if ok and typeof(fresh) == "table" then
		return fresh
	end
	return Config
end

export type SupplyRecord = {
	model: Model,
	root: BasePart,
	label: TextLabel,
	hitsLeft: number,
	alive: boolean,
	kind: "ally" | "bomb",
}

export type AllyRecord = {
	model: Model,
	root: BasePart,
	humanoid: Humanoid,
	healthFill: Frame,
	slot: number,
	lastFire: number,
	alive: boolean,
	torsoWeld: Weld,
	rightArmWeld: Weld,
	leftArmWeld: Weld,
	rightLegWeld: Weld,
	leftLegWeld: Weld,
	rightLegBaseC0: CFrame,
	leftLegBaseC0: CFrame,
	strafeYaw: number,
	walkPhase: number,
}

export type AttackTarget = {
	kind: "player" | "ally",
	ally: AllyRecord?,
}

local SupplyService = {}

local supplies = {} :: { SupplyRecord }
local allies = {} :: { AllyRecord }
local recruitsThisMatch = 0
local onRecruited: ((AllyRecord) -> ())? = nil
local onAllyDied: ((AllyRecord) -> ())? = nil
local onBombPicked: (() -> ())? = nil

local function ensureFolder(name: string): Folder
	local existing = Workspace:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	return folder
end

local function weldConstraint(root: BasePart, child: BasePart)
	child.Anchored = false
	child.CanCollide = false
	child.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = child
	weld.Parent = child
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

local function makePart(parent: Instance, name: string, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CFrame = cf
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.Parent = parent
	return p
end

local function allySlotOffset(slot: number): Vector3
	local pattern = {
		Vector3.new(-2.6, 0, 1.4),
		Vector3.new(2.6, 0, 1.4),
		Vector3.new(-4.4, 0, 0.4),
		Vector3.new(4.4, 0, 0.4),
		Vector3.new(-3.4, 0, 2.6),
		Vector3.new(3.4, 0, 2.6),
	}
	return pattern[((slot - 1) % #pattern) + 1]
end

local function setHitLabel(label: TextLabel, hits: number)
	label.Text = tostring(math.max(0, math.floor(hits)))
end

local function attachOverheadHits(adornee: BasePart, hits: number, offsetY: number, textColor: Color3, sizeScale: number): TextLabel
	local s = math.clamp(sizeScale, 0.4, 2.5)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HitCount"
	billboard.Size = UDim2.fromOffset(math.floor(52 * s), math.floor(34 * s))
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 240
	billboard.LightInfluence = 0
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = textColor
	label.TextStrokeColor3 = Color3.fromRGB(15, 12, 10)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = billboard
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = math.floor(30 * s)
	cap.MinTextSize = 14
	cap.Parent = label
	setHitLabel(label, hits)
	return label
end

local function overheadOffset(model: Model, root: BasePart): number
	local bboxCf, bboxSize = model:GetBoundingBox()
	return (bboxCf.Position.Y + bboxSize.Y * 0.5) - root.Position.Y + 0.7
end

local function plantCrate(model: Model, root: BasePart)
	local scale = Config.Supply.SizeScale
	if math.abs(scale - 1) > 0.01 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	local bboxCf, bboxSize = model:GetBoundingBox()
	local groundY = Config.Lane.CenterY + Config.Lane.Thickness * 0.5
	local bottomY = bboxCf.Position.Y - bboxSize.Y * 0.5
	root.CFrame = root.CFrame + Vector3.new(0, groundY - bottomY, 0)
end

-- Standing recruit on the crate (idle pose).
local function buildCrateRecruit(parent: Model, root: BasePart)
	local skin = Color3.fromRGB(210, 170, 135)
	local camo = Color3.fromRGB(52, 62, 48)
	local vest = Color3.fromRGB(34, 38, 32)
	local pants = Color3.fromRGB(40, 44, 36)
	local boot = Color3.fromRGB(28, 28, 26)

	local torso = makePart(parent, "Torso", Vector3.new(2, 2, 1), camo, root.CFrame * CFrame.new(0, 2.55, 0))
	weldConstraint(root, torso)
	weldConstraint(root, makePart(parent, "Vest", Vector3.new(2.15, 1.35, 1.15), vest, torso.CFrame * CFrame.new(0, 0.15, 0), Enum.Material.Fabric))
	local head = makePart(parent, "Head", Vector3.new(1.15, 1.15, 1.15), skin, torso.CFrame * CFrame.new(0, 1.55, 0))
	weldConstraint(root, head)
	weldConstraint(root, makePart(parent, "Helmet", Vector3.new(1.35, 0.55, 1.35), Color3.fromRGB(28, 32, 26), head.CFrame * CFrame.new(0, 0.45, 0.05), Enum.Material.Metal))
	weldConstraint(root, makePart(parent, "Goggles", Vector3.new(0.95, 0.22, 0.2), Color3.fromRGB(20, 24, 28), head.CFrame * CFrame.new(0, 0.12, -0.55)))

	for _, side in { -1, 1 } do
		weldConstraint(root, makePart(parent, "Arm", Vector3.new(0.72, 1.15, 0.72), camo, torso.CFrame * CFrame.new(side * 1.35, 0.25, 0)))
		weldConstraint(root, makePart(parent, "Hand", Vector3.new(0.62, 0.7, 0.62), Color3.fromRGB(32, 32, 30), torso.CFrame * CFrame.new(side * 1.35, -0.75, 0)))
		weldConstraint(root, makePart(parent, "Leg", Vector3.new(0.78, 1.35, 0.78), pants, torso.CFrame * CFrame.new(side * 0.45, -1.7, 0)))
		weldConstraint(root, makePart(parent, "Boot", Vector3.new(0.82, 0.55, 0.95), boot, torso.CFrame * CFrame.new(side * 0.45, -2.55, 0.05)))
	end
end

local function buildCrateBomb(parent: Model, root: BasePart)
	local shell = Color3.fromRGB(46, 50, 42)
	local band = Color3.fromRGB(78, 82, 70)
	local bomb = makePart(parent, "Bomb", Vector3.new(1.7, 1.7, 1.7), shell, root.CFrame * CFrame.new(0, 2.55, 0), Enum.Material.Metal)
	bomb.Shape = Enum.PartType.Ball
	weldConstraint(root, bomb)
	weldConstraint(root, makePart(parent, "BombBand", Vector3.new(1.75, 0.22, 1.75), band, bomb.CFrame * CFrame.new(0, 0.1, 0), Enum.Material.Metal))
	weldConstraint(root, makePart(parent, "BombCap", Vector3.new(0.5, 0.32, 0.5), Color3.fromRGB(30, 32, 28), bomb.CFrame * CFrame.new(0, 0.85, 0), Enum.Material.Metal))
	local fuse = makePart(parent, "BombFuse", Vector3.new(0.14, 0.55, 0.14), Color3.fromRGB(96, 72, 40), bomb.CFrame * CFrame.new(0, 1.25, 0))
	weldConstraint(root, fuse)
	local spark = makePart(parent, "BombSpark", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(255, 140, 40), bomb.CFrame * CFrame.new(0, 1.55, 0), Enum.Material.Neon)
	weldConstraint(root, spark)
end

-- Combat ally: special-forces look + shouldered ADS arm pose.
local function buildCombatAlly(parent: Model, root: BasePart): (BasePart, Weld, Weld, Weld, Weld, Weld)
	local skin = Color3.fromRGB(210, 170, 135)
	local camo = Color3.fromRGB(52, 62, 48)
	local vest = Color3.fromRGB(34, 38, 32)
	local pants = Color3.fromRGB(40, 44, 36)
	local boot = Color3.fromRGB(28, 28, 26)

	local torso = makePart(parent, "Torso", Vector3.new(2, 2, 1), camo, root.CFrame * CFrame.new(0, 0.1, 0))
	local torsoWeld = attachWeld(root, torso, CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(6), math.rad(10), math.rad(-3)))

	local plate = makePart(parent, "Vest", Vector3.new(2.15, 1.35, 1.15), vest, torso.CFrame, Enum.Material.Fabric)
	weldConstraint(torso, plate)

	local head = makePart(parent, "Head", Vector3.new(1.15, 1.15, 1.15), skin, torso.CFrame)
	attachWeld(torso, head, CFrame.new(0, 1.55, 0) * CFrame.Angles(math.rad(-14), math.rad(-6), 0))
	weldConstraint(head, makePart(parent, "Helmet", Vector3.new(1.35, 0.55, 1.35), Color3.fromRGB(28, 32, 26), head.CFrame * CFrame.new(0, 0.45, 0.05), Enum.Material.Metal))
	weldConstraint(head, makePart(parent, "Goggles", Vector3.new(0.95, 0.22, 0.2), Color3.fromRGB(20, 24, 28), head.CFrame * CFrame.new(0, 0.12, -0.55)))

	local rightArm = makePart(parent, "RightArm", Vector3.new(0.7, 1.5, 0.7), camo, root.CFrame)
	local rightArmWeld = attachWeld(root, rightArm, CFrame.new(1.05, 0.55, -0.35) * CFrame.Angles(math.rad(-95), math.rad(-35), math.rad(25)))
	local rightHand = makePart(parent, "RightHand", Vector3.new(0.55, 0.55, 0.55), Color3.fromRGB(32, 32, 30), root.CFrame)
	attachWeld(rightArm, rightHand, CFrame.new(0, -0.95, 0))

	local leftArm = makePart(parent, "LeftArm", Vector3.new(0.7, 1.55, 0.7), camo, root.CFrame)
	local leftArmWeld = attachWeld(root, leftArm, CFrame.new(-0.55, 0.7, -0.95) * CFrame.Angles(math.rad(-105), math.rad(40), math.rad(-15)))
	local leftHand = makePart(parent, "LeftHand", Vector3.new(0.55, 0.55, 0.55), Color3.fromRGB(32, 32, 30), root.CFrame)
	attachWeld(leftArm, leftHand, CFrame.new(0, -1.0, 0))

	local rightLeg = makePart(parent, "RightLeg", Vector3.new(0.78, 1.35, 0.78), pants, root.CFrame)
	local rightLegWeld = attachWeld(root, rightLeg, CFrame.new(0.45, -1.7, 0) * CFrame.Angles(math.rad(4), 0, math.rad(3)))
	local leftLeg = makePart(parent, "LeftLeg", Vector3.new(0.78, 1.35, 0.78), pants, root.CFrame)
	local leftLegWeld = attachWeld(root, leftLeg, CFrame.new(-0.45, -1.7, 0) * CFrame.Angles(math.rad(4), 0, math.rad(-3)))

	weldConstraint(rightLeg, makePart(parent, "Boot", Vector3.new(0.82, 0.55, 0.95), boot, rightLeg.CFrame * CFrame.new(0, -0.85, 0.05)))
	weldConstraint(leftLeg, makePart(parent, "Boot", Vector3.new(0.82, 0.55, 0.95), boot, leftLeg.CFrame * CFrame.new(0, -0.85, 0.05)))

	return head, torsoWeld, rightArmWeld, leftArmWeld, rightLegWeld, leftLegWeld
end

local function attachAllyHealthBar(head: BasePart, humanoid: Humanoid): Frame
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AllyHealthBar"
	billboard.Size = UDim2.fromOffset(76, 8)
	billboard.StudsOffset = Vector3.new(0, 2.7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	billboard.LightInfluence = 0
	billboard.Parent = head

	local barBg = Instance.new("Frame")
	barBg.Name = "Back"
	barBg.Size = UDim2.fromScale(1, 1)
	barBg.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
	barBg.BorderSizePixel = 0
	barBg.Parent = billboard
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(72, 210, 96)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local function refresh()
		local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
	end
	humanoid.HealthChanged:Connect(refresh)
	refresh()
	return fill
end

function SupplyService.onRecruited(callback: (AllyRecord) -> ())
	onRecruited = callback
end

function SupplyService.onAllyDied(callback: (AllyRecord) -> ())
	onAllyDied = callback
end

function SupplyService.onBombPicked(callback: () -> ())
	onBombPicked = callback
end

function SupplyService.hasRecruitedThisMatch(): boolean
	return recruitsThisMatch > 0
end

function SupplyService.canSpawn(): boolean
	if #supplies >= Config.Supply.MaxAlive then
		return false
	end
	return recruitsThisMatch < Config.Supply.MaxRecruitsPerMatch
end

function SupplyService.canSpawnBomb(): boolean
	if #supplies >= Config.Supply.MaxAlive then
		return false
	end
	local bombAlive = 0
	for _, record in supplies do
		if record.alive and record.kind == "bomb" then
			bombAlive += 1
		end
	end
	return bombAlive < Config.BombCrate.MaxAlive
end

function SupplyService.getAlive(): { SupplyRecord }
	return supplies
end

function SupplyService.getAllies(): { AllyRecord }
	local list = {}
	for _, ally in allies do
		if ally.alive and ally.model.Parent and ally.humanoid.Health > 0 then
			table.insert(list, ally)
		end
	end
	allies = list
	return allies
end

-- Random player/ally pick for a newly spawned zombie.
function SupplyService.pickAttackTarget(): AttackTarget
	local options: { AttackTarget } = { { kind = "player", ally = nil } }
	for _, ally in SupplyService.getAllies() do
		table.insert(options, { kind = "ally", ally = ally })
	end
	return options[math.random(1, #options)]
end

function SupplyService.resolveTargetPosition(target: AttackTarget, playerPosition: Vector3): Vector3
	if target.kind == "ally" and target.ally and target.ally.alive and target.ally.model.Parent then
		return target.ally.root.Position
	end
	return playerPosition
end

function SupplyService.applyTargetDamage(target: AttackTarget, amount: number): boolean
	if target.kind == "ally" and target.ally then
		return SupplyService.damageAlly(target.ally, amount)
	end
	return false
end

function SupplyService.clear()
	for _, record in supplies do
		if record.model.Parent then
			record.model:Destroy()
		end
	end
	supplies = {}

	for _, ally in allies do
		ally.alive = false
		if ally.model.Parent then
			ally.model:Destroy()
		end
	end
	allies = {}
	recruitsThisMatch = 0

	local suppliesFolder = Workspace:FindFirstChild("Supplies")
	if suppliesFolder then
		suppliesFolder:ClearAllChildren()
	end
	local alliesFolder = Workspace:FindFirstChild("Allies")
	if alliesFolder then
		alliesFolder:ClearAllChildren()
	end
end

function SupplyService.create(): SupplyRecord?
	if not SupplyService.canSpawn() then
		return nil
	end

	local folder = ensureFolder("Supplies")
	local x = Config.sidePathCenterX()
	local y = Config.Lane.CenterY + 1.6
	local z = Config.Lane.SpawnZ
	local position = Vector3.new(x, y, z)

	local hits = math.random(Config.Supply.HitCountMin, Config.Supply.HitCountMax)

	local model = Instance.new("Model")
	model.Name = "SupplyCrate"
	model:SetAttribute("IsSupply", true)
	model:SetAttribute("HitsLeft", hits)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3.2, 2.4, 3.2)
	root.Color = Color3.fromRGB(150, 96, 42)
	root.Material = Enum.Material.Wood
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	root.Anchored = true
	root.CanCollide = true
	root.Parent = model

	local lid = makePart(model, "Lid", Vector3.new(3.4, 0.35, 3.4), Color3.fromRGB(120, 72, 32), root.CFrame * CFrame.new(0, 1.35, 0), Enum.Material.Wood)
	weldConstraint(root, lid)
	local stripe = makePart(model, "Stripe", Vector3.new(3.45, 0.55, 0.55), Color3.fromRGB(210, 170, 50), root.CFrame * CFrame.new(0, 0.2, 0), Enum.Material.Metal)
	weldConstraint(root, stripe)

	buildCrateRecruit(model, root)

	model.PrimaryPart = root
	model.Parent = folder
	plantCrate(model, root)

	local hitScale = liveConfig().Supply.HitLabelScale or 1
	local label = attachOverheadHits(
		root,
		hits,
		overheadOffset(model, root),
		Color3.fromRGB(255, 255, 255),
		hitScale
	)

	local record: SupplyRecord = {
		model = model,
		root = root,
		label = label,
		hitsLeft = hits,
		alive = true,
		kind = "ally",
	}
	table.insert(supplies, record)
	return record
end

function SupplyService.createBomb(): SupplyRecord?
	if not SupplyService.canSpawnBomb() then
		return nil
	end

	local folder = ensureFolder("Supplies")
	local x = Config.sidePathCenterX()
	local y = Config.Lane.CenterY + 1.6
	local z = Config.Lane.SpawnZ
	local position = Vector3.new(x, y, z)
	local hits = Config.BombCrate.HitCount

	local model = Instance.new("Model")
	model.Name = "BombCrate"
	model:SetAttribute("IsSupply", true)
	model:SetAttribute("IsBombCrate", true)
	model:SetAttribute("HitsLeft", hits)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3.2, 2.4, 3.2)
	root.Color = Color3.fromRGB(150, 96, 42)
	root.Material = Enum.Material.Wood
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	root.Anchored = true
	root.CanCollide = true
	root.Parent = model

	local lid = makePart(model, "Lid", Vector3.new(3.4, 0.35, 3.4), Color3.fromRGB(120, 72, 32), root.CFrame * CFrame.new(0, 1.35, 0), Enum.Material.Wood)
	weldConstraint(root, lid)
	local stripe = makePart(model, "Stripe", Vector3.new(3.45, 0.55, 0.55), Color3.fromRGB(210, 170, 50), root.CFrame * CFrame.new(0, 0.2, 0), Enum.Material.Metal)
	weldConstraint(root, stripe)
	buildCrateBomb(model, root)

	model.PrimaryPart = root
	model.Parent = folder
	plantCrate(model, root)

	local hitScale = liveConfig().BombCrate.HitLabelScale or 1
	local label = attachOverheadHits(
		root,
		hits,
		overheadOffset(model, root),
		Color3.fromRGB(255, 210, 120),
		hitScale
	)

	local record: SupplyRecord = {
		model = model,
		root = root,
		label = label,
		hitsLeft = hits,
		alive = true,
		kind = "bomb",
	}
	table.insert(supplies, record)
	return record
end

local killAlly: (AllyRecord) -> ()

killAlly = function(ally: AllyRecord)
	if not ally.alive then
		return
	end
	ally.alive = false
	ally.humanoid.Health = 0
	if onAllyDied then
		onAllyDied(ally)
	end
	if ally.model.Parent then
		ally.model:Destroy()
	end
	SupplyService.getAllies()
end

function SupplyService.damageAlly(ally: AllyRecord, amount: number): boolean
	if not ally.alive or not ally.model.Parent then
		return false
	end
	local nextHealth = ally.humanoid.Health - amount
	ally.humanoid.Health = nextHealth
	if nextHealth <= 0 then
		killAlly(ally)
	end
	return true
end

local function recruitFrom(record: SupplyRecord)
	if #SupplyService.getAllies() >= Config.Supply.MaxAllies then
		record.model:Destroy()
		return
	end

	local alliesFolder = ensureFolder("Allies")
	local slot = #allies + 1

	local model = Instance.new("Model")
	model.Name = "Ally"
	model:SetAttribute("IsAlly", true)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = record.root.CFrame * CFrame.new(0, 1.2, 0)
	root.Parent = model

	local head, torsoWeld, rightArmWeld, leftArmWeld, rightLegWeld, leftLegWeld = buildCombatAlly(model, root)
	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.MaxHealth = Config.Supply.AllyHealth
	humanoid.Health = Config.Supply.AllyHealth
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	local healthFill = attachAllyHealthBar(head, humanoid)
	model.Parent = alliesFolder
	Gun.attach(model)

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Hero"
		end
	end

	local ally: AllyRecord = {
		model = model,
		root = root,
		humanoid = humanoid,
		healthFill = healthFill,
		slot = slot,
		lastFire = 0,
		alive = true,
		torsoWeld = torsoWeld,
		rightArmWeld = rightArmWeld,
		leftArmWeld = leftArmWeld,
		rightLegWeld = rightLegWeld,
		leftLegWeld = leftLegWeld,
		rightLegBaseC0 = rightLegWeld.C0,
		leftLegBaseC0 = leftLegWeld.C0,
		strafeYaw = 0,
		walkPhase = 0,
	}
	table.insert(allies, ally)
	recruitsThisMatch += 1

	humanoid.Died:Connect(function()
		killAlly(ally)
	end)

	record.model:Destroy()

	if onRecruited then
		onRecruited(ally)
	end
end

function SupplyService.damageModel(model: Model, hits: number?): boolean
	local hitPower = math.max(1, math.floor(hits or 1))
	for _, record in supplies do
		if record.model == model and record.alive then
			record.hitsLeft -= hitPower
			model:SetAttribute("HitsLeft", record.hitsLeft)
			setHitLabel(record.label, record.hitsLeft)
			if record.hitsLeft <= 0 then
				record.alive = false
				if record.kind == "bomb" then
					record.model:Destroy()
					if onBombPicked then
						onBombPicked()
					end
				else
					recruitFrom(record)
				end
				local keep = {}
				for _, other in supplies do
					if other.alive and other.model.Parent then
						table.insert(keep, other)
					end
				end
				supplies = keep
			end
			return true
		end
	end
	return false
end

local ALLY_STRAFE_YAW = math.rad(38)
local ALLY_YAW_LERP = 9

function SupplyService.update(dt: number, playerPosition: Vector3?, strafe: number?)
	local keep = {}
	for _, record in supplies do
		if not (record.alive and record.model.Parent) then
			continue
		end

		local pos = record.root.Position
		local nextZ = pos.Z - Config.Supply.WalkSpeed * dt
		if nextZ < Config.Supply.DespawnZ then
			record.alive = false
			record.model:Destroy()
			continue
		end

		record.root.CFrame = CFrame.lookAt(
			Vector3.new(pos.X, pos.Y, nextZ),
			Vector3.new(pos.X, pos.Y, nextZ - 1)
		)
		table.insert(keep, record)
	end
	supplies = keep

	if not playerPosition then
		return
	end

	local move = strafe or 0
	local isMoving = math.abs(move) > 0.1
	local targetYaw = 0
	if move < -0.1 then
		targetYaw = ALLY_STRAFE_YAW
	elseif move > 0.1 then
		targetYaw = -ALLY_STRAFE_YAW
	end

	for _, ally in SupplyService.getAllies() do
		local offset = allySlotOffset(ally.slot)
		local target = Vector3.new(
			playerPosition.X + offset.X,
			Config.Player.Height,
			Config.Lane.PlayerZ + offset.Z
		)

		local alpha = 1 - math.exp(-ALLY_YAW_LERP * dt)
		if isMoving then
			ally.strafeYaw += (targetYaw - ally.strafeYaw) * alpha
			ally.walkPhase += dt * 9
		else
			ally.strafeYaw = 0
			ally.walkPhase = 0
		end

		-- Root always faces +Z so torso/arms/gun never yaw with strafe.
		local facing = CFrame.lookAt(target, target + Vector3.new(0, 0, 12))
		ally.root.CFrame = facing
		ally.torsoWeld.C1 = CFrame.identity
		ally.rightArmWeld.C1 = CFrame.identity
		ally.leftArmWeld.C1 = CFrame.identity

		-- Legs only: strafe turn + walk cycle (same idea as player lower body).
		local legTurn = CFrame.Angles(0, ally.strafeYaw, 0)
		if isMoving then
			local swing = math.sin(ally.walkPhase)
			ally.rightLegWeld.C0 = legTurn * ally.rightLegBaseC0 * CFrame.Angles(math.rad(32) * swing, 0, 0)
			ally.leftLegWeld.C0 = legTurn * ally.leftLegBaseC0 * CFrame.Angles(math.rad(-32) * swing, 0, 0)
		else
			ally.rightLegWeld.C0 = ally.rightLegBaseC0
			ally.leftLegWeld.C0 = ally.leftLegBaseC0
		end
		ally.rightLegWeld.C1 = CFrame.identity
		ally.leftLegWeld.C1 = CFrame.identity
	end
end

function SupplyService.allyMuzzlePoints(now: number): { Vector3 }
	local points = {}
	for _, ally in SupplyService.getAllies() do
		if now - ally.lastFire < Config.Supply.AllyFireInterval then
			continue
		end
		ally.lastFire = now
		local muzzle = Gun.getMuzzlePosition(ally.model)
		local rootPos = ally.root.Position
		if muzzle then
			-- Lock lane X; keep muzzle height/depth so shots stay +Z forward.
			table.insert(points, Vector3.new(rootPos.X, muzzle.Y, muzzle.Z))
		else
			table.insert(points, rootPos + Vector3.new(0, 1.2, 1.4))
		end
	end
	return points
end

return SupplyService
