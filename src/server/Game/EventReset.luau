local EventFlags = require(script.Parent.EventFlags)
local Context = require(script.Parent.Context)

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

function EventReset.resetChapter3Round5Events(setState: (string, any) -> ())
	Ev.resetCh3Round5()
end

function EventReset.resetChapter3Round6Events(setState: (string, any) -> ())
	Ev.resetCh3Round6()
end

function EventReset.resetChapter3Round7Events(setState: (string, any) -> ())
	Ev.resetCh3Round7()
end

function EventReset.resetChapter3Round8Events(setState: (string, any) -> ())
	Ev.resetCh3Round8()
end

function EventReset.resetChapter3Round9Events(setState: (string, any) -> ())
	Ev.resetCh3Round9()
	Context.windSpeedScale = 1
	setState("Ch3WindActive", false)
end

function EventReset.resetChapter3Round10Events(setState: (string, any) -> ())
	Ev.resetCh3Round10()
	setState("Ch3FenceBreached", false)
end

function EventReset.resetChapter3Events(setState: (string, any) -> ())
	Ev.resetCh3()
	Context.windSpeedScale = 1
	setState("Ch3FogActive", false)
	setState("Ch3WindActive", false)
	setState("Ch3FenceBreached", false)
end

function EventReset.resetChapter2Round2Events()
	Ev.resetCh2()
end

return EventReset
