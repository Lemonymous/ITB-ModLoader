local localPath = GetParentPath(...)
local Subscribable = require(localPath .. "subscribable")

local Observable = Class.inherit(Subscribable)

function Observable:new(workerFn)
    assert(type(workerFn) == "function", "Observable.new: first argument must be a function.")
    Subscribable.new(self)
    self.workerFn = workerFn
    self.workerResult = nil
    self.isDone = false
end

function Observable:subscribe(fn)
    modApi:runLater(function() self:execute() end)
    return Subscribable.subscribe(self, fn)
end

function Observable:execute()
    if not self.isDone then
		local ok, err = pcall(function() self.workerFn() end)
        self.isDone = true

        if not ok then
			LOG("An observable callback failed: ", err)
        end
    end

    for _, fn in pairs(self.subscribers) do
        fn(self.workerResult)
    end
end

function Observable:isEmpty()
    -- No way to obtain field count in a table without iterating;
    -- Need to loop through the fields to enumerate them.
    for k, v in pairs(self.subscribers) do
        return false
    end

    return true
end

function Observable:isDone()
    return self.isDone
end

local ObservableInterface = Class.interface(Observable, {
    "subscribe",
    "execute",
    "isEmpty",
    "isDone"
})

--[[
    Convenience function to create observables of simple values, mostly for debugging purposes.
--]]
function ObservableInterface.of(...)
    local t = { ... }
    if #t == 1 and type(t[1]) == "table" then
        t = t[1]
    end

    return ObservableInterface(function() return t end)
end

return ObservableInterface
