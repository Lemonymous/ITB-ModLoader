
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

local function getCurrentModResourcePath()
	return mod_loader.mods[modApi.currentMod].resourcePath
end

local function AssertIsUniqueId(isUnique, id, msg)
	msg = (msg and msg .. ": ") or ""
	msg = string.format("%s Id '%s' is already taken", msg, id)
	assert(isUnique, msg)
end

local function AssertEntryExists(tbl, entry, name, msg)
	assert(tbl[entry] ~= nil, string.format("%s: %s '%s' could not be found. List of current valid %ss:\n%s", msg, name, entry, string.lower(name), save_table(tbl, 0)))
end

local template_tileset = {
	IsTilesetClass = true,
	Climate = "Not defined"
}

CreateClass(template_tileset)

function template_tileset:GetId()
	return self.Id
end

function template_tileset:CopyAssets(tileset_id)
	AssertEntryExists(modApi.tilesets, tileset_id, "Tileset", "CopyAssets - Arg#1 (tileset id)")
	
	if tileset_id == self:GetId() then
		return
	end
	
	modApi:copyTilesetAssets("tiles_".. tileset_id, "tiles_".. self:GetId())
end

function template_tileset:GetTilePath()
	return self.TilePath:gsub("[^/]$","%1/")
end

function template_tileset:SetTilePath(path)
	Assert.DirectoryRelativeToCurrentModExists(path, "SetTilePath - Arg#1 (folder containing tile images, relative to mod root)")
	
	self.TilePath = path
end

function template_tileset:GetEnvironmentChance(tileType, difficulty)
	-- tileset.EnvironmentChance can be structured as any of the following:
	-- tileset.EnvironmentChance == chance
	-- tileset.EnvironmentChance[tileType] == chance
	-- tileset.EnvironmentChance[difficulty][tileType] == chance
	
	local env = self.EnvironmentChance
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

function template_tileset:GetRainChance()
	return type(self.RainChance) == 'number' and self.RainChance or 0
end

function template_tileset:AddTile(id, loc)
	Assert.Equals('string', type(id), "AddTile - Arg#1 (tile id)")
	assert(loc == nil or isUserdataPoint(loc), "AddTile - Arg#2 (tile offset): Expected 'nil' or 'Point', but was '%s'", type(loc))
	
	if loc == nil then
		loc = tileLoc[id]
	end
	
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	local resourcePath = string.format("combat/tiles_%s/%s.png", self:GetId(), id)
	local filePath = string.format("%s%s%s.png", modPath, self:GetTilePath(), id)
	Location[resourcePath] = loc
	
	Assert.FileExists(filePath, string.format("AddTile - Arg#1"))
	
	modApi:appendAsset("img/".. resourcePath, filePath)
end

function template_tileset:AddTiles(tiles)
	for id, loc in pairs(tiles) do
		
		if type(id) == 'number' then
			id = loc
			loc = nil
		end
		
		self:AddTile(id, loc)
	end
end

function template_tileset:SetTilesetIcon(filePath)
	Assert.FileRelativeToCurrentModExists(filePath, "SetTileIcon - Arg#1 (Filepath for tileset icon)")
	
	local modPath = getCurrentModResourcePath()
	modApi:appendAsset(string.format("img/strategy/corp/%s_env.png", self:GetId()), modPath .. filePath)
end

function template_tileset:AppendAssets()
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	local tilePath = self:GetTilePath()
	local files = mod_loader:enumerateFilesIn(modPath .. tilePath)
	local images = {}
	
	for _, file in ipairs(files) do
		if modApi:stringEndsWith(file, ".png") then
			if file == "env.png" then
				self:SetTilesetIcon(tilePath .. file)
			else
				table.insert(images, file:sub(1, -5))
			end
		end
	end
	
	self:AddTiles(images)
end

modApi.tilesets = {}

function modApi:copyTilesetAssets(from, to)
	Assert.ResourceDatIsOpen("copyTilesetAssets")
	Assert.Equals('string', type(from), "Arg#1")
	Assert.Equals('string', type(to), "Arg#2")
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
	Assert.Equals('string', type(id), "newTileset - Arg#1 (Tileset id)")
	AssertIsUniqueId(modApi.tilesets[id] == nil, id, "newTileset - Arg#1 (Tileset id)")
	Assert.Equals({'nil', 'table', 'string'}, type(base), "newTileset - Arg#2 (Base tileset/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.tilesets, base, "Tileset", "newTileset - Arg#2")
		base = modApi.tilesets[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.tilesets, base.Id, "Tileset", "newTileset - Arg#2")
	end
	
	modApi.tilesets[id] = (base or template_tileset):new{
		Id = id,
		TilePath = string.format("img/combat/tiles_%s/", id)
	}
	local tileset = modApi.tilesets[id]
	
	if base ~= nil then
		tileset:CopyAssets(base.Id)
	end
	
	return tileset
end

function modApi:getTileset(id)
	AssertEntryExists(modApi.tilesets, id, "Tileset", "getTileset")
	
	return modApi.tilesets[id]
end

local vanillaTilesets = {
	"grass",
	"sand",
	"snow",
	"acid",
	"lava",
	"volcano"
}

local vanillaCorporations = {
	"Corp_Grass",
	"Corp_Desert",
	"Corp_Snow",
	"Corp_Factory"
}

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

-- temporarily override GetDifficulty while extracting EnvironmentChance for vanilla tilesets
local oldGetDifficulty = GetDifficulty
function GetDifficulty()
	return difficulty
end

-- add vanilla tilesets
for i, tileset_id in ipairs(vanillaTilesets) do
	local tileset = modApi:newTileset(tileset_id)
	
	local corp = vanillaCorporations[i]
	if corp then
		tileset.Climate = Mission_Texts[corp .."_Environment"] or template_tileset.Climate
	end
	
	-- extract RainChance from vanilla function
	tileset.RainChance = getRainChance(tileset_id)
	
	-- extract EnvironmentChance from vanilla function
	tileset.EnvironmentChance = {}
	
	for _, diff in ipairs(difficulties) do
		difficulty = diff
		tileset.EnvironmentChance[diff] = {}
		
		for _, tileType in ipairs(tileTypes) do
			tileset.EnvironmentChance[diff][tileType] = getEnvironmentChance(tileset_id, tileType)
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
	
	if tileset and tileset.GetEnvironmentChance then
		return tileset:GetEnvironmentChance(tileType, GetDifficulty())
	end
	
	return 0
end
