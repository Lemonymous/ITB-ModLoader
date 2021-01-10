UiRoot = Class.inherit(Ui)

function UiRoot:new()
	Ui.new(self)
	
	self.childrenContainingMouse = {}
	self.hoveredchild = nil
	self.pressedchild = nil
	self.draggedchild = nil
	self.focuschild = self
	self.translucent = true
	
	self.tooltipUi = UiTooltip():setSwappable(false):addTo(self)
	self.dropDownUi = Ui():width(1):height(1):setSwappable(false):addTo(self)
	self.dropDownUi.translucent = true
end

function UiRoot:draw(screen)
	self:relayout()

	Ui.draw(self, screen)
end

function UiRoot:setfocus(newfocus)
	assert(
		-- we permit the focus to be set to nil, ui elements with a parent,
		-- or to the root itself
		newfocus == nil or (newfocus.parent or newfocus.root == newfocus),
		"Unable to set focus, because the UI element has no parent"
	)

	-- clear old focus
	local p = self.focuschild
	while p do
		p.focused = false
		p = p.parent
	end

	self.focuschild = newfocus
	
	p = self.focuschild
	while p do
		p.focused = true
		p = p.parent
	end

	return true
end

function UiRoot:cleanupDropdown()
	for i = #self.dropDownUi.children, 1, -1 do
		local dropDown = self.dropDownUi.children[i]
		
		local parent = dropDown.owner
		while parent.parent do
			-- fetch root of dropDown
			parent = parent.parent
		end
		
		-- if owner is not attached to root, remove dropDown
		if parent ~= self then
			table.remove(self.dropDownUi.children, i)
		end
	end
end

function UiRoot:releasePressedElement(mx, my, button)
	if not self.pressedchild then return end
	
	self.pressedchild.pressed = false
	self.pressedchild:setfocus(nil)
	self.pressedchild = nil
end

function UiRoot:releaseDraggedElement(mx, my, button)
	if not self.draggedElement then return end

	self.draggedElement.dragged = false
	self.draggedElement:stopDrag(mx, my, button)
	self.draggedElement = nil
end

function UiRoot:event(eventloop)
	if not self.visible then return false end
	
	local type = eventloop:type()
	local mx = sdl.mouse.x()
	local my = sdl.mouse.y()
	
	if type == sdl.events.mousewheel then
		return self:wheel(mx, my, eventloop:wheel())
	end

	if type == sdl.events.mousebuttondown then
		local button = eventloop:mousebutton()
		self:setfocus(nil)
		
		self:releaseDraggedElement(mx, my, button)
		
		local consumeEvent = self:mousedown(mx, my, button)
		
		-- inform open dropDownUi's of mouse down event,
		-- even if the mouse click was outside of its area,
		-- in order to allow them to close
		for _, dropDown in ipairs(self.dropDownUi.children) do
			if not dropDown.containsMouse then
				dropDown:mousedown(mx, my, button)
			end
		end
		
		self:cleanupDropdown()
		
		if button == 3 then
			-- release pressed left mouse on right mouse down
			self:releasePressedElement()
			
			-- release dragged element on right mouse down
			self:releaseDraggedElement(mx, my, button)
		end
		
		return consumeEvent
	end
	
	if type == sdl.events.mousebuttonup then
		local button = eventloop:mousebutton()
		
		-- call mouseup for all eligible objects
		local consumeEvent = self:mouseup(mx, my, button)
		
		if button == 1 then
			local pressedchild = self.pressedchild
			if pressedchild then
				-- release pressed left mouse on left mouse up
				self:releasePressedElement()
				
				-- and click it
				consumeEvent = pressedchild:mouseup(mx, my, button)
				pressedchild:clicked(button)
			end
			
			-- release dragged element on left mouse up
			self:releaseDraggedElement(mx, my, button)
			
			-- relayout any potential ui changes
			self:relayout()
		end
		
		self:cleanupDropdown()
		
		-- run a mousemotion event to update ui element variable status
		self:event({
			type = function() return sdl.events.mousemotion end
		})
		
		return consumeEvent
	end
	
	if type == sdl.events.mousemotion then
		
		-- reset hoveredchild
		if self.hoveredchild ~= nil then
			self.hoveredchild.hovered = false
			self.hoveredchild = nil
		end
		
		self.tooltip = ""
		
		-- handle pressed element first in order to update any possible location changes
		if self.pressedchild ~= nil then
			local pressedchild = self.pressedchild
			
			if
				not pressedchild.disabled    and
				not pressedchild.ignoreMouse and
				pressedchild.visible
			then
				pressedchild:mousemove(mx, my)
			else
				self.pressedchild = nil
				pressedchild.pressed = false
				pressedchild:mouseup(mx, my, 1)
			end
		end
		
		-- update 'containsMouse' for elements that contained the mouse on the last frame
		for i = #self.childrenContainingMouse, 1, -1 do
			local child = self.childrenContainingMouse[i]
			child.containsMouse =
				child.visible and
				not child.ignoreMouse and
				rect_contains(
					child.screenx,
					child.screeny,
					child.w,
					child.h,
					mx, my
				)
			
			if not child.containsMouse then
				table.remove(self.childrenContainingMouse, i)
				child:mouseExited()
			end
		end
		
		return self:mousemove(mx, my)
	end

	if type == sdl.events.keydown then
		if self.focuschild then
			local consumeEvent = self.focuschild:keydown(eventloop:keycode())
			
			-- temporary measure to test update on escape for ui dialogs
			-- run a mousemotion event to update ui element variable status
			self:event({
				type = function() return sdl.events.mousemotion end
			})
			
			return consumeEvent
		else
			return false
		end
	end

	if type == sdl.events.keyup then
		if self.focuschild then
			return self.focuschild:keyup(eventloop:keycode())
		else
			return false
		end
	end

	return false
end

