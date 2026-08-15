local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local function liveNumberGate()
	local module = ReplicatedStorage:FindFirstChild("Shared")
	local scriptInst = if module then module:FindFirstChild("Config") else nil
	if not (scriptInst and scriptInst:IsA("ModuleScript")) then
		return Config.NumberGate
	end
	local clone = scriptInst:Clone()
	clone.Parent = scriptInst.Parent
	local ok, fresh = pcall(require, clone)
	clone:Destroy()
	if ok and typeof(fresh) == "table" and fresh.NumberGate then
		return fresh.NumberGate
	end
	return Config.NumberGate
end

export type GateRecord = {
	model: Model,
	root: BasePart,
	label: TextLabel,
	hitsLeft: number,
	alive: boolean,
}

local NumberGate = {}

local gates = {} :: { GateRecord }
local onCollected: (() -> ())? = nil

local function ensureFolder(): Folder
	local existing = Workspace:FindFirstChild("NumberGates")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "NumberGates"
	folder.Parent = Workspace
	return folder
end

local function setHitLabel(label: TextLabel, hits: number)
	label.Text = tostring(math.max(0, math.floor(hits)))
end

local function weldTo(root: BasePart, child: BasePart, canQuery: boolean?)
	child.Anchored = false
	child.CanCollide = false
	child.CanQuery = canQuery == true
	child.Massless = true
	child.CastShadow = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = child
	weld.Parent = child
end

local function makePart(parent: Instance, name: string, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function addCorner(parent: Model, root: BasePart, xSign: number, ySign: number, cfg)
	local frame = Color3.fromRGB(18, 58, 150)
	local bolt = Color3.fromRGB(210, 230, 255)
	local insetX = cfg.Width * 0.5 - 0.28
	local insetY = cfg.Height * 0.5 - 0.28
	local origin = root.CFrame * CFrame.new(xSign * insetX, ySign * insetY, 0)

	local h = makePart(
		parent,
		"CornerH",
		Vector3.new(1.05, 0.22, cfg.Depth + 0.12),
		frame,
		origin * CFrame.new(-xSign * 0.32, 0, 0),
		Enum.Material.Metal
	)
	weldTo(root, h)
	local v = makePart(
		parent,
		"CornerV",
		Vector3.new(0.22, 1.05, cfg.Depth + 0.12),
		frame,
		origin * CFrame.new(0, -ySign * 0.32, 0),
		Enum.Material.Metal
	)
	weldTo(root, v)
	local cap = makePart(
		parent,
		"Bolt",
		Vector3.new(0.32, 0.32, 0.32),
		bolt,
		origin * CFrame.new(0, 0, -cfg.Depth * 0.15),
		Enum.Material.Metal
	)
	cap.Shape = Enum.PartType.Ball
	weldTo(root, cap)
end

local function gateCFrame(position: Vector3): CFrame
	return CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
end

local function attachOverheadHits(adornee: BasePart, hits: number, offsetY: number, sizeScale: number): TextLabel
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
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
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

-- TextSize caps at 100; UIScale on the TextLabel is the bypass (100 * Scale).
local function attachFaceLabel(panel: BasePart, multiplier: number, cfg)
	local fill = 1.5
	local pixelsPerStud = 70
	local canvasH = math.max(1, (cfg.Height - 0.55) * pixelsPerStud)
	local uiScale = math.max(canvasH * 0.7 * fill / 100, 1.05)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "FaceLabel"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.ZOffset = 0.08
	gui.Parent = panel

	local function makeGlyph(name: string, zIndex: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.9 / uiScale, 0.82 / uiScale)
		label.Font = Enum.Font.FredokaOne
		label.Text = `x{multiplier}`
		label.TextColor3 = color
		label.TextSize = 100
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.ZIndex = zIndex
		label.Parent = gui
		local scale = Instance.new("UIScale")
		scale.Scale = uiScale
		scale.Parent = label
		return label
	end

	local glow = makeGlyph("Glow", 1, Color3.fromRGB(150, 220, 255))
	glow.TextTransparency = 0.28
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(90, 195, 255)
	glowStroke.Thickness = 6
	glowStroke.Transparency = 0.35
	glowStroke.LineJoinMode = Enum.LineJoinMode.Round
	glowStroke.Parent = glow

	local face = makeGlyph("Text", 3, Color3.fromRGB(255, 255, 255))
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(16, 48, 130)
	stroke.Thickness = 4.2
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = face
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 232, 255)),
	})
	gradient.Parent = face
end

function NumberGate.onCollected(callback: () -> ())
	onCollected = callback
end

function NumberGate.aliveCount(): number
	local n = 0
	for _, record in gates do
		if record.alive and record.model.Parent then
			n += 1
		end
	end
	return n
end

function NumberGate.canSpawn(): boolean
	return NumberGate.aliveCount() < liveNumberGate().MaxAlive
end

function NumberGate.create(): GateRecord?
	if not NumberGate.canSpawn() then
		return nil
	end

	local cfg = liveNumberGate()
	local folder = ensureFolder()
	local x = Config.sidePathCenterX()
	local y = Config.Lane.CenterY + Config.Lane.Thickness * 0.5 + cfg.Height * 0.5 + 0.15
	local z = Config.Lane.SpawnZ
	local position = Vector3.new(x, y, z)

	local hits = math.random(cfg.HitCountMin, cfg.HitCountMax)

	local model = Instance.new("Model")
	model.Name = "NumberGate"
	model:SetAttribute("IsNumberGate", true)
	model:SetAttribute("Multiplier", cfg.Multiplier)
	model:SetAttribute("HitsLeft", hits)
	model:SetAttribute("LabelScale", cfg.LabelScale)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(cfg.Width, cfg.Height, math.max(cfg.Depth, 2.2))
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CFrame = gateCFrame(position)
	root.Parent = model

	local frameColor = Color3.fromRGB(22, 72, 175)
	local panelColor = Color3.fromRGB(110, 185, 230)

	local panel = makePart(
		model,
		"Panel",
		Vector3.new(cfg.Width - 0.55, cfg.Height - 0.55, cfg.Depth * 0.45),
		panelColor,
		root.CFrame,
		Enum.Material.SmoothPlastic
	)
	panel.Transparency = 0.22
	weldTo(root, panel, true)
	attachFaceLabel(panel, cfg.Multiplier, cfg)

	local top = makePart(
		model,
		"FrameTop",
		Vector3.new(cfg.Width, 0.28, cfg.Depth + 0.08),
		frameColor,
		root.CFrame * CFrame.new(0, cfg.Height * 0.5 - 0.12, 0),
		Enum.Material.Metal
	)
	weldTo(root, top)
	local bottom = makePart(
		model,
		"FrameBottom",
		Vector3.new(cfg.Width, 0.28, cfg.Depth + 0.08),
		frameColor,
		root.CFrame * CFrame.new(0, -(cfg.Height * 0.5 - 0.12), 0),
		Enum.Material.Metal
	)
	weldTo(root, bottom)
	local left = makePart(
		model,
		"FrameLeft",
		Vector3.new(0.28, cfg.Height - 0.2, cfg.Depth + 0.08),
		frameColor,
		root.CFrame * CFrame.new(-(cfg.Width * 0.5 - 0.12), 0, 0),
		Enum.Material.Metal
	)
	weldTo(root, left)
	local right = makePart(
		model,
		"FrameRight",
		Vector3.new(0.28, cfg.Height - 0.2, cfg.Depth + 0.08),
		frameColor,
		root.CFrame * CFrame.new(cfg.Width * 0.5 - 0.12, 0, 0),
		Enum.Material.Metal
	)
	weldTo(root, right)

	addCorner(model, root, -1, 1, cfg)
	addCorner(model, root, 1, 1, cfg)
	addCorner(model, root, -1, -1, cfg)
	addCorner(model, root, 1, -1, cfg)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(110, 185, 230)
	light.Brightness = 0.35
	light.Range = 8
	light.Parent = panel

	local hitScale = cfg.HitLabelScale or 1
	local label = attachOverheadHits(root, hits, cfg.Height * 0.5 + cfg.HitLabelOffset, hitScale)

	model.PrimaryPart = root
	model.Parent = folder

	local record: GateRecord = {
		model = model,
		root = root,
		label = label,
		hitsLeft = hits,
		alive = true,
	}
	table.insert(gates, record)
	return record
end

local function collect(record: GateRecord)
	if not record.alive then
		return
	end
	record.alive = false
	if record.model.Parent then
		record.model:Destroy()
	end
	if onCollected then
		onCollected()
	end
end

function NumberGate.damageModel(model: Model, hits: number?): boolean
	local hitPower = math.max(1, math.floor(hits or 1))
	for _, record in gates do
		if record.model == model and record.alive then
			record.hitsLeft -= hitPower
			model:SetAttribute("HitsLeft", record.hitsLeft)
			setHitLabel(record.label, record.hitsLeft)
			if record.hitsLeft <= 0 then
				collect(record)
			end
			return true
		end
	end
	return false
end

function NumberGate.update(dt: number, _playerPosition: Vector3?)
	local keep = {}
	for _, record in gates do
		if not (record.alive and record.model.Parent) then
			continue
		end

		local pos = record.root.Position
		local nextZ = pos.Z - Config.NumberGate.WalkSpeed * dt
		if nextZ < Config.Supply.DespawnZ then
			record.alive = false
			record.model:Destroy()
			continue
		end

		record.root.CFrame = gateCFrame(Vector3.new(pos.X, pos.Y, nextZ))

		table.insert(keep, record)
	end
	gates = keep
end

function NumberGate.clear()
	for _, record in gates do
		record.alive = false
		if record.model.Parent then
			record.model:Destroy()
		end
	end
	gates = {}
	local folder = Workspace:FindFirstChild("NumberGates")
	if folder then
		folder:ClearAllChildren()
	end
end

return NumberGate
