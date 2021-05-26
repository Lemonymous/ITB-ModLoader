GAME_STATE_MAIN_MENU = 0
GAME_STATE_MAP = 1
GAME_STATE_ISLAND = 2
GAME_STATE_MISSION = 3
GAME_STATE_MISSION_TEST = 4

local currentState = GAME_STATE_MAIN_MENU

function modApi:getGameState()
	return currentState
end

local function setGameState(state)
	local oldState = currentState

	if currentState ~= state then
		currentState = state
		modApi.events.onGameStateChanged:dispatch(currentState, oldState)
	end

	if GAME then
		GAME.currentState = currentState
	end
end

modApi.events.onGameExited:subscribe(function()
	setGameState(GAME_STATE_MAIN_MENU)
end)

local function updateGameState()
	mission = GetCurrentMission()

	if not Game then
		setGameState(GAME_STATE_MAIN_MENU)
	elseif mission == Mission_Test then
		setGameState(GAME_STATE_MISSION_TEST)
	elseif mission then
		setGameState(GAME_STATE_MISSION)
	elseif RegionData.podRewards then
		setGameState(GAME_STATE_ISLAND)
	else
		setGameState(GAME_STATE_MAP)
	end
end

modApi.events.onSaveDataUpdated:subscribe(updateGameState)
modApi.events.onMissionChanged:subscribe(updateGameState)
