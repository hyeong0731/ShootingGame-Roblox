local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

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

local function addStuds(parent: Frame)
	local overlay = Instance.new("ImageLabel")
	overlay.Name = "Studs"
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Image = "rbxasset://textures/studs.png"
	overlay.ImageTransparency = 0.72
	overlay.ScaleType = Enum.ScaleType.Tile
	overlay.TileSize = UDim2.fromOffset(18, 18)
	overlay.ZIndex = 2
	overlay.Parent = parent
end

local function addRifleIcon(parent: Frame)
	local holder = Instance.new("Frame")
	holder.Name = "Rifle"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(0.78, 0.52)
	holder.Position = UDim2.new(0.5, 0, 0.42, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Rotation = -28
	holder.ZIndex = 3
	holder.Parent = parent

	local function piece(name: string, size: UDim2, pos: UDim2, color: Color3, z: number)
		local f = Instance.new("Frame")
		f.Name = name
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.Size = size
		f.Position = pos
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.ZIndex = z
		f.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.6
		stroke.Color = Color3.fromRGB(8, 8, 10)
		stroke.Parent = f
		return f
	end

	local metal = Color3.fromRGB(28, 30, 34)
	local dark = Color3.fromRGB(18, 18, 22)
	piece("Stock", UDim2.fromScale(0.22, 0.34), UDim2.fromScale(0.14, 0.58), dark, 4)
	piece("Body", UDim2.fromScale(0.42, 0.28), UDim2.fromScale(0.42, 0.46), metal, 5)
	piece("Barrel", UDim2.fromScale(0.38, 0.12), UDim2.fromScale(0.78, 0.42), Color3.fromRGB(40, 42, 48), 4)
	piece("Mag", UDim2.fromScale(0.12, 0.42), UDim2.fromScale(0.4, 0.78), dark, 4)
	piece("Grip", UDim2.fromScale(0.1, 0.32), UDim2.fromScale(0.3, 0.72), dark, 4)
	piece("Sight", UDim2.fromScale(0.08, 0.16), UDim2.fromScale(0.5, 0.28), dark, 6)
end

local function addBombIcon(parent: Frame)
	local holder = Instance.new("Frame")
	holder.Name = "Bomb"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(0.62, 0.58)
	holder.Position = UDim2.new(0.5, 0, 0.4, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.ZIndex = 3
	holder.Visible = false
	holder.Parent = parent

	local function piece(name: string, size: UDim2, pos: UDim2, color: Color3, corner: number, z: number)
		local f = Instance.new("Frame")
		f.Name = name
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.Size = size
		f.Position = pos
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.ZIndex = z
		f.Parent = holder
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(corner, 0)
		c.Parent = f
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(8, 8, 10)
		stroke.Parent = f
		return f
	end

	piece("Body", UDim2.fromScale(0.72, 0.72), UDim2.fromScale(0.5, 0.58), Color3.fromRGB(42, 46, 40), 1, 4)
	piece("Band", UDim2.fromScale(0.78, 0.14), UDim2.fromScale(0.5, 0.58), Color3.fromRGB(78, 82, 70), 0.2, 5)
	piece("Cap", UDim2.fromScale(0.28, 0.16), UDim2.fromScale(0.5, 0.22), Color3.fromRGB(28, 30, 26), 0.2, 5)
	piece("Fuse", UDim2.fromScale(0.1, 0.22), UDim2.fromScale(0.5, 0.08), Color3.fromRGB(96, 72, 40), 0.4, 5)
	piece("Spark", UDim2.fromScale(0.14, 0.14), UDim2.fromScale(0.5, -0.02), Color3.fromRGB(255, 140, 40), 1, 6)
end

local function addSniperIcon(parent: Frame)
	local holder = Instance.new("Frame")
	holder.Name = "Sniper"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(0.86, 0.52)
	holder.Position = UDim2.new(0.5, 0, 0.42, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Rotation = -28
	holder.ZIndex = 3
	holder.Visible = false
	holder.Parent = parent

	local function piece(name: string, size: UDim2, pos: UDim2, color: Color3, z: number)
		local f = Instance.new("Frame")
		f.Name = name
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.Size = size
		f.Position = pos
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.ZIndex = z
		f.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.6
		stroke.Color = Color3.fromRGB(8, 8, 10)
		stroke.Parent = f
		return f
	end

	local metal = Color3.fromRGB(28, 32, 40)
	local dark = Color3.fromRGB(16, 18, 22)
	piece("Stock", UDim2.fromScale(0.2, 0.34), UDim2.fromScale(0.1, 0.58), dark, 4)
	piece("Body", UDim2.fromScale(0.4, 0.26), UDim2.fromScale(0.38, 0.46), metal, 5)
	piece("Barrel", UDim2.fromScale(0.48, 0.1), UDim2.fromScale(0.78, 0.42), Color3.fromRGB(42, 48, 56), 4)
	piece("Mag", UDim2.fromScale(0.1, 0.36), UDim2.fromScale(0.36, 0.74), dark, 4)
	piece("Grip", UDim2.fromScale(0.09, 0.3), UDim2.fromScale(0.26, 0.7), dark, 4)
	piece("Scope", UDim2.fromScale(0.22, 0.22), UDim2.fromScale(0.42, 0.22), Color3.fromRGB(70, 180, 230), 6)
end

local function hudAssetImage(name: string): string
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("HudAssets")
	if not assets then
		return ""
	end
	local inst = assets:FindFirstChild(name)
	if inst and inst:IsA("Decal") then
		return inst.Texture
	end
	if inst and inst:IsA("ImageLabel") then
		return inst.Image
	end
	return ""
end

local function setWeaponIcon(btn: Frame, mode: string)
	local rifle = btn:FindFirstChild("Rifle")
	local bomb = btn:FindFirstChild("Bomb")
	local sniper = btn:FindFirstChild("Sniper")
	local gunImage = btn:FindFirstChild("GunImage")
	local usingBomb = mode == "bomb"
	local usingSniper = mode == "sniper"
	if rifle and rifle:IsA("GuiObject") then
		rifle.Visible = not usingBomb and not usingSniper
	end
	if bomb and bomb:IsA("GuiObject") then
		bomb.Visible = usingBomb
	end
	if sniper and sniper:IsA("GuiObject") then
		sniper.Visible = usingSniper
	end
	if gunImage and gunImage:IsA("ImageLabel") then
		local gunTex = hudAssetImage("GunIcon")
		local bombTex = hudAssetImage("BombIcon")
		if usingBomb then
			if bombTex ~= "" then
				gunImage.Image = bombTex
				gunImage.Visible = true
				if bomb and bomb:IsA("GuiObject") then
					bomb.Visible = false
				end
			else
				gunImage.Visible = false
			end
		elseif usingSniper then
			gunImage.Visible = false
		else
			if gunTex ~= "" then
				gunImage.Image = gunTex
				gunImage.Visible = true
				if rifle and rifle:IsA("GuiObject") then
					rifle.Visible = false
				end
			else
				gunImage.Visible = false
			end
		end
	end
end

local function createWeaponButton(parent: Instance): Frame
	local btn = Instance.new("Frame")
	btn.Name = "CurrentWeapon"
	btn.BackgroundColor3 = Color3.fromRGB(168, 212, 236)
	btn.BorderSizePixel = 0
	local size = Config.Hud.WeaponButtonSize
	btn.Size = UDim2.fromOffset(size, size)
	btn.Position = UDim2.new(0.02, 0, 0.22, 0)
	btn.ZIndex = 1
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.16, 0)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = math.max(3, math.floor(size / 22))
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = btn

	addStuds(btn)
	addRifleIcon(btn)
	addBombIcon(btn)
	addSniperIcon(btn)

	local gunImage = Instance.new("ImageLabel")
	gunImage.Name = "GunImage"
	gunImage.BackgroundTransparency = 1
	gunImage.BorderSizePixel = 0
	gunImage.Size = UDim2.fromScale(0.78, 0.58)
	gunImage.Position = UDim2.new(0.5, 0, 0.4, 0)
	gunImage.AnchorPoint = Vector2.new(0.5, 0.5)
	gunImage.ScaleType = Enum.ScaleType.Fit
	gunImage.ZIndex = 4
	gunImage.Visible = false
	gunImage.Parent = btn

	setWeaponIcon(btn, "rifle")

	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.new(1, -6, 0.3, 0)
	caption.Position = UDim2.new(0.5, 0, 0.98, 0)
	caption.AnchorPoint = Vector2.new(0.5, 1)
	caption.Font = Enum.Font.GothamBlack
	caption.Text = "현재 무기"
	caption.TextColor3 = Color3.fromRGB(255, 255, 255)
	caption.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	caption.TextStrokeTransparency = 0
	caption.TextScaled = true
	caption.ZIndex = 5
	caption.Parent = btn
	local capConstraint = Instance.new("UITextSizeConstraint")
	capConstraint.MaxTextSize = 22
	capConstraint.MinTextSize = 12
	capConstraint.Parent = caption

	local timeLeft = Instance.new("TextLabel")
	timeLeft.Name = "TimeLeft"
	timeLeft.BackgroundTransparency = 1
	timeLeft.Size = UDim2.new(0.92, 0, 0.34, 0)
	timeLeft.Position = UDim2.new(0.5, 0, 0.02, 0)
	timeLeft.AnchorPoint = Vector2.new(0.5, 0)
	timeLeft.Font = Enum.Font.GothamBlack
	timeLeft.Text = ""
	timeLeft.TextColor3 = Color3.fromRGB(255, 230, 40)
	timeLeft.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	timeLeft.TextStrokeTransparency = 0
	timeLeft.TextScaled = true
	timeLeft.Visible = false
	timeLeft.ZIndex = 6
	timeLeft.Parent = btn
	local timeConstraint = Instance.new("UITextSizeConstraint")
	timeConstraint.MaxTextSize = 22
	timeConstraint.MinTextSize = 12
	timeConstraint.Parent = timeLeft

	return btn
end

local function createHitCountBadge(parent: Instance): Frame
	local weaponSize = Config.Hud.WeaponButtonSize
	local badge = Instance.new("Frame")
	badge.Name = "CurrentHits"
	badge.BackgroundColor3 = Color3.fromRGB(168, 212, 236)
	badge.BorderSizePixel = 0
	badge.Size = UDim2.fromOffset(math.floor(weaponSize * 1.45), weaponSize)
	badge.Position = UDim2.new(0.02, weaponSize + 12, 0.22, 0)
	badge.ZIndex = 1
	badge.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.16, 0)
	corner.Parent = badge

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = math.max(3, math.floor(weaponSize / 22))
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = badge

	addStuds(badge)

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.BackgroundTransparency = 1
	value.Size = UDim2.new(1, -10, 0.72, 0)
	value.Position = UDim2.new(0.5, 0, 0.5, 0)
	value.AnchorPoint = Vector2.new(0.5, 0.5)
	value.Font = Enum.Font.GothamBlack
	value.Text = "현재타수 : 1"
	value.TextColor3 = Color3.fromRGB(20, 28, 48)
	value.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	value.TextStrokeTransparency = 0.35
	value.TextScaled = true
	value.ZIndex = 5
	value.Parent = badge
	local valueConstraint = Instance.new("UITextSizeConstraint")
	valueConstraint.MaxTextSize = 22
	valueConstraint.MinTextSize = 11
	valueConstraint.Parent = value

	return badge
end

local function createDevStepper(parent: Instance, name: string, titleText: string, y: number): (TextLabel, TextButton, TextButton)
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -12, 0, 44)
	row.Position = UDim2.new(0, 6, 0, y)
	row.ZIndex = 9
	row.Parent = parent

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 16)
	title.Font = Enum.Font.GothamBold
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(255, 200, 70)
	title.TextScaled = true
	title.ZIndex = 10
	title.Parent = row

	local minus = Instance.new("TextButton")
	minus.Name = "Minus"
	minus.Size = UDim2.fromOffset(32, 24)
	minus.Position = UDim2.new(0, 0, 0, 18)
	minus.BackgroundColor3 = Color3.fromRGB(36, 42, 62)
	minus.BorderSizePixel = 0
	minus.Font = Enum.Font.GothamBold
	minus.Text = "-"
	minus.TextColor3 = Color3.new(1, 1, 1)
	minus.TextScaled = true
	minus.ZIndex = 10
	minus.Parent = row
	Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.BackgroundTransparency = 1
	value.Size = UDim2.new(1, -72, 0, 24)
	value.Position = UDim2.new(0, 36, 0, 18)
	value.Font = Enum.Font.GothamBlack
	value.Text = "0"
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextScaled = true
	value.ZIndex = 10
	value.Parent = row

	local plus = Instance.new("TextButton")
	plus.Name = "Plus"
	plus.Size = UDim2.fromOffset(32, 24)
	plus.Position = UDim2.new(1, -32, 0, 18)
	plus.BackgroundColor3 = Color3.fromRGB(36, 42, 62)
	plus.BorderSizePixel = 0
	plus.Font = Enum.Font.GothamBold
	plus.Text = "+"
	plus.TextColor3 = Color3.new(1, 1, 1)
	plus.TextScaled = true
	plus.ZIndex = 10
	plus.Parent = row
	Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)

	return value, minus, plus
end

function Hud.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "LaneHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	local kills = textLabel(gui, "Kills", {
		Size = UDim2.new(0.28, 0, 0.055, 0),
		Position = UDim2.new(0.96, 0, 0.082, 0),
		AnchorPoint = Vector2.new(1, 0),
		Align = Enum.TextXAlignment.Right,
	})

	local waveLabel = textLabel(gui, "Wave", {
		Size = UDim2.new(0.32, 0, 0.055, 0),
		Position = UDim2.new(0.96, 0, 0.028, 0),
		AnchorPoint = Vector2.new(1, 0),
		Align = Enum.TextXAlignment.Right,
	})
	waveLabel.Text = "라운드 1"
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	local bombTime = textLabel(gui, "BombTime", {
		Size = UDim2.new(0.78, 0, 0.09, 0),
		Position = UDim2.new(0.5, 0, 0.088, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Align = Enum.TextXAlignment.Center,
	})
	bombTime.Font = Enum.Font.GothamBlack
	bombTime.Text = ""
	bombTime.TextColor3 = Color3.fromRGB(255, 230, 40)
	bombTime.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	bombTime.TextStrokeTransparency = 0
	bombTime.Visible = false
	local bombOutline = Instance.new("UIStroke")
	bombOutline.Thickness = 5
	bombOutline.Color = Color3.fromRGB(0, 0, 0)
	bombOutline.Parent = bombTime

	local timer = textLabel(gui, "Timer", {
		Size = UDim2.new(0.16, 0, 0.055, 0),
		Position = UDim2.new(0.67, 0, 0.04, 0),
		AnchorPoint = Vector2.new(1, 0),
		Align = Enum.TextXAlignment.Right,
	})
	timer.Text = "0:00"
	timer.TextTransparency = 0.1

	local weaponBtn = createWeaponButton(gui)
	weaponBtn.Visible = false
	local hitBadge = createHitCountBadge(gui)
	hitBadge.Visible = false

	if Config.Debug.Enabled then
		local debugPanel = Instance.new("Frame")
		debugPanel.Name = "DevRounds"
		debugPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
		debugPanel.BackgroundTransparency = 0.25
		debugPanel.BorderSizePixel = 0
		debugPanel.Size = UDim2.fromOffset(168, 252)
		debugPanel.Position = UDim2.new(1, -12, 0.22, 0)
		debugPanel.AnchorPoint = Vector2.new(1, 0)
		debugPanel.ZIndex = 8
		debugPanel.Parent = gui
		Instance.new("UICorner", debugPanel).CornerRadius = UDim.new(0, 10)
		local debugStroke = Instance.new("UIStroke")
		debugStroke.Color = Color3.fromRGB(255, 180, 40)
		debugStroke.Thickness = 2
		debugStroke.Parent = debugPanel

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, -8, 0, 22)
		title.Position = UDim2.fromOffset(4, 4)
		title.Font = Enum.Font.GothamBlack
		title.Text = "DEV 라운드"
		title.TextColor3 = Color3.fromRGB(255, 200, 70)
		title.TextScaled = true
		title.ZIndex = 9
		title.Parent = debugPanel

		local grid = Instance.new("Frame")
		grid.Name = "Buttons"
		grid.BackgroundTransparency = 1
		grid.Size = UDim2.new(1, -12, 1, -72)
		grid.Position = UDim2.fromOffset(6, 28)
		grid.ZIndex = 9
		grid.Parent = debugPanel
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.fromOffset(48, 32)
		layout.CellPadding = UDim2.fromOffset(6, 6)
		layout.FillDirectionMaxCells = 3
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid

		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local setRound = remotes:WaitForChild("DebugSetRound")
		for i, round in Config.Debug.RoundButtons do
			local btn = Instance.new("TextButton")
			btn.Name = `Round{round}`
			btn.BackgroundColor3 = Color3.fromRGB(36, 42, 62)
			btn.BorderSizePixel = 0
			btn.Font = Enum.Font.GothamBold
			btn.Text = tostring(round)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.TextScaled = true
			btn.AutoButtonColor = true
			btn.LayoutOrder = i
			btn.ZIndex = 10
			btn.Parent = grid
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			btn.MouseButton1Click:Connect(function()
				if setRound:IsA("RemoteEvent") then
					setRound:FireServer(round)
				end
			end)
		end

		local chapter2 = Instance.new("TextButton")
		chapter2.Name = "Chapter2"
		chapter2.BackgroundColor3 = Color3.fromRGB(36, 42, 62)
		chapter2.BorderSizePixel = 0
		chapter2.Font = Enum.Font.GothamBold
		chapter2.Text = "챕터 2"
		chapter2.TextColor3 = Color3.new(1, 1, 1)
		chapter2.TextScaled = true
		chapter2.AutoButtonColor = true
		chapter2.Size = UDim2.new(1, -12, 0, 32)
		chapter2.Position = UDim2.new(0, 6, 1, -40)
		chapter2.ZIndex = 10
		chapter2.Parent = debugPanel
		Instance.new("UICorner", chapter2).CornerRadius = UDim.new(0, 6)
		local setChapter = remotes:WaitForChild("DebugSetChapter")
		chapter2.MouseButton1Click:Connect(function()
			if setChapter:IsA("RemoteEvent") then
				setChapter:FireServer(2)
			end
		end)

		local hitsPanel = Instance.new("Frame")
		hitsPanel.Name = "DevHitPower"
		hitsPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
		hitsPanel.BackgroundTransparency = 0.25
		hitsPanel.BorderSizePixel = 0
		hitsPanel.Size = UDim2.fromOffset(168, 80)
		hitsPanel.Position = UDim2.new(1, -12, 0.22, 264)
		hitsPanel.AnchorPoint = Vector2.new(1, 0)
		hitsPanel.ZIndex = 8
		hitsPanel.Parent = gui
		Instance.new("UICorner", hitsPanel).CornerRadius = UDim.new(0, 10)
		local hitsStroke = Instance.new("UIStroke")
		hitsStroke.Color = Color3.fromRGB(255, 180, 40)
		hitsStroke.Thickness = 2
		hitsStroke.Parent = hitsPanel

		local hitsTitle = Instance.new("TextLabel")
		hitsTitle.Name = "Title"
		hitsTitle.BackgroundTransparency = 1
		hitsTitle.Size = UDim2.new(1, -8, 0, 22)
		hitsTitle.Position = UDim2.fromOffset(4, 4)
		hitsTitle.Font = Enum.Font.GothamBlack
		hitsTitle.Text = "DEV 총알 타수"
		hitsTitle.TextColor3 = Color3.fromRGB(255, 200, 70)
		hitsTitle.TextScaled = true
		hitsTitle.ZIndex = 9
		hitsTitle.Parent = hitsPanel

		local powerValue, powerMinus, powerPlus = createDevStepper(hitsPanel, "HitPower", "현재 타수", 28)

		local setHitPower = remotes:WaitForChild("DebugHitPower")
		local function currentHitPower(): number
			local state = ReplicatedStorage:FindFirstChild("GameState")
			local value = if state then state:GetAttribute("HitPower") else nil
			if typeof(value) == "number" then
				return value
			end
			return 1
		end
		local function refreshHitPower()
			powerValue.Text = tostring(currentHitPower())
		end
		refreshHitPower()
		task.spawn(function()
			local state = ReplicatedStorage:WaitForChild("GameState")
			state.AttributeChanged:Connect(function(name)
				if name == "HitPower" then
					refreshHitPower()
				end
			end)
			refreshHitPower()
		end)
		powerMinus.MouseButton1Click:Connect(function()
			if setHitPower:IsA("RemoteEvent") then
				setHitPower:FireServer(currentHitPower() - 1)
			end
		end)
		powerPlus.MouseButton1Click:Connect(function()
			if setHitPower:IsA("RemoteEvent") then
				setHitPower:FireServer(currentHitPower() + 1)
			end
		end)
	end

	local banner = textLabel(gui, "Banner", {
		Size = UDim2.new(0.82, 0, 0.12, 0),
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
		local chapter = state:GetAttribute("Chapter") or 1

		local minutes = math.floor(elapsed / 60)
		local seconds = elapsed % 60
		timer.Text = string.format("%d:%02d", minutes, seconds)
		waveLabel.Text = `라운드 {Config.chapterRound(wave, chapter)}`
		kills.Text = `처치 {formatKills(killCount)}`
		local hitPower = state:GetAttribute("HitPower") or 1
		local hitValue = hitBadge:FindFirstChild("Value")
		if hitValue and hitValue:IsA("TextLabel") then
			hitValue.Text = `현재타수 : {hitPower}`
		end
		local isLobby = currentPhase == "lobby"
		local isClear = currentPhase == "chapterClear"
		kills.Visible = not isLobby
		timer.Visible = not isLobby
		waveLabel.Visible = not isLobby
		weaponBtn.Visible = not isLobby and not isClear
		hitBadge.Visible = not isLobby
		ensureWorldBar(currentPhase)

		local bombLeft = state:GetAttribute("BombLeft") or 0
		local sniperLeft = state:GetAttribute("SniperLeft") or 0
		local weaponMode = "rifle"
		if currentPhase == "playing" and sniperLeft > 0 then
			weaponMode = "sniper"
		elseif currentPhase == "playing" and bombLeft > 0 then
			weaponMode = "bomb"
		end
		setWeaponIcon(weaponBtn, weaponMode)
		local timeLeft = weaponBtn:FindFirstChild("TimeLeft")
		if timeLeft and timeLeft:IsA("TextLabel") then
			if currentPhase == "playing" and sniperLeft > 0 then
				timeLeft.Visible = true
				timeLeft.Text = `{sniperLeft}s`
			elseif currentPhase == "playing" and bombLeft > 0 then
				timeLeft.Visible = true
				timeLeft.Text = `{bombLeft}s`
			else
				timeLeft.Visible = false
				timeLeft.Text = ""
			end
		end
		bombTime.Visible = false
		bombTime.Text = ""

		if currentPhase == "lobby" then
			banner.Text = ""
			hint.Text = "초록 발판에 올라가면 게임이 시작됩니다"
		elseif currentPhase == "chapterClear" then
			banner.Text = "1챕터 클리어"
			hint.Text = "도로를 따라 걸어가 파란 발판을 밟으세요"
		elseif currentPhase == "countdown" then
			banner.Text = "A / D 를 사용해서 좀비를 무찌르세요"
			hint.Text = if countdown > 0 then `시작 {countdown}` else "시작!"
		elseif currentPhase == "gameOver" then
			banner.Text = `게임 오버  ·  처치 {formatKills(killCount)}`
			hint.Text = "로비로 돌아갑니다"
		else
			local announce = state:GetAttribute("Announce") or ""
			banner.Text = if typeof(announce) == "string" then announce else ""
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
