
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

function shuffle_list(list)
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		
		-- swap entries
		list[i], list[j] = list[j], list[i]
	end
end

local template_enemyList = {
	isEnemyListClass = true,
	categories = { "Core", "Core", "Core", "Leaders", "Unique", "Unique" },
	enemies = {},
	bosses = {}
}

CreateClass(template_enemyList)

function template_enemyList:getId()
	return self.id
end

function template_enemyList:setCategories(categories)
	AssertEquals(6, #categories, "setCategories - Arg#1 (number of categories)")
	
	self.categories = categories
end

function template_enemyList:addEnemy(enemy, category)
	AssertEquals('string', type(enemy), "addEnemy - Arg#1 (enemy id)")
	AssertEquals('string', type(enemy), "addEnemy - Arg#1 (enemy category; 'Core', 'Leaders' or 'Unique')")
	
	self.enemies[category] = self.enemies[category] or {}
	table.insert(self.enemies[category], enemy)
end

function template_enemyList:pickEnemies(islandNumber, timesPicked)
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
		self.enemies[category] = self.enemies[category] or {}
		for _, enemy in ipairs(self.enemies[category]) do
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
	
	for _, category in ipairs(self.categories) do
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
	
	AssertEquals(6, #result, "pickEnemies - Resulting number of enemies")
	
	return result
end

function template_enemyList:pickBoss()
	
end

modApi.enemyLists = {}

function modApi:newEnemyList(id, base)
	AssertEquals('string', type(id), "newEnemyList - Arg#1 (Enemy list id)")
	AssertIsUniqueId(modApi.enemyLists[id] == nil, id, "newEnemyList - Arg#1 (Enemy list id)")
	AssertMultiple({'nil', 'table', 'string'}, type(base), "newEnemyList - Arg#2 (Base enemy list/id)")
	
	if type(base) == 'string' then
		AssertEntryExists(modApi.enemyLists, base, "EnemyList", "newEnemyList - Arg#2")
		base = modApi.enemyLists[base]
		
	elseif type(base) == 'table' then
		AssertEntryExists(modApi.enemyLists, base.id, "EnemyList", "newEnemyList - Arg#2")
	end
	
	modApi.enemyLists[id] = (base or template_enemyList):new{ id = id }
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
	AssertMultiple({'number', 'string'}, type(enemyListIdOrIslandNumber), "getEnemyList - Arg#1 (Island number or enemy list id)")
	
	if type(enemyListIdOrIslandNumber) == 'number' then
		local islandNumber = enemyListIdOrIslandNumber
		local island = modApi:getIsland(islandNumber)
		
		return island:getEnemyList()
		
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
	
	enemyList.enemies = copy_table(EnemyLists)
	
	if corp then
		enemyList.bosses = add_arrays(corp.Bosses, corp.UniqueBosses)
	else
		enemyList.bosses = shallow_copy(Corp_Default.Bosses)
	end
end

local oldStartNewGame = startNewGame
function startNewGame()
	oldStartNewGame()
	
	local timesPicked = {}
	for i = 1, 5 do
		local island = modApi:getIsland(i)
		local enemyList = island:getEnemyList()
		
		if enemyList ~= nil then
			GAME.Enemies[i] = enemyList:pickEnemies(i, timesPicked)
			--GAME.Bosses[i] = enemyList:pickBosses(i) or GAME.Bosses[i]
		end
	end
end
