local Context = require(script.Parent.Context)
local ZombieService = require(script.Parent.Parent.ZombieService)
local SupplyService = require(script.Parent.Parent.SupplyService)
local CombatService = require(script.Parent.Parent.CombatService)

local ctx = Context
local StateSync = {}

function StateSync.setState(key: string, value: any)
	ctx.stateFolder:SetAttribute(key, value)
end

function StateSync.shiftPausedTimers(duration: number)
	ctx.matchStart += duration
	if ctx.lastSpawnAt > 0 then ctx.lastSpawnAt += duration end
	if ctx.lastSupplySpawnAt > 0 then ctx.lastSupplySpawnAt += duration end
	if ctx.lastBombSpawnAt > 0 then ctx.lastBombSpawnAt += duration end
	if ctx.lastGateSpawnAt > 0 then ctx.lastGateSpawnAt += duration end
	if ctx.lastSidePathSpawnAt > 0 then ctx.lastSidePathSpawnAt += duration end
	if ctx.introGateDueAt > 0 then ctx.introGateDueAt += duration end
	if ctx.extraX2DueAt > 0 then ctx.extraX2DueAt += duration end
	if ctx.chapter2PlusDueAt > 0 then ctx.chapter2PlusDueAt += duration end
	if ctx.chapter2X2DueAt > 0 then ctx.chapter2X2DueAt += duration end
	if ctx.lastMolotovAt > 0 then ctx.lastMolotovAt += duration end
	for _, data in ctx.playerData do
		if data.lastFire > 0 then data.lastFire += duration end
		if data.bombUntil > 0 then data.bombUntil += duration end
		if data.sniperUntil > 0 then data.sniperUntil += duration end
		if data.shotgunUntil > 0 then data.shotgunUntil += duration end
	end
	ZombieService.shiftTimers(duration)
	SupplyService.shiftTimers(duration)
	CombatService.shiftTimers(duration)
end

return StateSync
