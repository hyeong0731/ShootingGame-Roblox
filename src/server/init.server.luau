local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(script.Arena)
local GameService = require(script.GameService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

Arena.build()
local remotes = Remotes.serverInit()
GameService.start(remotes)
