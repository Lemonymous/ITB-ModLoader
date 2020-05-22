--[[
	Root UI object provided by the modloader. 
--]]

local bgRobot = sdlext.getSurface({ path = "img/main_menus/bg3.png" })
local bgHangar = sdlext.getSurface({ path = "img/strategy/hangar_main.png" })
local loading = sdlext.getSurface({ path = "img/main_menus/Loading_main.png" })
local cursor = sdlext.getSurface({ path = "resources/mods/ui/pointer-large.png" })

-- //////////////////////////////////////////////////////////////////////

local isInMainMenu = false
function sdlext.isMainMenu()
	return isInMainMenu
end

local isInHangar = false
function sdlext.isHangar()
	return isInHangar
end

local isInGame = false
function sdlext.isGame()
	return isInGame
end

local consoleOpen = false
function sdlext.isConsoleOpen()
	return consoleOpen
end

function GetScreenCenter()
	return Point(ScreenSizeX() / 2, ScreenSizeY() / 2)
end

-- //////////////////////////////////////////////////////////////////////
-- UI hooks

local initialLoadingFinishedHookFired = false

local isShiftHeld = false
function sdlext.isShiftDown()
	return isShiftHeld
end

local isAltHeld = false
function sdlext.isAltDown()
	return isAltHeld
end

local isCtrlHeld = false
function sdlext.isCtrlDown()
	return isCtrlHeld
end

local wasOptionsWindow = false
local isOptionsWindow = false
modApi.events.frameDrawn:subscribe(function(screen)
	if wasOptionsWindow and not isOptionsWindow then
		-- Settings window was visible, but isn't anymore.
		-- This also triggers when the player hovers over
		-- an option in the options box, but this heuristic
		-- is good enough (at least we're not reloading
		-- the settings file every damn frame)
		local oldSettings = Settings
		Settings = modApi:loadSettings()

		if not compare_tables(oldSettings, Settings) then
			modApi.events.settingsChanged:fire(oldSettings, Settings)
		end
	end

	wasOptionsWindow = isOptionsWindow
	isOptionsWindow = false
end)

local optionsBox = Boxes.escape_options_box
local profileBox = Boxes.profile_window
local function adjustForGameVersion()
	if modApi:isVersion("1.2.20", modApi:getGameVersion()) then
		--
	end
	if modApi:isVersion("1.1.22", modApi:getGameVersion()) then
		optionsBox = Rect2D(optionsBox)
		optionsBox.w = optionsBox.w + 300
	end
end

modApi.events.windowVisible:subscribe(function(screen, x, y, w, h)
	if
		(w == optionsBox.w and h == optionsBox.h) or
		(w == profileBox.w and h == profileBox.h)
	then
		isOptionsWindow = true
	end
end)

modApi.events.preKeyDown:subscribe(function(keycode)
	if keycode == SDLKeycodes.SHIFT_LEFT or keycode == SDLKeycodes.SHIFT_RIGHT then
		isShiftHeld = true
		modApi.events.shiftToggled:fire(isShiftHeld)
	elseif keycode == SDLKeycodes.ALT_LEFT or keycode == SDLKeycodes.ALT_RIGHT then
		isAltHeld = true
		modApi.events.altToggled:fire(isAltHeld)
	elseif keycode == SDLKeycodes.CTRL_LEFT or keycode == SDLKeycodes.CTRL_RIGHT then
		isCtrlHeld = true
		modApi.events.ctrlToggled:fire(isCtrlHeld)
	end

	-- don't process other keypresses while the console is open
	if sdlext.isConsoleOpen() then
		return false
	end

	if keycode == Settings.hotkeys[23] then -- fullscreen hotkey
		Settings.fullscreen = 1 - Settings.fullscreen

		-- Game doesn't update settings.lua with new fullscreen status...
		-- Only writes to the file once the options menu is dismissed.
		modApi:writeFile(
			GetSavedataLocation() .. "settings.lua",
			"Settings = " .. save_table(Settings)
		)
		isOptionsWindow = true
	end

	return false
end)

modApi.events.preKeyUp:subscribe(function(keycode)
	if keycode == SDLKeycodes.SHIFT_LEFT or keycode == SDLKeycodes.SHIFT_RIGHT then
		isShiftHeld = false
		modApi.events.shiftToggled:fire(isShiftHeld)
	elseif keycode == SDLKeycodes.ALT_LEFT or keycode == SDLKeycodes.ALT_RIGHT then
		isAltHeld = false
		modApi.events.altToggled:fire(isAltHeld)
	elseif keycode == SDLKeycodes.CTRL_LEFT or keycode == SDLKeycodes.CTRL_RIGHT then
		isCtrlHeld = false
		modApi.events.ctrlToggled:fire(isCtrlHeld)
	end
	
	-- don't process other keypresses while the console is open
	if sdlext.isConsoleOpen() then
		return false
	end

	return false
end)

modApi.events.settingsChanged:subscribe(function(old, new)
	-- When deleting the currently active profile, last_profile is nil
	-- Just copy it over from the previous table, since it holds the correct value
	if not new.last_profile or new.last_profile == "" then
		new.last_profile = old.last_profile
	end

	if old.last_profile ~= new.last_profile then
		Hangar_lastProfileHadSecretPilots = IsSecretPilotsUnlocked()
		Profile = modApi:loadProfile()
	end
end)

modApi.events.gameWindowResized:subscribe(function(screen, oldSize)
	sdlext.getUiRoot():widthpx(screen:w()):heightpx(screen:h())
end)

-- //////////////////////////////////////////////////////////////////////

local uiRoot = nil
function sdlext.getUiRoot()
	return uiRoot
end

local srfBotLeft, srfTopRight
local function buildUiRoot(screen)
	adjustForGameVersion()

	uiRoot = UiRoot():widthpx(screen:w()):heightpx(screen:h())

	uiRoot.wheel = function(self, mx, my, scroll)
		if sdlext.isConsoleOpen() and mod_loader.logger.scroll then
			if isShiftHeld then
				scroll = scroll * 20
			end

			mod_loader.logger:scroll(-scroll)
			
			return true
		end

		return Ui.wheel(self, mx, my, scroll)
	end

	uiRoot.keydown = function(self, keycode)
		if sdlext.isConsoleOpen() and mod_loader.logger.scroll then
			if keycode == SDLKeycodes.PAGEUP then
				if isShiftHeld then
					mod_loader.logger:scrollToStart()
				else
					mod_loader.logger:scroll(-20)
				end

				return true
			elseif keycode == SDLKeycodes.PAGEDOWN then
				if isShiftHeld then
					mod_loader.logger:scrollToEnd()
				else
					mod_loader.logger:scroll(20)
				end

				return true
			end
		end

		return Ui.keydown(self, keycode)
	end

	srfBotLeft = sdlext.getSurface({ path = "img/ui/tooltipshadow_0.png" })
	srfTopRight = sdlext.getSurface({ path = "img/ui/tooltipshadow_4.png" })

	modApi.events.uiRootCreated:fire(screen, uiRoot)
	modApi.events.uiRootCreated:unsubscribeAll()
end

local isTestMech = false
local lastScreenSize = { x = ScreenSizeX(), y = ScreenSizeY() }
sdlext.CurrentWindowRect = sdl.rect(0, 0, 0, 0)
sdlext.LastWindowRect = sdl.rect(0, 0, 0, 0)
MOD_API_DRAW_HOOK = sdl.drawHook(function(screen)
	local wasMainMenu = isInMainMenu
	local wasHangar = isInHangar
	local wasGame = isInGame
	local wasTestMech = isTestMech

	isInMainMenu = bgRobot:wasDrawn() and bgRobot.x < screen:w() and not bgHangar:wasDrawn()
	isInHangar = bgHangar:wasDrawn()
	isInGame = Game ~= nil
	isTestMech = IsTestMechScenario()

	if not initialLoadingFinishedHookFired and bgRobot:wasDrawn() then
		initialLoadingFinishedHookFired = true
		modApi.events.initialLoadingFinished:fire()
		modApi.events.initialLoadingFinished:unsubscribeAll()
	end

	-- ////////////////////////////////////////////////////////
	-- Hooks

	if not uiRoot then
		buildUiRoot(screen)
	end

	if
		lastScreenSize.x ~= screen:w() or
		lastScreenSize.y ~= screen:h()
	then
		local oldSize = copy_table(lastScreenSize)
		modApi.events.gameWindowResized:fire(screen, oldSize)

		lastScreenSize.x = screen:w()
		lastScreenSize.y = screen:h()
	end

	if wasMainMenu and not isInMainMenu then
		modApi.events.mainMenuExited:fire(screen)
	elseif wasHangar and not isInHangar then
		modApi.events.hangarExited:fire(screen)
	elseif wasGame and not isInGame then
		modApi.events.gameExited:fire(screen)
	end

	if not wasMainMenu and isInMainMenu then
		modApi.events.mainMenuEntered:fire(screen, wasHangar, wasGame)
	elseif not wasHangar and isInHangar then
		modApi.events.hangarEntered:fire(screen)
	elseif not wasGame and isInGame then
		modApi.events.gameEntered:fire(screen)
	end

	if wasTestMech and not isTestMech then
		Mission_Test:MissionEnd()
	end

	-- ////////////////////////////////////////////////////////

	local wx, wy, ww, wh
	if srfBotLeft:wasDrawn() and srfTopRight:wasDrawn() then
		wx = srfBotLeft.x
		wy = srfTopRight.y - 4
		ww = srfTopRight.x - wx
		wh = srfBotLeft.y  - wy
	end

	if not rect_equals(sdlext.CurrentWindowRect, wx, wy, ww, wh) then
		rect_set(sdlext.LastWindowRect, sdlext.CurrentWindowRect)
	end

	rect_set(sdlext.CurrentWindowRect, wx, wy, ww, wh)
	if wx ~= nil then
		modApi.events.windowVisible:fire(screen, wx, wy, ww, wh)
	end

	uiRoot:draw(screen)

	modApi.events.frameDrawn:fire(screen)

	if not loading:wasDrawn() then
		screen:blit(cursor, nil, sdl.mouse.x(), sdl.mouse.y())
	end
end)

local function evaluateConsoleToggled(keycode)
	if keycode == SDLKeycodes.BACKQUOTE then
		consoleOpen = not consoleOpen

		modApi.events.consoleToggled:fire(consoleOpen)
	elseif consoleOpen and sdlext.isShiftDown() and (keycode == SDLKeycodes.RETURN or keycode == SDLKeycodes.RETURN2) then
		consoleOpen = false

		modApi.events.consoleToggled:fire(consoleOpen)
	end
end

MOD_API_EVENT_HOOK = sdl.eventHook(function(event)
	local type = event:type()
	local keycode = event:keycode()

	if type == sdl.events.keydown then
		local eventHandled = modApi.events.preKeyDown:fire(keycode)
		if eventHandled then
			return true
		end
	elseif type == sdl.events.keyup then
		local eventHandled = modApi.events.preKeyUp:fire(keycode)
		if eventHandled then
			return true
		end
	end

	local uiEventHandled = uiRoot:event(event)

	if not uiEventHandled then
		if type == sdl.events.keydown then
			local eventHandled = modApi.events.postKeyDown:fire(keycode)
			if eventHandled then
				return true
			end

			evaluateConsoleToggled(keycode)
		elseif type == sdl.events.keyup then
			local eventHandled = modApi.events.postKeyUp:fire(keycode)
			if eventHandled then
				return true
			end
		end
	end

	return uiEventHandled
end)
