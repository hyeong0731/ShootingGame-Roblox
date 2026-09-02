import fs from "fs";
import path from "path";

const ROOT = path.resolve("src/server");
const SRC = path.join(ROOT, "GameService.luau");
const OUT = path.join(ROOT, "Game");
const lines = fs.readFileSync(SRC, "utf8").split(/\r?\n/);

const STATE_VARS = [
  "stateFolder", "playerData", "phase", "paused", "kills", "matchStart",
  "lastSpawnAt", "lastSupplySpawnAt", "lastBombSpawnAt", "lastGateSpawnAt",
  "lastSidePathSpawnAt", "supplyRoundArmed", "bombRoundArmed",
  "megaBossSpawned", "eliteBossesSpawned", "finalBossSpawned",
  "introGateSpawned", "introGateDueAt", "extraX2Spawned", "extraX2DueAt",
  "plusGateSpawned", "chapter2PlusSpawned", "chapter2X2Spawned",
  "chapter2PlusDueAt", "chapter2X2DueAt", "gatePlayArmed", "chapterClearArmed",
  "chapterPadDebounce", "killBaseline", "hitPower", "nextIsBossAt",
  "heartbeatConn", "startPadDebounce", "lastMolotovAt",
];

function toCtx(code) {
  let out = code;
  for (const v of [...STATE_VARS].sort((a, b) => b.length - a.length)) {
    out = out.replace(new RegExp(`\\b${v}\\b`, "g"), `ctx.${v}`);
  }
  return out;
}

function extract(start, end) {
  return toCtx(lines.slice(start - 1, end).join("\n"));
}

function indent(code, spaces) {
  const pad = " ".repeat(spaces);
  return code
    .split("\n")
    .map((l) => (l.length ? pad + l : l))
    .join("\n");
}

function writeFile(rel, content) {
  const full = path.join(OUT, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, content.trimEnd() + "\n", "utf8");
}

const evSrc = fs.readFileSync(path.join(ROOT, "GameServiceEvents.luau"), "utf8");
writeFile(
  "EventFlags.luau",
  evSrc.replace(/GameServiceEvents/g, "EventFlags").replace(/^--.*\n/, "-- Round event flags\n")
);

writeFile("Context.luau", `export type PlayerData = {
	strafe: number,
	character: Model?,
	lastFire: number,
	bombUntil: number,
	hadBomb: boolean,
	sniperUntil: number,
	hadSniper: boolean,
	shotgunUntil: number,
	hadShotgun: boolean,
	fireRateMult: number,
}

local Context = {
	stateFolder = nil :: Folder?,
	playerData = {} :: { [Player]: PlayerData },
	phase = "lobby",
	paused = false,
	kills = 0,
	matchStart = 0,
	lastSpawnAt = 0,
	lastSupplySpawnAt = 0,
	lastBombSpawnAt = 0,
	lastGateSpawnAt = 0,
	lastSidePathSpawnAt = 0,
	supplyRoundArmed = false,
	bombRoundArmed = false,
	megaBossSpawned = false,
	eliteBossesSpawned = false,
	finalBossSpawned = false,
	introGateSpawned = false,
	introGateDueAt = 0,
	extraX2Spawned = false,
	extraX2DueAt = 0,
	plusGateSpawned = false,
	chapter2PlusSpawned = false,
	chapter2X2Spawned = false,
	chapter2PlusDueAt = 0,
	chapter2X2DueAt = 0,
	gatePlayArmed = false,
	chapterClearArmed = false,
	chapterPadDebounce = false,
	killBaseline = 0,
	hitPower = 1,
	nextIsBossAt = 0,
	heartbeatConn = nil :: RBXScriptConnection?,
	startPadDebounce = false,
	lastMolotovAt = 0,
}

return Context
`);

writeFile("Api.luau", `local Api = {}

return Api
`);

writeFile("EventReset.luau", `local EventFlags = require(script.Parent.EventFlags)

local EventReset = {}
local Ev = EventFlags

function EventReset.resetChapter3Round1Events(setState: (string, any) -> ())
	Ev.resetCh3Round1()
end

function EventReset.resetChapter3Round2Events(setState: (string, any) -> ())
	Ev.resetCh3Round2()
end

function EventReset.resetChapter3Round3Events(setState: (string, any) -> ())
	Ev.resetCh3Round3()
	setState("Ch3FogActive", false)
end

function EventReset.resetChapter3Round4Events(setState: (string, any) -> ())
	Ev.resetCh3Round4()
end

function EventReset.resetChapter3Events(setState: (string, any) -> ())
	Ev.resetCh3()
	setState("Ch3FogActive", false)
end

function EventReset.resetChapter2Round2Events()
	Ev.resetCh2()
end

return EventReset
`);

const stateSyncBody = extract(71, 96)
  .replace(/^local function setState/m, "function StateSync.setState")
  .replace(/^local function shiftPausedTimers/m, "function StateSync.shiftPausedTimers");

writeFile("StateSync.luau", `local Context = require(script.Parent.Context)
local ZombieService = require(script.Parent.Parent.ZombieService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local CombatService = require(script.Parent.Parent.CombatService)

local ctx = Context
local StateSync = {}

${stateSyncBody}

return StateSync
`);

const charBody = extract(98, 209)
  .replace(/^local function isLanePhase/m, "function Character.isLanePhase")
  .replace(/^local function getLeaderPosition/m, "function Character.getLeaderPosition")
  .replace(/^local function setHeroCollision/m, "function Character.setHeroCollision")
  .replace(/^local function applyLobbyCharacter/m, "function Character.applyLobbyCharacter")
  .replace(/^local function teleportToLobby/m, "function Character.teleportToLobby")
  .replace(/^local function teleportToLane/m, "function Character.teleportToLane")
  .replace(/^local function applyWalkCharacter/m, "function Character.applyWalkCharacter")
  .replace(/^local function teleportToChapterWalk/m, "function Character.teleportToChapterWalk");

writeFile("Character.luau", `local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Context = require(script.Parent.Context)
local Gun = require(script.Parent.Parent.Gun)

local ctx = Context
local Character = {}

${charBody}

return Character
`);

const spawningMisc = extract(322, 515)
  .replace(/^local function currentUnitDamage/m, "function Spawning.currentUnitDamage")
  .replace(/^local function delayBombAfterGate/m, "function Spawning.delayBombAfterGate")
  .replace(/^local function markSidePathSpawn/m, "function Spawning.markSidePathSpawn")
  .replace(/^local function sidePathReady/m, "function Spawning.sidePathReady")
  .replace(/^local function chapter2HealthPerKill/m, "function Spawning.chapter2HealthPerKill")
  .replace(/^local function currentStats/m, "function Spawning.currentStats")
  .replace(/^local function waveLocalElapsed/m, "function Spawning.waveLocalElapsed")
  .replace(/^local function chapter2BigUnlocked/m, "function Spawning.chapter2BigUnlocked");

const spawningSpawn = extract(543, 1186)
  .replace(/^local function spawnOne/m, "function Spawning.spawnOne")
  .replace(/^local function spawnMegaBossAt/m, "function Spawning.spawnMegaBossAt")
  .replace(/^local function spawnMegaBoss/m, "function Spawning.spawnMegaBoss")
  .replace(/^local function spawnFinalBoss/m, "function Spawning.spawnFinalBoss")
  .replace(/^local function spawnEliteBosses/m, "function Spawning.spawnEliteBosses")
  .replace(/^local function spawnChapter2MidBoss/m, "function Spawning.spawnChapter2MidBoss")
  .replace(/^local function spawnChapter2DogSwarm/m, "function Spawning.spawnChapter2DogSwarm")
  .replace(/^local function spawnChapter2FinalBoss/m, "function Spawning.spawnChapter2FinalBoss")
  .replace(/^local function spawnChapter2OpeningSwarm/m, "function Spawning.spawnChapter2OpeningSwarm")
  .replace(/^local function spawnChapter2MidSwarm/m, "function Spawning.spawnChapter2MidSwarm")
  .replace(/^local function spawnChapter2FinalHorde/m, "function Spawning.spawnChapter2FinalHorde")
  .replace(/^local function spawnChapter3BigZombie/m, "function Spawning.spawnChapter3BigZombie")
  .replace(/^local function spawnChapter3BigZombieSwarm/m, "function Spawning.spawnChapter3BigZombieSwarm")
  .replace(/^local function spawnChapter3DogSwarmEven/m, "function Spawning.spawnChapter3DogSwarmEven")
  .replace(/^local function spawnChapter3DogSwarm/m, "function Spawning.spawnChapter3DogSwarm")
  .replace(/^local function spawnChapter2ShieldPack/m, "function Spawning.spawnChapter2ShieldPack")
  .replace(/^local function spawnChapter2SmallMidBoss/m, "function Spawning.spawnChapter2SmallMidBoss")
  .replace(/^local function spawnChapter2ZombieSwarm/m, "function Spawning.spawnChapter2ZombieSwarm");

writeFile("Spawning.luau", `local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.Parent.ZombieService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local Context = require(script.Parent.Context)

local ctx = Context
local Spawning = {}

${spawningMisc}

${spawningSpawn}

return Spawning
`);

const gatesBody = extract(1188, 1301)
  .replace(/^local function spawnIntroGate/m, "function Gates.spawnIntroGate")
  .replace(/^local function spawnPlusGate/m, "function Gates.spawnPlusGate")
  .replace(/^local function spawnExtraX2/m, "function Gates.spawnExtraX2")
  .replace(/^local function respawnNumberGate/m, "function Gates.respawnNumberGate")
  .replace(/^local function applyRoundFeatures/m, "function Gates.applyRoundFeatures");

writeFile("Gates.luau", `local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.SupplyService)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Spawning = require(script.Parent.Spawning)

local ctx = Context
local setState = StateSync.setState
local markSidePathSpawn = Spawning.markSidePathSpawn
local delayBombAfterGate = Spawning.delayBombAfterGate
local spawnFinalBoss = Spawning.spawnFinalBoss
local spawnEliteBosses = Spawning.spawnEliteBosses
local spawnMegaBoss = Spawning.spawnMegaBoss

local Gates = {}

${gatesBody}

return Gates
`);

const debugPart1 = extract(211, 320)
  .replace(/^local function destroyChapterPad/m, "function Debug.destroyChapterPad")
  .replace(/^local function debugEnterChapter/m, "function Debug.debugEnterChapter")
  .replace(/^local function spawnChapterPad/m, "function Debug.spawnChapterPad")
  .replace(/startChapter2\(\)/g, "Api.startChapter2()")
  .replace(/startChapter3\(\)/g, "Api.startChapter3()")
  .replace(/resetChapter3Events\(\)/g, "EventReset.resetChapter3Events(setState)")
  .replace(/resetChapter2Round2Events\(\)/g, "EventReset.resetChapter2Round2Events()");

const debugPart2 = extract(1453, 1546)
  .replace(/^local function jumpToRound/m, "function Debug.jumpToRound")
  .replace(/^local function onZombieDied/m, "function Debug.onZombieDied")
  .replace(/beginPlay\(\)/g, "Api.beginPlay()")
  .replace(/resetChapter3Events\(\)/g, "EventReset.resetChapter3Events(setState)")
  .replace(/resetChapter2Round2Events\(\)/g, "EventReset.resetChapter2Round2Events()");

writeFile("Debug.luau", `local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Arena = require(script.Parent.Parent.Arena)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local Context = require(script.Parent.Context)
local Api = require(script.Parent.Api)
local StateSync = require(script.Parent.StateSync)
local Character = require(script.Parent.Character)
local Gates = require(script.Parent.Gates)
local EventReset = require(script.Parent.EventReset)

local ctx = Context
local setState = StateSync.setState
local teleportToChapterWalk = Character.teleportToChapterWalk
local teleportToLane = Character.teleportToLane
local applyRoundFeatures = Gates.applyRoundFeatures

local Debug = {}

${debugPart1}

${debugPart2}

return Debug
`);

const lifecycleStart = extract(1303, 1378)
  .replace(/^local function startChapter/m, "local function startChapter")
  .replace(/^startChapter2 = function\(\)/m, "Api.startChapter2 = function()")
  .replace(/^startChapter3 = function\(\)/m, "Api.startChapter3 = function()")
  .replace(/resetChapter3Events\(\)/g, "EventReset.resetChapter3Events(setState)")
  .replace(/resetChapter2Round2Events\(\)/g, "EventReset.resetChapter2Round2Events()");

const lifecycleClearPlay = extract(1380, 1451)
  .replace(/^local function beginChapterClear/m, "function Lifecycle.beginChapterClear")
  .replace(/^local function beginPlay/m, "function Lifecycle.beginPlay")
  .replace(/resetChapter3Events\(\)/g, "EventReset.resetChapter3Events(setState)")
  .replace(/resetChapter2Round2Events\(\)/g, "EventReset.resetChapter2Round2Events()");

const lifecycleCountdown = extract(1559, 1576)
  .replace(/^startCountdown = function\(\)/m, "function Lifecycle.startCountdown")
  .replace(/beginPlay\(\)/g, "Lifecycle.beginPlay()");

const lifecycleLobby = extract(1664, 1726)
  .replace(/^local function returnToLobby/m, "function Lifecycle.returnToLobby")
  .replace(/resetChapter3Events\(\)/g, "EventReset.resetChapter3Events(setState)")
  .replace(/resetChapter2Round2Events\(\)/g, "EventReset.resetChapter2Round2Events()");

const lifecycleMatch = extract(1728, 1999)
  .replace(/^local function startMatch/m, "function Lifecycle.startMatch")
  .replace(/^local function onPlayerDied/m, "function Lifecycle.onPlayerDied")
  .replace(/^local function setupCharacter/m, "function Lifecycle.setupCharacter")
  .replace(/^local function setupPlayer/m, "function Lifecycle.setupPlayer")
  .replace(/^local function bindStartPad/m, "function Lifecycle.bindStartPad")
  .replace(/startCountdown\(\)/g, "Lifecycle.startCountdown()")
  .replace(/resetChapter3Events\(\)/g, "EventReset.resetChapter3Events(setState)")
  .replace(/resetChapter2Round2Events\(\)/g, "EventReset.resetChapter2Round2Events()");

writeFile("Lifecycle.luau", `local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Arena = require(script.Parent.Parent.Arena)
local ZombieService = require(script.Parent.Parent.ZombieService)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local Gun = require(script.Parent.Parent.Gun)
local Context = require(script.Parent.Context)
local Api = require(script.Parent.Api)
local StateSync = require(script.Parent.StateSync)
local Character = require(script.Parent.Character)
local Debug = require(script.Parent.Debug)
local EventReset = require(script.Parent.EventReset)

local ctx = Context
local setState = StateSync.setState
local isLanePhase = Character.isLanePhase
local setHeroCollision = Character.setHeroCollision
local teleportToLobby = Character.teleportToLobby
local teleportToLane = Character.teleportToLane
local applyWalkCharacter = Character.applyWalkCharacter
local spawnChapterPad = Debug.spawnChapterPad
local destroyChapterPad = Debug.destroyChapterPad

local Lifecycle = {}

${lifecycleStart}

${lifecycleClearPlay}

${lifecycleCountdown}

${lifecycleLobby}

${lifecycleMatch}

Api.beginPlay = Lifecycle.beginPlay

return Lifecycle
`);

const combatBody = extract(1579, 1662)
  .replace(/^local function applySpikeDamage/m, "function Combat.applySpikeDamage")
  .replace(/^local function throwRockAt/m, "function Combat.throwRockAt")
  .replace(/^local function damagePlayersNear/m, "function Combat.damagePlayersNear")
  .replace(/^local function damagePlayers/m, "function Combat.damagePlayers");

const combatGrants = extract(1838, 1964)
  .replace(/^local function restoreGun/m, "function Combat.restoreGun")
  .replace(/^grantBombs = function\(\)/m, "function Combat.grantBombs")
  .replace(/^grantSniper = function\(\)/m, "function Combat.grantSniper")
  .replace(/^grantShotgun = function\(\)/m, "function Combat.grantShotgun")
  .replace(/^local function grantFireBoost/m, "function Combat.grantFireBoost")
  .replace(/^local function tryFire/m, "function Combat.tryFire");

writeFile("Combat.luau", `local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local Gun = require(script.Parent.Parent.Gun)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Spawning = require(script.Parent.Spawning)

local ctx = Context
local setState = StateSync.setState
local currentUnitDamage = Spawning.currentUnitDamage

local Combat = {}

${combatBody}

${combatGrants}

return Combat
`);

const hb1 = extract(2226, 2316);
const ch1 = extract(2318, 2364);
const ch2 = extract(2366, 2681);
const ch3 = extract(2683, 2828);
const hb2 = extract(2830, 2883);

writeFile("RoundTimeline/Chapter1.luau", `local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local Context = require(script.Parent.Parent.Context)
local Spawning = require(script.Parent.Parent.Spawning)

local ctx = Context
local markSidePathSpawn = Spawning.markSidePathSpawn
local delayBombAfterGate = Spawning.delayBombAfterGate
local sidePathReady = Spawning.sidePathReady

local Chapter1 = {}

function Chapter1.tick(now: number, wave: number)
${indent(ch1, 1)}
end

return Chapter1
`);

const SPAWN_ALIASES = [
  "spawnChapter2DogSwarm", "spawnChapter2MidBoss", "spawnChapter2OpeningSwarm",
  "spawnChapter2MidSwarm", "spawnChapter2FinalHorde", "spawnChapter2FinalBoss",
  "spawnChapter2ShieldPack", "spawnChapter2SmallMidBoss", "spawnChapter2ZombieSwarm",
  "spawnChapter3BigZombie", "spawnChapter3BigZombieSwarm", "spawnChapter3DogSwarm",
  "spawnChapter3DogSwarmEven",
];

function aliasSpawns(code) {
  let out = code;
  for (const name of SPAWN_ALIASES) {
    out = out.replace(new RegExp(`\\b${name}\\(`, "g"), `Spawning.${name}(`);
  }
  return out;
}

const ch2Aliased = aliasSpawns(ch2);
const ch3Aliased = aliasSpawns(ch3);

writeFile("RoundTimeline/Chapter2.luau", `local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local Context = require(script.Parent.Parent.Context)
local StateSync = require(script.Parent.Parent.StateSync)
local Spawning = require(script.Parent.Parent.Spawning)
local EventFlags = require(script.Parent.Parent.EventFlags)

local ctx = Context
local setState = StateSync.setState
local waveLocalElapsed = Spawning.waveLocalElapsed
local Ev = EventFlags

local Chapter2 = {}

function Chapter2.tick(now: number, wave: number)
${indent(ch2Aliased, 1)}
end

return Chapter2
`);

writeFile("RoundTimeline/Chapter3.luau", `local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberGate = require(script.Parent.Parent.Parent.NumberGate)
local SupplyService = require(script.Parent.Parent.Parent.SupplyService)
local SpikeTrap = require(script.Parent.Parent.Parent.SpikeTrap)
local Context = require(script.Parent.Parent.Context)
local StateSync = require(script.Parent.Parent.StateSync)
local Spawning = require(script.Parent.Parent.Spawning)
local EventFlags = require(script.Parent.Parent.EventFlags)

local ctx = Context
local setState = StateSync.setState
local waveLocalElapsed = Spawning.waveLocalElapsed
local Ev = EventFlags

local Chapter3 = {}

function Chapter3.tick(now: number, wave: number)
${indent(ch3Aliased, 1)}
end

return Chapter3
`);

writeFile("Heartbeat.luau", `local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.Parent.ZombieService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local SpikeTrap = require(script.Parent.Parent.SpikeTrap)
local CombatService = require(script.Parent.Parent.CombatService)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Character = require(script.Parent.Character)
local Spawning = require(script.Parent.Spawning)
local Gates = require(script.Parent.Gates)
local Lifecycle = require(script.Parent.Lifecycle)
local Combat = require(script.Parent.Combat)
local EventFlags = require(script.Parent.EventFlags)
local Chapter1 = require(script.Parent.RoundTimeline.Chapter1)
local Chapter2 = require(script.Parent.RoundTimeline.Chapter2)
local Chapter3 = require(script.Parent.RoundTimeline.Chapter3)

local ctx = Context
local setState = StateSync.setState
local shiftPausedTimers = StateSync.shiftPausedTimers
local getLeaderPosition = Character.getLeaderPosition
local isLanePhase = Character.isLanePhase
local currentStats = Spawning.currentStats
local spawnOne = Spawning.spawnOne
local applyRoundFeatures = Gates.applyRoundFeatures
local beginChapterClear = Lifecycle.beginChapterClear
local restoreGun = Combat.restoreGun
local tryFire = Combat.tryFire
local applySpikeDamage = Combat.applySpikeDamage
local Ev = EventFlags

local Heartbeat = {}

function Heartbeat.connect()
	if ctx.heartbeatConn then
		ctx.heartbeatConn:Disconnect()
	end

	ctx.heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local playerPos = getLeaderPosition()

${indent(hb1, 2)}

			local wave = (ctx.stateFolder:GetAttribute("Wave") :: number?) or 1
			if Config.chapter() <= 1 then
				Chapter1.tick(now, wave)
			end
			if Config.chapter() == 2 then
				Chapter2.tick(now, wave)
			end
			if Config.chapter() == 3 then
				Chapter3.tick(now, wave)
			end

${indent(hb2, 2)}
	end)
end

return Heartbeat
`);

const orchStart = extract(2001, 2220)
  .replace(/^function GameService\.start\(remotes\)/m, "function Orchestrator.start(remotes)")
  .replace(/onZombieDied\(\)/g, "Debug.onZombieDied()")
  .replace(/throwRockAt\(/g, "Combat.throwRockAt(")
  .replace(/damagePlayersNear\(/g, "Combat.damagePlayersNear(")
  .replace(/damagePlayers\(/g, "Combat.damagePlayers(")
  .replace(/grantBombs\(\)/g, "Combat.grantBombs()")
  .replace(/grantSniper\(\)/g, "Combat.grantSniper()")
  .replace(/grantShotgun\(\)/g, "Combat.grantShotgun()")
  .replace(/grantFireBoost\(\)/g, "Combat.grantFireBoost()")
  .replace(/jumpToRound\(/g, "Debug.jumpToRound(")
  .replace(/debugEnterChapter\(/g, "Debug.debugEnterChapter(")
  .replace(/setupPlayer\(/g, "Lifecycle.setupPlayer(")
  .replace(/bindStartPad\(\)/g, "Lifecycle.bindStartPad()")
  .replace(/if heartbeatConn then/m, "if ctx.heartbeatConn then")
  .replace(/heartbeatConn:Disconnect\(\)/m, "ctx.heartbeatConn:Disconnect()");

writeFile("Orchestrator.luau", `local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.Parent.ZombieService)
local CombatService = require(script.Parent.Parent.CombatService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local NumberGate = require(script.Parent.Parent.NumberGate)
local Context = require(script.Parent.Context)
local StateSync = require(script.Parent.StateSync)
local Lifecycle = require(script.Parent.Lifecycle)
local Combat = require(script.Parent.Combat)
local Debug = require(script.Parent.Debug)
local EventFlags = require(script.Parent.EventFlags)
local Heartbeat = require(script.Parent.Heartbeat)

local ctx = Context
local setState = StateSync.setState
local Ev = EventFlags

local Orchestrator = {}

${orchStart}
	Heartbeat.connect()
end

return Orchestrator
`);

writeFile("init.luau", `local Orchestrator = require(script.Orchestrator)

return {
\tstart = Orchestrator.start,
}
`);

writeFile("../GameService.luau", "return require(script.Game)\n");

console.log("Generated Game modules");
