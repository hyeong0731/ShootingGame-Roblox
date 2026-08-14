local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = {}

function Effects.start(remotes)
	remotes.HitFx.OnClientEvent:Connect(function(position: Vector3, isBoss: boolean)
		local spark = Instance.new("Part")
		spark.Shape = Enum.PartType.Ball
		spark.Size = Vector3.new(if isBoss then 1.2 else 0.55, if isBoss then 1.2 else 0.55, if isBoss then 1.2 else 0.55)
		spark.Color = Color3.fromRGB(255, 40, 40)
		spark.Material = Enum.Material.Neon
		spark.Anchored = true
		spark.CanCollide = false
		spark.CanQuery = false
		spark.CFrame = CFrame.new(position)
		spark.Parent = Workspace:FindFirstChild("Fx") or Workspace
		Debris:AddItem(spark, 0.08)
	end)
end

return Effects
