Class = {}

function Class.new()
	local o = {}
	o.__index = o
	setmetatable(o, {
		__call = function (cls, ...)
			local self = setmetatable({}, cls)
			self:new(...)
			return self
		end,
	})
	
	return o
end

function Class.inherit(base)
	local o = {}
	o.__index = o
	o.__super = base
	setmetatable(o, {
		__index = base,
		__call = function (cls, ...)
			local self = setmetatable({}, cls)
			self:new(...)
			return self
		end,
	})
	
	return o
end

local keywords = {
    "new"
}
local function checkKeywords(list)
    for _, fnName in pairs(list) do
        assert(type(fnName) == "string", "Class.interface: second and/or third arguments must be a list of strings.")
        for _, keyword in pairs(keywords) do
            assert(fnName ~= keyword, "Class.interface: list of interface function names contains reserved keyword: " .. keyword)
        end
    end
end

Class.interface = function(classObject, interfaceMethods, interfaceFunctions)
    assert(type(classObject) == "table", "Class.interface: first argument must be a table.")
    assert(type(classObject.new) == "function", "Class.interface: first argument must be a class.")
    assert(interfaceMethods or interfaceFunctions, "Class.interface: either second or third argument must not be nil.")
    assert(not interfaceMethods or type(interfaceMethods) == "table", "Class.interface: second argument must be a table.")
    assert(not interfaceMethods or #interfaceMethods > 0, "Class.interface: second argument must not be empty.")
    assert(not interfaceFunctions or type(interfaceFunctions) == "table", "Class.interface: third argument must be a table.")
    assert(not interfaceFunctions or #interfaceFunctions > 0, "Class.interface: third argument must not be empty.")

    if interfaceMethods then
        checkKeywords(interfaceMethods)
    end
    if interfaceFunctions then
        checkKeywords(interfaceFunctions)
    end

    local interfaceObject = Class.new()

    interfaceObject.new = function(self, ...)
        local implementation = classObject(...)

        if interfaceMethods then
            -- Methods: first argument is reference to self
            for _, fnName in pairs(interfaceMethods) do
                interfaceObject[fnName] = function(self, ...)
                    implementation[fnName](implementation, ...)
                end
            end
        end

        if interfaceFunctions then
            -- Functions: no special first argument
            for _, fnName in pairs(interfaceFunctions) do
                interfaceObject[fnName] = function(...)
                    implementation[fnName](...)
                end
            end
        end
    end

    return interfaceObject
end

Class.getParentClass = function(class)
    local meta = getmetatable(class)
    if meta then
        return meta.__index
    else
        return nil
    end
end

Class.getClass = function(instance)
    return getmetatable(instance)
end

function Class.inheritsFrom(class, expectedClass)
    local parent = Class.getParentClass(class)

    while (parent and parent ~= class) do
        if parent == expectedClass then
            return true
        end

        class = parent
        parent = Class.getParentClass(class)
    end

    return false
end

function Class.instanceOf(instance, expectedClass)
    return Class.inheritsFrom(Class.getClass(instance), expectedClass)
end
