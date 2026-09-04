local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local BarricadeService = {}

type BarricadeState = {
	model: Model,
	root: BasePart,
	hp: number,
	maxHp: number,
	z: number,
	xMin: number,
	xMax: number,
	fill: Frame?,
}

local active: BarricadeState? = nil

local function ensureFolder(): Folder
	local folder = Workspace:FindFirstChild("Barricades")
	if folder and folder:IsA("Folder") then
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = "Barricades"
	folder.Parent = Workspace
	return folder
end

local function playerMaxHealth(): number
	local best = Config.Player.Health
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.MaxHealth > 0 then
			best = math.max(best, humanoid.MaxHealth)
		end
	end
	return best
end

local function roadXBounds(): (number, number)
	local lane = Config.activeLane()
	-- 본도로만 (오른쪽 보급라인·Gap 제외). +X=왼쪽 철조망 / -X=도로 오른쪽 가장자리
	local xMax = lane.Width / 2 - 0.35
	local xMin = -(lane.Width / 2 - 0.35)
	return xMin, xMax
end

local function molotovFrontZ(): number
	local lane = Config.activeLane()
	local midZ = (lane.SpawnZ + lane.PlayerZ) / 2
	local offset = Config.Barricade.ZOffsetFromMolotov or 10
	return midZ - offset
end

local function refreshBar(state: BarricadeState)
	if not state.fill then
		return
	end
	local ratio = if state.maxHp > 0 then math.clamp(state.hp / state.maxHp, 0, 1) else 0
	state.fill.Size = UDim2.fromScale(ratio, 1)
	if ratio > 0.55 then
		state.fill.BackgroundColor3 = Color3.fromRGB(72, 210, 96)
	elseif ratio > 0.3 then
		state.fill.BackgroundColor3 = Color3.fromRGB(230, 190, 60)
	else
		state.fill.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
	end
end

local function buildVisual(parent: Model, xMin: number, xMax: number, z: number, y: number)
	local width = xMax - xMin
	local midX = (xMin + xMax) * 0.5
	local cfg = Config.Barricade

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(width, cfg.Height or 4.6, cfg.Thickness or 1.2)
	root.Color = Color3.fromRGB(52, 50, 46)
	root.Material = Enum.Material.Metal
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CFrame = CFrame.new(midX, y + (cfg.Height or 4.6) * 0.5, z)
	root.Transparency = 1
	root.Parent = parent

	-- 철조망 스타일: 가로 철사 + X 교차 + 양끝 기둥
	for _, wy in { y + 1.15, y + 2.05, y + 2.95, y + 3.85 } do
		local wire = Instance.new("Part")
		wire.Name = "BarbedWire"
		wire.Size = Vector3.new(width, 0.07, 0.07)
		wire.Color = Color3.fromRGB(38, 36, 34)
		wire.Material = Enum.Material.Metal
		wire.Anchored = true
		wire.CanCollide = false
		wire.CastShadow = false
		wire.CFrame = CFrame.new(midX, wy, z)
		wire.Parent = parent
	end
	local diagLen = math.sqrt(width * width + 7.3)
	for _, ang in { math.atan2(width, 2.7), -math.atan2(width, 2.7) } do
		local xbar = Instance.new("Part")
		xbar.Name = "BarbedX"
		xbar.Size = Vector3.new(0.06, diagLen, 0.06)
		xbar.Color = Color3.fromRGB(42, 40, 38)
		xbar.Material = Enum.Material.Metal
		xbar.Anchored = true
		xbar.CanCollide = false
		xbar.CastShadow = false
		xbar.CFrame = CFrame.new(midX, y + 2.5, z) * CFrame.Angles(0, 0, ang)
		xbar.Parent = parent
	end
	for _, x in { xMin + 0.2, xMax - 0.2 } do
		local post = Instance.new("Part")
		post.Name = "FencePost"
		post.Size = Vector3.new(0.38, 4.8, 0.38)
		post.Color = Color3.fromRGB(52, 50, 46)
		post.Material = Enum.Material.Metal
		post.Anchored = true
		post.CanCollide = false
		post.CFrame = CFrame.new(x, y + 2.55, z)
		post.Parent = parent
	end
	local jersey = Instance.new("Part")
	jersey.Name = "Jersey"
	jersey.Size = Vector3.new(width - 0.4, 1.15, 0.85)
	jersey.Color = Color3.fromRGB(118, 114, 104)
	jersey.Material = Enum.Material.Concrete
	jersey.Anchored = true
	jersey.CanCollide = false
	jersey.CFrame = CFrame.new(midX, y + 0.7, z)
	jersey.Parent = parent

	return root
end

local function destroyActive()
	if active and active.model.Parent then
		active.model:Destroy()
	end
	active = nil
end

function BarricadeService.isAlive(): boolean
	return active ~= nil and active.hp > 0
end

function BarricadeService.getBlockZ(): number?
	if not BarricadeService.isAlive() or not active then
		return nil
	end
	return active.z
end

function BarricadeService.getXBounds(): (number?, number?)
	if not BarricadeService.isAlive() or not active then
		return nil, nil
	end
	return active.xMin, active.xMax
end

function BarricadeService.place(): boolean
	if BarricadeService.isAlive() then
		return false
	end
	local lane = Config.activeLane()
	local cfg = Config.Barricade
	local xMin, xMax = roadXBounds()
	local z = molotovFrontZ()
	local y = lane.CenterY
	local maxHp = math.max(1, math.floor(playerMaxHealth() * (cfg.HpPlayerMult or 3)))

	local model = Instance.new("Model")
	model.Name = "Barricade"
	model:SetAttribute("IsBarricade", true)
	model:SetAttribute("Hp", maxHp)
	model:SetAttribute("MaxHp", maxHp)

	local root = buildVisual(model, xMin, xMax, z, y)
	model.PrimaryPart = root
	model.Parent = ensureFolder()

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HpBar"
	billboard.Size = UDim2.fromOffset(110, 14)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.LightInfluence = 0
	billboard.Parent = root

	local barBg = Instance.new("Frame")
	barBg.Name = "Back"
	barBg.Size = UDim2.fromScale(1, 1)
	barBg.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
	barBg.BorderSizePixel = 0
	barBg.Parent = billboard
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(72, 210, 96)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	active = {
		model = model,
		root = root,
		hp = maxHp,
		maxHp = maxHp,
		z = z,
		xMin = xMin,
		xMax = xMax,
		fill = fill,
	}
	refreshBar(active)
	return true
end

function BarricadeService.damage(amount: number): boolean
	if not BarricadeService.isAlive() or not active then
		return false
	end
	local dmg = math.max(0, amount)
	if dmg <= 0 then
		return true
	end
	active.hp = math.max(0, active.hp - dmg)
	active.model:SetAttribute("Hp", active.hp)
	refreshBar(active)
	if active.hp <= 0 then
		destroyActive()
		return false
	end
	return true
end

-- 좀비 공격. midBoss면 최대HP의 MidBossHpFraction
function BarricadeService.hitByZombie(isMidBoss: boolean?, contactDamage: number?): boolean
	if not BarricadeService.isAlive() or not active then
		return false
	end
	local cfg = Config.Barricade
	local amount: number
	if isMidBoss then
		amount = active.maxHp * (cfg.MidBossHpFraction or (1 / 3))
	else
		amount = math.max(1, (contactDamage or 7) * (cfg.NormalHitScale or 1))
	end
	return BarricadeService.damage(amount)
end

function BarricadeService.clear()
	destroyActive()
end

return BarricadeService
