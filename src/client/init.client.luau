local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

local function showBootError(message: string)
	warn("[Client] Boot failed:", message)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BootError"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.86, 0.42)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(24, 18, 18)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -24, 0, 36)
	title.Position = UDim2.fromOffset(12, 12)
	title.Font = Enum.Font.GothamBlack
	title.Text = "게임 로드 실패"
	title.TextColor3 = Color3.fromRGB(255, 120, 90)
	title.TextScaled = true
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -24, 1, -60)
	body.Position = UDim2.fromOffset(12, 52)
	body.Font = Enum.Font.Gotham
	body.Text = `{message}\n\nStudio Output 창 확인 · Rojo Connect(녹색) · rojo serve 재시작`
	body.TextColor3 = Color3.fromRGB(240, 240, 240)
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextSize = 18
	body.Parent = frame
end

local function boot()
	local shared = ReplicatedStorage:WaitForChild("Shared", 60)
	if not shared then
		error("ReplicatedStorage.Shared missing — Rojo가 src/shared 를 동기화했는지 Explorer에서 확인")
	end

	local okRemotesMod, Remotes = pcall(require, shared.Remotes)
	if not okRemotesMod then
		error(`Shared.Remotes load failed: {Remotes}`)
	end

	local CameraController = require(script.CameraController)
	local Hud = require(script.Hud)
	local Effects = require(script.Effects)
	local Input = require(script.Input)
	local CombatPose = require(script.CombatPose)

	local remotes = Remotes.clientWait(60)
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
	local serverErr = ReplicatedStorage:FindFirstChild("BootError")
	if serverErr and serverErr:IsA("StringValue") and serverErr.Value ~= "" then
		showBootError(`서버: {serverErr.Value}\n클라: {err}`)
	else
		showBootError(tostring(err))
	end
end
