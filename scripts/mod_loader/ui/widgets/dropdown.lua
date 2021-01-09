UiDropDown = Class.inherit(Ui)

function UiDropDown:new(values,strings,value)
	Ui.new(self)

	self.tooltip = ""
	self.nofitx = true
	self.nofity = true
	self.values = values
	self.strings = strings or {}
	if value then
		for i, v in pairs(values) do
			if value == v then
				self.choice = i
				self.value = v
				break
			end
		end
	end
	if not self.choice then
		self.choice = 1
		self.value = values[1]
	end
	self.open = false
	
	local items = {}
	
	local max_w = 32
	for i, v in ipairs(self.values) do
		local txt = DecoRAlignedText(self.strings[i] or tostring(v))
		
		if txt.surface:w() > max_w then
			max_w = txt.surface:w()
		end
		
		local item = Ui()
			:width(1):heightpx(40)
			:decorate({
				DecoSolidHoverable(deco.colors.button, deco.colors.buttonborder),
				DecoAlign(0, 2),
				txt
			})
		table.insert(items, item)
		
		item.onclicked = function(btn, button)
			if button == 1 then
				self.choice = i
				self.value = self.values[i]
				
				self:onDropDownChoice(self.choice, self.value)
				self:destroyDropDown()
				return true
			end
			return false
		end
	end
	
	local function destroyDropDown()
		self:destroyDropDown()
	end
	
	local function mousedown(dropDown, mx, my, button)
		
		if
			button == 1                      and
			self.open                        and
			not self.containsMouse           and
			not dropDown.containsMouse
		then
			self:destroyDropDown()
			
		elseif button == 3 and self.open then
			self:destroyDropDown()
		end
		
		return Ui.mousedown(dropDown, mx, my, button)
	end
	
	local ddw = math.max(max_w + 8, 210)
	self.dropDown = Ui()
		:pospx(
			self.rect.x + self.w - ddw,
			self.rect.y + self.h + 2)
		:widthpx(ddw)
		:heightpx(math.min(2 + #self.values * 40, 210))
		:decorate({ DecoFrame(nil, nil, 1) })
	self.dropDown.owner = self
	self.dropDown.destroyDropDown = destroyDropDown
	self.dropDown.mousedown = mousedown
	
	local scrollarea = UiScrollArea()
		:width(1):height(1)
		:addTo(self.dropDown)

	local layout = UiBoxLayout()
		:vgap(0)
		:width(1)
		:addTo(scrollarea)
	
	for i, item in ipairs(items) do
		layout:add(item)
	end
end

function UiDropDown:onDropDownChoice(choice, value) end

function UiDropDown:destroyDropDown()
	self.open = false
	self.dropDown.visible = false
end

function UiDropDown:createDropDown()
	if self.root then
		if self.dropDown.parent ~= self.root.dropDownUi then
			self.dropDown:detach()
		end
		
		if self.dropDown.parent == nil then
			self.dropDown:addTo(self.root.dropDownUi)
		end
		
		local max_w = 32
		local ddw = math.max(max_w + 8, 210)
		self.open = true
		self.dropDown.visible = true
		self.dropDown.x = self.rect.x + self.w - ddw
		self.dropDown.y = self.rect.y + self.h + 2
		
		self.dropDown.parent:relayout()
	end
end

function UiDropDown:draw(screen)
	if self.open then

		local oldClip = self.root.clippingrect
		self.root.clippingrect = nil
		--We don't want our dropDown to be clipped
		if oldClip then
			screen:unclip()
		end
		
		Ui.draw(self, screen)
		
		if oldClip then
			screen:clip(oldClip)
		end
	else
		Ui.draw(self, screen)
	end
end

function UiDropDown:mousedown(mx, my, button)
	
	if
		button == 1                      and
		self.open                        and
		not self.containsMouse           and
		not self.dropDown.containsMouse
	then
		self:destroyDropDown()
		
	elseif button == 3 and self.open then
		self:destroyDropDown()
	end
	
	return Ui.mousedown(self, mx, my, button)
end

function UiDropDown:clicked(button)
	if button == 1 then
		if self.open then
			self:destroyDropDown()
		else
			self:createDropDown()
		end
	end
	
	return Ui.clicked(self, button)
end

function UiDropDown:keydown(keycode)
	if self.focused then
		if self.open then
			if keycode == SDLKeycodes.ESCAPE then
				self:destroyDropDown()
			end

			return true
		else
			if
				keycode == SDLKeycodes.RETURN  or
				keycode == SDLKeycodes.RETURN2
			then
				self:createDropDown()
				return true
			end
		end
	end

	return Ui.keydown(self, keycode)
end

function UiDropDown:keyup(keycode)
	if
		self.open and self.focused and (
			keycode == SDLKeycodes.ESCAPE  or
			keycode == SDLKeycodes.RETURN  or
			keycode == SDLKeycodes.RETURN2
		)
	then
		return true
	end

	return Ui.keyup(self, keycode)
end
