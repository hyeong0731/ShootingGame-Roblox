local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = {}

local function textLabel(parent: Instance, name: string, props): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Size = props.Size
	label.Position = props.Position
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	label.TextXAlignment = props.Align or Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function attachWorldHealth(character: Model, player: Player)
	local existing = character:FindFirstChild("PlayerHealthBar", true)
	if existing then
		existing:Destroy()
	end

	local head = character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerHealthBar"
	billboard.Size = UDim2.fromOffset(92, 14)
	billboard.StudsOffset = Vector3.new(0, 2.9, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.LightInfluence = 0
	billboard.Parent = head

	local portrait = Instance.new("ImageLabel")
	portrait.Name = "Portrait"
	portrait.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	portrait.BorderSizePixel = 0
	portrait.Size = UDim2.fromOffset(14, 14)
	portrait.Position = UDim2.fromOffset(0, 0)
	portrait.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=48&h=48`
	portrait.Parent = billboard
	Instance.new("UICorner", portrait).CornerRadius = UDim.new(0, 3)

	local barBg = Instance.new("Frame")
	barBg.Name = "Back"
	barBg.Position = UDim2.fromOffset(16, 3)
	barBg.Size = UDim2.fromOffset(76, 8)
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

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return billboard
	end
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local function refreshBar()
		local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = Color3.fromRGB(72, 210, 96)
	end

	humanoid.HealthChanged:Connect(refreshBar)
	refreshBar()
	return billboard
end

function Hud.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "LaneHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local kills = textLabel(gui, "Kills", {
		Size = UDim2.new(0.28, 0, 0.055, 0),
		Position = UDim2.new(0.96, 0, 0.04, 0),
		AnchorPoint = Vector2.new(1, 0),
		Align = Enum.TextXAlignment.Right,
	})

	local timer = textLabel(gui, "Timer", {
		Size = UDim2.new(0.28, 0, 0.04, 0),
		Position = UDim2.new(0.5, 0, 0.085, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Align = Enum.TextXAlignment.Center,
	})
	timer.Text = "0:00"
	timer.TextTransparency = 0.1

	local waveLabel = textLabel(gui, "Wave", {
		Size = UDim2.new(0.4, 0, 0.055, 0),
		Position = UDim2.new(0.5, 0, 0.028, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Align = Enum.TextXAlignment.Center,
	})
	waveLabel.Text = "웨이브 1"
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	local banner = textLabel(gui, "Banner", {
		Size = UDim2.new(0.7, 0, 0.1, 0),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Align = Enum.TextXAlignment.Center,
	})
	banner.Text = ""
	banner.TextColor3 = Color3.fromRGB(255, 230, 120)

	local hint = textLabel(gui, "Hint", {
		Size = UDim2.new(0.62, 0, 0.035, 0),
		Position = UDim2.new(0.5, 0, 0.9, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Align = Enum.TextXAlignment.Center,
	})
	hint.Text = "초록 발판에 올라가면 게임이 시작됩니다"
	hint.TextColor3 = Color3.fromRGB(220, 220, 230)
	hint.TextTransparency = 0.15

	local worldBar: BillboardGui? = nil

	local function inLane(phase: string): boolean
		return phase == "playing" or phase == "countdown"
	end

	local function ensureWorldBar(phase: string)
		local character = player.Character
		if not character or not inLane(phase) then
			if worldBar then
				worldBar.Enabled = false
			end
			return
		end
		if not worldBar or worldBar.Parent == nil or worldBar.Parent.Parent ~= character then
			worldBar = attachWorldHealth(character, player)
		end
		if worldBar then
			worldBar.Enabled = true
		end
	end

	local function formatKills(count: number): string
		if count >= 1000 then
			local k = count / 1000
			if math.abs(k - math.floor(k + 1e-9)) < 0.05 then
				return `{math.floor(k + 1e-9)}k`
			end
			return string.format("%.1fk", k)
		end
		return tostring(count)
	end

	local function refresh()
		local state = ReplicatedStorage:FindFirstChild("GameState")
		if not state then
			return
		end

		local killCount = state:GetAttribute("Kills") or 0
		local currentPhase = state:GetAttribute("Phase") or "lobby"
		local countdown = state:GetAttribute("Countdown") or 0
		local elapsed = state:GetAttribute("Elapsed") or 0
		local wave = state:GetAttribute("Wave") or 1

		local minutes = math.floor(elapsed / 60)
		local seconds = elapsed % 60
		timer.Text = string.format("%d:%02d", minutes, seconds)
		waveLabel.Text = `웨이브 {wave}`
		kills.Text = `처치 {formatKills(killCount)}`
		local isLobby = currentPhase == "lobby"
		kills.Visible = not isLobby
		timer.Visible = not isLobby
		waveLabel.Visible = not isLobby
		ensureWorldBar(currentPhase)

		if currentPhase == "lobby" then
			banner.Text = ""
			hint.Text = "초록 발판에 올라가면 게임이 시작됩니다"
		elseif currentPhase == "countdown" then
			banner.Text = "A / D 를 사용해서 좀비를 무찌르세요"
			hint.Text = if countdown > 0 then `시작 {countdown}` else "시작!"
		elseif currentPhase == "gameOver" then
			banner.Text = `게임 오버  ·  처치 {formatKills(killCount)}`
			hint.Text = "로비로 돌아갑니다"
		else
			banner.Text = ""
			hint.Text = ""
		end
	end

	player.CharacterAdded:Connect(function()
		worldBar = nil
		task.defer(refresh)
	end)

	task.spawn(function()
		local state = ReplicatedStorage:WaitForChild("GameState")
		state.AttributeChanged:Connect(refresh)
		refresh()
		while gui.Parent do
			refresh()
			task.wait(0.1)
		end
	end)
end

return Hud
