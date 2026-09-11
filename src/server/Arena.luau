local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ruins = require(script.Parent.Ruins)
local Bridge = require(script.Parent.Bridge)
local Dmz = require(script.Parent.Dmz)

local Arena = {}

local boundStartPad: BasePart? = nil

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

local function matchesLobbyName(name: string): boolean
	local target = Config.Lobby.StudioName
	if name == target or name == "찐 로비" or name == "씬로비" then
		return true
	end
	return string.find(name, target, 1, true) ~= nil or string.find(name, "씬로비", 1, true) ~= nil
end

local function findLobbyIn(root: Instance): Instance?
	if matchesLobbyName(root.Name) then
		return root
	end
	for _, child in root:GetChildren() do
		if matchesLobbyName(child.Name) then
			return child
		end
	end
	for _, desc in root:GetDescendants() do
		if matchesLobbyName(desc.Name) and (desc:IsA("Model") or desc:IsA("Folder")) then
			return desc
		end
	end
	return nil
end

local function findStudioLobby(): Instance?
	local found = findLobbyIn(Workspace)
	if found then
		return found
	end
	return nil
end

-- Arena를 다시 만들기 전에 찐로비·흙바닥을 Workspace로 빼 둔다
local function isLaneScriptPart(name: string): boolean
	return name == "Path"
		or name == "Shoulder"
		or name == "Curb"
		or name == "LaneBarrier"
		or name == "Median"
		or name == "MergedRoad"
		or name == "SidePath"
		or name == "PlayerSpawn"
		or name == "LobbyTitle"
end

local function looksLikeGround(p: BasePart): boolean
	local footprint = p.Size.X * p.Size.Z
	if p.Size.Y > 12 or footprint < 200 then
		return false
	end
	local n = string.lower(p.Name)
	if n == "lobbyfloor"
		or string.find(n, "floor", 1, true)
		or string.find(n, "ground", 1, true)
		or string.find(p.Name, "땅")
		or string.find(p.Name, "바닥")
		or string.find(p.Name, "흙")
	then
		return true
	end
	local mat = p.Material
	if mat == Enum.Material.Ground
		or mat == Enum.Material.Grass
		or mat == Enum.Material.Sand
		or mat == Enum.Material.Mud
		or mat == Enum.Material.LeafyGrass
	then
		return p.Size.Y <= 6 and footprint >= 800
	end
	-- 얇고 넓은 판이면 바닥으로 취급
	return p.Size.Y <= 4 and footprint >= 1500
end

local function salvageStudioLobby(): Instance?
	local arena = Workspace:FindFirstChild("Arena")
	local lobby = findStudioLobby()

	if not arena then
		return lobby
	end

	-- LobbyFloor / 흙바닥이 찐로비 밖에 있어도 지워지지 않게 회수
	local grounds = {}
	for _, desc in arena:GetDescendants() do
		if desc:IsA("BasePart") and looksLikeGround(desc) then
			table.insert(grounds, desc)
		end
	end

	if lobby and lobby:IsDescendantOf(arena) then
		lobby.Parent = Workspace
	end

	local host = lobby
	if not host and #grounds > 0 then
		host = Instance.new("Folder")
		host.Name = Config.Lobby.StudioName
		host.Parent = Workspace
		lobby = host
	end

	if host then
		for _, ground in grounds do
			if ground.Parent and not ground:IsDescendantOf(host) then
				ground.Parent = host
			end
		end
	end

	-- 시작 발판·장식 모델이 Arena 직속이면 같이 보존
	for _, child in arena:GetChildren() do
		if child ~= host and not isLaneScriptPart(child.Name) then
			if child:IsA("Model") or child:IsA("Folder") then
				if matchesLobbyName(child.Name) then
					child.Parent = Workspace
					lobby = child
				elseif child:FindFirstChild("StartPad", true) or child:FindFirstChildWhichIsA("SpawnLocation", true) then
					child.Parent = Workspace
				end
			elseif host and child:IsA("BasePart") then
				if child.Name == "StartPad" or child:GetAttribute("IsStartPad") == true or looksLikeGround(child) then
					child.Parent = host
				end
			end
		end
	end

	return findStudioLobby() or lobby
end

local function greenPadScore(p: BasePart): number
	if p:GetAttribute("IsStartPad") == true or p.Name == "StartPad" then
		return 10000
	end

	local score = 0
	local name = string.lower(p.Name)
	if string.find(name, "start", 1, true) or string.find(p.Name, "시작") or string.find(p.Name, "발판") or string.find(p.Name, "초록") then
		score += 80
	end

	local c = p.Color
	local isGreen = c.G > 0.38 and c.G > c.R + 0.06 and c.G > c.B + 0.04
	if isGreen then
		score += 40 + math.floor(c.G * 25)
	end
	if p.Material == Enum.Material.Neon and isGreen then
		score += 35
	end

	local footprint = p.Size.X * p.Size.Z
	if p.Size.Y <= 8 and footprint >= 16 and footprint <= 600 then
		score += 25
	end
	if footprint > 2500 then
		score -= 80 -- 잔디 바닥 같은 큰 판
	end

	return score
end

local function largestPart(root: Instance): BasePart?
	local best: BasePart? = nil
	local bestVol = 0
	local list = if root:IsA("BasePart") then { root } else root:GetDescendants()
	for _, desc in list do
		if desc:IsA("BasePart") then
			local vol = desc.Size.X * desc.Size.Y * desc.Size.Z
			if vol > bestVol then
				bestVol = vol
				best = desc
			end
		end
	end
	return best
end

local function findStartPad(lobby: Instance): BasePart?
	if lobby:IsA("BasePart") then
		return lobby
	end
	local best: BasePart? = nil
	local bestScore = 0

	for _, desc in lobby:GetDescendants() do
		if desc:IsA("Model") then
			local n = string.lower(desc.Name)
			if string.find(n, "start", 1, true) or string.find(desc.Name, "시작") or string.find(desc.Name, "발판") then
				local part = largestPart(desc)
				if part then
					return part
				end
			end
		end
	end

	for _, desc in lobby:GetDescendants() do
		if desc:IsA("BasePart") then
			local score = greenPadScore(desc)
			if score > bestScore then
				bestScore = score
				best = desc
			end
		end
	end
	if best and bestScore >= 40 then
		return best
	end
	return nil
end

local function lobbyCenter(lobby: Instance): Vector3
	if lobby:IsA("Model") then
		return lobby:GetPivot().Position
	end
	if lobby:IsA("BasePart") then
		return lobby.Position
	end
	local acc = Vector3.zero
	local n = 0
	for _, desc in lobby:GetDescendants() do
		if desc:IsA("BasePart") then
			acc += desc.Position
			n += 1
		end
	end
	if n > 0 then
		return acc / n
	end
	return Config.Lobby.Center
end

local function findSpawnPart(lobby: Instance, pad: BasePart): BasePart?
	for _, desc in lobby:GetDescendants() do
		if desc:IsA("SpawnLocation") and desc ~= pad then
			local delta = desc.Position - pad.Position
			if Vector3.new(delta.X, 0, delta.Z).Magnitude > 8 then
				return desc
			end
		end
	end
	return nil
end

local function ensureStartLabel(pad: BasePart)
	if pad:FindFirstChild("StartLabel") then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StartLabel"
	billboard.Size = UDim2.new(0, 220, 0, 56)
	billboard.StudsOffset = Vector3.new(0, 4.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pad

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = "게임 시작"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = billboard
end

local function bindPad(pad: BasePart)
	boundStartPad = pad
	pad.Anchored = true
	pad.CanCollide = true
	pad.CanTouch = true
	pad:SetAttribute("IsStartPad", true)
	ensureStartLabel(pad)
end

local function applyLobbyConfig(center: Vector3, spawn: Vector3, padPos: Vector3)
	Config.Lobby.Center = center
	Config.Lobby.Spawn = spawn
	Config.Lobby.StartPad = padPos
end

local function adoptStudioLobby(lobby: Instance): boolean
	local pad = findStartPad(lobby)
	if not pad then
		warn(`[Arena] "{lobby.Name}"에서 초록 시작 발판을 못 찾음 — 기본 로비를 씁니다`)
		return false
	end

	bindPad(pad)

	local center = lobbyCenter(lobby)
	local spawnPart = findSpawnPart(lobby, pad)
	local spawn: Vector3
	if spawnPart then
		spawn = spawnPart.Position + Vector3.new(0, 3, 0)
	else
		local away = Vector3.new(center.X - pad.Position.X, 0, center.Z - pad.Position.Z)
		if away.Magnitude < 8 then
			away = Vector3.new(0, 0, -16)
		end
		spawn = pad.Position + away.Unit * 18 + Vector3.new(0, 4, 0)
	end

	applyLobbyConfig(center, spawn, pad.Position)
	print(`[Arena] 로비 = {lobby.Name} / 시작발판 = {pad.Name}`)
	return true
end

local function buildGeneratedLobby(folder: Folder)
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
	bindPad(startPad)

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
end

function Arena.getStartPad(): BasePart?
	if boundStartPad and boundStartPad.Parent then
		return boundStartPad
	end
	local arena = Workspace:FindFirstChild("Arena")
	local pad = arena and arena:FindFirstChild("StartPad")
	if pad and pad:IsA("BasePart") then
		return pad
	end
	return nil
end

function Arena.build(): Folder
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Hero")
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Horde")
	end)
	PhysicsService:CollisionGroupSetCollidable("Hero", "Horde", false)

	boundStartPad = nil
	local studioLobby = salvageStudioLobby()

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

	local usingStudioLobby = studioLobby and studioLobby.Parent and adoptStudioLobby(studioLobby)
	if not usingStudioLobby then
		if studioLobby == nil then
			warn(`[Arena] Workspace에 "{Config.Lobby.StudioName}"가 없음 — 기본 로비를 씁니다`)
		end
		buildGeneratedLobby(folder)
	end

	local lobby = Config.Lobby
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

	-- 찐로비 쓸 때는 Studio 조명을 그대로 둔다 (바닥색이 바뀌어 보이지 않게)
	if not usingStudioLobby then
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
	end

	return folder
end

function Arena.applyChapterLook(chapter: number)
	-- 로비(챕터1 복귀): Studio 꾸민 로비가 있으면 조명 덮어쓰지 않음
	if chapter <= 1 and findStudioLobby() ~= nil then
		return
	end
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
