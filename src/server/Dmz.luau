local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Dmz = {}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.Concrete
	p.Color = props.Color
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Name = props.Name or "Dmz"
	p.CastShadow = props.CastShadow ~= false
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Parent = props.Parent
	return p
end

local function signLabel(host: Part, text: string, face: Enum.NormalId, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0.2
	gui.Parent = host
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = gui
end

local function barbedSpan(folder: Folder, x: number, y: number, zA: number, zB: number)
	local midZ = (zA + zB) * 0.5
	local length = math.abs(zB - zA)
	for _, wy in { y + 1.15, y + 2.05, y + 2.95, y + 3.85 } do
		part({
			Name = "BarbedWire",
			Parent = folder,
			Color = Color3.fromRGB(38, 36, 34),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.07, 0.07, length),
			CFrame = CFrame.new(x, wy, midZ),
			CanCollide = false,
			CastShadow = false,
		})
	end
	part({
		Name = "BarbedX",
		Parent = folder,
		Color = Color3.fromRGB(42, 40, 38),
		Material = Enum.Material.Metal,
		Size = Vector3.new(0.06, math.sqrt(length * length + 7.3), 0.06),
		CFrame = CFrame.new(x, y + 2.5, midZ) * CFrame.Angles(math.atan2(length, 2.7), 0, 0),
		CanCollide = false,
		CastShadow = false,
	})
	part({
		Name = "BarbedX",
		Parent = folder,
		Color = Color3.fromRGB(42, 40, 38),
		Material = Enum.Material.Metal,
		Size = Vector3.new(0.06, math.sqrt(length * length + 7.3), 0.06),
		CFrame = CFrame.new(x, y + 2.5, midZ) * CFrame.Angles(-math.atan2(length, 2.7), 0, 0),
		CanCollide = false,
		CastShadow = false,
	})
end

local function fenceLine(folder: Folder, x: number, y: number, zStart: number, zEnd: number)
	local spacing = 9
	local posts = {}
	local z = zStart
	while z <= zEnd + 0.1 do
		table.insert(posts, z)
		part({
			Name = "FencePost",
			Parent = folder,
			Color = Color3.fromRGB(52, 50, 46),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.38, 4.8, 0.38),
			CFrame = CFrame.new(x, y + 2.55, z),
		})
		part({
			Name = "Jersey",
			Parent = folder,
			Color = Color3.fromRGB(118, 114, 104),
			Material = Enum.Material.Concrete,
			Size = Vector3.new(0.85, 1.15, spacing - 0.4),
			CFrame = CFrame.new(x, y + 0.7, z + spacing * 0.45),
		})
		z += spacing
	end
	for i = 1, #posts - 1 do
		barbedSpan(folder, x, y, posts[i], posts[i + 1])
	end
end

local function coil(folder: Folder, x: number, y: number, z: number)
	part({
		Name = "RazorCoil",
		Parent = folder,
		Color = Color3.fromRGB(70, 68, 64),
		Material = Enum.Material.CorrodedMetal,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.15, 1.7, 1.7),
		CFrame = CFrame.new(x, y + 0.7, z) * CFrame.Angles(0, 0, math.rad(90)),
		CanCollide = false,
	})
end

local function watchtower(folder: Folder, x: number, z: number, yaw: number)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	for _, corner in { Vector3.new(-2.1, 5.2, -2.1), Vector3.new(2.1, 5.2, -2.1), Vector3.new(-2.1, 5.2, 2.1), Vector3.new(2.1, 5.2, 2.1) } do
		part({
			Name = "TowerLeg",
			Parent = folder,
			Color = Color3.fromRGB(86, 78, 62),
			Material = Enum.Material.Wood,
			Size = Vector3.new(0.45, 10.4, 0.45),
			CFrame = cf * CFrame.new(corner),
		})
	end
	part({
		Name = "TowerDeck",
		Parent = folder,
		Color = Color3.fromRGB(72, 68, 56),
		Material = Enum.Material.Wood,
		Size = Vector3.new(5.6, 0.45, 5.6),
		CFrame = cf * CFrame.new(0, 10.5, 0),
	})
	part({
		Name = "TowerCabin",
		Parent = folder,
		Color = Color3.fromRGB(78, 82, 64),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(4.4, 2.6, 4.4),
		CFrame = cf * CFrame.new(0, 12, 0),
	})
	part({
		Name = "TowerRoof",
		Parent = folder,
		Color = Color3.fromRGB(58, 56, 48),
		Material = Enum.Material.Metal,
		Size = Vector3.new(5.2, 0.35, 5.2),
		CFrame = cf * CFrame.new(0, 13.45, 0),
	})
	local light = part({
		Name = "Searchlight",
		Parent = folder,
		Color = Color3.fromRGB(210, 200, 160),
		Material = Enum.Material.Neon,
		Size = Vector3.new(0.7, 0.7, 0.7),
		CFrame = cf * CFrame.new(0, 13.95, 1.6),
		CanCollide = false,
	})
	local point = Instance.new("PointLight")
	point.Brightness = 0.55
	point.Range = 28
	point.Color = Color3.fromRGB(220, 200, 140)
	point.Parent = light
end

local function sandbag(folder: Folder, x: number, z: number, yaw: number)
	part({
		Name = "Sandbag",
		Parent = folder,
		Color = Color3.fromRGB(128, 112, 78),
		Material = Enum.Material.Fabric,
		Size = Vector3.new(2.4, 0.7, 1.1),
		CFrame = CFrame.new(x, 1.0, z) * CFrame.Angles(0, yaw, 0),
	})
end

local function warningSign(folder: Folder, x: number, z: number, yaw: number, text: string)
	part({
		Name = "SignPost",
		Parent = folder,
		Color = Color3.fromRGB(48, 46, 42),
		Material = Enum.Material.Metal,
		Size = Vector3.new(0.28, 3.6, 0.28),
		CFrame = CFrame.new(x, 2.0, z),
	})
	local board = part({
		Name = "WarningSign",
		Parent = folder,
		Color = Color3.fromRGB(28, 28, 24),
		Material = Enum.Material.Metal,
		Size = Vector3.new(4.6, 2.1, 0.18),
		CFrame = CFrame.new(x, 4.1, z) * CFrame.Angles(0, yaw, 0),
	})
	signLabel(board, text, Enum.NormalId.Front, Color3.fromRGB(220, 190, 50))
	signLabel(board, text, Enum.NormalId.Back, Color3.fromRGB(220, 190, 50))
end

function Dmz.build(folder: Folder)
	local lane = Config.Chapter3.Lane
	local midZ = (lane.PlayerZ + lane.SpawnZ) * 0.5
	local pathLength = lane.Length
	local pathWidth = lane.Width
	local deckY = lane.CenterY
	local sideX = -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth / 2)
	local outerX = -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth)
	local leftX = pathWidth / 2
	local zStart = lane.PlayerZ - 14
	local zEnd = lane.SpawnZ + 16

	part({
		Name = "DmzRoad",
		Parent = folder,
		Color = Color3.fromRGB(78, 74, 64),
		Material = Enum.Material.Asphalt,
		Size = Vector3.new(pathWidth, lane.Thickness, pathLength),
		CFrame = CFrame.new(0, deckY, midZ),
	})
	part({
		Name = "DmzPaint",
		Parent = folder,
		Color = Color3.fromRGB(150, 140, 70),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(0.28, 0.12, pathLength - 8),
		CFrame = CFrame.new(0, deckY + lane.Thickness * 0.5 + 0.08, midZ),
		CanCollide = false,
		CastShadow = false,
	})
	part({
		Name = "DmzWalk",
		Parent = folder,
		Color = Color3.fromRGB(86, 80, 68),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(lane.SidePathWidth, lane.Thickness, pathLength),
		CFrame = CFrame.new(sideX, deckY, midZ),
	})
	part({
		Name = "DmzMedian",
		Parent = folder,
		Color = Color3.fromRGB(70, 78, 52),
		Material = Enum.Material.Ground,
		Size = Vector3.new(lane.GapWidth, 0.7, pathLength),
		CFrame = CFrame.new(-(pathWidth / 2 + lane.GapWidth / 2), 0.35, midZ),
	})

	part({
		Name = "DmzShoulder",
		Parent = folder,
		Color = Color3.fromRGB(72, 78, 54),
		Material = Enum.Material.Ground,
		Size = Vector3.new(70, 1, pathLength + 36),
		CFrame = CFrame.new(leftX + 35, 0.35, midZ),
	})
	part({
		Name = "DmzShoulder",
		Parent = folder,
		Color = Color3.fromRGB(72, 78, 54),
		Material = Enum.Material.Ground,
		Size = Vector3.new(70, 1, pathLength + 36),
		CFrame = CFrame.new(outerX - 35, 0.35, midZ),
	})

	fenceLine(folder, leftX + 0.55, 0, zStart, zEnd)
	fenceLine(folder, outerX - 0.55, 0, zStart, zEnd)

	for i = 0, 10 do
		coil(folder, leftX + 1.35, 0, lane.PlayerZ + 6 + i * 18)
		coil(folder, outerX - 1.35, 0, lane.PlayerZ + 12 + i * 18)
	end

	watchtower(folder, leftX + 11, lane.PlayerZ + 28, math.rad(-12))
	watchtower(folder, outerX - 11, lane.PlayerZ + 86, math.rad(18))
	watchtower(folder, leftX + 12, lane.SpawnZ - 36, math.rad(-8))
	watchtower(folder, outerX - 12, lane.SpawnZ - 90, math.rad(14))

	warningSign(folder, leftX + 3.2, lane.PlayerZ + 18, math.rad(-90), "군사통제구역")
	warningSign(folder, outerX - 3.2, lane.PlayerZ + 40, math.rad(90), "지뢰지대")
	warningSign(folder, leftX + 3.2, midZ, math.rad(-90), "출입금지")
	warningSign(folder, outerX - 3.2, lane.SpawnZ - 22, math.rad(90), "DMZ")

	part({
		Name = "CheckpointBooth",
		Parent = folder,
		Color = Color3.fromRGB(82, 88, 68),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(5.2, 3.6, 4.4),
		CFrame = CFrame.new(leftX + 7.5, 2.3, lane.PlayerZ + 2),
	})
	part({
		Name = "BoomArm",
		Parent = folder,
		Color = Color3.fromRGB(200, 170, 40),
		Material = Enum.Material.Metal,
		Size = Vector3.new(14, 0.28, 0.28),
		CFrame = CFrame.new(2, 2.6, lane.PlayerZ - 8) * CFrame.Angles(0, 0, math.rad(12)),
	})
	part({
		Name = "Bunker",
		Parent = folder,
		Color = Color3.fromRGB(96, 94, 84),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(8.5, 3.2, 5.5),
		CFrame = CFrame.new(outerX - 9, 2.1, lane.PlayerZ + 6),
	})

	part({
		Name = "Humvee",
		Parent = folder,
		Color = Color3.fromRGB(70, 78, 52),
		Material = Enum.Material.Metal,
		Size = Vector3.new(4.4, 1.8, 7.6),
		CFrame = CFrame.new(leftX + 8, 1.6, midZ - 28) * CFrame.Angles(0, math.rad(16), 0),
	})
	part({
		Name = "HumveeCabin",
		Parent = folder,
		Color = Color3.fromRGB(58, 64, 44),
		Material = Enum.Material.Metal,
		Size = Vector3.new(4.1, 1.3, 3.2),
		CFrame = CFrame.new(leftX + 8, 3.1, midZ - 29) * CFrame.Angles(0, math.rad(16), 0),
	})
	part({
		Name = "WreckTruck",
		Parent = folder,
		Color = Color3.fromRGB(96, 72, 48),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(4.6, 2.2, 10),
		CFrame = CFrame.new(outerX - 9, 1.8, midZ + 48) * CFrame.Angles(0, math.rad(-64), math.rad(4)),
	})
	part({
		Name = "CrateStack",
		Parent = folder,
		Color = Color3.fromRGB(110, 92, 58),
		Material = Enum.Material.Wood,
		Size = Vector3.new(3.4, 2.4, 3.4),
		CFrame = CFrame.new(outerX - 7, 1.7, lane.PlayerZ + 22),
	})
	part({
		Name = "FuelDrum",
		Parent = folder,
		Color = Color3.fromRGB(72, 92, 48),
		Material = Enum.Material.Metal,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 1.15, 1.15),
		CFrame = CFrame.new(leftX + 3.2, 1.0, midZ + 18) * CFrame.Angles(0, 0, math.rad(90)),
	})
	part({
		Name = "FuelDrum",
		Parent = folder,
		Color = Color3.fromRGB(58, 62, 48),
		Material = Enum.Material.Metal,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 1.15, 1.15),
		CFrame = CFrame.new(leftX + 4.1, 1.0, midZ + 20) * CFrame.Angles(0, 0, math.rad(90)),
	})

	for i = 0, 7 do
		sandbag(folder, leftX + 2.2, lane.PlayerZ + 10 + i * 3.2, 0)
		sandbag(folder, outerX - 2.2, lane.PlayerZ + 48 + i * 3.2, 0)
	end

	for i = 1, 8 do
		local poleX = if i % 2 == 0 then leftX + 2.2 else outerX - 2.2
		part({
			Name = "FloodlightPole",
			Parent = folder,
			Color = Color3.fromRGB(42, 40, 38),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.4, 12, 0.4),
			CFrame = CFrame.new(poleX, 6.2, lane.PlayerZ + 8 + i * 24) * CFrame.Angles(0, 0, math.rad(if i % 3 == 0 then 5 else -3)),
		})
		part({
			Name = "Floodlight",
			Parent = folder,
			Color = Color3.fromRGB(210, 200, 150),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.9, 0.45, 0.7),
			CFrame = CFrame.new(poleX, 12.1, lane.PlayerZ + 8 + i * 24),
			CanCollide = false,
		})
	end

	part({
		Name = "CamoNet",
		Parent = folder,
		Color = Color3.fromRGB(62, 78, 48),
		Material = Enum.Material.Grass,
		Size = Vector3.new(10, 0.2, 14),
		CFrame = CFrame.new(sideX, 4.4, midZ - 8) * CFrame.Angles(math.rad(8), 0, 0),
		CanCollide = false,
	})

	part({
		Name = "LaneBarrier",
		Parent = folder,
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(2, 16, pathLength + 8),
		CFrame = CFrame.new(leftX + 0.7, deckY + 8, midZ),
		CastShadow = false,
		Transparency = 1,
	})
	part({
		Name = "LaneBarrier",
		Parent = folder,
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(2, 16, pathLength + 8),
		CFrame = CFrame.new(outerX - 0.7, deckY + 8, midZ),
		CastShadow = false,
		Transparency = 1,
	})
end

return Dmz
