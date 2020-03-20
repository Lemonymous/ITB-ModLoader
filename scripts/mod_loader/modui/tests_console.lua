-- TODO
-- add ui elements for reporting test results, which tests passed and which failed, etc.
-- figure out a cleaner way to handle which tests are selected for running
-- collapse/expand buttons facing the right way

TestConsole = {}

TestConsole.colors = {}
TestConsole.colors.border_ok = sdl.rgb(64, 196, 64)
TestConsole.colors.border_running = sdl.rgb(192, 192, 64)
TestConsole.colors.border_fail = sdl.rgb(192, 32, 32)

deco.surfaces.markTick = sdlext.getSurface({
	path = "resources/mods/ui/mark-tick.png",
	colormap = {
		sdl.rgb(255, 255, 255),
		TestConsole.colors.border_ok
	}
})
deco.surfaces.markCross = sdlext.getSurface({
	path = "resources/mods/ui/mark-cross.png",
	colormap = {
		sdl.rgb(255, 255, 255),
		TestConsole.colors.border_fail
	}
})

local resetEvent = nil

local subscriptions = {}
local function cleanup()
	for _, sub in ipairs(subscriptions) do
		sub:unsubscribe()
	end
	subscriptions = {}
end

local selectedTestsMap = nil
local function toggleSelection(entry)
	if selectedTestsMap[entry] == nil then
		selectedTestsMap[entry] = true
	end
	selectedTestsMap[entry] = not selectedTestsMap[entry]
end
local function isSelected(entry)
	if selectedTestsMap[entry] == nil then
		selectedTestsMap[entry] = true
	end
	return selectedTestsMap[entry]
end

local function isTestSuiteElement(element)
	return element.__index == UiBoxLayout
end

local function updateSelectedTest(testHolder, checked)
	local checkbox = testHolder.children[1]

	checkbox.checked = checked
	selectedTestsMap[testHolder.entry] = checked
end

local updateSelectedItems = nil
local function updateSelectedTestsuite(testsuiteHolder, checked)
	local header = testsuiteHolder.children[1]
	local content = testsuiteHolder.children[2]

	header.children[2].checked = checked
	selectedTestsMap[testsuiteHolder.entry] = checked

	for _, child in ipairs(content.children) do
		updateSelectedItems(child, checked)
	end
end

local rootTestsuiteHolder = nil
updateSelectedItems = function(holder, checked)
	holder = holder or rootTestsuiteHolder
	checked = checked or isSelected(holder.entry)

	if isTestSuiteElement(holder) then
		updateSelectedTestsuite(holder, checked)
	else
		updateSelectedTest(holder, checked)
	end
end

local function buildTestUi(testEntry)
	local entryHolder = UiWeightLayout()
			:width(1):heightpx(41)
			:addTo(entryBoxHolder)

	local checkbox = UiCheckbox()
		:width(1):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(),
			DecoAlign(4, 2),
			DecoText(testEntry.name)
		})
		:addTo(entryHolder)
	checkbox.checked = true

	sdlext.addButtonSoundHandlers(checkbox, function()
		toggleSelection(testEntry)
		updateSelectedItems(entryHolder)
	end)

	local statusBox = Ui()
		:widthpx(41):heightpx(41)
		:decorate({
			DecoButton(),
			DecoSurface()
		})
		:addTo(entryHolder)
	statusBox.disabled = true

	entryHolder.entry = testEntry
	entryHolder.checkbox = checkbox
	entryHolder.statusBox = statusBox

	entryHolder.onReset = function()
		statusBox.decorations[1].bordercolor = deco.colors.buttonborder
		statusBox.decorations[2].surface = nil
		statusBox.disabled = true
		statusBox:settooltip("")

		statusBox.onMouseEnter = Ui.onMouseEnter
		statusBox.onclicked = Ui.onMouseEnter
	end
	entryHolder.onTestStarted = function(entry)
		if entry.name == testEntry.name then
			statusBox.decorations[1].bordercolor = TestConsole.colors.border_running
		end
	end
	entryHolder.onTestSuccess = function(entry, resultTable)
		if entry.name == testEntry.name then
			statusBox.decorations[1].bordercolor = deco.colors.buttonborder
			statusBox.decorations[2].surface = deco.surfaces.markTick
		end
	end
	entryHolder.onTestFailed = function(entry, resultTable)
		if entry.name == testEntry.name then
			statusBox.decorations[1].bordercolor = deco.colors.buttonborder
			statusBox.decorations[2].surface = deco.surfaces.markCross
			statusBox.disabled = false
			statusBox:settooltip("This test has failed. Click to bring up a detailed summary.")

			sdlext.addButtonSoundHandlers(statusBox, function ()
				sdlext.showTextDialog("Failure Summary", resultTable.result, 1000, 1000)
			end)
		end
	end

	return entryHolder
end

local function buildTestsuiteUi(testsuiteEntry, isNestedTestsuite)
	indentLevel = indentLevel or 0
	local tests, testsuites = testsuiteEntry.suite:EnumerateTests()

	local entryBoxHolder = UiBoxLayout()
		:vgap(5)
		:width(1)

	-- Use UiWeightLayout so that we don't have to manually decide each element's size,
	-- just tell it to take up the remainder of horizontal space.
	local entryHeaderHolder = UiWeightLayout()
		:width(1):heightpx(41)
		:addTo(entryBoxHolder)

	local entryContentHolder = UiBoxLayout()
		:vgap(5)
		:width(1)
		:addTo(entryBoxHolder)

	if isNestedTestsuite then
		-- Have child elements be indented one level to the right, for visual clarity,
		-- except for the root element, since its children are supposed to be only other
		-- testsuites, which already have a collapse button that effectively indents them.
		entryContentHolder.padl = 46
	end

	-- Add a collapse button for nested testsuites.
	-- This is just a checkbox, but skinned differently.
	local collapse = UiCheckbox()
		:widthpx(41):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(
				deco.surfaces.dropdownOpenRight,
				deco.surfaces.dropdownClosed,
				deco.surfaces.dropdownOpenRightHovered,
				deco.surfaces.dropdownClosedHovered
			)
		})
		:addTo(entryHeaderHolder)
	if not isNestedTestsuite then
		collapse.visible = false
	end

	sdlext.addButtonSoundHandlers(collapse, function()
		entryContentHolder.visible = not collapse.checked

		entryBoxHolder:relayout()
	end)

	local checkbox = UiCheckbox()
		:width(1):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(),
			DecoAlign(4, 2),
			DecoText(testsuiteEntry.name)
		})
		:addTo(entryHeaderHolder)
	checkbox.checked = true

	sdlext.addButtonSoundHandlers(checkbox, function()
		toggleSelection(testsuiteEntry)
		updateSelectedItems(entryBoxHolder)
	end)

	local statusBox = Ui()
		:widthpx(200):heightpx(41)
		:decorate({
			DecoButton(),
			DecoAlign(0, 2),
			DecoText()
		})
		:addTo(entryHeaderHolder)

	sdlext.addButtonSoundHandlers(statusBox, function() end)

	entryHeaderHolder.collapse = collapse
	entryHeaderHolder.checkbox = checkbox
	entryHeaderHolder.statusBox = statusBox

	-- Build ui elements for tests in this testsuite
	for _, entry in ipairs(tests) do
		local testUi = buildTestUi(entry)
			:addTo(entryContentHolder)

		table.insert(subscriptions, resetEvent:subscribe(testUi.onReset))
		table.insert(subscriptions, testsuiteEntry.suite.onTestStarted:subscribe(testUi.onTestStarted))
		table.insert(subscriptions, testsuiteEntry.suite.onTestSuccess:subscribe(testUi.onTestSuccess))
		table.insert(subscriptions, testsuiteEntry.suite.onTestFailed:subscribe(testUi.onTestFailed))
	end

	-- Recursively build ui elements for nested testsuites in this testsuite
	for i, entry in ipairs(testsuites) do
		buildTestsuiteUi(entry, true)
			:addTo(entryContentHolder)
	end

	entryBoxHolder.entry = testsuiteEntry
	entryBoxHolder.header = entryHeaderHolder
	entryBoxHolder.content = entryContentHolder

	return entryBoxHolder
end

local function buildTestingConsoleContent(scroll)
	local entry = {
		name = "Root Testsuite",
		suite = Testsuites
	}

	rootTestsuiteHolder = buildTestsuiteUi(entry)
		:addTo(scroll)
end

local function buildTestingConsoleButtons(buttonLayout)
	local btnRunAll = sdlext.buildButton(
		"Run All",
		nil,
		function()
			resetEvent:fire()
			Testsuites:RunAllTests()
		end
	)
	btnRunAll:heightpx(40)
	btnRunAll:addTo(buttonLayout)

	local btnRunSelected = sdlext.buildButton(
		"Run Selected",
		nil,
		function()
			resetEvent:fire()
			-- TODO
			LOG("Run Selected clicked")
		end
	)
	btnRunSelected:heightpx(40)
	btnRunSelected:addTo(buttonLayout)
end

local function showTestingConsole()
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = function()
			cleanup()
			rootTestsuiteHolder = nil
			selectedTestsMap = nil
		end

		selectedTestsMap = {}
		local frame = sdlext.buildButtonDialog(
			modApi:getText("TestingConsole_FrameTitle"),
			0.6 * ScreenSizeX(), 0.8 * ScreenSizeY(),
			buildTestingConsoleContent,
			buildTestingConsoleButtons
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

local function calculateToggleButtonPosition()
	-- Use the Buttons element maintained by the game itself.
	-- This way we don't have to worry about calculating locations
	-- for our UI, we can just offset based on the game's own UI
	-- whenever the screen is resized.
	local btnEndTurn = Buttons["action_end"]
	return btnEndTurn.pos.x, btnEndTurn.pos.y
end

local function createToggleButton(root)
	local button = sdlext.buildButton(
		modApi:getText("TestingConsole_ToggleButton_Text"),
		modApi:getText("TestingConsole_ToggleButton_Tooltip"),
		function()
			showTestingConsole()
		end
	)
	:widthpx(302):heightpx(40)
	:pospx(calculateToggleButtonPosition())
	:addTo(root)

	button.draw = function(self, screen)
		-- TODO mod loader config option to enable development mode
		self.visible = not sdlext.isConsoleOpen() and IsTestMechScenario()

		Ui.draw(self, screen)
	end

	sdlext.addSettingsChangedHook(function()
		button:pospx(calculateToggleButtonPosition())
	end)

	sdlext.addGameWindowResizedHook(function()
		button:pospx(calculateToggleButtonPosition())
	end)
end

sdlext.addUiRootCreatedHook(function(screen, root)
	resetEvent = Event()
	createToggleButton(root)
end)
