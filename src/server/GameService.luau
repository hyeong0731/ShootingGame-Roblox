local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)
local CombatService = require(script.Parent.CombatService)
local Gun = require(script.Parent.Gun)

type PlayerData = {
	strafe: number,
	character: Model?,
	lastFire: number,
}

local GameService = {}

local stateFolder: Folder
local playerData: { [Player]: PlayerData } = {}
local phase = "lobby"
local kills = 0
local matchStart = 0
local lastSpawnAt = 0
local nextIsBossAt = Config.Boss.EveryNKills
local heartbeatConn: RBXScriptConnection?
local startPadDebounce = false

local function setState(key: string, value: any)
	stateFolder:SetAttribute(key, value)
end

local function isLanePhase(): boolean
	return phase == "playing" or phase == "countdown"
end

local function getLeaderPosition(): Vector3?
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
	end
	return nil
end

local function setHeroCollision(character: Model)
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Hero"
		end
	end
end

local function applyLobbyCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	Gun.remove(character)
	humanoid.WalkSpeed = Config.Player.LobbyWalkSpeed
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
	humanoid.AutoRotate = true
	root.Anchored = false
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		pcall(function()
			root:SetNetworkOwner(player)
		end)
	end
end

local function teleportToLobby(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	root.CFrame = CFrame.lookAt(Config.Lobby.Spawn, Vector3.new(Config.Lobby.StartPad.X, Config.Lobby.Spawn.Y, Config.Lobby.StartPad.Z))
	applyLobbyCharacter(character)
end

local function teleportToLane(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	root.CFrame = CFrame.lookAt(
		Vector3.new(0, Config.Player.Height, Config.Lane.PlayerZ),
		Vector3.new(0, Config.Player.Height, Config.Lane.PlayerZ + 10)
	)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	humanoid.MaxHealth = Config.Player.Health
	humanoid.Health = Config.Player.Health
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	root.Anchored = true
	Gun.attach(character)
end

local function currentStats()
	local elapsed = math.max(0, os.clock() - matchStart)
	local health = Config.Zombie.Health + kills * Config.Infinite.HealthPerKill
	local speed = Config.Zombie.WalkSpeed + elapsed * Config.Infinite.SpeedPerSecond
	local gap = math.max(
		Config.Infinite.SpawnGapMin,
		Config.Infinite.SpawnGapStart - elapsed * 0.018
	)
	return {
		health = health,
		speed = speed,
		gap = gap,
	}
end

local function spawnOne()
	local stats = currentStats()
	local slots = Config.Infinite.LaneSlots
	local x = slots[math.random(1, #slots)]
	local isBoss = kills >= nextIsBossAt
	if isBoss then
		nextIsBossAt += Config.Boss.EveryNKills
		x = slots[math.ceil(#slots / 2)]
	end

	local scale = if isBoss then Config.Boss.SizeMultiplier else 1
	local y = Config.Lane.CenterY + 2.4 * scale
	ZombieService.create(Vector3.new(x, y, Config.Lane.SpawnZ), {
		health = if isBoss then stats.health * Config.Boss.HealthMultiplier else stats.health,
		walkSpeed = if isBoss then stats.speed * Config.Boss.SpeedMultiplier else stats.speed,
		isBoss = isBoss,
		contactDamage = if isBoss then Config.Boss.ContactDamage else Config.Zombie.ContactDamage,
		scale = scale,
	})
end

local function beginPlay()
	phase = "playing"
	matchStart = os.clock()
	lastSpawnAt = 0
	setState("Phase", "playing")
	setState("Kills", kills)
	setState("Elapsed", 0)
end

local startCountdown: () -> ()

local function onZombieDied()
	if phase ~= "playing" then
		return
	end
	kills += 1
	setState("Kills", kills)
	setState("ZombiesAlive", #ZombieService.getAlive())
end

startCountdown = function()
	phase = "countdown"
	setState("Phase", "countdown")
	setState("Elapsed", 0)
	task.spawn(function()
		for i = Config.Waves.Countdown, 1, -1 do
			if phase ~= "countdown" then
				return
			end
			setState("Countdown", i)
			task.wait(1)
		end
		if phase == "countdown" then
			setState("Countdown", 0)
			beginPlay()
		end
	end)
end

local function damagePlayers(amount: number)
	for _, player in Players:GetPlayers() do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(amount)
		end
	end
end

local function returnToLobby()
	phase = "lobby"
	kills = 0
	CombatService.clear()
	ZombieService.clear()
	setState("Phase", "lobby")
	setState("Kills", 0)
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)

	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLobby(player.Character)
		end
	end
end

local function startMatch()
	if isLanePhase() then
		return
	end

	kills = 0
	nextIsBossAt = Config.Boss.EveryNKills
	CombatService.clear()
	ZombieService.clear()
	setState("Kills", 0)

	for _, player in Players:GetPlayers() do
		if player.Character then
			teleportToLane(player.Character)
		end
	end

	startCountdown()
end

local function onPlayerDied(_player: Player)
	if phase == "gameOver" or phase == "lobby" then
		return
	end
	phase = "gameOver"
	setState("Phase", "gameOver")
	CombatService.clear()
	ZombieService.clear()

	task.delay(2.2, function()
		if phase == "gameOver" then
			returnToLobby()
		end
	end)
end

local function setupCharacter(player: Player, character: Model)
	local data = playerData[player]
	if not data then
		return
	end
	data.character = character

	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local _ = root

	humanoid.MaxHealth = Config.Player.Health
	humanoid.Health = Config.Player.Health
	setHeroCollision(character)

	if isLanePhase() then
		teleportToLane(character)
	else
		teleportToLobby(character)
	end

	humanoid.Died:Connect(function()
		onPlayerDied(player)
	end)
end

local function setupPlayer(player: Player)
	playerData[player] = {
		strafe = 0,
		character = nil,
		lastFire = 0,
	}

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

local function tryFire(now: number)
	if phase ~= "playing" then
		return
	end

	for player, data in playerData do
		local character = player.Character
		if not character then
			continue
		end
		if now - data.lastFire < Config.Combat.FireInterval then
			continue
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			continue
		end

		data.lastFire = now
		local muzzle = Gun.getMuzzlePosition(character)
			or (root.CFrame * CFrame.new(Config.Combat.MuzzleOffset)).Position
		local origin = Vector3.new(root.Position.X, muzzle.Y, muzzle.Z)
		CombatService.fireStraight(origin, Config.Combat.UnitDamage)
	end
end

local function bindStartPad()
	local arena = Workspace:WaitForChild("Arena")
	local pad = arena:WaitForChild("StartPad")
	if not pad:IsA("BasePart") then
		return
	end

	pad.Touched:Connect(function(hit)
		if startPadDebounce or phase ~= "lobby" then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		startPadDebounce = true
		startMatch()
		task.delay(1.5, function()
			startPadDebounce = false
		end)
	end)
end

function GameService.start(remotes)
	CombatService.bind(remotes)

	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if existing and existing:IsA("Folder") then
		stateFolder = existing
	else
		stateFolder = Instance.new("Folder")
		stateFolder.Name = "GameState"
		stateFolder.Parent = ReplicatedStorage
	end

	setState("Kills", 0)
	setState("Phase", "lobby")
	setState("ZombiesAlive", 0)
	setState("Countdown", 0)
	setState("Elapsed", 0)

	ZombieService.onDied(function()
		onZombieDied()
	end)
	ZombieService.onReached(function(record)
		if phase == "playing" then
			damagePlayers(record.contactDamage)
		end
	end)

	remotes.Strafe.OnServerEvent:Connect(function(player: Player, value: unknown)
		local data = playerData[player]
		if not data or typeof(value) ~= "number" then
			return
		end
		data.strafe = math.clamp(value :: number, -1, 1)
	end)

	Players.RespawnTime = 2
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		playerData[player] = nil
	end)

	bindStartPad()

	if heartbeatConn then
		heartbeatConn:Disconnect()
	end

	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local playerPos = getLeaderPosition()

		if phase == "playing" then
			local elapsed = math.floor(now - matchStart)
			if (stateFolder:GetAttribute("Elapsed") or 0) ~= elapsed then
				setState("Elapsed", elapsed)
			end
		end

		if isLanePhase() then
			for _, data in playerData do
				local character = data.character
				if not character then
					continue
				end
				local root = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
					continue
				end

				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid.JumpHeight = 0
				humanoid.AutoRotate = false

				local minX, maxX = Config.laneXBounds()
				-- Camera looks toward +Z, so D (screen-right) moves toward world -X / side path.
				local x = math.clamp(root.Position.X - data.strafe * Config.Player.StrafeSpeed * dt, minX, maxX)
				root.CFrame = CFrame.lookAt(
					Vector3.new(x, Config.Player.Height, Config.Lane.PlayerZ),
					Vector3.new(x, Config.Player.Height, Config.Lane.PlayerZ + 12)
				)
			end
		end

		if phase == "playing" then
			local stats = currentStats()
			if #ZombieService.getAlive() < Config.Infinite.MaxAlive and now - lastSpawnAt >= stats.gap then
				lastSpawnAt = now
				spawnOne()
			end
			ZombieService.update(dt, playerPos)
			tryFire(now)
			CombatService.update(dt)
		end
	end)
end

return GameService
