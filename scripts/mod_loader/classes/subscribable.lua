local localPath = GetParentPath(...)
local Subscription = require(localPath .. "subscription")

local NO_OP_FN = function() end
local Subscribable = Class.new()

function Subscribable:new()
    self.subscribers = {}
    LOG(gsub == Subscription)
end

--[[
    Subscribes to this subscribable entity; the function passed in argument will be invoked
    when the subscribable is triggered.

    Returns a Subscription handle that can be used to cancel the subscription.
--]]
function Subscribable:subscribe(fn)
    assert(fn == nil or type(fn) == "function", "Subscribable.subscribe: first argument must be a function or nil.")
    if not fn then fn = NO_OP_FN end

    local sub = Subscription(self)
    subscribers[sub] = fn

    return sub
end

function Subscribable.isSubscribable(classObject)
    return getmetatable(classObject).__index == Subscribable
end

return Subscribable
