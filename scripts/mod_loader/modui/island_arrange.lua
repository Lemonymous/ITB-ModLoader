
--[[
-- TODO:
	Island slots:
		fill slots for all islands with island, corporation, tileset and enemylist
		
	Make a simplified view where islands can be slotted in how they are originally constructed.
	Add a button to swap between simple/complex view. Default is simple.
	
	Draggable element:
		highlight eligible elements when dragging
		add functionality for dropping element in island boxes
	
	Construct icon for enemylists; maybe try some things with different vek arranged behind each other
	
	Add randomize button to each island
	Add randomize toggle button which will randomize islands from all presets at game startup,
	..if there are no save games
	Add default button which set island choices back to Archive, RST, Pinnacle and Detritus
	
	Very unlikely ideas:
		Allow for creating custom presets for island/corp/tileset/enemylist combinations with the in-game ui
		Allow for creating new enemylists in game where you can drag-drop enemies in them
]]
deco.surfaces.minimizeboxChecked = sdlext.getSurface({ path = "resources/mods/ui/minimizebox-checked.png" })
deco.surfaces.minimizeboxUnchecked = sdlext.getSurface({ path = "resources/mods/ui/minimizebox-unchecked.png" })
deco.surfaces.minimizeboxHoveredChecked = sdlext.getSurface({ path = "resources/mods/ui/minimizebox-hovered-checked.png" })
deco.surfaces.minimizeboxHoveredUnchecked = sdlext.getSurface({ path = "resources/mods/ui/minimizebox-hovered-unchecked.png" })

-- TODO
--[[function loadIslandOrder()
	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		for k, v in ipairs(obj.islandOrder or {}) do
			order[v] = k
		end
	end)
end]]

-- TODO
--[[function saveIslandOrder(islands)
	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		obj.islandOrder = islands
	end)
end]]

local function getIslandBackgroundSurface(scale)
	return sdlext.getSurface({
		path = "img/strategy/waterbg.png",
		transformations = {
			{ scale = scale }
		}
	})
end

local function getIslandSurface(island_id, scale)
	return sdlext.getSurface({
		path = string.format("img/strategy/island1x_%s.png", island_id),
		transformations = {
			{ scale = scale }
		}
	})
end

local function getCEOSurface(corporation_id, scale)
	return sdlext.getSurface({
		path = string.format("img/portraits/ceo/%s", modApi.corporations[corporation_id].CEO_Image),
		transformations = {
			{ scale = scale }
		}
	})
end

local function getTilesetSurface(tileset_id, scale)
	return sdlext.getSurface({
		path = string.format("img/strategy/corp/%s_env.png", tileset_id),
		transformations = {
			{ scale = scale }
		}
	})
end

local function createUi()
	local islands = {}
	local corporations = {}
	local tilesets = {}
	local enemylists = {}

	local box = {
		size = math.vec2(2*61, 2*61),
		margin = math.vec2(10,10),
		border = 2,
		padding = 10
	}
	
	local header = {
		size = math.vec2(0, 25),
		padding = box.padding,
		border = box.border
	}
	
	local function UiHeader(text)
		return Ui()
			:width(1):heightpx(header.size.h + 2*header.padding)
			:decorate({
				DecoFrame(deco.colors.buttonhl, nil, box.border),
				DecoText(text, deco.uifont.title.font, deco.uifont.title.set)
			})
			:padding(header.padding)
	end
	
	for _, island in pairs(modApi.islands) do
		islands[#islands+1] = island:GetId()
	end
	
	for _, corporation in pairs(modApi.corporations) do
		corporations[#corporations+1] = corporation:GetId()
	end
	
	for _, tileset in pairs(modApi.tilesets) do
		tilesets[#tilesets+1] = tileset:GetId()
	end
	
	for _, enemylist in pairs(modApi.enemyLists) do
		enemylists[#enemylists+1] = enemylist:GetId()
	end
	
	local onExit = function(self)
		-- TODO
	end
	
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit
		
		local screen = sdl.screen()
		local isSmallIcons = screen:w() < 1280
		
		local draggedElement = Ui()
			:heightpx(box.size.h):widthpx(box.size.w)
			:bringToTop()
			:addTo(ui)
		draggedElement.visible = false
		draggedElement.translucent = true
		
		local elements = {}
		elements.main = {}
		elements.top = {}
		elements.bottom = {}
		elements.island_layouts = {}
		
		elements.main.area = UiWeightLayout()
			:width(0.8):height(0.9)
			:posCentered()
			:orientation(false)
			:vgap(2*box.padding)
			:addTo(ui)
			
		-- TOP AREA --
		--------------
		
		elements.top.area = Ui()
			:width(1):heightpx(2*box.size.h + header.size.h + 2*header.padding + 2*header.border)
			:addTo(elements.main.area)
			
		elements.top.layout = UiBoxLayout()
			:width(1):height(1)
			:anchor("center", "top")
			:hgap(math.min(box.size.w, (screen:w() - (8*box.size.w)) / 4))
			:addTo(elements.top.area)
			
		local function addSlotContainer(text)
			local island_layout = {}
			table.insert(elements.island_layouts, island_layout)
			
			island_layout.area = UiWeightLayout()
				:widthpx(2*box.size.w):height(1)
				:orientation(false)
				:vgap(0):hgap(0)
				:addTo(elements.top.layout)
				
			island_layout.header = UiHeader(text)
				:addTo(island_layout.area)
				
			island_layout.flow = UiFlowLayout()
				:width(1):height(1)
				:hgap(0):vgap(0)
				:addTo(island_layout.area)
			
			local function addSlot()
				return Ui()
					:widthpx(box.size.w):heightpx(box.size.h)
					:decorate({ DecoFrame(nil, nil, box.border) })
					:addTo(island_layout.flow)
			end
			
			for i = 1, 4 do
				island_layout[i] = addSlot()
			end
		end
		
		addSlotContainer("Archive")
		addSlotContainer("R.S.T.")
		addSlotContainer("Pinnacle")
		addSlotContainer("Detritus")
		
		-- BOTTOM AREA --
		-----------------
		
		elements.bottom.area = Ui()
			:width(1):height(1)
			:decorate({ DecoFrame(nil, nil, box.border) })
			:addTo(elements.main.area)
		
		elements.bottom.scroll = UiScrollArea()
			:width(1):height(1)
			:addTo(elements.bottom.area)
			
		elements.bottom.layout = UiBoxLayout()
			:width(1):height(1)
			:padding(box.padding)
			:vgap(5)
			:addTo(elements.bottom.scroll)
		
		local function addIconContainer(name)
			elements[name] = {}
			local element = elements[name]
			
			element.area = UiBoxLayout()
				:width(1):height(1)
				:vgap(box.padding)
				:addTo(elements.bottom.layout)
				
			local text = name:gsub("^.", string.upper) .."s"
			element.header = UiHeader(text)
				:addTo(element.area)
				
			element.flow = UiFlowLayout()
				:height(1):width(1)
				:decorate({ DecoFrame(nil, nil, box.border) })
				:padding(box.padding)
				:addTo(element.area)
		end
		
		addIconContainer("island")
		addIconContainer("corporation")
		addIconContainer("tileset")
		addIconContainer("enemylist")
		
		local function addMinimizeBox(element)
			local button = UiCheckbox()
				:heightpx(deco.surfaces.minimizeboxChecked:w())
				:widthpx(deco.surfaces.minimizeboxChecked:h())
				:anchor("right")
				:decorate({
					DecoCheckbox(
						deco.surfaces.minimizeboxChecked,
						deco.surfaces.minimizeboxUnchecked,
						deco.surfaces.minimizeboxHoveredChecked,
						deco.surfaces.minimizeboxHoveredUnchecked)
				})
				:addTo(element.header)
			
			function button:onclicked()
				if self.checked then
					element.flow:hide()
				else
					element.flow:show()
				end
				
				element.area:relayout()
				
				return true
			end
		end
		
		addMinimizeBox(elements.island)
		addMinimizeBox(elements.corporation)
		addMinimizeBox(elements.tileset)
		addMinimizeBox(elements.enemylist)
		
		local function addIconTo(element)
			local icon = Ui()
				:widthpx(box.size.h):heightpx(box.size.w)
				:addTo(element)
				
			icon:registerDragMove()
			
			icon.startDrag = function(self, mx, my, btn)
				UiDraggable.startDrag(self, mx, my, btn)
				draggedElement:decorate(self.decorations)
				draggedElement.visible = true
				draggedElement.x = sdl.mouse.x()
				draggedElement.y = sdl.mouse.y()
			end
			
			icon.stopDrag = function(self, mx, my, btn)
				UiDraggable.stopDrag(self, mx, my, btn)
				draggedElement.visible = false
			end
			
			icon.dragMove = function(self, mx, my)
				UiDraggable.dragMove(self, mx, my)
				draggedElement.x = sdl.mouse.x()
				draggedElement.y = sdl.mouse.y()
			end
			
			return icon
		end
		
		for _, island in pairs(modApi.islands) do
			local element = addIconTo(elements.island.flow)
			element:decorate({
				DecoButton(),
				DecoAnchor(),
				DecoSurfaceCropped(getIslandBackgroundSurface(), 4),
				DecoSurfaceCropped(getIslandSurface(island.Id), 4)
			})
		end
		
		for _, corporation in pairs(modApi.corporations) do
			local element = addIconTo(elements.corporation.flow)
			element:decorate({
				DecoButton(),
				DecoAnchor(),
				DecoSurfaceCropped(getCEOSurface(corporation.Id, 2), 4)
			})
		end
		
		for _, tileset in pairs(modApi.tilesets) do
			local element = addIconTo(elements.tileset.flow)
			element:settooltip(tileset.Id)
			element:decorate({
				DecoButton(deco.colors.dialogbg),
				DecoAnchor(),
				DecoSurfaceCropped(getTilesetSurface(tileset.Id), 4)
			})
		end
		
		for _, enemylist in pairs(modApi.enemyLists) do
			local element = addIconTo(elements.enemylist.flow)
		end
		
		ui:relayout()
	end)
end

function ArrangeIslands()
	-- TODO
	--loadIslandOrder()

	createUi()
end
