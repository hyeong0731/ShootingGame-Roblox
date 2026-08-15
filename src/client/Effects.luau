local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = {}

function Effects.start(remotes)
	remotes.ExplodeFx.OnClientEvent:Connect(function(position: Vector3, radius: number)
		local fxFolder = Workspace:FindFirstChild("Fx") or Workspace
		local blast = Instance.new("Part")
		blast.Name = "Blast"
		blast.Shape = Enum.PartType.Ball
		blast.Anchored = true
		blast.CanCollide = false
		blast.CanQuery = false
		blast.Material = Enum.Material.Neon
		blast.Color = Color3.fromRGB(255, 140, 40)
		blast.Transparency = 0.15
		blast.Size = Vector3.new(2, 2, 2)
		blast.CFrame = CFrame.new(position)
		blast.Parent = fxFolder
		Debris:AddItem(blast, 0.28)

		local ring = Instance.new("Part")
		ring.Name = "BlastRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 90, 30)
		ring.Transparency = 0.25
		ring.Size = Vector3.new(0.35, 3, 3)
		ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = fxFolder
		Debris:AddItem(ring, 0.28)

		task.spawn(function()
			local t = 0
			while t < 0.26 and blast.Parent do
				t += task.wait()
				local u = math.clamp(t / 0.26, 0, 1)
				local size = 2 + (radius * 2 - 2) * u
				blast.Size = Vector3.new(size, size, size)
				blast.Transparency = 0.15 + 0.8 * u
				local ringSize = 3 + (radius * 2 - 3) * u
				ring.Size = Vector3.new(0.28, ringSize, ringSize)
				ring.Transparency = 0.25 + 0.7 * u
			end
		end)

		for _ = 1, 8 do
			local chip = Instance.new("Part")
			chip.Shape = Enum.PartType.Ball
			chip.Size = Vector3.new(0.45, 0.45, 0.45)
			chip.Color = Color3.fromRGB(255, 200, 80)
			chip.Material = Enum.Material.Neon
			chip.Anchored = true
			chip.CanCollide = false
			chip.CanQuery = false
			local offset = Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5).Unit * (radius * 0.35)
			chip.CFrame = CFrame.new(position + offset)
			chip.Parent = fxFolder
			Debris:AddItem(chip, 0.12)
		end
	end)
end

return Effects
