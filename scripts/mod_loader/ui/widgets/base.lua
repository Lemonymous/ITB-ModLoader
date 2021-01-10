Ui = Class.new()

function Ui:new()
  	self.children = {}
	self.captiontext = ""
	self.w = 0
	self.h = 0
	self.x = 0
	self.y = 0
	self.dx = 0
	self.dy = 0
	self.padt = 0
	self.padr = 0
	self.padb = 0
	self.padl = 0
	self.screenx = 0
	self.screeny = 0
	self.font = uifont
	self.textset = uitextset
	self.innerWidth = 0
	self.innerHeight = 0
	self.bgcolor = nil
	self.rect = sdl.rect(0,0,0,0)
	self.decorations = {}
	self.animations = {}
	self.pressed = false
	self.hovered = false
	self.disabled = false
	self.focused = false
	self.containsMouse = false
	self.ignoreMouse = false
	self.visible = true
	self.root = self
	self.parent = nil
end

function Ui:add(child, index)
	child:setroot(self.root)
	if index then
		assert(type(index) == "number")
		table.insert(self.children, index, child)
	else
		table.insert(self.children, child)
	end
	child.parent = self
	
	if self.nofitx == nil then
		if self.w > 0 and child.w + child.x > self.w - self.padl - self.padr then
			child.w = self.w - self.padl - self.padr - child.x
		end
	end
	
	if self.nofity == nil then
		if self.h > 0 and child.h + child.y > self.h - self.padt - self.padb then
			child.h = self.h - self.padt - self.padb - child.y
		end
	end
	
	return self
end

function Ui:remove(child)
	if not child then return self end

	if self.root.focuschild == child then
		-- pass self as arg for UiRoot override
		self:setfocus(self)
	end

	child:setroot(nil)
	remove_element(child, self.children)
	child.parent = nil

	return self
end

function Ui:detach()
	if not self.parent then return self end

	self.parent:remove(self)

	return self
end

function Ui:addTo(parent, index)
	if parent == nil then return self end
	
	parent:add(self, index)
	
	return self
end

function Ui:setroot(root)
	self.root = root
	
	for i=1,#self.children do
		self.children[i]:setroot(root)
	end
	
	return self
end

function Ui:settooltip(tip)
	self.tooltip = tip
	
	return self
end

function Ui:decorate(decorations)
	for i=1,#self.decorations do
		self.decorations[i]:unapply(self)
	end

	self.decorations = decorations
	
	for i=1,#self.decorations do
		self.decorations[i]:apply(self)
	end

	return self
end

function Ui:show()
	self.visible = true
	
	return self
end

function Ui:hide()
	self.visible = false
	
	return self
end

--[[
	Attempts to set root's focus to this element. Returns true if this
	element successfully obtained focus.
--]]
function Ui:setfocus()
	if not self.visible then return false end

	self.root:setfocus(self)
end

--[[
	Returns true if this element, or any of its children, have focus.
--]]
function Ui:hasfocus()
	return self.focused
end

function Ui:pos(x, y)
	self.xPercent = x
	self.yPercent = y
	
	return self
end

function Ui:posCentered(x, y)
	x = x or 0.5
	y = y or 0.5
	self.xPercent = x - self.wPercent / 2
	self.yPercent = y - self.hPercent / 2

	return self
end

function Ui:pospx(x, y)
	self.x = x
	self.y = y
	
	return self
end

function Ui:setxpx(x)
	self.x = x
	self.xPercent = nil
	
	return self
end

function Ui:setypx(y)
	self.y = y
	self.yPercent = nil
	
	return self
end

function Ui:caption(text)
	self.captiontext = text
	
	return self
end

function Ui:padding(v)
	self.padt = self.padt + v
	self.padr = self.padr + v
	self.padb = self.padb + v
	self.padl = self.padl + v

	return self
end

function Ui:width(w)
	self.wPercent = w
	return self
end

function Ui:height(h)
	self.hPercent = h
	return self
end

function Ui:widthpx(w)
	self.w = w
	return self
end

function Ui:heightpx(h)
	self.h = h
	return self
end

function Ui:wheel(mx,my,y)
	if not self.visible then return false end
	if self.ignoreMouse then return false end

	for i=1,#self.children do
		local child = self.children[i]
		
		if
			child.visible      and
			rect_contains(
				child.screenx,
				child.screeny,
				child.w,
				child.h,
				mx, my
			)
		then
			if child:wheel(mx,my,y) then
				return true
			end
		end
	end

	if self.translucent then return false end
	return true
end

function Ui:mousedown(mx, my, button)

	-- iterate all eligible objects
	for i=1,#self.children do
		local child = self.children[i]
		
		if
			not child.disabled     and
			not child.ignoreMouse  and
			child.visible          and
			child.containsMouse
		then
			child:mousedown(mx, my, button)
		end
	end

	if button == 3 then
		if self.root.pressedchild then
			local child = self.root.pressedchild
			self.root.pressedchild = nil
			
			child:setfocus(nil)
			child.pressed = false
			
			-- treat right mouse click as left mouse up
			-- if an object is being dragged
			if child.dragged then
				child:mouseup(mx, my, 1)
			end
			
			return true
		end
	elseif button == 1 then
		-- only hovered objects can be pressed
		if self.hovered and not self.root.pressedchild then
			
			self.root.pressedchild = self
			-- pass self as arg for UiRoot override
			self:setfocus(self)
			self.pressed = true

			if self.draggable then
				self.dragged = true
				self:startDrag(mx, my, button)
			end
			
			return true
		end
	end
	
	return false
end

function Ui:mouseup(mx, my, button)
	local pressedchild
	
	-- call mouseup on all eligible objects
	for i=1,#self.children do
		local child = self.children[i]
		
		if child == self.root.pressedchild then
			-- handle pressed child later, in case
			-- it leads to fractured ui structure
			pressedchild = child
		elseif
			not child.disabled                  and
			not child.ignoreMouse               and
			child.visible                       and
			child.containsMouse
		then
			child:mouseup(mx, my, button)
		end
	end
	
	-- only treat mouse button 1 as mouse click
	if button == 1 then
		if self == self.root.pressedchild then
			self.root.pressedchild = nil
			self.pressed = false
			self:clicked(button)
		end
		
		if self.dragged then
			self.dragged = false
			self:stopDrag(mx, my, button)
			
			self.root.draggedElement = nil
			self.root:relayout()
		end
	end
	
	if pressedchild then
		return pressedchild:mouseup(mx, my, button)
	end
	
	return false
end

function Ui:mousemove(mx, my)
	-- handle dragMove regardless of containsMouse or translucent
	if self.dragged then
		self:dragMove(mx, my)
		return true
	end
	
	if
		self.containsMouse or
		rect_contains(
			self.screenx,
			self.screeny,
			self.w,
			self.h,
			mx, my
		)
	then
		if not self.containsMouse then
			table.insert(self.root.childrenContainingMouse, self)
			self.containsMouse = true
			self:mouseEntered()
		end
		
		-- translucent objects can not be hovered or interacted with further
		if not self.translucent then
			-- if not pressing an object, the first object found is hovered.
			-- if pressing an object, only the pressed object can be hovered,
			-- and only if it contains the mouse cursor
			if not self.root.pressedchild or self == self.root.pressedchild then
				-- pass hovered from parent to child if applicable
				if self.parent and self.parent.hovered then
					self.parent.hovered = false
					self.root.hoveredchild = nil
				end
				
				-- the first object we find is the hovered object
				if not self.root.hoveredchild then
					self.root.hoveredchild = self
					self.hovered = true
					
					if self.tooltip then
						self.root.tooltip = self.tooltip
					end
				end
			end
		end
		
		for i=1,#self.children do
			local child = self.children[i]
			if child ~= self.root.pressedchild then -- dont iterate pressedchild again. It is always handled from root
				if
					not child.disabled     and
					not child.ignoreMouse  and
					child.visible
				then
					-- fire mousemove for all children to check if they contain the mouse
					child:mousemove(mx, my)
				end
			end
		end
	end

	return false
end

function Ui:keydown(keycode)
	if not self.visible then return false end

	if self.parent then
		return self.parent:keydown(keycode)
	end

	return false
end

function Ui:keyup(keycode)
	if not self.visible then return false end

	if self.parent then
		return self.parent:keyup(keycode)
	end

	return false
end

function Ui:relayout()
	local innerWidth = 0
	local innerHeight = 0

	for i=1,#self.children do
		local child = self.children[i]
		
		if child.wPercent ~= nil then
			child.w = (self.w - self.padl - self.padr) * child.wPercent
			child.wPercent = nil
		end
		if child.hPercent ~= nil then
			child.h = (self.h - self.padt - self.padb) * child.hPercent
			child.hPercent = nil
		end
		if child.xPercent ~= nil then
			child.x = (self.w - self.padl - self.padr) * child.xPercent
			child.xPercent = nil
		end
		if child.yPercent ~= nil then
			child.y = (self.h - self.padt - self.padb) * child.yPercent
			child.yPercent = nil
		end
		
		child.screenx = self.screenx + self.padl - self.dx + child.x
		child.screeny = self.screeny + self.padt - self.dy + child.y
		
		child:relayout()
		
		local childright = self.padl + child.x + child.w + self.padr
		local childbottom = self.padt + child.y + child.h + self.padb
		if innerWidth < childright then innerWidth = childright end
		if innerHeight < childbottom then innerHeight = childbottom end
		
		child.rect.x = child.screenx
		child.rect.y = child.screeny
		child.rect.w = child.w
		child.rect.h = child.h
	end
	
	self.innerWidth = innerWidth
	self.innerHeight = innerHeight
end

function Ui:draw(screen)
	if not self.visible then return end
	
	if self.animations then
		for _, anim in pairs(self.animations) do
			anim:update(modApi:deltaTime())
		end
	end
	
	self.decorationx = 0
	self.decorationy = 0
	for i=1,#self.decorations do
		local decoration = self.decorations[i]
		decoration:draw(screen, self)
	end

	for i=#self.children,1,-1 do
		local child = self.children[i]
		child:draw(screen)
	end
end

function Ui:clicked(button)
	if self.onclicked ~= nil then
		local ret = self:onclicked(button)
		-- Make sure we bug people to update their code to return
		-- either `true` or `false`, depending on whether they actually
		-- ended up handling the click.
		if ret == nil then
			error(
				"'onclicked' function must return a value.\n"
				.."True if your function handled the click, false if it ignored it."
			)
		end
		return ret
	end

	return false
end

function Ui:mouseEntered()
	if self.onMouseEnter ~= nil then
		self:onMouseEnter()
	end
end

function Ui:mouseExited()
	for i=1,#self.children do
		local child = self.children[i]
		if child.containsMouse then
			child.containsMouse = false
			child:mouseExited()
		end
	end

	if self.onMouseExit ~= nil then
		self:onMouseExit()
	end
end

function Ui:stopDrag(mx, my, button)
end

function Ui:dragMove(mx, my)
end

function Ui:startDrag(mx, my, button)
	self:stopDrag(mx, my, button)
end

function Ui:setSwappable(flag)
	self.swappable = flag
	return self
end

function Ui:isSwappable()
	-- defaults to swappable
	return self.swappable ~= false
end

function Ui:swapSibling(destIndex)
	if self.parent == nil then return self end
	if not self:isSwappable() then return self end
	local list = self.parent.children
	if destIndex < 1 or destIndex > #list then return self end
	local sourceIndex = list_indexof(list, self)

	local dest = list[destIndex]
	if dest:isSwappable() then
		list[destIndex] = self
		list[sourceIndex] = dest
	end

	return self
end

function Ui:bringUp()
	if self.parent == nil then return self end
	local list = self.parent.children
	local index = list_indexof(list, self)
	if index == #list then return self end

	return self:swapSibling(index + 1)
end

function Ui:bringDown()
	if self.parent == nil then return self end
	local list = self.parent.children
	local index = list_indexof(list, self)
	if index == 1 then return self end

	return self:swapSibling(index - 1)
end

function Ui:bringToTop()
	if self.parent == nil then return self end
	local list = self.parent.children
	
	for k,v in ipairs(list) do
		if self == v then
			table.remove(list, k)
			break
		end
	end
	
	for k,v in ipairs(list) do
		if v:isSwappable() then
			table.insert(list, k, self)
			return self
		end
	end
	
	-- default backup
	table.insert(list, self)
end

