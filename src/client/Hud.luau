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

local function setWeaponIcon(btn: Frame, usingBomb: boolean)
	local rifle = btn:FindFirstChild("Rifle")
	local bomb = btn:FindFirstChild("Bomb")
	local gunImage = btn:FindFirstChild("GunImage")
	if rifle and rifle:IsA("GuiObject") then
		rifle.Visible = not usingBomb
	end
	if bomb and bomb:IsA("GuiObject") then
		bomb.Visible = usingBomb
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

	setWeaponIcon(btn, false)

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

	return btn
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

	local waveLabel = textLabel(gui, "Wave", {
		Size = UDim2.new(0.4, 0, 0.055, 0),
		Position = UDim2.new(0.5, 0, 0.028, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Align = Enum.TextXAlignment.Center,
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
		Size = UDim2.new(0.28, 0, 0.04, 0),
		Position = UDim2.new(0.5, 0, 0.185, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Align = Enum.TextXAlignment.Center,
	})
	timer.Text = "0:00"
	timer.TextTransparency = 0.1

	local weaponBtn = createWeaponButton(gui)
	weaponBtn.Visible = false

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
		waveLabel.Text = `라운드 {wave}`
		kills.Text = `처치 {formatKills(killCount)}`
		local isLobby = currentPhase == "lobby"
		kills.Visible = not isLobby
		timer.Visible = not isLobby
		waveLabel.Visible = not isLobby
		weaponBtn.Visible = not isLobby
		ensureWorldBar(currentPhase)

		local bombLeft = state:GetAttribute("BombLeft") or 0
		setWeaponIcon(weaponBtn, currentPhase == "playing" and bombLeft > 0)
		if currentPhase == "playing" and bombLeft > 0 then
			bombTime.Visible = true
			bombTime.Text = `폭탄 {bombLeft}초`
			timer.Position = UDim2.new(0.5, 0, 0.185, 0)
		else
			bombTime.Visible = false
			bombTime.Text = ""
			timer.Position = UDim2.new(0.5, 0, 0.088, 0)
		end

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
