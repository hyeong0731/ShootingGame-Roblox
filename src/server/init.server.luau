local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function bootError(message: string)
	warn("[Server] Boot failed:", message)
	local flag = ReplicatedStorage:FindFirstChild("BootError")
	if not flag then
		flag = Instance.new("StringValue")
		flag.Name = "BootError"
		flag.Parent = ReplicatedStorage
	end
	flag.Value = message
end

local shared = ReplicatedStorage:WaitForChild("Shared", 30)
if not shared then
	bootError("ReplicatedStorage.Shared missing — Rojo sync 확인 (Shared 폴더)")
	return
end

-- Remotes + GameState first: client can boot while heavy modules load / arena builds.
local okRemotes, Remotes = pcall(require, shared.Remotes)
if not okRemotes then
	bootError(`Shared.Remotes load failed: {Remotes}`)
	return
end

local remotes = Remotes.serverInit()

local stateFolder = ReplicatedStorage:FindFirstChild("GameState")
if not stateFolder then
	stateFolder = Instance.new("Folder")
	stateFolder.Name = "GameState"
	stateFolder.Parent = ReplicatedStorage
end
stateFolder:SetAttribute("Phase", "lobby")
stateFolder:SetAttribute("Chapter", 1)
stateFolder:SetAttribute("Ch3FogActive", false)
stateFolder:SetAttribute("Paused", false)
stateFolder:SetAttribute("Wave", 1)
stateFolder:SetAttribute("BootOk", false)

local okArenaMod, Arena = pcall(require, script.Arena)
if not okArenaMod then
	bootError(`Arena module load failed: {Arena}`)
	return
end

local okBuild, buildErr = pcall(Arena.build)
if not okBuild then
	bootError(`Arena.build failed: {buildErr}`)
	return
end

local okGameMod, GameService = pcall(require, script.GameService)
if not okGameMod then
	bootError(`GameService module load failed: {GameService}`)
	return
end

local okStart, startErr = pcall(GameService.start, remotes)
if not okStart then
	bootError(`GameService.start failed: {startErr}`)
	return
end

stateFolder:SetAttribute("BootOk", true)
local bootFlag = ReplicatedStorage:FindFirstChild("BootError")
if bootFlag then
	bootFlag:Destroy()
end

print("[Server] Ready")
