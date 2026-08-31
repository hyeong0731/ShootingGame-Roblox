local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes + GameState first: client can boot while heavy modules load / arena builds.
local Remotes = require(ReplicatedStorage.Shared.Remotes)
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

local Arena = require(script.Arena)
local GameService = require(script.GameService)

Arena.build()
GameService.start(remotes)

print("[Server] Ready")
