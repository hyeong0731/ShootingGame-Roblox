local CombatPose = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StrafeState = require(script.Parent.StrafeState)

local savedAnimate: { [Model]: Instance } = {}
local ikBound: { [Model]: boolean } = {}

local function motor(character: Model, partName: string, motorName: string): Motor6D?
	local part = character:FindFirstChild(partName)
	if not part then
		return nil
	end
	local found = part:FindFirstChild(motorName)
	if found and found:IsA("Motor6D") then
		return found
	end
	return nil
end

local function stopDefault(character: Model)
	local animate = character:FindFirstChild("Animate")
	if animate then
		savedAnimate[character] = animate
		if animate:IsA("LocalScript") or animate:IsA("Script") then
			animate.Disabled = true
		end
		animate.Parent = nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		for _, track in humanoid:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in animator:GetPlayingAnimationTracks() do
				track:Stop(0)
			end
		end
	end
end

local function unbindIk(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		for _, name in { "GunIK_Right", "GunIK_Left" } do
			local old = humanoid:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
	end
	ikBound[character] = nil
end

local function restoreDefault(character: Model)
	unbindIk(character)
	local animate = savedAnimate[character]
	if animate then
		animate.Parent = character
		if animate:IsA("LocalScript") or animate:IsA("Script") then
			animate.Disabled = false
		end
		savedAnimate[character] = nil
	end
end

local function bindIk(character: Model)
	local gun = character:FindFirstChild("Gun")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not (gun and humanoid) then
		if ikBound[character] then
			unbindIk(character)
		end
		return
	end

	if ikBound[character] then
		local existing = humanoid:FindFirstChild("GunIK_Right")
		if existing and existing:IsA("IKControl") and existing.Target and existing.Target.Parent then
			return
		end
		unbindIk(character)
	end

	local rightGrip = gun:FindFirstChild("RightGrip", true)
	local leftGrip = gun:FindFirstChild("LeftGrip", true)
	if not (rightGrip and leftGrip) then
		return
	end

	for _, name in { "GunIK_Right", "GunIK_Left" } do
		local old = humanoid:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	local rightRoot = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Torso")
	local leftRoot = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Torso")

	if rightHand and rightRoot and rightHand:IsA("BasePart") and rightRoot:IsA("BasePart") then
		local ik = Instance.new("IKControl")
		ik.Name = "GunIK_Right"
		ik.Type = Enum.IKControlType.Transform
		ik.ChainRoot = rightRoot
		ik.EndEffector = rightHand
		ik.Target = rightGrip
		ik.SmoothTime = 0
		ik.Weight = 1
		ik.Priority = 2
		ik.Enabled = true
		ik.Parent = humanoid
	end
	if leftHand and leftRoot and leftHand:IsA("BasePart") and leftRoot:IsA("BasePart") then
		local ik = Instance.new("IKControl")
		ik.Name = "GunIK_Left"
		ik.Type = Enum.IKControlType.Transform
		ik.ChainRoot = leftRoot
		ik.EndEffector = leftHand
		ik.Target = leftGrip
		ik.SmoothTime = 0
		ik.Weight = 1
		ik.Priority = 2
		ik.Enabled = true
		ik.Parent = humanoid
	end

	ikBound[character] = true
end

local function strafeInput(): number
	local value = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		value -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		value += 1
	end
	return value
end

-- Shouldered ADS. Arms are a fallback; IK snaps hands to grip + handguard.
local function applyR15(character: Model, moving: number)
	local rightShoulder = motor(character, "RightUpperArm", "RightShoulder")
	local leftShoulder = motor(character, "LeftUpperArm", "LeftShoulder")
	local rightElbow = motor(character, "RightLowerArm", "RightElbow")
	local leftElbow = motor(character, "LeftLowerArm", "LeftElbow")
	local rightWrist = motor(character, "RightHand", "RightWrist")
	local leftWrist = motor(character, "LeftHand", "LeftWrist")
	local neck = motor(character, "Head", "Neck")
	local waist = motor(character, "UpperTorso", "Waist")
	local root = motor(character, "LowerTorso", "Root")
	local rightHip = motor(character, "RightUpperLeg", "RightHip")
	local leftHip = motor(character, "LeftUpperLeg", "LeftHip")
	local rightKnee = motor(character, "RightLowerLeg", "RightKnee")
	local leftKnee = motor(character, "LeftLowerLeg", "LeftKnee")

	if waist then
		waist.Transform = CFrame.Angles(math.rad(8), math.rad(18), math.rad(-4))
	end
	if neck then
		neck.Transform = CFrame.Angles(math.rad(-18), math.rad(-10), math.rad(4))
	end
	if rightShoulder then
		rightShoulder.Transform = CFrame.Angles(math.rad(75), math.rad(58), math.rad(28))
	end
	if rightElbow then
		rightElbow.Transform = CFrame.Angles(math.rad(42), math.rad(8), math.rad(12))
	end
	if rightWrist then
		rightWrist.Transform = CFrame.Angles(math.rad(-8), math.rad(12), 0)
	end
	if leftShoulder then
		leftShoulder.Transform = CFrame.Angles(math.rad(98), math.rad(-55), math.rad(-18))
	end
	if leftElbow then
		leftElbow.Transform = CFrame.Angles(math.rad(18), math.rad(6), math.rad(-10))
	end
	if leftWrist then
		leftWrist.Transform = CFrame.identity
	end
	if root then
		root.Transform = CFrame.identity
	end

	local dir = 0
	if moving > 0.1 then
		dir = 1
	elseif moving < -0.1 then
		dir = -1
	end

	if dir == 0 then
		if rightHip then
			rightHip.Transform = CFrame.Angles(math.rad(4), 0, math.rad(3))
		end
		if leftHip then
			leftHip.Transform = CFrame.Angles(math.rad(4), 0, math.rad(-3))
		end
		if rightKnee then
			rightKnee.Transform = CFrame.identity
		end
		if leftKnee then
			leftKnee.Transform = CFrame.identity
		end
	else
		if rightHip then
			rightHip.Transform = CFrame.Angles(math.rad(8), 0, math.rad(-14) * dir)
		end
		if leftHip then
			leftHip.Transform = CFrame.Angles(math.rad(8), 0, math.rad(-14) * dir)
		end
		if rightKnee then
			rightKnee.Transform = CFrame.Angles(math.rad(12), 0, 0)
		end
		if leftKnee then
			leftKnee.Transform = CFrame.Angles(math.rad(12), 0, 0)
		end
	end
end

local function applyR6(character: Model, moving: number)
	local torso = character:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	local rightArm = torso:FindFirstChild("Right Shoulder")
	local leftArm = torso:FindFirstChild("Left Shoulder")
	local rightHip = torso:FindFirstChild("Right Hip")
	local leftHip = torso:FindFirstChild("Left Hip")
	local neck = torso:FindFirstChild("Neck")

	if rightArm and rightArm:IsA("Motor6D") then
		rightArm.Transform = CFrame.Angles(math.rad(80), math.rad(45), math.rad(12))
	end
	if leftArm and leftArm:IsA("Motor6D") then
		leftArm.Transform = CFrame.Angles(math.rad(100), math.rad(-48), math.rad(-10))
	end
	if neck and neck:IsA("Motor6D") then
		neck.Transform = CFrame.Angles(math.rad(-14), math.rad(-8), 0)
	end

	local dir = 0
	if moving > 0.1 then
		dir = 1
	elseif moving < -0.1 then
		dir = -1
	end
	if rightHip and rightHip:IsA("Motor6D") then
		rightHip.Transform = CFrame.Angles(0, 0, math.rad(-12) * dir)
	end
	if leftHip and leftHip:IsA("Motor6D") then
		leftHip.Transform = CFrame.Angles(0, 0, math.rad(-12) * dir)
	end
end

function CombatPose.start()
	local player = Players.LocalPlayer
	local gameplay = false

	local function currentPhase(): string
		local state = ReplicatedStorage:FindFirstChild("GameState")
		if not state then
			return "lobby"
		end
		return (state:GetAttribute("Phase") :: string?) or "lobby"
	end

	local function inLane(): boolean
		local phase = currentPhase()
		return phase == "playing" or phase == "countdown"
	end

	task.spawn(function()
		local state = ReplicatedStorage:WaitForChild("GameState")
		state.AttributeChanged:Connect(function(name)
			if name ~= "Phase" then
				return
			end
			local character = player.Character
			if not character then
				return
			end
			if inLane() then
				stopDefault(character)
				gameplay = true
			else
				restoreDefault(character)
				gameplay = false
			end
		end)
	end)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		if inLane() then
			stopDefault(character)
			gameplay = true
		else
			restoreDefault(character)
			gameplay = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then
			return
		end
		if not inLane() then
			if gameplay then
				restoreDefault(character)
				gameplay = false
			end
			return
		end

		if not gameplay then
			stopDefault(character)
			gameplay = true
		end

		bindIk(character)

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			for _, track in humanoid:GetPlayingAnimationTracks() do
				track:Stop(0)
			end
		end

		local moving = StrafeState.value
		if moving == 0 then
			moving = strafeInput()
		end
		if character:FindFirstChild("UpperTorso") then
			applyR15(character, moving)
		else
			applyR6(character, moving)
		end
	end)
end

return CombatPose
