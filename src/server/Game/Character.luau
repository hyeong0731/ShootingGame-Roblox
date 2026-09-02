local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Context = require(script.Parent.Context)
local Gun = require(script.Parent.Parent.Gun)

local ctx = Context
local Character = {}

function Character.isLanePhase(): boolean
	return ctx.phase == "playing" or ctx.phase == "countdown"
end

function Character.getLeaderPosition(): Vector3?
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
	end
	return nil
end

function Character.setHeroCollision(character: Model)
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Hero"
		end
	end
end

function Character.applyLobbyCharacter(character: Model)
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

function Character.teleportToLobby(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	root.CFrame = CFrame.lookAt(Config.Lobby.Spawn, Vector3.new(Config.Lobby.StartPad.X, Config.Lobby.Spawn.Y, Config.Lobby.StartPad.Z))
	applyLobbyCharacter(character)
end

function Character.teleportToLane(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	local lane = Config.activeLane()
	local standY = Config.playerStandY()
	root.CFrame = CFrame.lookAt(
		Vector3.new(0, standY, lane.PlayerZ),
		Vector3.new(0, standY, lane.PlayerZ + 10)
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

function Character.applyWalkCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	humanoid.WalkSpeed = Config.Player.LobbyWalkSpeed
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
	humanoid.AutoRotate = true
	humanoid.Health = humanoid.MaxHealth
	root.Anchored = false
	Gun.remove(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		pcall(function()
			root:SetNetworkOwner(player)
		end)
	end
end

function Character.teleportToChapterWalk(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local lane = Config.activeLane()
	local standY = Config.playerStandY()
	root.CFrame = CFrame.lookAt(
		Vector3.new(0, standY, lane.PlayerZ + 24),
		Vector3.new(0, standY, lane.SpawnZ)
	)
	applyWalkCharacter(character)
end

return Character
