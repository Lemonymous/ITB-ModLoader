
local function traceback()
	return Assert.Traceback and debug.traceback("\n", 3) or ""
end

local function AssertIsUniqueId(isUnique, id, msg)
	msg = (msg and msg .. ": ") or ""
	msg = string.format("%s Id '%s' is already taken%s", msg, id, traceback())
	assert(isUnique, msg)
end

local function AssertEntryExists(tbl, entry, name, msg)
	assert(tbl[entry] ~= nil, string.format("%s: %s '%s' could not be found. List of current valid %ss:\n%s%s", msg, name, entry, string.lower(name), save_table(tbl, 0), traceback()))
end

function shuffle_list(list)
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		
		-- swap entries
		list[i], list[j] = list[j], list[i]
	end
end

local template_enemyList = {
	IsEnemyListClass = true,
	Categories = { "Core", "Core", "Core", "Leaders", "Unique", "Unique" },
	Enemies = {},
	Bosses = {}
}

CreateClass(template_enemyList)

function template_enemyList:GetId()
	return self.Id
end

function template_enemyList:SetCategories(categories)
	Assert.Equals(6, #categories, "SetCategories - Arg#1 (number of categories)")
	
	self.Categories = categories
end

function template_enemyList:AddEnemy(enemy, category)
	Assert.Equals('string', type(enemy), "AddEnemy - Arg#1 (enemy id)")
	Assert.Equals('string', type(enemy), "AddEnemy - Arg#1 (enemy category; 'Core', 'Leaders' or 'Unique')")
	
	self.Enemies[category] = self.Enemies[category] or {}
	table.insert(self.Enemies[category], enemy)
end

function template_enemyList:PickEnemies(islandNumber, timesPicked)
	timesPicked = timesPicked or {}
	local result = {}
	local choices = {}
	local excluded = {}
	
	local exclusiveReversed = {}
	for i, v in ipairs(ExclusiveElements) do
		exclusiveReversed[v] = i
	end
	
	local function isUnlocked(unit)
		local lock = IslandLocks[unit] or 4
		return islandNumber == nil or islandNumber >= lock or Game:IsIslandUnlocked(lock-1)
	end
	
	local function addExclusions(unit)
		if ExclusiveElements[unit] then
			excluded[ExclusiveElements[unit]] = true
		end
		if exclusiveReversed[unit] then
			excluded[exclusiveReversed[unit]] = true
		end
	end
	
	local function getEnemyChoices(category)
		if type(category) ~= 'string' then
			return {}
		end
		
		if choices[category] and #choices[category] > 0 then
			return choices[category]
		end
		
		local leastPicked = INT_MAX
		
		choices[category] = {}
		self.Enemies[category] = self.Enemies[category] or {}
		for _, enemy in ipairs(self.Enemies[category]) do
			if isUnlocked(enemy) and not excluded[enemy] then
				table.insert(choices[category], enemy)
			end
		end
		
		shuffle_list(choices[category])
		table.sort(choices[category], function(a,b)
			return (timesPicked[a] or 0) > (timesPicked[b] or 0)
		end)
		
		return choices[category]
	end
	
	for _, category in ipairs(self.Categories) do
		local enemyChoices = getEnemyChoices(category)
		local choice = "Scorpion"
		
		for i = #enemyChoices, 1, -1 do
			if not excluded[enemyChoices[i]] then
				choice = enemyChoices[i]
				table.remove(enemyChoices, i)
				
				break
			end
		end
		
		timesPicked[choice] = (timesPicked[choice] or 0) + 1
		addExclusions(choice)
		table.insert(result, choice)
	end
	
	Assert.Equals(6, #result, "PickEnemies - Resulting number of enemies")
	
	return result
end

function template_enemyList:PickBoss()
	
end

modApi.enemyLists = {}

function modApi:newEnemyList(id, base)
	Assert.Equals('string', type(id), "newEnemyList - Arg#1 (Enemy list id)")
	AssertIsUniqueId(modApi.enemyLists[id] == nil, id, "newEnemyList - Arg#1 (Enemy list id)")
	Assert.Equals({'nil', 'table', 'string'}, type(base), "newEnemyList - Arg#2 (Base enemy list/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.enemyLists, base, "EnemyList", "newEnemyList - Arg#2")
		base = modApi.enemyLists[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.enemyLists, base.Id, "EnemyList", "newEnemyList - Arg#2")
	end
	
	modApi.enemyLists[id] = (base or template_enemyList):new{ Id = id }
	local enemyList = modApi.enemyLists[id]
	
	-- create unique copies of all tables in default template
	for i, _ in pairs(template_enemyList) do
		if i ~= '__index' then
			enemyList[i] = copy_table(enemyList[i])
		end
	end
	
	return enemyList
end

function modApi:getEnemyList(enemyListIdOrIslandNumber)
	Assert.Equals({'number', 'string'}, type(enemyListIdOrIslandNumber), "getEnemyList - Arg#1 (Island number or enemy list id)")
	
	if type(enemyListIdOrIslandNumber) == 'number' then
		local islandNumber = enemyListIdOrIslandNumber
		local island = modApi:getIsland(islandNumber)
		
		return island:GetEnemyList()
		
	elseif type(enemyListIdOrIslandNumber) == 'string' then
		local enemyList_id = enemyListIdOrIslandNumber
		AssertEntryExists(modApi.enemyLists, enemyList_id, "Enemy list", "getEnemyList - Arg#1 (Enemy list id)")
		
		return modApi.enemyLists[enemyList_id]
	end
end

local vanillaEnemyLists = {
	"grass",
	"desert",
	"snow",
	"factory",
	"volcano"
}

local vanillaCorps = {
	"Corp_Grass",
	"Corp_Desert",
	"Corp_Snow",
	"Corp_Factory",
}

for i, id in ipairs(vanillaEnemyLists) do
	local enemyList = modApi:newEnemyList(id)
	local corp = _G[vanillaCorps[i]]
	
	enemyList.Enemies = copy_table(EnemyLists)
	
	if corp then
		enemyList.Bosses = add_arrays(corp.Bosses, corp.UniqueBosses)
	else
		enemyList.Bosses = shallow_copy(Corp_Default.Bosses)
	end
end

local oldStartNewGame = startNewGame
function startNewGame()
	oldStartNewGame()
	
	local timesPicked = {}
	for i = 1, 5 do
		local island = Islands[i]
		local enemyList = island:GetEnemyList()
		
		if enemyList ~= nil then
			GAME.Enemies[i] = enemyList:PickEnemies(i, timesPicked)
			--GAME.Bosses[i] = enemyList:PickBosses(i) or GAME.Bosses[i]
		end
	end
end
