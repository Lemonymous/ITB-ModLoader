local localPath = GetParentPath(...)
local Subscribable = require(localPath .. "subscribable")

local Event = Class.inherit(Subscribable)

function Event:new(argSchema)
    assert(argSchema == nil or type(argSchema) == "table", "Event.new: first argument must be a table or nil")
    Subscribable.new(self)

    if argSchema then
        for k, v in pairs(argSchema) do
            assert(type(v) == "string", "Event.new: first argument must be a list of strings")
        end
    end

    self.argSchema = argSchema
end

--[[
    Verifies the schema (expected arguments) of the event
--]]
function Event:checkSchema(...)
    if self.argSchema then
        local t = { ... }
        local errs = {}

        for i, argType in ipairs(self.argSchema) do
            if type(t[i]) ~= argType then
                table.insert(errs, {
                    index = i,
                    expected = argType,
                    got = type(t[i])
                })
            end
        end

        if #errs > 0 then
            local m = "Event.fire was called with incorrect arguments:"
            for _, v in ipairs(errs) do
                m = m .. string.format("\n - Arg #%s, expected %s, got %s", v.index, v.expected, v.got)
            end

            error(m)
        end
    end
end

function Event:fire(...)
    local arg = ...
    self:checkSchema(arg)

    for _, fn in pairs(self.subscribers) do
		local ok, err = pcall(function() fn(arg) end)

        if not ok then
			LOG("An event callback failed: ", err)
		end
    end
end

local EventInterface = Class.interface(Event, {
    "fire"
})

return EventInterface
