-- Round event flags
local EventFlags = {
	Ch2 = {
		R1SniperSpawned = false,
		R1PlusSpawned = false,
		R1X2Spawned = false,
		R2MinusSpawned = false,
		R2BombSpawned = false,
		R2Plus1Spawned = false,
		R2SniperSpawned = false,
		R2Plus2Spawned = false,
		R3PlusSpawned = false,
		R3AllySpawned = false,
		R3Crate1Spawned = false,
		R3Minus1Spawned = false,
		R3Crate2Spawned = false,
		R3Minus2Spawned = false,
		R4CrateSpawned = false,
		R4X2Spawned = false,
		R4X2Collected = false,
		R4MinusSpawned = false,
		R4AllySpawned = false,
		R4DogSwarmSpawned = false,
		R5MidBoss1Spawned = false,
		R5MidBoss2Spawned = false,
		R5X2RetrySpawned = false,
		R5BombSpawned = false,
		R6SniperSpawned = false,
		R6Div2Spawned = false,
		R6BombSpawned = false,
		R6PlusSpawned = false,
		R6MolotovSpawned = false,
		R7SniperSpawned = false,
		R7MinusSpawned = false,
		R7PlusSpawned = false,
		R7BombSpawned = false,
		R7ShieldPackSpawned = false,
		R8Div2Spawned = false,
		R8SniperSpawned = false,
		R8X2Spawned = false,
		R8X2Collected = false,
		R8Sniper2Spawned = false,
		R8MinusSpawned = false,
		R8X2RetrySpawned = false,
		R8SwarmSpawned = false,
		R8PlusSpawned = false,
		R8BombSpawned = false,
		R8MolotovSpawned = false,
		R9MidBossSpawned = false,
		R9SniperSpawned = false,
		R9MinusSpawned = false,
		R9PlusSpawned = false,
		R9BombSpawned = false,
		R9ShieldPackSpawned = false,
		R9Sniper2Spawned = false,
		R9MolotovSpawned = false,
		R10BossSpawned = false,
		R10SniperSpawned = false,
		R10HordeSpawned = false,
		R10LateHordeSpawned = false,
		R10OpeningSpawned = false,
		R10MidSwarmSpawned = false,
		R10IntroShown = false,
	},
	Ch3 = {
		R1ShotgunSpawned = false,
		R1SpikeSpawned = false,
		R1SniperSpawned = false,
		R1PlusSpawned = false,
		R1Shotgun2Spawned = false,
		R2MinusSpawned = false,
		R2BombSpawned = false,
		R2BigRightSpawned = false,
		R2BigLeftSpawned = false,
		R2MolotovSpawned = false,
		R2DogSwarmSpawned = false,
		R2SpikeSpawned = false,
		R2SniperSpawned = false,
		R3FogWarnShown = false,
		R3FogActive = false,
		R3FogEndAt = 0,
		R3SniperSpawned = false,
		R3X2Spawned = false,
		R3X2Collected = false,
		R3X2RetrySpawned = false,
		R3SpikeSpawned = false,
		R4AllySpawned = false,
		R4FireBoostSpawned = false,
		R4BigSwarmStarted = false,
		R4MolotovSpawned = false,
		R4PlusSpawned = false,
		R4DogSwarmStarted = false,
		R5FlashbangSpawned = false,
		R5HordeActive = false,
		R5SniperSpawned = false,
		R5ShotgunSpawned = false,
		R5MinusSpawned = false,
		R5MidBossSpawned = false,
		R5ThrowerWaveStarted = false,
		R5SpikeSpawned = false,
		R6ShieldPackStarted = false,
		R6PlusSpawned = false,
		R6SniperSpawned = false,
		R6Mine0 = false,
		R6Mine15 = false,
		R6Mine30 = false,
		R6Mine50 = false,
		R6MolotovSpawned = false,
		R6BombSpawned = false,
		R6ThrowerDogStarted = false,
		R7BombSpawned = false,
		R7ShieldBoostActive = false,
		R7SpikeSpawned = false,
		R7Mine10 = false,
		R7MinusSpawned = false,
		R7ThrowerWaveStarted = false,
		R7MolotovSpawned = false,
		R7Mine33 = false,
		R7MidBossSpawned = false,
		R7MidBoss2Spawned = false,
		R8AllySpawned = false,
		R8X2Spawned = false,
		R8X2Collected = false,
		R8X2RetrySpawned = false,
		R8SniperSpawned = false,
		R8Mine25 = false,
		R8PlusSpawned = false,
		R8MixedWaveStarted = false,
	},
}

function EventFlags.resetCh2()
	local ch2 = EventFlags.Ch2
	for key, value in ch2 do
		ch2[key] = if typeof(value) == "number" then 0 else false
	end
end

function EventFlags.resetCh3Round1()
	local ch3 = EventFlags.Ch3
	ch3.R1ShotgunSpawned = false
	ch3.R1SpikeSpawned = false
	ch3.R1SniperSpawned = false
	ch3.R1PlusSpawned = false
	ch3.R1Shotgun2Spawned = false
end

function EventFlags.resetCh3Round2()
	local ch3 = EventFlags.Ch3
	ch3.R2MinusSpawned = false
	ch3.R2BombSpawned = false
	ch3.R2BigRightSpawned = false
	ch3.R2BigLeftSpawned = false
	ch3.R2MolotovSpawned = false
	ch3.R2DogSwarmSpawned = false
	ch3.R2SpikeSpawned = false
	ch3.R2SniperSpawned = false
end

function EventFlags.resetCh3Round3()
	local ch3 = EventFlags.Ch3
	ch3.R3FogWarnShown = false
	ch3.R3FogActive = false
	ch3.R3FogEndAt = 0
	ch3.R3SniperSpawned = false
	ch3.R3X2Spawned = false
	ch3.R3X2Collected = false
	ch3.R3X2RetrySpawned = false
	ch3.R3SpikeSpawned = false
end

function EventFlags.resetCh3Round4()
	local ch3 = EventFlags.Ch3
	ch3.R4AllySpawned = false
	ch3.R4FireBoostSpawned = false
	ch3.R4BigSwarmStarted = false
	ch3.R4MolotovSpawned = false
	ch3.R4PlusSpawned = false
	ch3.R4DogSwarmStarted = false
end

function EventFlags.resetCh3Round5()
	local ch3 = EventFlags.Ch3
	ch3.R5FlashbangSpawned = false
	ch3.R5HordeActive = false
	ch3.R5SniperSpawned = false
	ch3.R5ShotgunSpawned = false
	ch3.R5MinusSpawned = false
	ch3.R5MidBossSpawned = false
	ch3.R5ThrowerWaveStarted = false
	ch3.R5SpikeSpawned = false
end

function EventFlags.resetCh3Round6()
	local ch3 = EventFlags.Ch3
	ch3.R6ShieldPackStarted = false
	ch3.R6PlusSpawned = false
	ch3.R6SniperSpawned = false
	ch3.R6Mine0 = false
	ch3.R6Mine15 = false
	ch3.R6Mine30 = false
	ch3.R6Mine50 = false
	ch3.R6MolotovSpawned = false
	ch3.R6BombSpawned = false
	ch3.R6ThrowerDogStarted = false
end

function EventFlags.resetCh3Round7()
	local ch3 = EventFlags.Ch3
	ch3.R7BombSpawned = false
	ch3.R7ShieldBoostActive = false
	ch3.R7SpikeSpawned = false
	ch3.R7Mine10 = false
	ch3.R7MinusSpawned = false
	ch3.R7ThrowerWaveStarted = false
	ch3.R7MolotovSpawned = false
	ch3.R7Mine33 = false
	ch3.R7MidBossSpawned = false
	ch3.R7MidBoss2Spawned = false
end

function EventFlags.resetCh3Round8()
	local ch3 = EventFlags.Ch3
	ch3.R8AllySpawned = false
	ch3.R8X2Spawned = false
	ch3.R8X2Collected = false
	ch3.R8X2RetrySpawned = false
	ch3.R8SniperSpawned = false
	ch3.R8Mine25 = false
	ch3.R8PlusSpawned = false
	ch3.R8MixedWaveStarted = false
end

function EventFlags.resetCh3()
	EventFlags.resetCh3Round1()
	EventFlags.resetCh3Round2()
	EventFlags.resetCh3Round3()
	EventFlags.resetCh3Round4()
	EventFlags.resetCh3Round5()
	EventFlags.resetCh3Round6()
	EventFlags.resetCh3Round7()
	EventFlags.resetCh3Round8()
end

return EventFlags
