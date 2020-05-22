modApi = {}
sdlext = {}
mod_loader = {}


modApi.hooks = {}
modApi.hooks.preMissionAvailable = Event()
modApi.hooks.postMissionAvailable = Event()
modApi.hooks.preEnvironment = Event()
modApi.hooks.postEnvironment = Event()
modApi.hooks.nextTurn = Event()
modApi.hooks.voiceEvent = Event()
modApi.hooks.preIslandSelection = Event()
modApi.hooks.postIslandSelection = Event()
modApi.hooks.missionUpdate = Event()
modApi.hooks.missionStart = Event()
modApi.hooks.missionEnd = Event()
modApi.hooks.missionNextPhaseCreated = Event()
modApi.hooks.preStartGame = Event()
modApi.hooks.postStartGame = Event()
modApi.hooks.preLoadGame = Event()
modApi.hooks.postLoadGame = Event()
modApi.hooks.saveGame = Event()
modApi.hooks.vekSpawnAdded = Event()
modApi.hooks.vekSpawnRemoved = Event()
modApi.hooks.preprocessVekRetreat = Event()
modApi.hooks.processVekRetreat = Event()
modApi.hooks.postprocessVekRetreat = Event()
modApi.hooks.testMechEntered = Event()
modApi.hooks.testMechExited = Event()
modApi.hooks.saveDataUpdated = Event()

modApi.events = {}
modApi.events.modsInitialized = Event()
modApi.events.modsFirstLoaded = Event()
modApi.events.initialLoadingFinished = Event()
modApi.events.modsLoaded = Event()
modApi.events.uiRootCreated = Event()
modApi.events.gameWindowResized = Event()
modApi.events.mainMenuEntered = Event()
modApi.events.mainMenuExited = Event()
modApi.events.hangarEntered = Event()
modApi.events.hangarExited = Event()
modApi.events.hangarLeaving = Event()
--[[
	Fired when the Continue button is clicked.
--]]
modApi.events.continueClick = Event()
--[[
	Fired when the New Game button is clicked.
	This does NOT account for the confirmation box
	that pops up when you have a game in progress.
--]]
modApi.events.newGameClick = Event()
--[[
	Fired when the leaves the Main Menu for the Hangar
--]]
modApi.events.mainMenuLeaving = Event()
modApi.events.gameEntered = Event()
modApi.events.gameExited = Event()
modApi.events.consoleToggled = Event()
modApi.events.frameDrawn = Event()
modApi.events.windowVisible = Event()
modApi.events.settingsChanged = Event()

modApi.events.shiftToggled = Event()
modApi.events.altToggled = Event()
modApi.events.ctrlToggled = Event()

modApi.events.preKeyDown = InputEvent()
modApi.events.preKeyUp = InputEvent()
modApi.events.postKeyDown = InputEvent()
modApi.events.postKeyUp = InputEvent()


-- ///////////////////////////////////////////////////////////////////////////////////
-- Backwards compatibility with old hooks system

local function addHookCompat(name, event)
	local Name = name:gsub("^.", string.upper) -- capitalize first letter

	modApi["add".. Name .."Hook"] = function(self, fn)
		return event:subscribe(fn)
	end

	modApi["rem".. Name .."Hook"] = function(self, fn)
		return event:unsubscribe(fn)
	end

	modApi["fire".. Name .."Hooks"] = function(self, ...)
		event:fire(...)
	end
end

for name, event in pairs(modApi.hooks) do
	addHookCompat(name, event)
end
addHookCompat("modsInitialized", modApi.events.modsInitialized)
addHookCompat("modsFirstLoaded", modApi.events.modsFirstLoaded)
addHookCompat("modsLoaded", modApi.events.modsLoaded)

for name, event in pairs(modApi.events) do
	local Name = name:gsub("^.", string.upper) -- capitalize first letter

	sdlext["add".. Name .."Hook"] = function(fn)
		return event:subscribe(fn)
	end
end

function modApi:addMissionAvailableHook(fn)
	self:addPostMissionAvailableHook(fn)
end
