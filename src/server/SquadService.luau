local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type Squad = {
	folder: Folder,
	units: { BasePart },
	count: number,
}

local SquadService = {}

local function makeUnit(parent: Folder, color: Color3, size: Vector3): Part
	local body = Instance.new("Part")
	body.Name = "Unit"
	body.Size = size
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CastShadow = false
	body.Parent = parent

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.7, 0.7, 0.7)
	head.Color = Color3.fromRGB(245, 210, 170)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CastShadow = false
	head.Parent = body

	return body
end

local function formationOffset(index: number): Vector3
	local golden = math.pi * (3 - math.sqrt(5))
	local angle = index * golden
	local radius = Config.Squad.ClusterRadius * math.sqrt(index)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius * 0.42)
end

function SquadService.create(character: Model, count: number): Squad
	local existing = character:FindFirstChild("Squad")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Squad"
	folder.Parent = character

	local squad: Squad = {
		folder = folder,
		units = {},
		count = 0,
	}
	SquadService.setCount(squad, character, count)
	return squad
end

function SquadService.setCount(squad: Squad, character: Model, count: number)
	count = math.clamp(count, 1, Config.Player.MaxUnits)
	squad.count = count

	local needed = math.max(count - 1, 0)
	while #squad.units < needed do
		local unit = makeUnit(squad.folder, Color3.fromRGB(48, 92, 210), Vector3.new(0.9, 1.35, 0.7))
		table.insert(squad.units, unit)
	end
	while #squad.units > needed do
		local unit = table.remove(squad.units)
		if unit then
			unit:Destroy()
		end
	end

	SquadService.update(squad, character)
end

function SquadService.update(squad: Squad, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	for index, unit in squad.units do
		local offset = formationOffset(index)
		local world = root.CFrame * CFrame.new(offset.X, Config.Squad.UnitHeight, offset.Z)
		unit.CFrame = world
		local head = unit:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			head.CFrame = world * CFrame.new(0, 1.05, 0)
		end
	end
end

function SquadService.muzzlePoints(squad: Squad, character: Model, maxCount: number): { Vector3 }
	local points = {}
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return points
	end

	local muzzle = Config.Combat.MuzzleOffset
	table.insert(points, (root.CFrame * CFrame.new(muzzle)).Position)

	for index, unit in squad.units do
		if #points >= maxCount then
			break
		end
		table.insert(points, unit.Position + Vector3.new(0, 0.8, 1.4))
		local _ = index
	end

	return points
end

return SquadService
