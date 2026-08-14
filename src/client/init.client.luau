local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarterGui = game:GetService("StarterGui")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CameraController = require(script.CameraController)
local Hud = require(script.Hud)
local Effects = require(script.Effects)
local Input = require(script.Input)

local CombatPose = require(script.CombatPose)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

local remotes = Remotes.clientWait()
CameraController.start()
Hud.start()
Effects.start(remotes)
Input.start(remotes)
CombatPose.start()
