local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Ruins = {}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.Material = props.Material or Enum.Material.Concrete
	p.Color = props.Color
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Name = props.Name or "Ruin"
	p.CastShadow = props.CastShadow ~= false
	p.Parent = props.Parent
	return p
end

local function building(parent: Folder, x: number, z: number, width: number, height: number, depth: number, color: Color3)
	part({
		Name = "Building",
		Parent = parent,
		Color = color,
		Material = Enum.Material.Concrete,
		Size = Vector3.new(width, height, depth),
		CFrame = CFrame.new(x, height / 2, z),
		CanCollide = true,
	})
	local floors = math.max(2, math.floor(height / 10))
	for floor = 1, floors do
		local wy = 3 + (floor - 1) * (height / floors)
		for _, wx in { x - width * 0.28, x + width * 0.28 } do
			part({
				Name = "Window",
				Parent = parent,
				Color = Color3.fromRGB(18, 18, 16),
				Material = Enum.Material.SmoothPlastic,
				Size = Vector3.new(width * 0.22, 3.2, 0.4),
				CFrame = CFrame.new(wx, wy, z + (if x > 0 then -depth / 2 else depth / 2) * 0.98),
			})
		end
	end
	if height > 18 then
		part({
			Name = "Vine",
			Parent = parent,
			Color = Color3.fromRGB(46, 92, 42),
			Material = Enum.Material.Grass,
			Size = Vector3.new(1.4, height * 0.7, depth * 0.9),
			CFrame = CFrame.new(x + (if x > 0 then -width / 2 + 0.6 else width / 2 - 0.6), height * 0.35, z),
		})
	end
end

local function rustCar(parent: Folder, x: number, z: number, yaw: number)
	local body = part({
		Name = "Car",
		Parent = parent,
		Color = Color3.fromRGB(92, 62, 38),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(4.4, 1.5, 8.2),
		CFrame = CFrame.new(x, 1.4, z) * CFrame.Angles(0, yaw, 0),
		CanCollide = true,
	})
	part({
		Name = "Cabin",
		Parent = parent,
		Color = Color3.fromRGB(70, 48, 32),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(4.1, 1.3, 3.4),
		CFrame = body.CFrame * CFrame.new(0, 1.3, -0.4),
	})
end

function Ruins.build(folder: Folder)
	local lane = Config.Lane
	local pathWidth = lane.Width
	local midZ = lane.Length / 2 - 8
	local leftSide = pathWidth / 2 + 16
	local rightSide = pathWidth / 2 + lane.GapWidth + lane.SidePathWidth + 16
	local concrete = Color3.fromRGB(92, 90, 82)
	local dirty = Color3.fromRGB(78, 74, 66)
	local dark = Color3.fromRGB(62, 60, 54)

	part({
		Name = "Asphalt",
		Parent = folder,
		Color = Color3.fromRGB(58, 56, 52),
		Material = Enum.Material.Asphalt,
		Size = Vector3.new(pathWidth, 0.2, lane.Length),
		CFrame = CFrame.new(0, lane.CenterY + 0.55, midZ),
	})

	for i = 0, 9 do
		local z = 8 + i * 14
		building(folder, -rightSide, z, 18, 22 + (i % 3) * 8, 16, if i % 2 == 0 then concrete else dirty)
		building(folder, leftSide, z + 6, 16, 18 + (i % 4) * 7, 14, if i % 2 == 1 then concrete else dark)
	end

	-- pharmacy sign
	local sign = part({
		Name = "PharmacySign",
		Parent = folder,
		Color = Color3.fromRGB(36, 40, 36),
		Material = Enum.Material.Metal,
		Size = Vector3.new(8, 3.2, 0.4),
		CFrame = CFrame.new(-rightSide + 8.8, 14, 24),
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = "+"
	label.TextColor3 = Color3.fromRGB(70, 170, 80)
	label.TextScaled = true
	label.Parent = gui

	rustCar(folder, pathWidth / 2 + 5, 18, math.rad(18))
	rustCar(folder, -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth + 8), 40, math.rad(-35))
	rustCar(folder, pathWidth / 2 + 6, 72, math.rad(80))
	rustCar(folder, -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth + 7), 96, math.rad(-12))
	rustCar(folder, pathWidth / 2 + 4, 118, math.rad(40))

	part({
		Name = "Container",
		Parent = folder,
		Color = Color3.fromRGB(110, 72, 42),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(8, 8, 18),
		CFrame = CFrame.new(-(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth + 12), 4.2, 58) * CFrame.Angles(0, math.rad(-18), math.rad(8)),
		CanCollide = true,
	})

	part({
		Name = "TrainCar",
		Parent = folder,
		Color = Color3.fromRGB(86, 70, 52),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(10, 8, 28),
		CFrame = CFrame.new(-rightSide + 2, 18, 88) * CFrame.Angles(math.rad(6), math.rad(-12), math.rad(4)),
		CanCollide = true,
	})

	for i = 1, 8 do
		local poleX = if i % 2 == 0 then leftSide - 2 else -rightSide + 2
		local poleZ = 12 + i * 16
		part({
			Name = "Pole",
			Parent = folder,
			Color = Color3.fromRGB(48, 46, 42),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.7, 18, 0.7),
			CFrame = CFrame.new(poleX, 9, poleZ) * CFrame.Angles(0, 0, math.rad((i % 2 == 0 and 6 or -5))),
			CanCollide = true,
		})
	end

	for i = 1, 18 do
		local sideClear = pathWidth / 2 + lane.GapWidth + lane.SidePathWidth + 3
		local scatterX = if i % 2 == 0 then -(sideClear + (i % 4)) else pathWidth / 2 + 3 + (i % 4)
		local scatterZ = 10 + i * 7
		part({
			Name = "Rubble",
			Parent = folder,
			Color = Color3.fromRGB(96, 90, 82),
			Material = Enum.Material.Slate,
			Size = Vector3.new(1.4 + (i % 3) * 0.6, 0.7 + (i % 2) * 0.4, 1.6 + (i % 4) * 0.5),
			CFrame = CFrame.new(scatterX, 1.1, scatterZ) * CFrame.Angles(0, math.rad(i * 27), math.rad(i % 5)),
		})
	end

	for i = 1, 6 do
		part({
			Name = "Canister",
			Parent = folder,
			Color = Color3.fromRGB(120, 120, 118),
			Material = Enum.Material.Metal,
			Size = Vector3.new(1.1, 1.6, 1.1),
			CFrame = CFrame.new(
				if i % 2 == 0
					then -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth + 4)
					else pathWidth / 2 + 4,
				1.5,
				16 + i * 18
			),
		})
	end

	part({
		Name = "Cart",
		Parent = folder,
		Color = Color3.fromRGB(80, 78, 74),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(2.2, 2.2, 3.4),
		CFrame = CFrame.new(pathWidth / 2 + 4, 1.6, 32) * CFrame.Angles(0, math.rad(25), 0),
	})
end

return Ruins
