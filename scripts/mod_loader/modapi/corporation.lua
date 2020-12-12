
local function getCurrentModResourcePath()
	return mod_loader.mods[modApi.currentMod].resourcePath
end

local function AssertTableHasFields(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	assert(type(actual) == 'table', string.format("%sExpected 'table', but was '%s'", msg, type(actual)))
	
	for key, value in pairs(expected) do
		assert(value == type(actual[key]), string.format("%sExpected field '%s' to be '%s', but was '%s'", msg, key, value, type(actual[key])))
	end
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
template_corp.IsCorporationClass = true
template_corp.Id = "Corp_Default"
template_corp.Description = "This is a non-descript default corporation"
template_corp.Bark_Name = "Default"

function template_corp:GetId()
	return self.Id
end

function template_corp:SetTileset(tilesetOrId)
	Assert.Equals({'table', 'string'}, type(tilesetOrId), "SetTileset - Arg#1 (Tileset or id")
	
	local tileset = tilesetOrId
	
	if type(tileset) == 'table' then
		assert(tileset.IsTilesetClass, "SetTileset - Arg#1: Table is not a valid tileset")
	else
		tileset = modApi:getTileset(tileset)
	end
	
	self.Tileset = tileset:GetId()
end

function template_corp:GetTileset()
	return type(self.Tileset) == 'string' and modApi:getTileset(self.Tileset) or nil
end

function template_corp:SetOffice(path_office_large, path_office_small)
	Assert.FileRelativeToCurrentModExists(path_office_large, "SetOffice - Arg#1 (Filepath for corporation office)")
	Assert.FileRelativeToCurrentModExists(path_office_small, "SetOffice - Arg#2 (Filepath for small version of corporation)")
	
	self.Office = self:GetId()
	
	local modPath = getCurrentModResourcePath()
	modApi:appendAsset(string.format("img/ui/corps/%s.png", self.Office), modPath .. path_office_large)
	modApi:appendAsset(string.format("img/ui/corps/%s_small.png", self.Office), modPath .. path_office_small)
end

function template_corp:SetCEO(path_ceo_image, personality)
	Assert.FileRelativeToCurrentModExists(path_ceo_image, "SetCEO - Arg#1 (Filepath for CEO portrait)")
	AssertTableHasFields(
	{
		Label = 'string',
		Name = 'string',
		GetPilotDialog = 'function'
	},
	personality, "setCEO - Arg#2 (CEO personality)")
	
	local ceo_personality_id = "CEO_".. self:GetId()
	self.CEO_Image = self:GetId() ..".png"
	self.CEO_Name = personality.Name
	self.CEO_Personality = ceo_personality_id
	
	Personality[ceo_personality_id] = personality
	
	local modPath = getCurrentModResourcePath()
	modApi:appendAsset(string.format("img/portraits/ceo/%s.png", self:GetId()), modPath .. path_ceo_image)
end

function template_corp:CopyAssets(corp_id)
	AssertEntryExists(modApi.corporations, corp_id, "Corporation", "CopyAssets - Arg#1 (corp id)")
	
	if corp_id == self:GetId() then
		return
	end
	
	local to = modApi.corporations[corp_id]
	
	modApi:copyAsset(string.format("img/ui/corps/%s.png", self.Office), string.format("img/ui/corps/%s.png", to.Office))
	modApi:copyAsset(string.format("img/ui/corps/%s_small.png", self.Office), string.format("img/ui/corps/%s_small.png", to.Office))
	modApi:copyAsset(string.format("img/portraits/ceo/%s", self.CEO_Image), string.format("img/portraits/ceo/%s", to.CEO_Image))
end

local vanillaCorporations = {
	"Corp_Grass",
	"Corp_Desert",
	"Corp_Snow",
	"Corp_Factory"
}

function modApi:newCorporation(id, base)
	Assert.Equals('string', type(id), "newCorporation - Arg#1 (Corporation id)")
	AssertIsUniqueId(modApi.corporations[id] == nil, id, "newCorporation - Arg#1 (Corporation id)")
	Assert.Equals({'nil', 'table', 'string'}, type(base), "newCorporation - Arg#2 (Base corporation/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.corporations, base, "Corporation", "newCorporation - Arg#2")
		base = modApi.corporations[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.corporations, base.Id, "Corporation", "newCorporation - Arg#2")
	end
	
	modApi.corporations[id] = (base or template_corp):new{ Id = id }
	local corp = modApi.corporations[id]
	
	-- create unique copies of all tables in default template
	for i, _ in pairs(template_corp) do
		if i ~= '__index' then
			corp[i] = shallow_copy(corp[i])
		end
	end
	
	if base ~= nil then
		corp:CopyAssets(base.Id)
	end
	
	return corp
end

function modApi:getCorporation(islandNumberOrCorpId)
	Assert.Equals({'number', 'string'}, type(islandNumberOrCorpId), "getCorporation - Arg#1 (Island number or corporation id)")
	
	if type(islandNumberOrCorpId) == 'number' then
		local islandNumber = islandNumberOrCorpId
		Assert.Range(1, 4, islandNumber, "getCorporation - Arg#1 (Island number)")
		
		local corp_id = vanillaCorporations[islandNumber]
		return _G[corp_id]
		
	elseif type(islandNumberOrCorpId) == 'string' then
		local corp_id = islandNumberOrCorpId
		AssertEntryExists(modApi.corporations, corp_id, "Corporation", "getCorporation - Arg#1 (Corporation id)")
		
		return modApi.corporations[corp_id]
	end
end

function modApi:setCorporation(islandNumber, corp)
	Assert.Equals('number', type(islandNumber), "setCorporation - Arg#1 (Island number)")
	Assert.Range(1, 4, islandNumber, "setCorporation - Arg#1 (Island number)")
	Assert.Equals({'table', 'string'}, type(corp), "setCorporation - Arg#2 (Corporation)")
	
	if type(corp) == 'string' then
		AssertEntryExists(modApi.corporations, corp, "Corporation", "setCorporation - Arg#2 (Corporation id)")
		corp = modApi.corporations[corp]
	else
		AssertTableHasFields({Id = 'string'}, corp, "setCorporation - Arg#2 (Corporation)")
		AssertEntryExists(modApi.corporations, corp.Id, "Corporation", "setCorporation - Arg#2 (Corporation)")
	end
	
	local vanilla_corp = vanillaCorporations[islandNumber]
	
	_G[vanilla_corp] = corp
	
	modApi.modLoaderDictionary[vanilla_corp .."_CEO_Name"] = corp.CEO_Name
	modApi.modLoaderDictionary[vanilla_corp .."_Name"] = corp.Name
	modApi.modLoaderDictionary[vanilla_corp .."_Environment"] = modApi:getTileset(corp.Tileset).Climate
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
	corp.Description = Global_Texts[corp_id .."_Description"] or base.Description or ""
	
	-- update actual corp
	_G[corp_id] = corp
end
