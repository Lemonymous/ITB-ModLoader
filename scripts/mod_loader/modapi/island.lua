
local function traceback()
	return Assert.Traceback and debug.traceback("\n", 3) or ""
end

local function AssertTableHasFields(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	assert(type(actual) == 'table', string.format("%sExpected 'table', but was '%s'%s", msg, type(actual), traceback()))
	
	for key, value in pairs(expected) do
		assert(value == type(actual[key]), string.format("%sExpected field '%s' to be '%s', but was '%s'%s", msg, key, value, type(actual[key]), traceback()))
	end
end

local function AssertIsUniqueId(isUnique, id, msg)
	msg = (msg and msg .. ": ") or ""
	msg = string.format("%s Id '%s' is already taken%s", msg, id, traceback())
	assert(isUnique, msg)
end

local function AssertEntryExists(tbl, entry, name, msg)
	assert(tbl[entry] ~= nil, string.format("%s: %s '%s' could not be found. List of current valid %ss:\n%s%s", msg, name, entry, string.lower(name), save_table(tbl, 0), traceback()))
end

local vanillaIslands = {
	"grass",
	"desert",
	"snow",
	"factory",
	--"volcano"
}

local Island_Shifts = {
	Point(14,5),
	Point(16,15),
	Point(17,12),
	Point(18,15),
	Point(0,0)
}

local template_island = {
	IsIslandClass = true,
	Shift = Island_Shifts[1],
	Magic = Island_Magic[1],
	Data = {
		Region_Data["island_0_0"],
		Region_Data["island_0_1"],
		Region_Data["island_0_2"],
		Region_Data["island_0_3"],
		Region_Data["island_0_4"],
		Region_Data["island_0_5"],
		Region_Data["island_0_6"],
		Region_Data["island_0_7"]
	},
	Network = {
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

function template_island:GetId()
	return self.Id
end

function template_island:GetPaths()
	local id = self:GetId()
	
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

function template_island:GetIslandPath()
	return self.IslandPath:gsub("[^/]$","%1/")
end

function template_island:SetIslandPath(path)
	Assert.DirectoryRelativeToCurrentModExists(path, "SetIslandPath - Arg#1 (folder containing island images, relative to mod root)")
	
	self.IslandPath = path
end

function template_island:SetEnemyList(enemyListOrIdOrIslandNumber)
	Assert.Equals({'table', 'string', 'number'}, type(enemyListOrIdOrIslandNumber), "SetEnemyList - Arg#1 (Enemy list, id or island number)")
	
	local enemyList = enemyListOrIdOrIslandNumber
	
	if type(enemyList) == 'table' then
		assert(enemyList.IsEnemyListClass, "SetEnemyList - Arg#1: Table is not a valid enemyList")
	else
		enemyList = modApi:getEnemyList(enemyList)
	end
	
	self.EnemyList = enemyList:GetId()
end

function template_island:GetEnemyList()
	return type(self.EnemyList) == 'string' and modApi:getEnemyList(self.EnemyList) or nil
end

function template_island:SetCorporation(corpOrIdOrIslandNumber)
	Assert.Equals({'table', 'string', 'number'}, type(corpOrIdOrIslandNumber), "SetCorporation - Arg#1 (Corp, id or island number")
	
	local corp = corpOrIdOrIslandNumber
	
	if type(corp) == 'table' then
		assert(corp.IsCorporationClass, "SetCorporation - Arg#1: Table is not a valid corporation")
	else
		corp = modApi:getCorporation(corp)
	end
	
	self.Corp = corp:GetId()
end

function template_island:GetCorporation()
	return type(self.Corp) == 'string' and modApi:getCorporation(self.Corp) or nil
end

function template_island:CopyAssets(island_id)
	AssertEntryExists(modApi.islands, island_id, "Island", "CopyAssets - Arg#1 (island id)")
	
	if island_id == self:GetId() then
		return
	end
	
	modApi:copyIslandAssets(island_id, self:GetId())
end

function template_island:AppendAssets()
	local modPath = mod_loader.mods[modApi.currentMod].resourcePath
	local paths = self:GetPaths()
	local islandPath = self:GetIslandPath()
	
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
	Assert.Equals('string', type(from), "Arg#1")
	Assert.Equals('string', type(to), "Arg#2")
	Assert.ResourceDatIsOpen("copyIslandAssets")
	
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
	Assert.Equals('string', type(id), "newIsland - Arg#1 (Island id)")
	AssertIsUniqueId(modApi.islands[id] == nil, id, "newIsland - Arg#1 (Island id)")
	Assert.Equals({'nil', 'table', 'string'}, type(base), "newIsland - Arg#2 (Base island/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.islands, base, "Island", "newIsland - Arg#2")
		base = modApi.islands[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.islands, base.Id, "Island", "newIsland - Arg#2")
	end
	
	modApi.islands[id] = (base or template_island):new{
		Id = id,
		IslandPath = string.format("img/strategy/", id)
	}
	local island = modApi.islands[id]
	
	if base ~= nil then
		island:CopyAssets(base.Id)
	end
	
	return island
end

function modApi:getIsland(islandNumberOrIslandId)
	Assert.Equals({'number', 'string'}, type(islandNumberOrIslandId), "getIsland - Arg#1 (Island number or island id)")
	
	if type(islandNumberOrIslandId) == 'number' then
		local islandNumber = islandNumberOrIslandId
		Assert.Range(1, 5, islandNumber, "getIsland - Arg#1 (Island number)")
		
		return Islands[islandNumber]
		
	elseif type(islandNumberOrIslandId) == 'string' then
		local island_id = islandNumberOrIslandId
		AssertEntryExists(modApi.islands, island_id, "Island", "getIsland - Arg#1 (Island id)")
		
		return modApi.islands[island_id]
	end
end

function modApi:setIsland(islandNumber, island)
	Assert.Equals('number', type(islandNumber), "setIsland - Arg#1 (Island number)")
	Assert.Range(1, 5, islandNumber, "setIsland - Arg#1 (Island Number)")
	Assert.Equals({'table', 'string'}, type(island), "setIsland - Arg#2 (Island)")
	
	if type(island) == 'string' then
		AssertEntryExists(modApi.islands, island, "Island", "setIsland - Arg#2 (Island id)")
		island = modApi.islands[island]
	else
		AssertTableHasFields({Id = 'string'}, island, "setIsland - Arg#2 (Island)")
		AssertEntryExists(modApi.islands, island.Id, "Island", "setIsland - Arg#2 (Island)")
	end
	
	local defaultRegionInfo = RegionInfo(Point(0,0), Point(0,0), 100)
	local n = islandNumber-1
	
	Island_Magic[islandNumber] = island.Magic
	
	Location[string.format("strategy/island%s.png", n)] = Island_Locations[islandNumber]
	Location[string.format("strategy/island1x_%s.png", n)] = Island_Locations[islandNumber] - island.Shift
	Location[string.format("strategy/island1x_%s_out.png", n)] = Island_Locations[islandNumber] - island.Shift
	
	for k = 0, 7 do
		Region_Data[string.format("island_%s_%s", n, k)] = island.Data[k+1] or defaultRegionInfo
	end
	
	for k = 0, 7 do
		_G["Network_Island_".. n][tostring(k)] = island.Network[k+1]
	end
	
	modApi:copyIslandAssets(island.Id, tostring(n))
	
	if island.Corp ~= nil then
		modApi:setCorporation(islandNumber, island.Corp)
	end
	
	Islands[islandNumber] = island
end

Islands = {}

-- save all vanilla island data
for i, id in ipairs(vanillaIslands) do
	local island = modApi:newIsland(id)
	local n = i-1
	
	island.Shift = Island_Shifts[i]
	island.Magic = Island_Magic[i]
	--island.Location = Island_Locations[i]
	island.Data = {}
	island.Network = {}
	
	if i <= 4 then
		for k = 0, 7 do
			table.insert(island.Data, Region_Data[string.format("island_%s_%s", n, k)])
		end
		
		for k = 0, 7 do
			table.insert(island.Network, _G["Network_Island_".. n][tostring(k)])
		end
		
		island:SetCorporation(i)
	end
	
	island:SetEnemyList(id)
	
	-- Island assets will be copied in mod_loader.loadAdditionalSprites
	--modApi:copyIslandAssets(tostring(n), id)
	
	modApi.islands[id] = island
	Islands[i] = island
end
