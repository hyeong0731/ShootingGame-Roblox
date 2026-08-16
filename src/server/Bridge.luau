local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Bridge = {}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.Concrete
	p.Color = props.Color
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Name = props.Name or "Bridge"
	p.CastShadow = props.CastShadow ~= false
	p.Parent = props.Parent
	return p
end

function Bridge.build(folder: Folder)
	local lane = Config.Chapter2.Lane
	local midZ = (lane.PlayerZ + lane.SpawnZ) * 0.5
	local pathLength = lane.Length
	local pathWidth = lane.Width
	local deckY = lane.CenterY
	local sideX = -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth / 2)
	local outerX = -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth)

	part({
		Name = "BridgeDeck",
		Parent = folder,
		Color = Color3.fromRGB(72, 68, 62),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(pathWidth, lane.Thickness, pathLength),
		CFrame = CFrame.new(0, deckY, midZ),
	})
	part({
		Name = "BridgeAsphalt",
		Parent = folder,
		Color = Color3.fromRGB(48, 46, 44),
		Material = Enum.Material.Asphalt,
		Size = Vector3.new(pathWidth - 1.2, 0.25, pathLength),
		CFrame = CFrame.new(0, deckY + lane.Thickness * 0.5 + 0.1, midZ),
		CanCollide = false,
	})
	part({
		Name = "BridgeWalk",
		Parent = folder,
		Color = Color3.fromRGB(64, 62, 56),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(lane.SidePathWidth, lane.Thickness, pathLength),
		CFrame = CFrame.new(sideX, deckY, midZ),
	})

	for i = 0, 12 do
		local z = lane.PlayerZ - 8 + i * 16
		if i % 4 ~= 2 then
			part({
				Name = "Rail",
				Parent = folder,
				Color = Color3.fromRGB(86, 78, 70),
				Material = Enum.Material.CorrodedMetal,
				Size = Vector3.new(0.45, 2.4, 14),
				CFrame = CFrame.new(pathWidth / 2 + 0.2, deckY + 1.8, z),
			})
		end
		if i % 5 ~= 1 then
			part({
				Name = "Rail",
				Parent = folder,
				Color = Color3.fromRGB(86, 78, 70),
				Material = Enum.Material.CorrodedMetal,
				Size = Vector3.new(0.45, 2.4, 14),
				CFrame = CFrame.new(outerX - 0.2, deckY + 1.8, z),
			})
		end
	end

	for i = 0, 6 do
		local z = lane.PlayerZ + 10 + i * 28
		part({
			Name = "Pier",
			Parent = folder,
			Color = Color3.fromRGB(78, 74, 68),
			Material = Enum.Material.Concrete,
			Size = Vector3.new(5.5, deckY + 8, 4.2),
			CFrame = CFrame.new(-pathWidth / 2 + 2, (deckY + 8) / 2 - 8, z),
		})
		part({
			Name = "Pier",
			Parent = folder,
			Color = Color3.fromRGB(78, 74, 68),
			Material = Enum.Material.Concrete,
			Size = Vector3.new(5.5, deckY + 8, 4.2),
			CFrame = CFrame.new(pathWidth / 2 - 2, (deckY + 8) / 2 - 8, z),
		})
	end

	part({
		Name = "BrokenSlab",
		Parent = folder,
		Color = Color3.fromRGB(90, 84, 76),
		Material = Enum.Material.Concrete,
		Size = Vector3.new(7, 1.1, 11),
		CFrame = CFrame.new(pathWidth / 2 + 3.5, deckY - 1.4, midZ + 22) * CFrame.Angles(math.rad(-18), math.rad(8), math.rad(12)),
	})
	part({
		Name = "WreckCar",
		Parent = folder,
		Color = Color3.fromRGB(88, 58, 42),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(4.2, 1.6, 8),
		CFrame = CFrame.new(pathWidth / 2 - 6, deckY + 1.6, midZ - 18) * CFrame.Angles(0, math.rad(22), math.rad(6)),
	})
	part({
		Name = "WreckCar",
		Parent = folder,
		Color = Color3.fromRGB(62, 70, 58),
		Material = Enum.Material.CorrodedMetal,
		Size = Vector3.new(4.2, 1.6, 8),
		CFrame = CFrame.new(sideX, deckY + 1.6, midZ + 40) * CFrame.Angles(0, math.rad(-70), 0),
	})

	for i = 1, 8 do
		part({
			Name = "Lamp",
			Parent = folder,
			Color = Color3.fromRGB(42, 40, 38),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.55, 11, 0.55),
			CFrame = CFrame.new(
				if i % 2 == 0 then pathWidth / 2 + 0.4 else outerX,
				deckY + 6.2,
				lane.PlayerZ + 8 + i * 22
			) * CFrame.Angles(0, 0, math.rad(if i % 3 == 0 then 8 else -4)),
		})
	end

	part({
		Name = "Void",
		Parent = folder,
		Color = Color3.fromRGB(18, 22, 28),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(220, 2, pathLength + 80),
		CFrame = CFrame.new(0, -12, midZ),
		CastShadow = false,
	})

	part({
		Name = "LaneBarrier",
		Parent = folder,
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(2, 16, pathLength + 8),
		CFrame = CFrame.new(pathWidth / 2 + 0.6, deckY + 8, midZ),
		CastShadow = false,
	}).Transparency = 1
	part({
		Name = "LaneBarrier",
		Parent = folder,
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(2, 16, pathLength + 8),
		CFrame = CFrame.new(outerX - 0.6, deckY + 8, midZ),
		CastShadow = false,
	}).Transparency = 1
end

return Bridge
