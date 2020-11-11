
local waterLoc = Point(-28,1)
local mountainLoc = Point(-28,-21)
local buildingTileLoc = Point(-28,-15)
local forestLoc = Point(-25,5)
local lavaLoc = Point(-27,2)
local sandLoc = Point(-28,1)
local tileLoc = {
	acid_0 = waterLoc,
	acid_1 = waterLoc,
	acid_2 = waterLoc,
	acid_3 = waterLoc,
	building_1_tile = buildingTileLoc,
	building_2_tile = buildingTileLoc,
	building_3_tile = buildingTileLoc,
	forest_0 = forestLoc,
	forest_0_front = forestLoc,
	ice = waterLoc,
	ice_1 = waterLoc,
	ice_1_crack = waterLoc,
	ice_2 = waterLoc,
	ice_2_crack = waterLoc,
	lava_0 = lavaLoc,
	lava_1 = lavaLoc,
	mountain = mountainloc,
	mountain_0 = mountainLoc,
	mountain_0_broken = mountainLoc,
	mountain_1 = mountainLoc,
	mountain_2 = mountainLoc,
	sand_0 = sandLoc,
	sand_1 = sandLoc,
	sand_0_front = sandLoc,
	sand_1_front = sandLoc,
	water = waterLoc,
	water_0 = waterLoc,
	water_1 = waterLoc,
	water_2 = waterLoc,
	water_3 = waterLoc,
}

local function getModFilePathRelativeToGameDir(filePathRelativeToModDir)
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	return modPath .. filePathRelativeToModDir
end

local function AssertFilePath(filePath, extension, msg)
	msg = (msg and msg .. ": ") or ""
	assert(type(filePath) == 'string', string.format("%sExpected 'string', but was '%s'", msg, type(filePath)))
	
	if extension ~= nil and extension ~= "" then
		assert(modApi:stringEndsWith(filePath, extension), string.format("%sExpected extension '.png'. Got '%s'", msg, filePath))
	end
	
	local fullFilePath = getModFilePathRelativeToGameDir(filePath)
	assert(modApi:fileExists(fullFilePath), string.format("%sFile '%s' could not be found", msg, fullFilePath))
end

local function AssertMultiple(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .."Expected "
	
	for i = 1, #expected do
		msg = string.format("%s'%s'", msg, tostring(expected[i]))
		if #expected > i then
			if #expected - i == 1 then
				msg = msg .." or "
			else
				msg = msg ..", "
			end
		end
	end
	
	msg = string.format("%s, but was '%s'", msg, tostring(actual))
	
	local result = false
	for _, e in ipairs(expected) do
		if e == actual then
			result = true
			break
		end
	end
	
	assert(result, msg)
end

local function AssertEquals(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected '%s', but was '%s'", tostring(expected), tostring(actual))
	assert(expected == actual, msg)
end

local function AssertIsUniqueId(isUnique, id, msg)
	msg = (msg and msg .. ": ") or ""
	msg = string.format("%s Id '%s' is already taken", msg, id)
	assert(isUnique, msg)
end

local function AssertEntryExists(tbl, entry, name, msg)
	assert(tbl[entry] ~= nil, string.format("%s: %s '%s' could not be found. List of current valid %ss:\n%s", msg, name, entry, string.lower(name), save_table(tbl, 0)))
end

local function AssertResourcesDatExists(msg)
	msg = (msg and msg .. ": ") or ""
	assert(modApi.resource ~= nil, msg .. "Resource.dat is closed. It can only be modified while mods are initializing")
end

local template_tileset = { isTilesetClass = true }

function template_tileset:getId()
	return self.id
end

function template_tileset:copyAssets(tileset_id)
	AssertEntryExists(modApi.tilesets, tileset_id, "Tileset", "copyAssets - Arg#1 (tileset id)")
	
	if tileset_id == self:getId() then
		return
	end
	
	modApi:copyTilesetAssets("tiles_".. tileset_id, "tiles_".. self:getId())
end

function template_tileset:getTilePath()
	return self.tilePath:gsub("[^/]$","%1/")
end

function template_tileset:setTilePath(path)
	AssertEquals('string', type(path), "setTilePath - Arg#1 (folder containing tile images, relative to mod root)")
	
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	assert(modApi:directoryExists(modPath .. path), string.format("setTilePath - Arg#1: Directory '%s' does not exist", modPath .. path))
	
	self.tilePath = path
end

function template_tileset:getEnvironmentChance(tileType, difficulty)
	-- tileset.environmentChance can be structured as any of the following:
	-- tileset.environmentChance == chance
	-- tileset.environmentChance[tileType] == chance
	-- tileset.environmentChance[difficulty][tileType] == chance
	
	local env = self.environmentChance
	local chance
	
	if type(env) == 'table' then
		if type(env[difficulty]) == 'table' then
			chance = env[difficulty][tileType]
		else
			chance = env[tileType]
		end
	else
		chance = env
	end
	
	return type(chance) == 'number' and chance or 0
end

function template_tileset:getRainChance()
	return type(self.rainChance) == 'number' and self.rainChance or 0
end

function template_tileset:addTile(id, loc)
	AssertEquals('string', type(id), "addTile - Arg#1 (tile id)")
	assert(loc == nil or isUserdataPoint(loc), "addTile - Arg#2 (tile offset): Expected 'nil' or 'Point', but was '%s'", type(loc))
	
	if loc == nil then
		loc = tileLoc[id]
	end
	
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	local resourcePath = string.format("combat/tiles_%s/%s.png", self:getId(), id)
	local filePath = string.format("%s%s%s.png", modPath, self:getTilePath(), id)
	Location[resourcePath] = loc
	
	assert(modApi:fileExists(filePath), string.format("addTile - Arg#1: File '%s' Could not be found", id, self:getId(), filePath))
	
	modApi:appendAsset("img/".. resourcePath, filePath)
end

function template_tileset:addTiles(tiles)
	for id, loc in pairs(tiles) do
		
		if type(id) == 'number' then
			id = loc
			loc = nil
		end
		
		self:addTile(id, loc)
	end
end

function template_tileset:setTilesetIcon(filePath)
	AssertFilePath(filePath, ".png", "setTilesetIcon - Arg#1 (Filepath for tileset icon)")
	
	modApi:appendAsset(string.format("img/strategy/corp/%s_env.png", self:getId()), getModFilePathRelativeToGameDir(filePath))
end

CreateClass(template_tileset)

local vanillaTilesets = {
	"grass",
	"sand",
	"snow",
	"acid",
	"lava",
	"volcano"
}
modApi.tilesets = {}

function modApi:copyTilesetAssets(from, to)
	AssertResourcesDatExists("copyTilesetAssets")
	AssertEquals('string', type(from), "Arg#1")
	AssertEquals('string', type(to), "Arg#2")
	assert(string.find(from, "[/\\]") == nil, "copyTilesetAssets - Arg#1: Expected directory name without '\\' and '/', was ".. from)
	assert(string.find(to, "[/\\]") == nil, "copyTilesetAssets - Arg#2: Expected directory name without '\\' and '/', was ".. to)
	
	local root = "img/combat/"
	
	-- ensure strings end with '/'
	from = root .. from:gsub("[^/]$","%1/")
	to = root .. to:gsub("[^/]$","%1/")
	
	local files = {}
	
	for _, file in ipairs(modApi.resource._files) do
		local filename = file._meta._filename
		
		if modApi:stringStartsWith(filename, from) then
			files[#files+1] = filename
		end
	end
	
	for _, filename in ipairs(files) do
		modApi:copyAsset(filename, filename:gsub(from, to))
	end
end

function modApi:newTileset(id, base)
	AssertEquals('string', type(id), "newTileset - Arg#1 (Tileset id)")
	AssertIsUniqueId(modApi.tilesets[id] == nil, id, "newTileset - Arg#1 (Tileset id)")
	AssertMultiple({'nil', 'table', 'string'}, type(base), "newTileset - Arg#2 (Base tileset/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.tilesets, base, "Tileset", "newTileset - Arg#2")
		base = modApi.tilesets[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.tilesets, base.id, "Tileset", "newTileset - Arg#2")
	end
	
	modApi.tilesets[id] = (base or template_tileset):new{
		id = id,
		tilePath = string.format("img/combat/tiles_%s/", id)
	}
	local tileset = modApi.tilesets[id]
	
	if base ~= nil then
		tileset:copyAssets(base.id)
	end
	
	return tileset
end

function modApi:getTileset(id)
	AssertEntryExists(modApi.tilesets, id, "Tileset", "getTileset")
	
	return modApi.tilesets[id]
end

local difficulties = {
	DIFF_EASY,
	DIFF_NORMAL,
	DIFF_HARD
}

local tileTypes = {
	TERRAIN_FOREST,
	TERRAIN_SAND,
	TERRAIN_ICE,
	TERRAIN_ACID
}
local difficulty

-- temporarily override GetDifficulty while extracting environmentChance for vanilla tilesets
local oldGetDifficulty = GetDifficulty
function GetDifficulty()
	return difficulty
end

-- add vanilla tilesets
for _, tileset_id in ipairs(vanillaTilesets) do
	local tileset = modApi:newTileset(tileset_id)
	
	-- extract rainChance from vanilla function
	tileset.rainChance = getRainChance(tileset_id)
	
	-- extract environmentChance from vanilla function
	tileset.environmentChance = {}
	
	for _, diff in ipairs(difficulties) do
		difficulty = diff
		tileset.environmentChance[diff] = {}
		
		for _, tileType in ipairs(tileTypes) do
			tileset.environmentChance[diff][tileType] = getEnvironmentChance(tileset_id, tileType)
		end
	end
end

GetDifficulty = oldGetDifficulty

function getRainChance(sectorType)
	local tileset = modApi:getTileset(sectorType)
	
	if tileset and tileset.getRainChance then
		return tileset:getRainChance()
	end
	
	return 0
end

function getEnvironmentChance(sectorType, tileType)
	local tileset = modApi:getTileset(sectorType)
	
	if tileset and tileset.getEnvironmentChance then
		return tileset:getEnvironmentChance(tileType, GetDifficulty())
	end
	
	return 0
end
