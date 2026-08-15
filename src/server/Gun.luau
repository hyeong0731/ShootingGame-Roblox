local Gun = {}

local function makePart(parent: Instance, name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = true
	p.Parent = parent
	return p
end

local function weldTo(root: BasePart, child: BasePart, offset: CFrame)
	child.CFrame = root.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = child
	weld.C0 = offset
	weld.Parent = child
end

function Gun.remove(character: Model)
	local existing = character:FindFirstChild("Gun")
	if existing then
		existing:Destroy()
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		for _, name in { "GunIK_Right", "GunIK_Left" } do
			local old = humanoid:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
	end
end

function Gun.attach(character: Model)
	Gun.remove(character)

	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	if not (torso and torso:IsA("BasePart")) then
		return
	end

	local model = Instance.new("Model")
	model.Name = "Gun"
	model.Parent = character

	local metal = Color3.fromRGB(38, 40, 44)
	local dark = Color3.fromRGB(22, 22, 26)
	local wood = Color3.fromRGB(78, 52, 32)

	local handle = makePart(model, "Handle", Vector3.new(0.28, 0.72, 0.3), dark, Enum.Material.SmoothPlastic)
	handle.CFrame = torso.CFrame
	model.PrimaryPart = handle

	weldTo(handle, makePart(model, "Body", Vector3.new(0.34, 0.32, 1.7), metal, Enum.Material.Metal), CFrame.new(0, 0.38, -0.45))
	weldTo(handle, makePart(model, "Handguard", Vector3.new(0.32, 0.28, 0.75), wood, Enum.Material.Wood), CFrame.new(0, 0.36, -1.2))
	weldTo(handle, makePart(model, "Stock", Vector3.new(0.28, 0.34, 0.7), dark, Enum.Material.SmoothPlastic), CFrame.new(0, 0.28, 0.7))
	weldTo(handle, makePart(model, "Barrel", Vector3.new(0.16, 0.16, 1.35), Color3.fromRGB(50, 52, 56), Enum.Material.Metal), CFrame.new(0, 0.42, -1.7))
	weldTo(handle, makePart(model, "Suppressor", Vector3.new(0.2, 0.2, 0.7), Color3.fromRGB(30, 30, 32), Enum.Material.Metal), CFrame.new(0, 0.42, -2.55))
	weldTo(
		handle,
		makePart(model, "Mag", Vector3.new(0.2, 0.85, 0.36), dark, Enum.Material.SmoothPlastic),
		CFrame.new(0, -0.38, -0.32) * CFrame.Angles(math.rad(20), 0, 0)
	)

	local rail = makePart(model, "Rail", Vector3.new(0.16, 0.1, 0.9), metal, Enum.Material.Metal)
	weldTo(handle, rail, CFrame.new(0, 0.58, -0.55))

	local sight = makePart(model, "Sight", Vector3.new(0.22, 0.28, 0.38), Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic)
	weldTo(handle, sight, CFrame.new(0, 0.78, -0.45))
	local lens = makePart(model, "Lens", Vector3.new(0.16, 0.16, 0.08), Color3.fromRGB(180, 40, 40), Enum.Material.Neon)
	weldTo(handle, lens, CFrame.new(0, 0.78, -0.28))

	local muzzle = makePart(model, "Muzzle", Vector3.new(0.18, 0.18, 0.18), Color3.fromRGB(255, 200, 80), Enum.Material.SmoothPlastic)
	weldTo(handle, muzzle, CFrame.new(0, 0.42, -2.95))

	local attachment = Instance.new("Attachment")
	attachment.Name = "MuzzlePoint"
	attachment.Parent = muzzle

	-- Right hand on pistol grip, left hand under the handguard.
	local rightGrip = Instance.new("Attachment")
	rightGrip.Name = "RightGrip"
	rightGrip.CFrame = CFrame.new(0.12, -0.18, 0.04) * CFrame.Angles(math.rad(90), math.rad(90), 0)
	rightGrip.Parent = handle

	local leftGrip = Instance.new("Attachment")
	leftGrip.Name = "LeftGrip"
	leftGrip.CFrame = CFrame.new(-0.08, 0.12, -1.18) * CFrame.Angles(math.rad(90), math.rad(90), 0)
	leftGrip.Parent = handle

	local grip = Instance.new("Weld")
	grip.Name = "Grip"
	grip.Part0 = torso
	grip.Part1 = handle
	if torso.Name == "UpperTorso" then
		grip.C0 = CFrame.new(0.48, 0.58, -1.08) * CFrame.Angles(math.rad(-6), math.rad(6), math.rad(-4))
	elseif torso.Name == "Torso" then
		grip.C0 = CFrame.new(0.46, 0.62, -1.0) * CFrame.Angles(math.rad(-6), math.rad(6), 0)
	else
		grip.C0 = CFrame.new(0.5, 1.2, -1.12) * CFrame.Angles(math.rad(-6), math.rad(6), 0)
	end
	grip.Parent = handle
end

function Gun.attachBomb(character: Model)
	Gun.remove(character)

	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	if not (torso and torso:IsA("BasePart")) then
		return
	end

	local model = Instance.new("Model")
	model.Name = "Gun"
	model.Parent = character

	local shell = Color3.fromRGB(42, 46, 40)
	local metal = Color3.fromRGB(70, 74, 68)
	local handle = makePart(model, "Handle", Vector3.new(0.9, 1.15, 0.9), shell, Enum.Material.Metal)
	handle.Shape = Enum.PartType.Ball
	handle.CFrame = torso.CFrame
	model.PrimaryPart = handle

	weldTo(handle, makePart(model, "Band", Vector3.new(0.95, 0.16, 0.95), metal, Enum.Material.Metal), CFrame.new(0, 0.12, 0))
	local cap = makePart(model, "Cap", Vector3.new(0.42, 0.28, 0.42), Color3.fromRGB(28, 30, 26), Enum.Material.Metal)
	weldTo(handle, cap, CFrame.new(0, 0.62, 0))
	local fuse = makePart(model, "Fuse", Vector3.new(0.12, 0.45, 0.12), Color3.fromRGB(90, 70, 40), Enum.Material.SmoothPlastic)
	weldTo(handle, fuse, CFrame.new(0, 0.95, 0))
	local spark = makePart(model, "Spark", Vector3.new(0.16, 0.16, 0.16), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	weldTo(handle, spark, CFrame.new(0, 1.18, 0))

	local muzzle = makePart(model, "Muzzle", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(255, 180, 60), Enum.Material.SmoothPlastic)
	muzzle.Transparency = 1
	weldTo(handle, muzzle, CFrame.new(0, 0.2, -0.7))
	local attachment = Instance.new("Attachment")
	attachment.Name = "MuzzlePoint"
	attachment.Parent = muzzle

	local rightGrip = Instance.new("Attachment")
	rightGrip.Name = "RightGrip"
	rightGrip.CFrame = CFrame.new(0.2, -0.1, 0.05) * CFrame.Angles(math.rad(90), math.rad(90), 0)
	rightGrip.Parent = handle
	local leftGrip = Instance.new("Attachment")
	leftGrip.Name = "LeftGrip"
	leftGrip.CFrame = CFrame.new(-0.18, 0.05, 0.05) * CFrame.Angles(math.rad(90), math.rad(90), 0)
	leftGrip.Parent = handle

	local grip = Instance.new("Weld")
	grip.Name = "Grip"
	grip.Part0 = torso
	grip.Part1 = handle
	if torso.Name == "UpperTorso" then
		grip.C0 = CFrame.new(0.55, 0.35, -1.05)
	elseif torso.Name == "Torso" then
		grip.C0 = CFrame.new(0.5, 0.4, -0.95)
	else
		grip.C0 = CFrame.new(0.5, 1.0, -1.05)
	end
	grip.Parent = handle
end

function Gun.getMuzzlePosition(character: Model): Vector3?
	local gun = character:FindFirstChild("Gun")
	if not gun then
		return nil
	end
	local point = gun:FindFirstChild("MuzzlePoint", true)
	if point and point:IsA("Attachment") then
		return point.WorldPosition
	end
	local muzzle = gun:FindFirstChild("Muzzle", true)
	if muzzle and muzzle:IsA("BasePart") then
		return muzzle.Position
	end
	return nil
end

return Gun
