
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
local transformation_border = { outline = { border = 1, color = deco.colors.buttonborder } }
deco.surfaces.minimizeboxChecked = sdlext.getSurface({ path = "resources/mods/ui/minimize-checked.png" })
deco.surfaces.minimizeboxUnchecked = sdlext.getSurface({ path = "resources/mods/ui/minimize-unchecked.png" })
deco.surfaces.minimizeboxHoveredChecked = sdlext.getSurface({ path = "resources/mods/ui/minimize-hovered-checked.png" })
deco.surfaces.minimizeboxHoveredUnchecked = sdlext.getSurface({ path = "resources/mods/ui/minimize-hovered-unchecked.png" })
deco.surfaces.complexityChecked = sdlext.getSurface({ path = "resources/mods/ui/complexity-checked.png" })
deco.surfaces.complexityUnchecked = sdlext.getSurface({ path = "resources/mods/ui/complexity-unchecked.png" })
deco.surfaces.complexityHoveredChecked = sdlext.getSurface({ path = "resources/mods/ui/complexity-hovered-checked.png" })
deco.surfaces.complexityHoveredUnchecked = sdlext.getSurface({ path = "resources/mods/ui/complexity-hovered-unchecked.png" })
deco.surfaces.randomicon = sdlext.getSurface({ path = "resources/mods/ui/random.png" })
deco.surfaces.randomiconHovered = sdlext.getSurface({ path = "resources/mods/ui/random-hovered.png" })
deco.surfaces.randomiconPressed = sdlext.getSurface({ path = "resources/mods/ui/random-pressed.png" })
deco.surfaces.randomiconHoveredPressed = sdlext.getSurface({ path = "resources/mods/ui/random-hovered-pressed.png" })
deco.surfaces.editicon = sdlext.getSurface({ path = "resources/mods/ui/edit.png" })
deco.surfaces.editiconHovered = sdlext.getSurface({ path = "resources/mods/ui/edit-hovered.png" })
deco.surfaces.editiconPressed = sdlext.getSurface({ path = "resources/mods/ui/edit-pressed.png" })
deco.surfaces.editiconHoveredPressed = sdlext.getSurface({ path = "resources/mods/ui/edit-hovered-pressed.png" })
deco.surfaces.undoicon = sdlext.getSurface({ path = "resources/mods/ui/undo.png" })
deco.surfaces.undoiconHovered = sdlext.getSurface({ path = "resources/mods/ui/undo-hovered.png" })
deco.surfaces.undoiconPressed = sdlext.getSurface({ path = "resources/mods/ui/undo-pressed.png" })
deco.surfaces.undoiconHoveredPressed = sdlext.getSurface({ path = "resources/mods/ui/undo-hovered-pressed.png" })
deco.surfaces.reseticon = sdlext.getSurface({ path = "resources/mods/ui/reset.png" })
deco.surfaces.reseticonHovered = sdlext.getSurface({ path = "resources/mods/ui/reset-hovered.png" })
deco.surfaces.reseticonPressed = sdlext.getSurface({ path = "resources/mods/ui/reset-pressed.png" })
deco.surfaces.reseticonHoveredPressed = sdlext.getSurface({ path = "resources/mods/ui/reset-hovered-pressed.png" })
local deco_surfaces_random_island = sdlext.getSurface({ path = "resources/mods/game/img/placeholders/island.png" })
local deco_surfaces_random_ceo = sdlext.getSurface({ path = "resources/mods/game/img/placeholders/portrait.png" })
local deco_surfaces_random_env = sdlext.getSurface({ path = "resources/mods/game/img/placeholders/env.png" })
local deco_surfaces_random_enemy = sdlext.getSurface({
	path = "resources/mods/game/img/placeholders/enemy.png",
	transformations = { transformation_border }})

local threat_scanner_font = sdlext.font("fonts/JustinFont11Bold.ttf", 11)
local cachedData

local defaults = {
	{
		island = "grass",
		corporation = "Corp_Grass",
		tileset = "grass",
		enemyList = "grass"
	},
	{
		island = "desert",
		corporation = "Corp_Desert",
		tileset = "sand",
		enemyList = "desert"
	},
	{
		island = "snow",
		corporation = "Corp_Snow",
		tileset = "snow",
		enemyList = "snow"
	},
	{
		island = "factory",
		corporation = "Corp_Factory",
		tileset = "acid",
		enemyList = "factory"
	},
}

local tile_size = {w = 56, h = 44}
local portrait = {
	size = {w = 61, h = 61}
}
local box = {
	size = {w = 2*portrait.size.w, h = 2*portrait.size.h},
	margin = {w = 10, h = 10},
	border = 2,
	padding = 10
}
local header = {
	size = {w = 25, h = 25},
	padding = box.padding,
	border = box.border
}

local function isEmpty(tbl)
	return type(tbl) ~= 'table' or not next(tbl)
end

local function IsSaveData()
	return false
end

-- writes island data
local function saveIslandData(obj)
	sdlext.config(
		"modcontent.lua",
		function(readObj)
			readObj.islands = obj
			cachedData = readObj.islands
		end
	)
end

-- reads island data
local function getIslandData()
	local result = nil
	
	if cachedData then
		result = cachedData
	else
		sdlext.config(
			"modcontent.lua",
			function(readObj)
				result = readObj.islands
				cachedData = result
			end
		)
	end
	
	return result
end

local island_compound_list = {}
function setupIslands()
	local modcontent = modApi:getCurrentModcontentPath()
	
	sdlext.config("modcontent.lua", function(obj)
		obj.islands = obj.islands or {}
		obj.islands.current = obj.islands.current or copy_table(defaults)
		obj.islands.next = obj.islands.next or {}
		
		-- construct the list of preset island compounds (island/corp/tileset/enemyList) before we rearrange them.
		island_compound_list = {}
		for island_id, island in pairs(modApi.islands) do
			local compound = {
				island = island_id,
				corporation = island.Corp,
				enemyList = island.EnemyList
			}
			
			if compound.corporation then
				compound.tileset = modApi:getCorporation(compound.corporation).Tileset
				
				if compound.tileset and compound.enemyList then
					table.insert(island_compound_list, compound)
				end
			end
		end
		
		-- create simple lists for random lookup
		local list_of = {
			island = {},
			corporation = {},
			tileset = {},
			enemyList = {}}
		for entry, _ in pairs(modApi.islands) do table.insert(list_of.island, entry) end
		for entry, _ in pairs(modApi.corporations) do table.insert(list_of.corporation, entry) end
		for entry, _ in pairs(modApi.tilesets) do table.insert(list_of.tileset, entry) end
		for entry, _ in pairs(modApi.enemyLists) do table.insert(list_of.enemyList, entry) end
		
		if not IsSaveData() then
			for i = 1, 4 do
				local current = obj.islands.current[i]
				local next = obj.islands.next[i]
				
				for _, component in ipairs({"island", "corporation", "tileset", "enemyList"}) do
					local nx = next and next[component] or nil
					if nx then
						if nx ~= "_random" then
							if modApi[component.."s"][nx] then
								current[component] = nx
								remove_element(nx, list_of[component])
							end
							next[component] = nil
						end
					else
						remove_element(current[component], list_of[component])
					end
				end
			end
			
			for i = 1, 4 do
				local current = obj.islands.current[i]
				local next = obj.islands.next[i]
				
				local function getRandomOrDefault(component)
					return #list_of[component] > 0 and random_element(list_of[component]) or defaults[i][component]
				end
				
				if next then
					if next.island == "_random" then
						current.island = getRandomOrDefault("island")
						remove_element(current.island, list_of.island)
					end
					
					if next.corporation == "_random" then
						if next.island == "_random" then
							current.corporation = modApi.islands[current.island].Corp
						else
							current.corporation = getRandomOrDefault("corporation")
						end
						remove_element(current.corporation, list_of.corporation)
					end
					
					if next.tileset == "_random" then
						if next.corporation == "_random" then
							current.tileset = modApi.corporations[current.corporation].Tileset
						else
							current.tileset = getRandomOrDefault("tileset")
						end
						remove_element(current.tileset, list_of.tileset)
					end
					
					if next.enemyList == "_random" then
						if next.island == "_random" then
							current.enemyList = modApi.islands[current.island].EnemyList
						else
							current.enemyList = getRandomOrDefault("enemyList")
						end
						remove_element(current.enemyList, list_of.enemyList)
					end
				end
			end
		end
		
		for i = 1, 4 do
			local current = obj.islands.current[i]
			
			-- fetch component data and verify they exist; or use defaults if they do not
			local island = modApi.islands[current.island]
			local corporation = modApi.corporations[current.corporation]
			local tileset = modApi.tilesets[current.tileset]
			local enemyList = modApi.enemyLists[current.enemyList]
			
			if island == nil then
				current.island = defaults[i].island
				island = modApi.islands[current.island]
			end
			
			if corporation == nil then
				current.corporation = defaults[i].corporation
				corporation = modApi.corporations[current.corporation]
			end
			
			if tileset == nil then
				current.tileset = defaults[i].tileset
				tileset = modApi.tilesets[current.tileset]
			end
			
			if enemyList == nil then
				current.enemyList = defaults[i].enemyList
				enemyList = modApi.enemyLists[current.enemyList]
			end
			
			-- apply island data if different from defaults
			if
				island.Id ~= defaults[i].island or 
				corporation.Id ~= defaults[i].corporation or 
				tileset.Id ~= defaults[i].tileset or 
				enemyList.Id ~= defaults[i].enemyList
			then
				island:SetEnemyList(enemyList)
				corporation:SetTileset(tileset)
				island:SetCorporation(corporation)
				modApi:setIsland(i, island)
			end
		end
		
		cachedData = obj.islands
	end)
	
	-- erase function after use at startup
	setupIslands = nil
end

local function getIslandBackgroundSurface(scale)
	return sdlext.getSurface({
		path = "img/strategy/waterbg.png",
		transformations = {
			{ scale = scale }
		}
	})
end

local function getIslandSurface(island_id, scale)
	if island_id == "_random" then
		return deco_surfaces_random_island
	end
	
	return sdlext.getSurface({
		path = string.format("img/strategy/island1x_%s.png", island_id),
		transformations = {
			{ scale = scale }
		}
	})
end

local function getCEOSurface(corporation_id, scale)
	if corporation_id == "_random" then
		return deco_surfaces_random_ceo
	end
	
	local corporation = modApi:getCorporation(corporation_id)
	return sdlext.getSurface({
		path = string.format("img/portraits/ceo/%s", corporation.CEO_Image),
		transformations = {
			{ scale = scale }
		}
	})
end

local function getTilesetSurface(tileset_id, scale)
	if tileset_id == "_random" then
		return deco_surfaces_random_env
	end
	
	return sdlext.getSurface({
		path = string.format("img/strategy/corp/%s_env.png", tileset_id),
		transformations = {
			{ scale = scale }
		}
	})
end

local function getEnemySurface(enemy_id, scale)
	if island_id == "_random" then
		return random_enemy
	end
	
	local surface = random_enemy
	local enemy = _G[enemy_id]
	
	if enemy then
		surface = sdlext.getSurface({
			path = "img/".. ANIMS[enemy.Image].Image,
			transformations = {
				{ scale = scale },
				transformation_border
			}
		})
	end
	
	return surface
end

-- DECORATIONS --
local DecoBorder = Class.inherit(UiDeco)
function DecoBorder:new(bordercolor, borderhlcolor, bordersize, borderhlsize)
	self.bordercolor = bordercolor or deco.colors.buttonborder
	self.borderhlcolor = borderhlcolor or deco.colors.achievementborder
	self.bordersize = bordersize or 2
	self.borderhlsize = borderhlsize or 4
	self.rect = sdl.rect(0, 0, 0, 0)
end

function DecoBorder:draw(screen, widget)
	local r = widget.rect
	
	local bordercolor = self.bordercolor
	local bordersize = self.bordersize
	
	if widget.highlighted then
		bordercolor = self.borderhlcolor
		bordersize = self.borderhlsize
	end
	
	-- left
	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = bordersize
	self.rect.h = r.h
	screen:drawrect(bordercolor, self.rect)
	
	-- top
	self.rect.x = r.x + bordersize
	self.rect.y = r.y
	self.rect.w = r.w - bordersize
	self.rect.h = bordersize
	screen:drawrect(bordercolor, self.rect)
	
	-- right
	self.rect.x = r.x + r.w - bordersize
	self.rect.y = r.y + bordersize
	self.rect.w = bordersize
	self.rect.h = r.h - bordersize
	screen:drawrect(bordercolor, self.rect)
	
	-- bottom
	self.rect.x = r.x
	self.rect.y = r.y + r.h - bordersize
	self.rect.w = r.w - bordersize
	self.rect.h = bordersize
	screen:drawrect(bordercolor, self.rect)
end

local DecoClickableIcon = Class.inherit(DecoSurface)
function DecoClickableIcon:new(unclicked, clicked, hovUnclicked, hovClicked)
	self.srfUnclicked = unclicked
	self.srfClicked = clicked
	self.srfHoveredUnclicked = hovUnclicked
	self.srfHoveredClicked = hovClicked
	
	DecoSurface.new(self, self.srfUnclicked)
end

function DecoClickableIcon:draw(screen, widget)
	if widget.pressed then
		if widget.hovered then
			self.surface = self.srfHoveredClicked
		else
			self.surface = self.srfClicked
		end
	else
		if widget.hovered then
			self.surface = self.srfHoveredUnclicked
		else
			self.surface = self.srfUnclicked
		end
	end
	
	DecoSurface.draw(self, screen, widget)
end

-- UI PREFABS --
local function UiClickableIcon(unclicked, clicked, hovUnclicked, hovClicked)
	local ui = Ui()
		:widthpx(unclicked:w()):heightpx(unclicked:h())
		:decorate{
			DecoClickableIcon(
				unclicked,
				clicked,
				hovUnclicked,
				hovClicked)}
	return ui
end

local function UiCEOIcon(corporation_id)
	local ui = Ui()
		:widthpx(box.size.w):heightpx(box.size.h)
		:setTranslucent()
		:clip()
		:settooltip(corporation_id)
		
	function ui:redecorate(data)
		local corporation_id = data.corporation
		if not corporation_id then return end
		
		self:decorate{
			DecoButton(),
			DecoAnchor(),
			DecoSurfaceAligned(getCEOSurface(corporation_id, 2))}
		
		return self
	end
	
	ui:redecorate({corporation = corporation_id})
	
	return ui
end

local function UiTilesetIcon(tileset_id)
	local ui = Ui()
		:widthpx(box.size.w):heightpx(box.size.h)
		:setTranslucent()
		:clip()
		:settooltip(tileset_id)
		
	function ui:redecorate(data)
		local tileset_id = data.tileset
		if not tileset_id then return end
		
		self:decorate{
			DecoButton(deco.colors.dialogbg),
			DecoAnchor(),
			DecoSurfaceAligned(getTilesetSurface(tileset_id))}
		
		return self
	end
	
	ui:redecorate({tileset = tileset_id})
	
	return ui
end

local function UiIslandIcon(island_id)
	local ui = Ui()
		:widthpx(box.size.w):heightpx(box.size.h)
		:setTranslucent()
		:clip()
		:settooltip(island_id)
		
	function ui:redecorate(data)
		local island_id = data.island
		if not island_id then return end
		
		self:decorate{
			DecoButton(),
			DecoAnchor(),
			DecoSurfaceAligned(getIslandBackgroundSurface()),
			DecoAnchor(),
			DecoSurfaceAligned(getIslandSurface(island_id), "center", "center")}
			
		return self
	end
	
	ui:redecorate({island = island_id})
	
	return ui
end

local function UiEnemyListIcon(enemyList_id)
	local ui = Ui()
		:widthpx(box.size.w):heightpx(box.size.h)
		:setTranslucent()
		:clip()
		:settooltip(enemyList_id)
		
	function ui:redecorate(data)
		local enemyList_id = data.enemyList
		if not enemyList_id then return end
		
		return self
	end
	
	ui:redecorate({enemyList = enemyList_id})
	
	return ui
end

local function UiHeader()
	local ui = Ui()
		:width(1):heightpx(header.size.h + 2*header.padding)
		:decorate{
			DecoFrame(deco.colors.buttonhl, nil, box.border),
			DecoText("", deco.uifont.title.font, deco.uifont.title.set)
		}
		:padding(header.padding)
	
	function ui:getText()
		return self.decorations[2].text
	end
	
	function ui:redecorate(data)
		-- TODO: don't know how to handle this yet
	end
	
	return ui
end

local cachedIslands = {}
local function UiIsland(island_id)
	local ui = Ui()
		:width(1):height(1)
		:setTranslucent()
	
	local img = Ui()
		:width(1):height(1)
		:setTranslucent()
		:addTo(ui)
		
	local bg = Ui()
		:width(1):height(1)
		:setTranslucent()
		:decorate{ DecoSurfaceAligned(getIslandBackgroundSurface()) }
		:addTo(ui)
	
	function ui:redecorate(data)
		local island_id = data.island
		if not island_id then return end
		
		local decorations = cachedIslands[island_id]
		if decorations then
			img.decorations = decorations
		else
			img:decorate{
				DecoAlign(-10),
				DecoSurfaceAligned(
					getIslandSurface(island_id),
					"left", "center")}
			cachedIslands[island_id] = img.decorations
		end
		
		return self
	end
	
	ui:redecorate({island = island_id})
	
	return ui
end

local tile_size = {w=56, h=44}
local tile_compound_size = {w = 3.5*tile_size.w, h = 6*tile_size.h}
local cachedTilesetCompounds = {}
local function UiTilesetCompound(tileset_id)
	local ui = Ui()
		:widthpx(tile_compound_size.w):heightpx(tile_compound_size.h)
		:setxpx(-2*tile_size.w)
		:setTranslucent()
		:anchor("right", "center")
		
	function ui:redecorate(data)
		local tileset_id = data.tileset
		if not tileset_id then return end
		
		local decorations = cachedTilesetCompounds[tileset_id]
		if decorations then
			self.decorations = decorations
		else
			local tileset_surface = getTilesetSurface(tileset_id)
			self:decorate{
				DecoSurfaceAligned(tileset_surface),
				DecoAlign(-.5*tile_size.w, .5*tile_size.h),
				DecoSurfaceAligned(tileset_surface),
				DecoAlign(-3*tile_size.w, tile_size.h),
				DecoSurfaceAligned(tileset_surface),
				DecoAlign(-tile_size.w, tile_size.h),
				DecoSurfaceAligned(tileset_surface),
				DecoAlign(-3.5*tile_size.w, .5*tile_size.h),
				DecoSurfaceAligned(tileset_surface)}
			cachedTilesetCompounds[tileset_id] = self.decorations
		end
		
		return self
	end
	
	ui:redecorate({tileset = tileset_id})
	
	return ui
end

local cachedCeos = {}
local function UiCEO(corporation_id)
	local drawrect = sdl.screen().drawrect
	
	local ui = Ui()
		:widthpx(portrait.size.w+4):heightpx(portrait.size.h+4)
		:setTranslucent()
		:pospx(14,12)
		:anchor("right", "top")
		:decorate{
			DecoDraw(drawrect, deco.colors.framebg),
			DecoAnchor(),
			DecoAlign(1,1),
			DecoDraw(drawrect, nil, sdl.rect(0,0,portrait.size.w+2,portrait.size.h+2)),
			DecoAnchor(),
			DecoAlign(2,2),
			DecoDraw(drawrect, deco.colors.framebg, sdl.rect(0,0,portrait.size.w,portrait.size.h))
		}
		
	local ceo = Ui()
		:widthpx(portrait.size.w):heightpx(portrait.size.h)
		:anchor("center", "center")
		:addTo(ui)
	
	function ui:redecorate(data)
		local corporation_id = data.corporation
		if not corporation_id then return end
		
		local decorations = cachedCeos[corporation_id]
		if decorations then
			ceo.decorations = decorations
		else
			ceo:decorate{ DecoSurfaceAligned(getCEOSurface(corporation_id)) }
			cachedCeos[corporation_id] = ceo.decorations
		end
		
		return self
	end
		
	ui:redecorate({corporation = corporation_id})
		
	return ui
end

local function UiEnemy(enemy_id)
	local enemy_ui
	local enemy = _G[enemy_id]
	if enemy then
		enemy_anim = ANIMS[enemy.Image]
		if enemy_anim then
			local surface = getEnemySurface(enemy_id)
			enemy_ui = Ui()
				:widthpx(surface:w() / enemy_anim.NumFrames)
				:heightpx(surface:h() / enemy_anim.Height)
				:anchor("left", "bottom")
				:clip()
				:decorate{
					DecoAlign(0,-enemy.ImageOffset * surface:h() / enemy_anim.Height),
					DecoSurfaceAligned(surface)}
		end
	end
	
	return enemy_ui or Ui()
end

local function UiEnemyRandom()
	return Ui()
		:widthpx(deco_surfaces_random_enemy:w()):heightpx(deco_surfaces_random_enemy:h())
		:anchor("left", "bottom")
		:clip()
		:decorate{ DecoSurfaceAligned(deco_surfaces_random_enemy) }
end

local function UiThreatScanner(enemyList_id)
	local drawrect = sdl.screen().drawrect
	
	local ui = Ui()
		:width(1):heightpx(88)
		:setTranslucent()
		:decorate{ DecoFrame(nil, nil, box.border) }
		
	local label = Ui()
		:width(1):height(1)
		:setTranslucent()
		:decorate{
			DecoAlign(33,0),
			DecoDraw(drawtri_tr, nil, sdl.rect(0,0,21,21)),
			DecoDraw(drawrect, nil, sdl.rect(0,0,132,21)),
			DecoDraw(drawtri_tl, nil, sdl.rect(0,0,21,21)),
			DecoAnchor(),
			DecoAlign(-1,4),
			DecoAlignedText("Threat Scanner",
				threat_scanner_font,
				deco.uifont.default.set,
				"center", "top")
		}
		:addTo(ui)
		
	local scroll = UiScrollAreaH()
		:width(1):height(1)
		:setTranslucent()
		:addTo(ui)
		
	local scanner = UiBoxLayout()
		:width(1):height(1)
		:setTranslucent()
		:padding(box.padding/2)
		:hgap(box.padding/2)
		:addTo(scroll)
		
	function ui:redecorate(data)
		local enemyList_id = data.enemyList
		if not enemyList_id then return end
		
		scanner.children = {}
		
		if enemyList_id == "_random" then
			for i = 1, 10 do
				UiEnemyRandom()
					:setTranslucent()
					:addTo(scanner)
			end
		else
			local enemyList = modApi:getEnemyList(enemyList_id)
			for category, enemies in pairs(enemyList.Enemies) do
				for _, enemy_id in ipairs(enemies) do
					UiEnemy(enemy_id .."1")
						:setTranslucent()
						:addTo(scanner)
				end
			end
		end
		
		return self
	end
	
	ui:redecorate({enemyList = enemyList_id})
	
	return ui
end

-- ISLAND COMPOUND --
local function UiIslandCompound(data)
	data = data or {}
	local content = {}
	local drawrect = sdl.screen().drawrect
	
	local ui = Ui()
		:widthpx(2*box.size.w):heightpx(289)
		
	local border = Ui()
		:width(1):height(1)
		:decorate{ DecoBorder(deco.colors.buttonborder, deco.colors.achievementborder, box.border, 4) }
		:addTo(ui)
		
	local layout = UiBoxLayout()
		:width(1):height(1)
		:decorate{ DecoFrame(deco.colors.framebg) }
		:setTranslucent()
		:padding(-box.border)
		:vgap(0)
		:addTo(ui)
	layout.padl = 0
	layout.padr = 0
	
	-- TOP
	content.header = UiHeader()
		:addTo(layout)
	-- CENTER
	local center = Ui()
		:width(1):heightpx(156)
		:padding(box.border)
		:clip()
		:addTo(layout)
	center.padl = 2*box.border
	center.padr = 2*box.border
	center.nofity = true
	-- CEO
	content.ceo = UiCEO(data.corporation)
		:addTo(center)
	-- TILESET
	content.tileset = UiTilesetCompound(data.tileset)
		:addTo(center)
	-- ISLAND
	content.island = UiIsland(data.island)
		:addTo(center)
	-- BOTTOM - THREAT_SCANNER
	content.enemyList = UiThreatScanner(data.enemyList)
		:addTo(layout)
		
	function ui:redecorate(data)
		if not data then return end
		content.ceo:redecorate(data)
		content.tileset:redecorate(data)
		content.island:redecorate(data)
		content.enemyList:redecorate(data)
	end
	
	ui.content = content
	ui.data = data
	return ui
end

-- SIMPLE ICON --
local function UiIcon(data)
	data = data or {}
	local content = {}
	local ui = Ui()
		:widthpx(box.size.h):heightpx(box.size.w)
		
	local border = Ui()
		:width(1):height(1)
		:setTranslucent()
		:decorate{ DecoBorder(deco.colors.buttonborder, deco.colors.achievementborder, box.border, 4) }
		:addTo(ui)
	
	local function show(self)
		content.ceo.visible = false
		content.tileset.visible = false
		content.island.visible = false
		content.enemyList.visible = false
		self.visible = true
	end
		
	content.ceo = UiCEOIcon(data.corporation)
		:addTo(ui)
	content.tileset = UiTilesetIcon(data.tileset)
		:addTo(ui)
	content.island = UiIslandIcon(data.island)
		:addTo(ui)
	content.enemyList = UiEnemyListIcon(data.enemyList)
		:addTo(ui)
	
	content.ceo.show = show
	content.tileset.show = show
	content.island.show = show
	content.enemyList.show = show
	
	local bg = Ui()
		:width(1):height(1)
		:setTranslucent()
		:decorate{ DecoFrame(deco.colors.framebg) }
		:addTo(ui)
		
	function ui:redecorate(data)
		if not data then return end
		for _, child in pairs(content) do
			if child:redecorate(data) then
				child:show()
			end
		end
	end
	
	ui.content = content
	ui.data = data
	return ui
end

local draggedSimple
local draggedIslandCompound
local currentDraggedElement

local function setDraggable(ui, draggedElement)
	ui.draggable   = true
	ui.dragMovable = true
	ui.dropTargets = draggedElement.dropTargets
	
	function ui:startDrag(mx, my, btn)
		UiDraggable.startDrag(self, mx, my, btn)
		
		currentDraggedElement = draggedElement
		draggedElement.visible = true
		draggedElement.dx = mx - self.screenx
		draggedElement.dy = my - self.screeny
		draggedElement.x = mx
		draggedElement.y = my
		draggedElement.w = self.w
		draggedElement.h = self.h
		draggedElement.data = self.data
		
		if draggedElement.redecorate then
			draggedElement:redecorate(self.data)
		end
	end
	
	function ui:stopDrag(mx, my, btn)
		UiDraggable.stopDrag(self, mx, my, btn)
		
		currentDraggedElement = nil
		draggedElement.visible = false
	end
	
	function ui:dragMove(mx, my)
		UiDraggable.dragMove(self, mx, my)
		
		draggedElement.x = mx
		draggedElement.y = my
	end
end

local function setDraggableIslandCompound(ui)
	setDraggable(ui, draggedIslandCompound)
end

local function setDraggableSimple(ui)
	setDraggable(ui, draggedSimple)
end

local function setDropTarget(target)
	draggedIslandCompound:registerDropTarget(target)
	draggedSimple:registerDropTarget(target)
	
	function target:onDraggableEntered(draggable)
		self:redecorate(draggable.data)
	end
	
	function target:onDraggableExited(draggable)
		self:redecorate(self.data)
	end
	
	function target:onDraggableDropped(draggable)
		self.data = add_tables(self.data, draggable.data)
		self:redecorate(draggable.data)
		for component, data in pairs(draggable.data) do
			cachedData.next[self._island_number] = cachedData.next[self._island_number] or {}
			cachedData.next[self._island_number][component] = shallow_copy(data)
		end
	end
end

local function createUi()
	local islands = {}
	local corporations = {}
	local tilesets = {}
	local enemyLists = {}
	
	for _, island in pairs(modApi.islands) do
		islands[#islands+1] = island:GetId()
	end
	
	for _, corporation in pairs(modApi.corporations) do
		corporations[#corporations+1] = corporation:GetId()
	end
	
	for _, tileset in pairs(modApi.tilesets) do
		tilesets[#tilesets+1] = tileset:GetId()
	end
	
	for _, enemyList in pairs(modApi.enemyLists) do
		enemyLists[#enemyLists+1] = enemyList:GetId()
	end
	
	local onExit = function(self)
		saveIslandData(cachedData)
	end
	
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit
		
		local screen = sdl.screen()
		local isSmallIcons = screen:w() < 1280
		
		draggedIslandCompound = UiIslandCompound({})
			:setTranslucent(true, true)
			:hide()
			:addTo(ui)
			
		draggedSimple = UiIcon()
			:setTranslucent()
			:hide()
			:addTo(ui)
		
		local tmp
		local elements = {}
		elements.main = {}
		elements.top = {}
		elements.bottom = {}
		elements.islandCompounds = {}
		
		elements.main = UiWeightLayout()
			:width(0.9):height(0.9)
			:posCentered()
			:orientation(false)
			:vgap(2*box.padding)
			:addTo(ui)
			
		-- TOP AREA --
		--------------
		
		tmp = Ui()
			:width(1):heightpx(2*box.size.h + header.size.h + 2*header.padding + 2*header.border)
			:addTo(elements.main)
			
		local top = UiBoxLayout()
			:width(1):height(1)
			:anchor("center", "top")
			:hgap(box.padding)
			:addTo(tmp)
		
		for island_number = 1, 4 do
			local data = add_tables(cachedData.current[island_number], cachedData.next[island_number] or {})
			local ui = UiIslandCompound(data)
				:setTranslucent(true, true)
				:setTranslucent(false)
				:addTo(top)
			ui._island_number = island_number
			setDropTarget(ui)
			
			local buttonRandom = UiClickableIcon(
				deco.surfaces.randomicon,
				deco.surfaces.randomiconPressed,
				deco.surfaces.randomiconHovered,
				deco.surfaces.randomiconHoveredPressed)
				:anchor("right", "center")
				:settooltip("Randomize island every time the game starts")
				:addTo(ui.content.header)
			
			-- function buttonRandom:mouseup(mx, my, button)
				-- TODO: self.hovered is true even if mouse leaves button while pressing
				-- TODO: self.containsMouse is true even if mouse leaves button while pressing
				--if button == 1 and self.pressed and self.hovered then
			
			function buttonRandom:mouseup(mx, my, button)
				if button == 1 then
					local data = {
						island = "_random",
						corporation = "_random",
						tileset = "_random",
						enemyList = "_random"}
					cachedData.next[island_number] = data
					ui:redecorate(data)
					ui.data = data
				end
				
				return Ui.mouseup(self, mx, my, button)
			end
			
			local buttonDefault = UiClickableIcon(
				deco.surfaces.reseticon,
				deco.surfaces.reseticonPressed,
				deco.surfaces.reseticonHovered,
				deco.surfaces.reseticonHoveredPressed)
				:setxpx(header.size.w + header.padding)
				:anchor("right", "center")
				:settooltip("Reset island to default layout")
				:addTo(ui.content.header)
				
			function buttonDefault:mouseup(mx, my, button)
				if button == 1 then
					local data = shallow_copy(defaults[island_number])
					cachedData.next[island_number] = data
					ui:redecorate(data)
					ui.data = data
				end
				
				return Ui.mouseup(self, mx, my, button)
			end
			
			table.insert(elements.islandCompounds, ui)
		end
		
		-- BOTTOM AREA --
		-----------------
		
		elements.bottom.area = UiWeightLayout()
			:width(1):height(1)
			:vgap(0):hgap(0)
			:decorate{ DecoFrame(nil, nil, box.border) }
			:addTo(elements.main)
			
		elements.bottom.left = Ui()
			:widthpx(header.size.w + 2*header.padding):height(1)
			:decorate{ DecoFrame(deco.colors.buttonhl, nil, 0) }
			:padding(header.padding)
			:addTo(elements.bottom.area)
			
		local separator = Ui()
			:widthpx(box.border):height(1)
			:decorate{ DecoSolid(deco.colors.buttonborder) }
			:addTo(elements.bottom.area)
			
		-- SIMPLE LIST - ISLAND PRESETS --
		local simple = UiScrollArea()
			:width(1):height(1)
			:addTo(elements.bottom.area)
			
		local simple_layout = UiFlowLayout()
			:width(1):height(1)
			:padding(box.padding)
			:addTo(simple)
		
		for _, compound in ipairs(island_compound_list) do
			local data = shallow_copy(compound)
			local ui = UiIslandCompound(data)
				:setTranslucent(true, true)
				:setTranslucent(false)
				:addTo(simple_layout)
			setDraggableIslandCompound(ui)
		end
		
		-- COMPLEX LIST --
		local complex = UiScrollArea()
			:width(1):height(1)
			:addTo(elements.bottom.area)
			:hide()
			
		local complex_layout = UiBoxLayout()
			:width(1):height(1)
			:padding(box.padding)
			:vgap(5)
			:addTo(complex)
			
		local function addIconContainer(name)
			elements[name] = {}
			local element = elements[name]
			
			element.area = UiBoxLayout()
				:width(1):height(1)
				:vgap(box.padding)
				:addTo(complex_layout)
				
			local text = name:gsub("^.", string.upper) .."s"
			element.header = UiHeader(text)
				:addTo(element.area)
				
			element.flow = UiFlowLayout()
				:height(1):width(1)
				:decorate{ DecoFrame(nil, nil, box.border) }
				:padding(box.padding)
				:addTo(element.area)
		end
		
		addIconContainer("island")
		addIconContainer("corporation")
		addIconContainer("tileset")
		addIconContainer("enemyList")
		
		-- BUTTONS --
		local function addMinimizeBox(element)
			local button = UiCheckbox()
				:widthpx(deco.surfaces.minimizeboxChecked:w())
				:heightpx(deco.surfaces.minimizeboxChecked:h())
				:anchor("right")
				:settooltip("Minimize")
				:decorate{
					DecoCheckbox(
						deco.surfaces.minimizeboxChecked,
						deco.surfaces.minimizeboxUnchecked,
						deco.surfaces.minimizeboxHoveredChecked,
						deco.surfaces.minimizeboxHoveredUnchecked)
				}
				:addTo(element.header)
			
			button.onclicked = function(self)
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
		addMinimizeBox(elements.enemyList)
		
		-- TODO: enable edit button for enemylists to open another ui for editing and creating new enemylists.
		
		local editButton = UiClickableIcon(
			deco.surfaces.editicon,
			deco.surfaces.editiconPressed,
			deco.surfaces.editiconHovered,
			deco.surfaces.editiconHoveredPressed)
			:setxpx(deco.surfaces.editicon:w() + box.padding)
			:anchor("right")
			:settooltip("Edit EnemyLists")
			:addTo(elements.enemyList.header)
		
		-- COMPLEXITY BOX --
		local complexityBox = UiCheckbox()
			:widthpx(deco.surfaces.complexityChecked:w())
			:heightpx(deco.surfaces.complexityChecked:h())
			:anchor("center", "top")
			:settooltip("Toggle complexity")
			:decorate{
				DecoCheckbox(
					deco.surfaces.complexityChecked,
					deco.surfaces.complexityUnchecked,
					deco.surfaces.complexityHoveredChecked,
					deco.surfaces.complexityHoveredUnchecked)
			}
			:addTo(elements.bottom.left)
		
		function complexityBox:onclicked()
			if self.checked then
				simple:hide()
				complex:show()
			else
				simple:show()
				complex:hide()
			end
			
			elements.bottom.area:relayout()
			
			return true
		end
		
		-- DEFAULT ALL ISLANDS BOX
		local buttonDefault = UiClickableIcon(
			deco.surfaces.reseticon,
			deco.surfaces.reseticonPressed,
			deco.surfaces.reseticonHovered,
			deco.surfaces.reseticonHoveredPressed)
			:setypx(header.size.h + header.padding)
			:anchor("center", "top")
			:settooltip("Reset all islands to default layouts")
			:addTo(elements.bottom.left)
		
		function buttonDefault:mouseup(mx, my, button)
			if button == 1 then
				
				for i = 1, 4 do
					local ui = elements.islandCompounds[i]
					ui:redecorate(defaults[i])
					ui.data = shallow_copy(defaults[i])
				end
				
				cachedData.next = copy_table(defaults)
			end
			
			return Ui.mouseup(self, mx, my, button)
		end
		
		-- RANDOMIZE ALL ISLANDS BOX --
		local buttonRandom = UiClickableIcon(
			deco.surfaces.randomicon,
			deco.surfaces.randomiconPressed,
			deco.surfaces.randomiconHovered,
			deco.surfaces.randomiconHoveredPressed)
			:setypx(2*(header.size.h + header.padding))
			:anchor("center", "top")
			:settooltip("Randomize all islands every time the game starts")
			:addTo(elements.bottom.left)
		
		function buttonRandom:mouseup(mx, my, button)
			if button == 1 then
				local data = {
					corporation = "_random",
					island = "_random",
					tileset = "_random",
					enemyList = "_random"}
				data = { data, data, data, data }
				
				for i = 1, 4 do
					local ui = elements.islandCompounds[i]
					local data = shallow_copy(data[i])
					ui:redecorate(data)
					ui.data = data
				end
				
				cachedData.next = copy_table(data)
			end
			
			return Ui.mouseup(self, mx, my, button)
		end
		
		-- UNDO CHANGES BOX
		local buttonUndo = UiClickableIcon(
			deco.surfaces.undoicon,
			deco.surfaces.undoiconPressed,
			deco.surfaces.undoiconHovered,
			deco.surfaces.undoiconHoveredPressed)
			:anchor("center", "bottom")
			:settooltip("Undo all changes\n\nAny island that was previously randomized will be fixed to their current settings")
			:addTo(elements.bottom.left)
		
		function buttonUndo:mouseup(mx, my, button)
			if button == 1 then
				local data = cachedData.current
				
				for i = 1, 4 do
					local ui = elements.islandCompounds[i]
					ui:redecorate(data[i])
					ui.data = shallow_copy(data[i])
				end
				
				cachedData.next = {}
			end
			
			return Ui.mouseup(self, mx, my, button)
		end
		
		-- À LA CARTE ITEMS --
		for _, island in pairs(modApi.islands) do
			local data = {island = island.Id}
			local ui = UiIcon(data)
				:addTo(elements.island.flow)
			setDraggableSimple(ui)
		end
		
		for _, corporation in pairs(modApi.corporations) do
			local data = {corporation = corporation.Id}
			local ui = UiIcon(data)
				:addTo(elements.corporation.flow)
			setDraggableSimple(ui)
		end
		
		for _, tileset in pairs(modApi.tilesets) do
			local data = {tileset = tileset.Id}
			local ui = UiIcon(data)
				:addTo(elements.tileset.flow)
			setDraggableSimple(ui)
		end
		
		for _, enemyList in pairs(modApi.enemyLists) do
			local data = {enemyList = enemyList.Id}
			local ui = UiIcon(data)
				:addTo(elements.enemyList.flow)
			setDraggableSimple(ui)
		end
		
		ui:relayout()
	end)
end

function ConfigureIslandLayouts()
	createUi()
end
