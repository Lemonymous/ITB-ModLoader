local Subscription = Class.new()

function Subscription:new(subscribable)
    assert(type(subscribable) == "table", "Subscription.new: first argument must be a table")
    assert(type(subscribable.subscribers) == "table", "Subscription.new: first argument must be a Subscribable")

    -- The subscribable this subscription is subscribed to.
    self.subscribable = subscribable
    -- Whether this subscription has already been unsubscribed.
    self.closed = false
    -- Teardown, or cleanup functions called when this subscription is unsubscribed.
    self.teardownFns = {}
end

--[[
    Adds a teardown (cleanup) function that is called when this subscription is unsubscribed.
--]]
function Subscription:addTeardown(fn)
    assert(type(fn) == "function", "Subscription.addTeardown: first argument must be a function.")

    table.insert(self.teardownFns, fn)
end

--[[
    Cancels this subscription, removing it from the list of subscribers and triggering
    its teardown functions.

    Does nothing if the subscription is already canceled.
--]]
function Subscription:unsubscribe()
    if self.closed then
        return false
    end

    table.remove(self.subscribable.subscribers, self)

    for i, teardownFn in ipairs(self.teardownFns) do
        teardownFn()
    end
    self.teardownFns = nil

    return true
end

function Subscription:isClosed()
    return self.closed
end

local SubscriptionInterface = Class.interface(Subscription, {
    "addTeardown",
    "unsubscribe",
    "isClosed"
})

return SubscriptionInterface
