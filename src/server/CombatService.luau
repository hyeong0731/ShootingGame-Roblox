local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)

local CombatService = {}
CombatService._remotes = nil :: any

local active = {} :: {
	{
		part: BasePart,
		direction: Vector3,
		speed: number,
		damage: number,
		born: number,
	}
}

function CombatService.bind(remotes)
	CombatService._remotes = remotes
end

local function spawnBolt(origin: Vector3, direction: Vector3): BasePart
	local bolt = Instance.new("Part")
	bolt.Name = "Bolt"
	bolt.Shape = Enum.PartType.Block
	bolt.Size = Vector3.new(0.28, 0.28, 3.4)
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(255, 220, 70)
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.CastShadow = false
	bolt.CFrame = CFrame.lookAt(origin, origin + direction)
	bolt.Parent = Workspace:FindFirstChild("Fx") or Workspace

	local tip = Instance.new("WedgePart")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.3, 0.3, 0.7)
	tip.Material = Enum.Material.Neon
	tip.Color = Color3.fromRGB(255, 245, 180)
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CastShadow = false
	tip.CFrame = bolt.CFrame * CFrame.new(0, 0, -2.0)
	tip.Parent = bolt

	return bolt
end

function CombatService.fireStraight(origin: Vector3, damage: number)
	local direction = Vector3.new(0, 0, 1)
	local part = spawnBolt(origin, direction)
	table.insert(active, {
		part = part,
		direction = direction,
		speed = Config.Combat.ProjectileSpeed,
		damage = damage,
		born = os.clock(),
	})
end

function CombatService.update(dt: number)
	local keep = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local zombiesFolder = Workspace:FindFirstChild("Zombies")
	if zombiesFolder then
		params.FilterDescendantsInstances = { zombiesFolder }
	end

	local now = os.clock()
	for _, shot in active do
		if not shot.part.Parent then
			continue
		end
		if now - shot.born > Config.Combat.ProjectileLifetime then
			shot.part:Destroy()
			continue
		end

		local visual = shot.part.Position
		local nextPos = visual + shot.direction * shot.speed * dt
		local castFrom = visual - shot.direction * 1.2
		local castTravel = shot.direction * (shot.speed * dt + 2.6)
		local result = Workspace:Spherecast(castFrom, 0.7, castTravel, params)
		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			while model and model.Name == "Bolt" do
				model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
			end
			if model then
				local damaged = ZombieService.damageModel(model, shot.damage)
				if damaged and CombatService._remotes then
					CombatService._remotes.HitFx:FireAllClients(result.Position, model:GetAttribute("IsBoss") == true)
				end
			end
			shot.part:Destroy()
			continue
		end

		local look = CFrame.lookAt(nextPos, nextPos + shot.direction)
		shot.part.CFrame = look
		local tip = shot.part:FindFirstChild("Tip")
		if tip and tip:IsA("BasePart") then
			tip.CFrame = look * CFrame.new(0, 0, -2.0)
		end
		table.insert(keep, shot)
	end
	active = keep
end

function CombatService.clear()
	for _, shot in active do
		if shot.part.Parent then
			shot.part:Destroy()
		end
	end
	active = {}
	local fx = Workspace:FindFirstChild("Fx")
	if fx then
		fx:ClearAllChildren()
	end
end

return CombatService
