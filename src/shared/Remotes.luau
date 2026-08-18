local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function ensureFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

local function ensureRemote(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function Remotes.serverInit()
	local folder = ensureFolder()
	return {
		Strafe = ensureRemote(folder, "Strafe"),
		HitFx = ensureRemote(folder, "HitFx"),
		FireFx = ensureRemote(folder, "FireFx"),
		ExplodeFx = ensureRemote(folder, "ExplodeFx"),
		DebugSetRound = ensureRemote(folder, "DebugSetRound"),
		DebugSetChapter = ensureRemote(folder, "DebugSetChapter"),
		DebugHitPower = ensureRemote(folder, "DebugHitPower"),
		UseMolotov = ensureRemote(folder, "UseMolotov"),
	}
end

function Remotes.clientWait()
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return {
		Strafe = folder:WaitForChild("Strafe"),
		HitFx = folder:WaitForChild("HitFx"),
		FireFx = folder:WaitForChild("FireFx"),
		ExplodeFx = folder:WaitForChild("ExplodeFx"),
		DebugSetRound = folder:WaitForChild("DebugSetRound"),
		DebugSetChapter = folder:WaitForChild("DebugSetChapter"),
		DebugHitPower = folder:WaitForChild("DebugHitPower"),
		UseMolotov = folder:WaitForChild("UseMolotov"),
	}
end

return Remotes
