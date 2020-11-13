
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
	assert(tbl[entry] ~= nil, string.format("%s: %s '%s' could not be found. List of current valid %ss:\n%s%s", msg, name, entry, string.lower(name), save_table(tbl, 0), debug.traceback()))
end

local template_corp = Corp_Default
template_corp.isCorporationClass = true
template_corp.id = "Corp_Default"
template_corp.Environment = "Unremarkable"
template_corp.Description = "This is a non-descript default corporation"
template_corp.Bark_Name = "Default"

function template_corp:getId()
	return self.id
end

function template_corp:setEnvironment(name)
	AssertEquals('string', type(name), "setEnvironment - Arg#1 (Corporation environment name)")
	
	self.Environment = name
end

function template_corp:getEnvironment()
	return self.Environment
end

function template_corp:setTileset(tileset_id)
	AssertEquals('string', type(tileset_id), "setTileset - Arg#1 (Corporation tileset id)")
	
	assert(type(modApi.tilesets[tileset_id]) == 'table', string.format("setTileset - Attempted to set tileset %q for corporation %q. Tileset does not exist", tileset_id, self:getId()))
	
	self.Tileset = tileset_id
end

function template_corp:getTileset()
	return self.Tileset
end

function template_corp:setOffice(path_office_large, path_office_small)
	AssertFilePath(path_office_large, ".png", "setOffice - Arg#1 (Filepath for corporation office)")
	AssertFilePath(path_office_small, ".png", "setOffice - Arg#2 (Filepath for small version of corporation)")
	
	self.Office = self:getId()
	modApi:appendAsset(string.format("img/ui/corps/%s.png", self.Office), getModFilePathRelativeToGameDir(path_office_large))
	modApi:appendAsset(string.format("img/ui/corps/%s_small.png", self.Office), getModFilePathRelativeToGameDir(path_office_small))
end

function template_corp:setCEO(path_ceo_image, personality)
	AssertFilePath(path_ceo_image, ".png", "setCEO - Arg#1 (Filepath for CEO portrait)")
	AssertTableHasFields(
	{
		Label = 'string',
		Name = 'string',
		GetPilotDialog = 'function'
	},
	personality, "setCEO - Arg#2 (CEO personality)")
	
	local ceo_personality_id = "CEO_".. self:getId()
	self.CEO_Image = self:getId() ..".png"
	self.CEO_Name = personality.Name
	self.CEO_Personality = ceo_personality_id
	
	Personality[ceo_personality_id] = personality
	
	modApi:appendAsset(string.format("img/portraits/ceo/%s.png", self:getId()), getModFilePathRelativeToGameDir(path_ceo_image))
end

local vanillaCorporations = {
	"Corp_Grass",
	"Corp_Desert",
	"Corp_Snow",
	"Corp_Factory"
}

function modApi:newCorporation(id, base)
	AssertEquals('string', type(id), "newCorporation - Arg#1 (Corporation id)")
	AssertIsUniqueId(modApi.corporations[id] == nil, id, "newCorporation - Arg#1 (Corporation id)")
	AssertMultiple({'nil', 'table', 'string'}, type(base), "newCorporation - Arg#2 (Base corporation/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.corporations, base, "Corporation", "newCorporation - Arg#2")
		base = modApi.corporations[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.corporations, base.id, "Corporation", "newCorporation - Arg#2")
	end
	
	modApi.corporations[id] = (base or template_corp):new{ id = id }
	local corp = modApi.corporations[id]
	
	-- create unique copies of all tables in default template
	for i, _ in pairs(template_corp) do
		if i ~= '__index' then
			corp[i] = shallow_copy(corp[i])
		end
	end
	
	return corp
end

function modApi:getCorporation(islandNumberOrCorpId)
	AssertMultiple({'number', 'string'}, type(islandNumberOrCorpId), "getCorporation - Arg#1 (Island number or corporation id)")
	
	if type(islandNumberOrCorpId) == 'number' then
		local islandNumber = islandNumberOrCorpId
		AssertRange(1, 4, islandNumber, "getCorporation - Arg#1 (Island number)")
		
		local corp_id = vanillaCorporations[islandNumber]
		return _G[corp_id]
		
	elseif type(islandNumberOrCorpId) == 'string' then
		local corp_id = islandNumberOrCorpId
		AssertEntryExists(modApi.corporations, corp_id, "Corporation", "getCorporation - Arg#1 (Corporation id)")
		
		return modApi.corporations[corp_id]
	end
end

function modApi:setCorporation(islandNumber, corp)
	AssertEquals('number', type(islandNumber), "setCorporation - Arg#1 (Island number)")
	AssertRange(1, 4, islandNumber, "setCorporation - Arg#1 (Island number)")
	AssertMultiple({'table', 'string'}, type(corp), "setCorporation - Arg#2 (Corporation)")
	
	if type(corp) == 'string' then
		AssertEntryExists(modApi.corporations, corp, "Corporation", "setCorporation - Arg#2 (Corporation id)")
		corp = modApi.corporations[corp]
	else
		AssertTableHasFields({id = 'string'}, corp, "setCorporation - Arg#2 (Corporation)")
		AssertEntryExists(modApi.corporations, corp.id, "Corporation", "setCorporation - Arg#2 (Corporation)")
	end
	
	local vanilla_corp = vanillaCorporations[islandNumber]
	
	_G[vanilla_corp] = corp
	
	modApi.modLoaderDictionary[vanilla_corp .."_CEO_Name"] = corp.CEO_Name
	modApi.modLoaderDictionary[vanilla_corp .."_Name"] = corp.Name
	modApi.modLoaderDictionary[vanilla_corp .."_Environment"] = corp.Environment
	modApi.modLoaderDictionary[vanilla_corp .."_Description"] = corp.Description
	modApi.modLoaderDictionary[vanilla_corp .."_Bark"] = corp.Bark_Name
end

modApi.corporations = {}

-- update vanilla corporations with new functionality
for _, corp_id in ipairs(vanillaCorporations) do
	local corp = modApi:newCorporation(corp_id)
	
	-- copy over data from actual corp
	for i, v in pairs(_G[corp_id]) do
		corp[i] = v
	end
	
	corp.CEO_Name = Mission_Texts[corp_id .."_CEO_Name"] or base.CEO_Name or ""
	corp.Name = Mission_Texts[corp_id .."_Name"] or base.Name or ""
	corp.Environment = Mission_Texts[corp_id .."_Environment"] or base.Environment or ""
	corp.Description = Global_Texts[corp_id .."_Description"] or base.Description or ""
	
	-- update actual corp
	_G[corp_id] = corp
end
