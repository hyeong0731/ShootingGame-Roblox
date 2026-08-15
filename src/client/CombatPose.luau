local CombatPose = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StrafeState = require(script.Parent.StrafeState)

-- A/D strafe turn (radians). Positive Y = turn left relative to facing +Z.
local STRAFE_YAW = math.rad(38)
local YAW_LERP = 9
-- R15 walk (legs). Upper body is overwritten by Motor6D.Transform each frame.
local WALK_ANIM_ID = "rbxassetid://913402848"

local ikBound: { [Model]: boolean } = {}
local walkTracks: { [Model]: AnimationTrack } = {}
local yawState: { [Model]: number } = {}

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

local function prepareLane(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		for _, track in humanoid:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
	local animate = character:FindFirstChild("Animate")
	if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
		animate.Disabled = true
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
	local track = walkTracks[character]
	if track then
		track:Stop(0.15)
		walkTracks[character] = nil
	end
	yawState[character] = nil
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
	end
	local animate = character:FindFirstChild("Animate")
	if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
		animate.Disabled = false
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

local function ensureWalkTrack(character: Model, humanoid: Humanoid): AnimationTrack?
	local existing = walkTracks[character]
	if existing then
		return existing
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animId = WALK_ANIM_ID
	local animate = character:FindFirstChild("Animate")
	if animate then
		local walkFolder = animate:FindFirstChild("walk") or animate:FindFirstChild("run")
		if walkFolder then
			local animObj = walkFolder:FindFirstChildOfClass("Animation")
			if animObj and animObj.AnimationId ~= "" then
				animId = animObj.AnimationId
			end
		end
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		return nil
	end
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement
	walkTracks[character] = track
	return track
end

local function updateWalkAnim(character: Model, humanoid: Humanoid, moving: number)
	local isMoving = math.abs(moving) > 0.1

	-- Kill every playing track while idle so default Animate can't bob the legs.
	if not isMoving then
		for _, track in humanoid:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in animator:GetPlayingAnimationTracks() do
				track:Stop(0)
			end
		end
		local ours = walkTracks[character]
		if ours and ours.IsPlaying then
			ours:Stop(0)
		end
		return
	end

	local track = ensureWalkTrack(character, humanoid)
	if not track then
		return
	end
	if not track.IsPlaying then
		track:Play(0.12)
	end
	track:AdjustSpeed(1.2)
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

local function smoothYaw(character: Model, targetYaw: number, dt: number): number
	local current = yawState[character] or 0
	local alpha = 1 - math.exp(-YAW_LERP * dt)
	local from = CFrame.Angles(0, current, 0)
	local to = CFrame.Angles(0, targetYaw, 0)
	local lerped = from:Lerp(to, alpha)
	local _, y = lerped:ToEulerAnglesYXZ()
	yawState[character] = y
	return y
end

-- Upper body ADS always faces character forward; lower body yaws only while strafing.
local function applyR15(character: Model, moving: number, dt: number)
	local neck = motor(character, "Head", "Neck")
	local waist = motor(character, "UpperTorso", "Waist")
	local root = motor(character, "LowerTorso", "Root")
	local rightShoulder = motor(character, "RightUpperArm", "RightShoulder")
	local leftShoulder = motor(character, "LeftUpperArm", "LeftShoulder")
	local rightElbow = motor(character, "RightLowerArm", "RightElbow")
	local leftElbow = motor(character, "LeftLowerArm", "LeftElbow")
	local rightWrist = motor(character, "RightHand", "RightWrist")
	local leftWrist = motor(character, "LeftHand", "LeftWrist")
	local rightHip = motor(character, "RightUpperLeg", "RightHip")
	local leftHip = motor(character, "LeftUpperLeg", "LeftHip")
	local rightKnee = motor(character, "RightLowerLeg", "RightKnee")
	local leftKnee = motor(character, "LeftLowerLeg", "LeftKnee")
	local rightAnkle = motor(character, "RightFoot", "RightAnkle")
	local leftAnkle = motor(character, "LeftFoot", "LeftAnkle")

	local isMoving = math.abs(moving) > 0.1
	local targetYaw = 0
	if isMoving then
		if moving < -0.1 then
			targetYaw = STRAFE_YAW
		else
			targetYaw = -STRAFE_YAW
		end
	end

	local yaw = 0
	if isMoving then
		yaw = smoothYaw(character, targetYaw, dt)
	else
		-- Idle: instantly plant hips forward — no leftover lerp sway.
		yawState[character] = 0
		yaw = 0
	end

	if root then
		root.Transform = if isMoving then CFrame.Angles(0, yaw, 0) else CFrame.identity
	end

	local adsWaist = CFrame.Angles(math.rad(8), math.rad(10), math.rad(-3))
	if waist then
		waist.Transform = if isMoving then CFrame.Angles(0, -yaw, 0) * adsWaist else adsWaist
	end
	if neck then
		neck.Transform = CFrame.Angles(math.rad(-16), math.rad(-6), math.rad(2))
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

	-- Always drive lower body when idle so anim residuals cannot move legs.
	if not isMoving then
		if rightHip then
			rightHip.Transform = CFrame.identity
		end
		if leftHip then
			leftHip.Transform = CFrame.identity
		end
		if rightKnee then
			rightKnee.Transform = CFrame.identity
		end
		if leftKnee then
			leftKnee.Transform = CFrame.identity
		end
		if rightAnkle then
			rightAnkle.Transform = CFrame.identity
		end
		if leftAnkle then
			leftAnkle.Transform = CFrame.identity
		end
	end
end

local function applyR6(character: Model, moving: number, dt: number)
	local torso = character:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local rootJoint = if hrp and hrp:IsA("BasePart") then hrp:FindFirstChild("RootJoint") else nil
	local rightArm = torso:FindFirstChild("Right Shoulder")
	local leftArm = torso:FindFirstChild("Left Shoulder")
	local neck = torso:FindFirstChild("Neck")
	local rightHip = torso:FindFirstChild("Right Hip")
	local leftHip = torso:FindFirstChild("Left Hip")

	local isMoving = math.abs(moving) > 0.1
	local targetYaw = 0
	if isMoving then
		if moving < -0.1 then
			targetYaw = STRAFE_YAW
		else
			targetYaw = -STRAFE_YAW
		end
	end
	local yaw = 0
	if isMoving then
		yaw = smoothYaw(character, targetYaw, dt)
	else
		yawState[character] = 0
	end

	if rootJoint and rootJoint:IsA("Motor6D") then
		rootJoint.Transform = if isMoving then CFrame.Angles(0, yaw, 0) else CFrame.identity
	end

	if rightArm and rightArm:IsA("Motor6D") then
		rightArm.Transform = CFrame.Angles(0, -yaw, 0) * CFrame.Angles(math.rad(80), math.rad(45), math.rad(12))
	end
	if leftArm and leftArm:IsA("Motor6D") then
		leftArm.Transform = CFrame.Angles(0, -yaw, 0) * CFrame.Angles(math.rad(100), math.rad(-48), math.rad(-10))
	end
	if neck and neck:IsA("Motor6D") then
		neck.Transform = CFrame.Angles(0, -yaw, 0) * CFrame.Angles(math.rad(-14), math.rad(-8), 0)
	end

	if not isMoving then
		if rightHip and rightHip:IsA("Motor6D") then
			rightHip.Transform = CFrame.identity
		end
		if leftHip and leftHip:IsA("Motor6D") then
			leftHip.Transform = CFrame.identity
		end
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
				prepareLane(character)
				gameplay = true
			else
				restoreDefault(character)
				gameplay = false
			end
		end)
	end)

	player.CharacterAdded:Connect(function(character)
		walkTracks[character] = nil
		yawState[character] = 0
		task.wait(0.2)
		if inLane() then
			prepareLane(character)
			gameplay = true
		else
			restoreDefault(character)
			gameplay = false
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
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
			prepareLane(character)
			gameplay = true
		end

		bindIk(character)

		local moving = StrafeState.value
		if moving == 0 then
			moving = strafeInput()
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			updateWalkAnim(character, humanoid, moving)
		end

		if character:FindFirstChild("UpperTorso") then
			applyR15(character, moving, dt)
		else
			applyR6(character, moving, dt)
		end
	end)
end

return CombatPose
