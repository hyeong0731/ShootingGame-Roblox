local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraController = {}

local function laneCamera(phase: string?): boolean
	return phase == "playing" or phase == "countdown"
end

function CameraController.start()
	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera
	local first = true
	local lastPhase = ""

	local function currentPhase(): string
		local state = ReplicatedStorage:FindFirstChild("GameState")
		if not state then
			return "lobby"
		end
		return (state:GetAttribute("Phase") :: string?) or "lobby"
	end

	local function apply()
		local phase = currentPhase()
		if phase ~= lastPhase then
			first = true
			lastPhase = phase
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end

		if laneCamera(phase) then
			local cam = Config.Camera
			local dist = math.clamp(cam.Distance or 1, 0.4, 1.5)
			local height = math.clamp(cam.Height or 1, 0.5, 1.5)
			local offset = Vector3.new(cam.Offset.X, cam.Offset.Y * height, cam.Offset.Z * dist)
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = cam.FieldOfView
			camera.CFrame = CFrame.lookAt(root.Position + offset, root.Position + cam.LookAhead)
		else
			if camera.CameraType == Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	end

	player.CharacterAdded:Connect(function()
		first = true
	end)

	RunService.RenderStepped:Connect(apply)
end

return CameraController
