local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ruins = require(script.Parent.Ruins)
local Bridge = require(script.Parent.Bridge)
local Dmz = require(script.Parent.Dmz)

local Arena = {}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.Concrete
	p.Color = props.Color
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Name = props.Name or "Part"
	p.CastShadow = props.CastShadow ~= false
	p.Parent = props.Parent
	return p
end

function Arena.build(): Folder
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Hero")
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Horde")
	end)
	PhysicsService:CollisionGroupSetCollidable("Hero", "Horde", false)

	local existing = Workspace:FindFirstChild("Arena")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Arena"
	folder.Parent = Workspace

	local lane = Config.Lane
	local pathLength = lane.Length
	local pathWidth = lane.Width
	local midZ = pathLength / 2 - 8

	part({
		Name = "Path",
		Parent = folder,
		Color = Color3.fromRGB(62, 58, 52),
		Material = Enum.Material.Asphalt,
		Size = Vector3.new(pathWidth, lane.Thickness, pathLength),
		CFrame = CFrame.new(0, lane.CenterY, midZ),
	})

	-- Camera looks +Z: screen-right is world -X. Side path lives there, separated by flat ground.
	local gapX = -(pathWidth / 2 + lane.GapWidth / 2)
	local sidePathX = -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth / 2)
	local outerX = -(pathWidth / 2 + lane.GapWidth + lane.SidePathWidth)

	part({
		Name = "Shoulder",
		Parent = folder,
		Color = Color3.fromRGB(54, 62, 42),
		Material = Enum.Material.Ground,
		Size = Vector3.new(90, 1, pathLength + 20),
		CFrame = CFrame.new(pathWidth / 2 + 45, 0.4, midZ),
		CanCollide = true,
	})
	part({
		Name = "Shoulder",
		Parent = folder,
		Color = Color3.fromRGB(54, 62, 42),
		Material = Enum.Material.Ground,
		Size = Vector3.new(90, 1, pathLength + 20),
		CFrame = CFrame.new(outerX - 45, 0.4, midZ),
		CanCollide = true,
	})

	-- main-path left curb (screen-left = +X)
	part({
		Name = "Curb",
		Parent = folder,
		Color = Color3.fromRGB(120, 118, 112),
		Material = Enum.Material.Slate,
		Size = Vector3.new(1.2, 1.6, pathLength),
		CFrame = CFrame.new(pathWidth / 2, 1.1, midZ),
	})
	part({
		Name = "LaneBarrier",
		Parent = folder,
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(2, 18, pathLength + 8),
		CFrame = CFrame.new(pathWidth / 2 - 0.4, 9, midZ),
		CanCollide = true,
		CastShadow = false,
	}).Transparency = 1

	-- Flat ground between roads, but only PAST the near merge so the player area is one wide road.
	local mergeUntilZ = lane.MergeUntilZ
	local pathStartZ = midZ - pathLength / 2
	local pathEndZ = midZ + pathLength / 2
	local farLength = math.max(4, pathEndZ - mergeUntilZ)
	local farMidZ = mergeUntilZ + farLength / 2
	local nearLength = math.max(4, mergeUntilZ - pathStartZ)
	local nearMidZ = pathStartZ + nearLength / 2
	local mergeWidth = lane.GapWidth + lane.SidePathWidth + 1.2

	part({
		Name = "Median",
		Parent = folder,
		Color = Color3.fromRGB(54, 62, 42),
		Material = Enum.Material.Ground,
		Size = Vector3.new(lane.GapWidth, 1, farLength),
		CFrame = CFrame.new(gapX, 0.4, farMidZ),
		CanCollide = true,
	})
	-- Fill the gap next to the player with the same asphalt as the main road.
	part({
		Name = "MergedRoad",
		Parent = folder,
		Color = Color3.fromRGB(62, 58, 52),
		Material = Enum.Material.Asphalt,
		Size = Vector3.new(mergeWidth, lane.Thickness, nearLength),
		CFrame = CFrame.new(-(pathWidth / 2 + mergeWidth / 2) + 0.4, lane.CenterY, nearMidZ),
	})
	part({
		Name = "SidePath",
		Parent = folder,
		Color = Color3.fromRGB(62, 58, 52),
		Material = Enum.Material.Asphalt,
		Size = Vector3.new(lane.SidePathWidth, lane.Thickness, pathLength),
		CFrame = CFrame.new(sidePathX, lane.CenterY, midZ),
	})
	part({
		Name = "Curb",
		Parent = folder,
		Color = Color3.fromRGB(120, 118, 112),
		Material = Enum.Material.Slate,
		Size = Vector3.new(1.2, 1.6, pathLength),
		CFrame = CFrame.new(outerX, 1.1, midZ),
	})
	part({
		Name = "LaneBarrier",
		Parent = folder,
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(2, 18, pathLength + 8),
		CFrame = CFrame.new(outerX + 0.4, 9, midZ),
		CanCollide = true,
		CastShadow = false,
	}).Transparency = 1

	Ruins.build(folder)
	Bridge.build(folder)
	Dmz.build(folder)

	-- open lobby field, far from the lane
	local lobby = Config.Lobby
	part({
		Name = "LobbyFloor",
		Parent = folder,
		Color = Color3.fromRGB(92, 124, 70),
		Material = Enum.Material.Grass,
		Size = lobby.Size,
		CFrame = CFrame.new(lobby.Center),
	})

	local startPad = part({
		Name = "StartPad",
		Parent = folder,
		Color = Color3.fromRGB(48, 190, 92),
		Material = Enum.Material.Neon,
		Size = Vector3.new(10, 1.2, 10),
		CFrame = CFrame.new(lobby.StartPad),
	})
	startPad:SetAttribute("IsStartPad", true)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StartLabel"
	billboard.Size = UDim2.new(0, 220, 0, 56)
	billboard.StudsOffset = Vector3.new(0, 4.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = startPad

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = "게임 시작"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = billboard

	local titlePart = part({
		Name = "LobbyTitle",
		Parent = folder,
		Color = Color3.fromRGB(40, 44, 56),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(0.4, 0.4, 0.4),
		CFrame = CFrame.new(lobby.Center.X, 8, lobby.Center.Z - 4),
		CanCollide = false,
		CastShadow = false,
	})
	titlePart.Transparency = 1
	local titleGui = Instance.new("BillboardGui")
	titleGui.Size = UDim2.new(0, 320, 0, 72)
	titleGui.StudsOffset = Vector3.new(0, 0, 0)
	titleGui.AlwaysOnTop = true
	titleGui.Parent = titlePart
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 1, 0)
	title.Font = Enum.Font.GothamBold
	title.Text = "좀비 디펜스"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.3
	title.TextScaled = true
	title.Parent = titleGui

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CFrame = CFrame.lookAt(
		lobby.Spawn,
		Vector3.new(lobby.StartPad.X, lobby.Spawn.Y, lobby.StartPad.Z)
	)
	spawn.Parent = folder

	local zombiesFolder = Instance.new("Folder")
	zombiesFolder.Name = "Zombies"
	zombiesFolder.Parent = Workspace

	local suppliesFolder = Instance.new("Folder")
	suppliesFolder.Name = "Supplies"
	suppliesFolder.Parent = Workspace

	local alliesFolder = Instance.new("Folder")
	alliesFolder.Name = "Allies"
	alliesFolder.Parent = Workspace

	local fxFolder = Instance.new("Folder")
	fxFolder.Name = "Fx"
	fxFolder.Parent = Workspace

	Lighting.Brightness = 2.55
	Lighting.Ambient = Color3.fromRGB(140, 138, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 168, 158)
	Lighting.ClockTime = 13.5
	Lighting.GeographicLatitude = 25
	Lighting.FogColor = Color3.fromRGB(190, 200, 210)
	Lighting.FogStart = 90
	Lighting.FogEnd = 320

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.18
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 205, 215)
	atmosphere.Decay = Color3.fromRGB(150, 155, 165)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 0.8

	return folder
end

function Arena.applyChapterLook(chapter: number)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	if chapter >= 3 then
		Lighting.Brightness = 1.65
		Lighting.Ambient = Color3.fromRGB(88, 96, 78)
		Lighting.OutdoorAmbient = Color3.fromRGB(108, 116, 92)
		Lighting.ClockTime = 16.85
		Lighting.GeographicLatitude = 38
		Lighting.FogColor = Color3.fromRGB(132, 140, 118)
		Lighting.FogStart = 48
		Lighting.FogEnd = 230
		atmosphere.Density = 0.3
		atmosphere.Offset = 0.08
		atmosphere.Color = Color3.fromRGB(150, 158, 132)
		atmosphere.Decay = Color3.fromRGB(90, 96, 78)
		atmosphere.Glare = 0.08
		atmosphere.Haze = 1.35
	else
		Lighting.Brightness = 2.55
		Lighting.Ambient = Color3.fromRGB(140, 138, 130)
		Lighting.OutdoorAmbient = Color3.fromRGB(170, 168, 158)
		Lighting.ClockTime = 13.5
		Lighting.GeographicLatitude = 25
		Lighting.FogColor = Color3.fromRGB(190, 200, 210)
		Lighting.FogStart = 90
		Lighting.FogEnd = 320
		atmosphere.Density = 0.18
		atmosphere.Offset = 0.1
		atmosphere.Color = Color3.fromRGB(200, 205, 215)
		atmosphere.Decay = Color3.fromRGB(150, 155, 165)
		atmosphere.Glare = 0.15
		atmosphere.Haze = 0.8
	end
end

return Arena
