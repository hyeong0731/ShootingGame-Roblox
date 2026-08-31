local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

local function boot()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local CameraController = require(script.CameraController)
	local Hud = require(script.Hud)
	local Effects = require(script.Effects)
	local Input = require(script.Input)
	local CombatPose = require(script.CombatPose)

	local remotes = Remotes.clientWait()
	CameraController.start()
	Hud.start(remotes)
	Effects.start(remotes)
	Input.start(remotes)
	CombatPose.start()

	local ok, chapter3Fog = pcall(require, script.Chapter3Fog)
	if ok and chapter3Fog and chapter3Fog.start then
		chapter3Fog.start()
	else
		warn("[Client] Chapter3Fog failed to load:", chapter3Fog)
	end

	print("[Client] Ready")
end

local ok, err = pcall(boot)
if not ok then
	warn("[Client] Boot failed:", err)
end
