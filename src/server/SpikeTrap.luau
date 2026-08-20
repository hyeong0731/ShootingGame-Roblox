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
	local cfg = Config.SpikeTrap
	local lane = Config.activeLane()
	local minX, maxX = Config.zombieXBounds(lane.SpawnZ)
	local half = cfg.Size * 0.5
	local loX = minX + half * 0.4
	local hiX = maxX - half * 0.4
	local spawnX = math.clamp(x or (loX + (hiX - loX) * math.random()), loX, hiX)
	local y = lane.CenterY + lane.Thickness * 0.5 + cfg.BaseHeight * 0.5

	local model = Instance.new("Model")
	model.Name = "SpikeTrap"

	local root = Instance.new("Part")
	root.Name = "Base"
	root.Size = Vector3.new(cfg.Size, cfg.BaseHeight, cfg.Size)
	root.Color = Color3.fromRGB(58, 54, 50)
	root.Material = Enum.Material.DiamondPlate
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.CFrame = CFrame.new(spawnX, y, lane.SpawnZ)
	root.Parent = model

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

	model.PrimaryPart = root
	model.Parent = ensureFolder()

	local zombieSpeed = Config.activeZombie().WalkSpeed
	local record: TrapRecord = {
		model = model,
		root = root,
		alive = true,
		walkSpeed = zombieSpeed * cfg.SpeedScale,
		half = half,
	}
	table.insert(traps, record)
	return record
end

-- 플레이어가 압정 위에 있으면 true (좀비/총알은 영향 없음)
function SpikeTrap.isInside(position: Vector3): boolean
	for _, record in traps do
		if not (record.alive and record.model.Parent) then
			continue
		end
		local pos = record.root.Position
		if math.abs(position.X - pos.X) <= record.half and math.abs(position.Z - pos.Z) <= record.half then
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
		record.root.CFrame = CFrame.new(pos.X, pos.Y, nextZ)
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
