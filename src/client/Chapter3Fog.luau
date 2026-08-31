--[[
	챕터3 안개 — Lighting 그라데이션 + 전 월드 LTM 보조
	· 0~20% 맑음 / 20~40% 옅게 / 40%+ 서서히 가림 (smoothstep)
	· 맵(Arena 전체)·유닛·Fx 매 프레임 적용 (Arena 누락이 기둥/실루엣 원인이었음)
	· Lighting/Atmosphere는 이벤트 중 매 프레임 고정 (덮어쓰기 방지)
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Chapter3Fog = {}

type SavedFog = {
	fogStart: number,
	fogEnd: number,
	fogColor: Color3,
	atmoDensity: number,
	atmoHaze: number,
	atmoColor: Color3,
}

local ENTITY_FOLDERS = { "Zombies", "NumberGates", "Supplies", "Hazards", "Allies" }
local MAP_ROOTS = { "Arena", "Ruins", "Bridge" }
local LARGE_MAP_NAMES: { [string]: boolean } = {
	Path = true,
	DmzRoad = true,
	DmzPaint = true,
	DmzWalk = true,
	DmzMedian = true,
	Shoulder = true,
	Median = true,
	Curb = true,
	LaneBarrier = true,
}

local savedFog: SavedFog?
local fogStartProxy: NumberValue?
local fogEndProxy: NumberValue?
local atmoDensityProxy: NumberValue?
local atmoHazeProxy: NumberValue?
local activeTweens: { Tween } = {}
local fogEventActive = false
local touchedParts: { [BasePart]: boolean } = {}
local targetFog = { start = 0, end_ = 0, color = Color3.new(), atmoDensity = 0, atmoHaze = 0, atmoColor = Color3.new() }
local worldFogFrame = 0

local function currentChapter(): number
	local state = ReplicatedStorage:FindFirstChild("GameState")
	if not state then
		return 1
	end
	return (state:GetAttribute("Chapter") :: number?) or 1
end

local function fogCfg()
	return Config.Chapter3.Fog
end

local function maxViewDistance(): number
	local cfg = fogCfg()
	if cfg.MaxDistance and cfg.MaxDistance > 0 then
		return cfg.MaxDistance
	end
	local lane = Config.Chapter3.Lane
	return lane.SpawnZ - lane.PlayerZ
end

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function zoneRatios(): (number, number, number)
	local cfg = fogCfg()
	return cfg.ClearEndRatio or 0.2, cfg.FeatherEndRatio or 0.4, cfg.BlackoutFullRatio or 0.52
end

local function cfgColor(): Color3
	return fogCfg().Color or Color3.fromRGB(45, 42, 50)
end

local function refreshTargets()
	local maxDist = maxViewDistance()
	local clearEnd, _, blackoutFull = zoneRatios()
	local cfg = fogCfg()
	targetFog.start = maxDist * clearEnd
	targetFog.end_ = maxDist * blackoutFull
	targetFog.color = cfgColor()
	targetFog.atmoDensity = cfg.EventAtmoDensity or 0.62
	targetFog.atmoHaze = cfg.EventAtmoHaze or 3.1
	targetFog.atmoColor = cfgColor()
end

-- 카메라 3D 거리 (Lighting Fog와 동일 기준)
local function depthRatioAt(worldPos: Vector3): number
	local cam = Workspace.CurrentCamera
	if not cam then
		local lane = Config.Chapter3.Lane
		return math.max(0, worldPos.Z - lane.PlayerZ) / maxViewDistance()
	end
	return (worldPos - cam.CFrame.Position).Magnitude / maxViewDistance()
end

local function visibilityAtRatio(ratio: number): number
	local clearEnd, featherEnd, blackoutFull = zoneRatios()
	local featherMin = fogCfg().FeatherMinVisibility or 0.9

	if ratio <= clearEnd then
		return 1
	end
	if ratio <= featherEnd then
		local t = smoothstep((ratio - clearEnd) / math.max(0.001, featherEnd - clearEnd))
		return 1 - (1 - featherMin) * t
	end
	if ratio >= blackoutFull then
		return 0
	end
	local t = smoothstep((ratio - featherEnd) / math.max(0.001, blackoutFull - featherEnd))
	return featherMin * (1 - t)
end

local function isLocalCharacterPart(part: BasePart): boolean
	local player = Players.LocalPlayer
	local character = player and player.Character
	return character ~= nil and part:IsDescendantOf(character)
end

local function applyPartFog(part: BasePart, ratio: number)
	if isLocalCharacterPart(part) then
		return
	end
	touchedParts[part] = true
	part.LocalTransparencyModifier = 1 - visibilityAtRatio(ratio)
end

local function applyEntityModel(model: Model)
	local pivotRatio = depthRatioAt(model:GetPivot().Position)
	local vis = visibilityAtRatio(pivotRatio)
	local ltm = 1 - vis
	local showGui = vis > 0.03

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			touchedParts[desc] = true
			desc.LocalTransparencyModifier = ltm
		elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
			desc.Enabled = showGui
		elseif desc:IsA("Highlight") or desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
			desc.Enabled = showGui
		end
	end
end

local function isLargeMapPart(part: BasePart): boolean
	if LARGE_MAP_NAMES[part.Name] then
		return true
	end
	return part.Size.Z > 85
end

local function applyMapPart(part: BasePart)
	if isLocalCharacterPart(part) or isLargeMapPart(part) then
		return
	end
	local ratio = depthRatioAt(part.Position)
	touchedParts[part] = true
	part.LocalTransparencyModifier = 1 - visibilityAtRatio(ratio)
end

local function updateWorldFog()
	for _, folderName in ENTITY_FOLDERS do
		local folder = Workspace:FindFirstChild(folderName)
		if not folder then
			continue
		end
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				applyEntityModel(child)
			elseif child:IsA("BasePart") then
				applyPartFog(child, depthRatioAt(child.Position))
			end
		end
	end

	for _, rootName in MAP_ROOTS do
		local root = Workspace:FindFirstChild(rootName)
		if not root then
			continue
		end
		for _, desc in root:GetDescendants() do
			if desc:IsA("BasePart") then
				applyMapPart(desc)
			end
		end
	end

	local fx = Workspace:FindFirstChild("Fx")
	if fx then
		for _, desc in fx:GetDescendants() do
			if desc:IsA("BasePart") then
				applyPartFog(desc, depthRatioAt(desc.Position))
			end
		end
	end
end

local function applyLightingNow()
	Lighting.FogColor = targetFog.color
	Lighting.FogStart = targetFog.start
	Lighting.FogEnd = targetFog.end_
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = targetFog.atmoDensity
		atmosphere.Haze = targetFog.atmoHaze
		atmosphere.Color = targetFog.atmoColor
		atmosphere.Decay = targetFog.atmoColor
	end
	if fogStartProxy then
		fogStartProxy.Value = targetFog.start
	end
	if fogEndProxy then
		fogEndProxy.Value = targetFog.end_
	end
	if atmoDensityProxy then
		atmoDensityProxy.Value = targetFog.atmoDensity
	end
	if atmoHazeProxy then
		atmoHazeProxy.Value = targetFog.atmoHaze
	end
end

local function ensureProxies()
	if fogStartProxy then
		return
	end
	fogStartProxy = Instance.new("NumberValue")
	fogStartProxy.Name = "Ch3FogStartProxy"
	fogStartProxy.Parent = script
	fogEndProxy = Instance.new("NumberValue")
	fogEndProxy.Name = "Ch3FogEndProxy"
	fogEndProxy.Parent = script
	atmoDensityProxy = Instance.new("NumberValue")
	atmoDensityProxy.Name = "Ch3AtmoDensityProxy"
	atmoDensityProxy.Parent = script
	atmoHazeProxy = Instance.new("NumberValue")
	atmoHazeProxy.Name = "CH3AtmoHazeProxy"
	atmoHazeProxy.Parent = script

	fogStartProxy.Changed:Connect(function(v)
		Lighting.FogStart = v
	end)
	fogEndProxy.Changed:Connect(function(v)
		Lighting.FogEnd = v
	end)
	atmoDensityProxy.Changed:Connect(function(v)
		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			atmosphere.Density = v
		end
	end)
	atmoHazeProxy.Changed:Connect(function(v)
		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			atmosphere.Haze = v
		end
	end)
end

local function getAtmosphere(): Atmosphere?
	return Lighting:FindFirstChildOfClass("Atmosphere")
end

local function saveBaselineIfNeeded()
	local state = ReplicatedStorage:FindFirstChild("GameState")
	if state and (state:GetAttribute("Chapter") or 1) < 3 then
		return
	end
	if savedFog then
		return
	end
	local atmosphere = getAtmosphere()
	savedFog = {
		fogStart = Lighting.FogStart,
		fogEnd = Lighting.FogEnd,
		fogColor = Lighting.FogColor,
		atmoDensity = if atmosphere then atmosphere.Density else 0.3,
		atmoHaze = if atmosphere then atmosphere.Haze else 1.35,
		atmoColor = if atmosphere then atmosphere.Color else Color3.new(1, 1, 1),
	}
end

local function refreshBaseline()
	local state = ReplicatedStorage:FindFirstChild("GameState")
	if not state or (state:GetAttribute("Chapter") or 1) < 3 then
		return
	end
	if fogEventActive then
		return
	end
	local atmosphere = getAtmosphere()
	savedFog = {
		fogStart = Lighting.FogStart,
		fogEnd = Lighting.FogEnd,
		fogColor = Lighting.FogColor,
		atmoDensity = if atmosphere then atmosphere.Density else 0.3,
		atmoHaze = if atmosphere then atmosphere.Haze else 1.35,
		atmoColor = if atmosphere then atmosphere.Color else Color3.new(1, 1, 1),
	}
end

local function cancelTweens()
	for _, tw in activeTweens do
		tw:Cancel()
	end
	table.clear(activeTweens)
end

local function restoreAllTouched()
	for part in touchedParts do
		if part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
	table.clear(touchedParts)
end

local function tweenToSaved()
	if not savedFog then
		return
	end
	saveBaselineIfNeeded()
	ensureProxies()
	cancelTweens()

	local duration = fogCfg().TweenDuration or 1.5
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local fogStart = fogStartProxy
	local fogEnd = fogEndProxy
	local atmoDensity = atmoDensityProxy
	local atmoHaze = atmoHazeProxy
	if not (fogStart and fogEnd and atmoDensity and atmoHaze) then
		return
	end

	fogStart.Value = Lighting.FogStart
	fogEnd.Value = Lighting.FogEnd
	local atmosphere = getAtmosphere()
	atmoDensity.Value = if atmosphere then atmosphere.Density else 0.3
	atmoHaze.Value = if atmosphere then atmosphere.Haze else 1.35

	for _, tw in {
		TweenService:Create(fogStart, info, { Value = savedFog.fogStart }),
		TweenService:Create(fogEnd, info, { Value = savedFog.fogEnd }),
		TweenService:Create(atmoDensity, info, { Value = savedFog.atmoDensity }),
		TweenService:Create(atmoHaze, info, { Value = savedFog.atmoHaze }),
	} do
		tw:Play()
		table.insert(activeTweens, tw)
	end

	Lighting.FogColor = savedFog.fogColor
	if atmosphere then
		atmosphere.Color = savedFog.atmoColor
		atmosphere.Decay = savedFog.atmoColor
	end
end

local function tweenToEvent()
	refreshTargets()
	saveBaselineIfNeeded()
	ensureProxies()
	cancelTweens()

	local fogStart = fogStartProxy
	local fogEnd = fogEndProxy
	local atmoDensity = atmoDensityProxy
	local atmoHaze = atmoHazeProxy
	if not (fogStart and fogEnd and atmoDensity and atmoHaze) then
		return
	end

	fogStart.Value = Lighting.FogStart
	fogEnd.Value = Lighting.FogEnd
	local atmosphere = getAtmosphere()
	atmoDensity.Value = if atmosphere then atmosphere.Density else 0.3
	atmoHaze.Value = if atmosphere then atmosphere.Haze else 1.35

	Lighting.FogColor = targetFog.color
	if atmosphere then
		atmosphere.Color = targetFog.atmoColor
		atmosphere.Decay = targetFog.atmoColor
	end

	local duration = fogCfg().TweenDuration or 1.5
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	for _, tw in {
		TweenService:Create(fogStart, info, { Value = targetFog.start }),
		TweenService:Create(fogEnd, info, { Value = targetFog.end_ }),
		TweenService:Create(atmoDensity, info, { Value = targetFog.atmoDensity }),
		TweenService:Create(atmoHaze, info, { Value = targetFog.atmoHaze }),
	} do
		tw:Play()
		table.insert(activeTweens, tw)
	end
end

local function applyFogEvent(active: boolean)
	if active == fogEventActive then
		return
	end
	fogEventActive = active

	local oldWall = Workspace:FindFirstChild("Ch3FogWall")
	if oldWall then
		oldWall:Destroy()
	end

	if active then
		tweenToEvent()
	else
		restoreAllTouched()
		tweenToSaved()
	end
end

local function isFogActive(): boolean
	if currentChapter() < 3 then
		return false
	end
	local state = ReplicatedStorage:FindFirstChild("GameState")
	return state ~= nil and state:GetAttribute("Ch3FogActive") == true
end

function Chapter3Fog.start()
	task.spawn(function()
		local state = ReplicatedStorage:WaitForChild("GameState", 30)
		if not state then
			warn("[Chapter3Fog] GameState missing — fog disabled")
			return
		end
		ensureProxies()
		saveBaselineIfNeeded()
		refreshTargets()

		applyFogEvent(isFogActive())
		state:GetAttributeChangedSignal("Ch3FogActive"):Connect(function()
			applyFogEvent(isFogActive())
		end)
		state:GetAttributeChangedSignal("Chapter"):Connect(function()
			if currentChapter() < 3 and fogEventActive then
				applyFogEvent(false)
			elseif currentChapter() >= 3 then
				refreshBaseline()
			end
		end)

		RunService.RenderStepped:Connect(function()
			if not fogEventActive or currentChapter() < 3 then
				return
			end
			refreshTargets()
			applyLightingNow()
			worldFogFrame += 1
			if worldFogFrame % 2 == 0 then
				updateWorldFog()
			end
		end)
	end)
end

return Chapter3Fog
