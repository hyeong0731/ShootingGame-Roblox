local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type TrapRecord = {
	model: Model,
	root: BasePart,
	alive: boolean,
	walkSpeed: number,
	half: number,
}

local SpikeTrap = {}

local traps = {} :: { TrapRecord }

local function ensureFolder(): Folder
	local existing = Workspace:FindFirstChild("Hazards")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Hazards"
	folder.Parent = Workspace
	return folder
end

local function weldTo(root: BasePart, child: BasePart)
	child.Anchored = false
	child.CanCollide = false
	child.CanQuery = false
	child.CanTouch = false
	child.Massless = true
	child.CastShadow = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = child
	weld.Parent = child
end

local function buildSpikes(model: Model, root: BasePart, cfg)
	local rows = math.max(2, math.floor(cfg.SpikeRows))
	local step = cfg.Size / rows
	local start = -cfg.Size * 0.5 + step * 0.5
	for ix = 0, rows - 1 do
		for iz = 0, rows - 1 do
			local spike = Instance.new("Part")
			spike.Name = "Spike"
			spike.Shape = Enum.PartType.Cylinder
			spike.Size = Vector3.new(cfg.SpikeHeight, 0.55, 0.55)
			spike.Color = Color3.fromRGB(196, 202, 208)
			spike.Material = Enum.Material.Metal
			spike.Reflectance = 0.18
			spike.CFrame = root.CFrame
				* CFrame.new(start + ix * step, cfg.BaseHeight * 0.5 + cfg.SpikeHeight * 0.5, start + iz * step)
				* CFrame.Angles(0, 0, math.rad(90))
			spike.Parent = model
			weldTo(root, spike)
		end
	end
end

function SpikeTrap.create(x: number?): TrapRecord
	return SpikeTrap.createVariant("spike", x)
end

function SpikeTrap.createLog(x: number?): TrapRecord
	return SpikeTrap.createVariant("log", x)
end

function SpikeTrap.createVariant(kind: string, x: number?): TrapRecord
	local isLog = kind == "log"
	local cfg = Config.SpikeTrap
	local logCfg = Config.LogTrap
	local lane = Config.activeLane()
	local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
	local sizeX = if isLog then (logCfg.Length or 14) else cfg.Size
	local sizeZ = if isLog then (logCfg.Radius or 2.2) * 2 else cfg.Size
	local halfX = sizeX * 0.5
	local halfZ = sizeZ * 0.5
	local loX = minX + halfX * 0.35
	local hiX = maxX - halfX * 0.35
	local spawnX = math.clamp(x or (loX + (hiX - loX) * math.random()), loX, hiX)
	local y = lane.CenterY + lane.Thickness * 0.5 + (if isLog then (logCfg.Radius or 2.2) else cfg.BaseHeight * 0.5)

	local model = Instance.new("Model")
	model.Name = if isLog then "LogTrap" else "SpikeTrap"

	local root = Instance.new("Part")
	root.Name = "Base"
	if isLog then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new((logCfg.Radius or 2.2) * 2, sizeX, (logCfg.Radius or 2.2) * 2)
		root.Color = Color3.fromRGB(112, 78, 42)
		root.Material = Enum.Material.Wood
		root.CFrame = CFrame.new(spawnX, y, lane.SpawnZ) * CFrame.Angles(0, 0, math.rad(90))
	else
		root.Size = Vector3.new(cfg.Size, cfg.BaseHeight, cfg.Size)
		root.Color = Color3.fromRGB(58, 54, 50)
		root.Material = Enum.Material.DiamondPlate
		root.CFrame = CFrame.new(spawnX, y, lane.SpawnZ)
	end
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.Parent = model

	if not isLog then
		local rim = Instance.new("Part")
		rim.Name = "Rim"
		rim.Size = Vector3.new(cfg.Size + 0.5, cfg.BaseHeight * 0.55, cfg.Size + 0.5)
		rim.Color = Color3.fromRGB(214, 148, 40)
		rim.Material = Enum.Material.Neon
		rim.Transparency = 0.35
		rim.CFrame = root.CFrame * CFrame.new(0, -cfg.BaseHeight * 0.25, 0)
		rim.Parent = model
		weldTo(root, rim)
		buildSpikes(model, root, cfg)
	else
		-- 통나무 마디/끝부분
		for _, side in { -1, 1 } do
			local cap = Instance.new("Part")
			cap.Name = "LogCap"
			cap.Shape = Enum.PartType.Cylinder
			local r = (logCfg.Radius or 2.2) * 0.92
			cap.Size = Vector3.new(0.45, r * 2, r * 2)
			cap.Color = Color3.fromRGB(168, 130, 78)
			cap.Material = Enum.Material.Wood
			cap.Anchored = true
			cap.CanCollide = false
			cap.CanQuery = false
			cap.CFrame = CFrame.new(spawnX + side * (sizeX * 0.48), y, lane.SpawnZ) * CFrame.Angles(0, 0, math.rad(90))
			cap.Parent = model
			weldTo(root, cap)
		end
	end

	model.PrimaryPart = root
	model.Parent = ensureFolder()

	local zombieSpeed = Config.activeZombie().WalkSpeed
	local speedScale = if isLog then (logCfg.SpeedScale or cfg.SpeedScale) else cfg.SpeedScale
	local record: TrapRecord = {
		model = model,
		root = root,
		alive = true,
		walkSpeed = zombieSpeed * speedScale,
		half = math.max(halfX, halfZ),
	}
	-- 통나무는 X/Z 각각 다른 half 필요 → attribute
	root:SetAttribute("HalfX", halfX)
	root:SetAttribute("HalfZ", halfZ)
	root:SetAttribute("IsLogTrap", isLog)
	table.insert(traps, record)
	return record
end

-- 플레이어가 압정/통나무 위에 있으면 true (좀비/총알은 영향 없음)
function SpikeTrap.isInside(position: Vector3): boolean
	for _, record in traps do
		if not (record.alive and record.model.Parent) then
			continue
		end
		local pos = record.root.Position
		local halfX = (record.root:GetAttribute("HalfX") :: number?) or record.half
		local halfZ = (record.root:GetAttribute("HalfZ") :: number?) or record.half
		if math.abs(position.X - pos.X) <= halfX and math.abs(position.Z - pos.Z) <= halfZ then
			return true
		end
	end
	return false
end

function SpikeTrap.aliveCount(): number
	return #traps
end

function SpikeTrap.update(dt: number)
	local keep = {}
	local despawnZ = Config.crateDespawnZ()
	for _, record in traps do
		if not (record.alive and record.model.Parent) then
			continue
		end
		local pos = record.root.Position
		local nextZ = pos.Z - record.walkSpeed * dt
		if nextZ < despawnZ then
			record.alive = false
			record.model:Destroy()
			continue
		end
		local rot = record.root.CFrame - record.root.CFrame.Position
		record.root.CFrame = CFrame.new(pos.X, pos.Y, nextZ) * rot
		table.insert(keep, record)
	end
	traps = keep
end

function SpikeTrap.clear()
	for _, record in traps do
		record.alive = false
		if record.model.Parent then
			record.model:Destroy()
		end
	end
	traps = {}
	local folder = Workspace:FindFirstChild("Hazards")
	if folder then
		folder:ClearAllChildren()
	end
end

return SpikeTrap
