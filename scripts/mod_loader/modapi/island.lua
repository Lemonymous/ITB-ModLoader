
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

local function AssertTableHasFields(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	assert(type(actual) == 'table', string.format("%sExpected 'table', but was '%s'", msg, type(actual)))
	
	for key, value in pairs(expected) do
		assert(value == type(actual[key]), string.format("%sExpected field '%s' to be '%s', but was '%s'", msg, key, value, type(actual[key])))
	end
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

local function AssertRange(from, to, actual, msg)
	assert(actual >= from and actual <= to, string.format("%s: Expected value in range [%s,%s], but was %s", msg, from, to, actual))
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

local vanillaIslands = {
	"grass",
	"desert",
	"snow",
	"factory",
	"volcano"
}

local Island_Shifts = {
	Point(14,5),
	Point(16,15),
	Point(17,12),
	Point(18,15),
	Point(0,0)
}

local template_island = {
	isIslandClass = true,
	shift = Island_Shifts[1],
	magic = Island_Magic[1],
	data = {
		Region_Data["island_0_0"],
		Region_Data["island_0_1"],
		Region_Data["island_0_2"],
		Region_Data["island_0_3"],
		Region_Data["island_0_4"],
		Region_Data["island_0_5"],
		Region_Data["island_0_6"],
		Region_Data["island_0_7"]
	},
	network = {
		Network_Island_0["0"],
		Network_Island_0["1"],
		Network_Island_0["2"],
		Network_Island_0["3"],
		Network_Island_0["4"],
		Network_Island_0["5"],
		Network_Island_0["6"],
		Network_Island_0["7"]
	}
}

CreateClass(template_island)

function template_island:getId()
	return self.id
end

function template_island:getPaths()
	local id = self:getId()
	
	return {
		["island"] = string.format("island%s", id),
		["island1x"] = string.format("island1x_%s", id),
		["island1x_out"] = string.format("island1x_%s_out", id),
		["islands/island_0"] = string.format("islands/island_%s_0", id),
		["islands/island_1"] = string.format("islands/island_%s_1", id),
		["islands/island_2"] = string.format("islands/island_%s_2", id),
		["islands/island_3"] = string.format("islands/island_%s_3", id),
		["islands/island_4"] = string.format("islands/island_%s_4", id),
		["islands/island_5"] = string.format("islands/island_%s_5", id),
		["islands/island_6"] = string.format("islands/island_%s_6", id),
		["islands/island_7"] = string.format("islands/island_%s_7", id),
		["islands/island_0_OL"] = string.format("islands/island_%s_0_OL", id),
		["islands/island_1_OL"] = string.format("islands/island_%s_1_OL", id),
		["islands/island_2_OL"] = string.format("islands/island_%s_2_OL", id),
		["islands/island_3_OL"] = string.format("islands/island_%s_3_OL", id),
		["islands/island_4_OL"] = string.format("islands/island_%s_4_OL", id),
		["islands/island_5_OL"] = string.format("islands/island_%s_5_OL", id),
		["islands/island_6_OL"] = string.format("islands/island_%s_6_OL", id),
		["islands/island_7_OL"] = string.format("islands/island_%s_7_OL", id)
	}
end

function template_island:getIslandPath()
	return self.islandPath:gsub("[^/]$","%1/")
end

function template_island:setIslandPath(path)
	AssertEquals('string', type(path), "setIslandPath - Arg#1 (folder containing island images, relative to mod root)")
	
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	assert(modApi:directoryExists(modPath .. path), string.format("setIslandPath - Arg#1: Directory '%s' does not exist", modPath .. path))
	
	self.islandPath = path
end

function template_island:setEnemyList(enemyListOrIdOrIslandNumber)
	AssertMultiple({'table', 'string', 'number'}, type(enemyListOrIdOrIslandNumber), "setEnemyList - Arg#1 (Enemy list, id or island number)")
	
	local enemyList = enemyListOrIdOrIslandNumber
	
	if type(enemyList) == 'table' then
		assert(enemyList.isEnemyListClass, "setEnemyList - Arg#1: Table is not a valid enemyList")
	else
		enemyList = modApi:getEnemyList(enemyList)
	end
	
	self.enemyList = enemyList:getId()
end

function template_island:getEnemyList()
	return type(self.enemyList) == 'string' and modApi:getEnemyList(self.enemyList) or nil
end

function template_island:setCorporation(corpOrIdOrIslandNumber)
	AssertMultiple({'table', 'string', 'number'}, type(corpOrIdOrIslandNumber), "setCorporation - Arg#1 (Corp, id or island number")
	
	local corp = corpOrIdOrIslandNumber
	
	if type(corp) == 'table' then
		assert(corp.isCorporationClass, "setCorporation - Arg#1: Table is not a valid corporation")
	else
		corp = modApi:getCorporation(corp)
	end
	
	self.corp = corp:getId()
end

function template_island:getCorporation()
	return self.corp and modApi:getCorporation(self.corp) or nil
end

function template_island:copyAssets(island_id)
	AssertEntryExists(modApi.islands, island_id, "Island", "copyAssets - Arg#1 (island id)")
	
	if island_id == self:getId() then
		return
	end
	
	modApi:copyIslandAssets(island_id, self:getId())
end

function template_island:appendAssets()
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	local paths = self:getPaths()
	local islandPath = self:getIslandPath()
	
	local function appendAsset(to, from)
		if modApi:fileExists(from) then
			modApi:appendAsset(to, from)
		end
	end
	
	for from, to in pairs(paths) do
		from = string.format("%s%s%s.png", modPath, islandPath, from)
		to = string.format("img/strategy/%s.png", to)
		
		appendAsset(to, from)
	end
end

modApi.islands = {}

function modApi:copyIslandAssets(from, to)
	AssertEquals('string', type(from), "Arg#1")
	AssertEquals('string', type(to), "Arg#2")
	AssertResourcesDatExists("copyIslandAssets")
	
	local root = "img/strategy/"
	
	modApi:copyAsset(string.format("%sisland%s.png", root, from), string.format("%sisland%s.png", root, to))
	modApi:copyAsset(string.format("%sisland1x_%s.png", root, from), string.format("%sisland1x_%s.png", root, to))
	modApi:copyAsset(string.format("%sisland1x_%s_out.png", root, from), string.format("%sisland1x_%s_out.png", root, to))
	
	for k = 0, 7 do
		modApi:copyAsset(string.format("%sislands/island_%s_%s.png", root, from, k), string.format("%sislands/island_%s_%s.png", root, to, k))
		modApi:copyAsset(string.format("%sislands/island_%s_%s_OL.png", root, from, k), string.format("%sislands/island_%s_%s_OL.png", root, to, k))
	end
end

function modApi:newIsland(id, base)
	AssertEquals('string', type(id), "newIsland - Arg#1 (Island id)")
	AssertIsUniqueId(modApi.islands[id] == nil, id, "newIsland - Arg#1 (Island id)")
	AssertMultiple({'nil', 'table', 'string'}, type(base), "newIsland - Arg#2 (Base island/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.islands, base, "Island", "newIsland - Arg#2")
		base = modApi.islands[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.islands, base.id, "Island", "newIsland - Arg#2")
	end
	
	modApi.islands[id] = (base or template_island):new{
		id = id,
		islandPath = string.format("img/strategy/", id)
	}
	local island = modApi.islands[id]
	
	if base ~= nil then
		island:copyAssets(base.id)
	end
	
	return island
end

function modApi:getIsland(islandNumberOrIslandId)
	AssertMultiple({'number', 'string'}, type(islandNumberOrIslandId), "getIsland - Arg#1 (Island number or island id)")
	
	if type(islandNumberOrIslandId) == 'number' then
		local islandNumber = islandNumberOrIslandId
		AssertRange(1, 5, islandNumber, "getIsland - Arg#1 (Island number)")
		
		return Islands[islandNumber]
		
	elseif type(islandNumberOrIslandId) == 'string' then
		local island_id = islandNumberOrIslandId
		AssertEntryExists(modApi.islands, island_id, "Island", "getIsland - Arg#1 (Island id)")
		
		return modApi.islands[island_id]
	end
end

function modApi:setIsland(islandNumber, island)
	AssertEquals('number', type(islandNumber), "setIsland - Arg#1 (Island number)")
	AssertRange(1, 5, islandNumber, "setIsland - Arg#1 (Island Number)")
	AssertMultiple({'table', 'string'}, type(island), "setIsland - Arg#2 (Island)")
	
	if type(island) == 'string' then
		AssertEntryExists(modApi.islands, island, "Island", "setIsland - Arg#2 (Island id)")
		island = modApi.islands[island]
	else
		AssertTableHasFields({id = 'string'}, island, "setIsland - Arg#2 (Island)")
		AssertEntryExists(modApi.islands, island.id, "Island", "setIsland - Arg#2 (Island)")
	end
	
	local defaultRegionInfo = RegionInfo(Point(0,0), Point(0,0), 100)
	local n = islandNumber-1
	
	Island_Magic[islandNumber] = island.magic
	
	Location[string.format("strategy/island%s.png", n)] = Island_Locations[islandNumber]
	Location[string.format("strategy/island1x_%s.png", n)] = Island_Locations[islandNumber] - island.shift
	Location[string.format("strategy/island1x_%s_out.png", n)] = Island_Locations[islandNumber] - island.shift
	
	for k = 0, 7 do
		Region_Data[string.format("island_%s_%s", n, k)] = island.data[k+1] or defaultRegionInfo
	end
	
	for k = 0, 7 do
		_G["Network_Island_".. n][tostring(k)] = island.network[k+1]
	end
	
	modApi:copyIslandAssets(island.id, tostring(n))
	
	if island.corp ~= nil then
		modApi:setCorporation(islandNumber, island.corp)
	end
	
	Islands[islandNumber] = island
end

Islands = {}

-- save all vanilla island data
for i, id in ipairs(vanillaIslands) do
	local island = modApi:newIsland(id)
	local n = i-1
	
	island.shift = Island_Shifts[i]
	island.magic = Island_Magic[i]
	--island.location = Island_Locations[i]
	island.data = {}
	island.network = {}
	
	if i <= 4 then
		for k = 0, 7 do
			table.insert(island.data, Region_Data[string.format("island_%s_%s", n, k)])
		end
		
		for k = 0, 7 do
			table.insert(island.network, _G["Network_Island_".. n][tostring(k)])
		end
		
		island:setCorporation(i)
	end
	
	island:setEnemyList(id)
	
	-- Island assets will be copied in mod_loader.loadAdditionalSprites
	--modApi:copyIslandAssets(tostring(n), id)
	
	modApi.islands[id] = island
	Islands[i] = island
end
