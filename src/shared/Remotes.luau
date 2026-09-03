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
		MolotovThrowAnim = ensureRemote(folder, "MolotovThrowAnim"),
		UseFlashbang = ensureRemote(folder, "UseFlashbang"),
		FlashFx = ensureRemote(folder, "FlashFx"),
		TogglePause = ensureRemote(folder, "TogglePause"),
	}
end

function Remotes.clientWait(timeout: number?)
	local waitSec = timeout or 60
	local folder = ReplicatedStorage:WaitForChild("Remotes", waitSec)
	if not folder then
		local bootErr = ReplicatedStorage:FindFirstChild("BootError")
		if bootErr and bootErr:IsA("StringValue") and bootErr.Value ~= "" then
			error(`Remotes missing (server boot error): {bootErr.Value}`)
		end
		error("Remotes missing — ServerScriptService.Server(init.server) 스크립트가 실행됐는지 확인")
	end

	local function waitRemote(name: string): RemoteEvent
		local remote = folder:WaitForChild(name, waitSec)
		if not remote or not remote:IsA("RemoteEvent") then
			error(`Remote missing: {name}`)
		end
		return remote
	end

	return {
		Strafe = waitRemote("Strafe"),
		HitFx = waitRemote("HitFx"),
		FireFx = waitRemote("FireFx"),
		ExplodeFx = waitRemote("ExplodeFx"),
		DebugSetRound = waitRemote("DebugSetRound"),
		DebugSetChapter = waitRemote("DebugSetChapter"),
		DebugHitPower = waitRemote("DebugHitPower"),
		UseMolotov = waitRemote("UseMolotov"),
		MolotovThrowAnim = waitRemote("MolotovThrowAnim"),
		UseFlashbang = waitRemote("UseFlashbang"),
		FlashFx = waitRemote("FlashFx"),
		TogglePause = waitRemote("TogglePause"),
	}
end

return Remotes
