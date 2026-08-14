local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StrafeState = require(script.Parent.StrafeState)

local Input = {}

local function makeButton(parent: Instance, name: string, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.16, 0, 0.14, 0)
	button.Position = position
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	button.BackgroundTransparency = 0.25
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0.2, 0)
	Instance.new("UIStroke", button).Color = Color3.fromRGB(80, 90, 120)
	return button
end

local function getControls()
	local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
	local playerModule = playerScripts:WaitForChild("PlayerModule", 5)
	if not playerModule then
		return nil
	end
	local ok, module = pcall(require, playerModule)
	if ok and module and module.GetControls then
		return module:GetControls()
	end
	return nil
end

local function lanePhase(phase: string?): boolean
	return phase == "playing" or phase == "countdown"
end

function Input.start(remotes)
	local player = Players.LocalPlayer
	local held = {
		left = false,
		right = false,
	}
	local lastSent = 0
	local controls = nil
	local gameplay = false

	task.spawn(function()
		controls = getControls()
	end)

	local function currentStrafe(): number
		local value = 0
		if held.left then
			value -= 1
		end
		if held.right then
			value += 1
		end
		return value
	end

	local function send(force: boolean?)
		if not gameplay then
			StrafeState.value = 0
			if lastSent ~= 0 then
				lastSent = 0
				remotes.Strafe:FireServer(0)
			end
			return
		end
		local value = currentStrafe()
		StrafeState.value = if gameplay then value else 0
		if force or value ~= lastSent then
			lastSent = value
			remotes.Strafe:FireServer(value)
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not gameplay then
			return
		end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			held.left = true
			send(true)
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			held.right = true
			send(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			held.left = false
			send(true)
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			held.right = false
			send(true)
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "StrafeControls"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local left = makeButton(gui, "Left", "◀", UDim2.new(0.12, 0, 0.82, 0))
	local right = makeButton(gui, "Right", "▶", UDim2.new(0.88, 0, 0.82, 0))

	local function bind(button: TextButton, which: string)
		button.MouseButton1Down:Connect(function()
			held[which] = true
			send(true)
		end)
		button.MouseButton1Up:Connect(function()
			held[which] = false
			send(true)
		end)
		button.MouseLeave:Connect(function()
			held[which] = false
			send(true)
		end)
	end
	bind(left, "left")
	bind(right, "right")

	local function setGameplay(on: boolean)
		gameplay = on
		gui.Enabled = on
		if controls then
			if on then
				controls:Disable()
			else
				controls:Enable()
			end
		end
		if not on then
			held.left = false
			held.right = false
			send(true)
		end
	end

	task.spawn(function()
		local state = ReplicatedStorage:WaitForChild("GameState")
		local function refresh()
			setGameplay(lanePhase(state:GetAttribute("Phase") :: string?))
		end
		state.AttributeChanged:Connect(function(name)
			if name == "Phase" then
				refresh()
			end
		end)
		refresh()
	end)

	RunService.Heartbeat:Connect(function()
		send(false)
	end)
end

return Input
