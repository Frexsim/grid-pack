--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

--// Packages
local Signal = require(script.Parent.Parent.signal)
local Trove = require(script.Parent.Parent.trove)

--// Constants
local guiInset = GuiService:GetGuiInset()

--// Types
local Types = require(script.Parent.Types)

--// Item Class
local Item = {}
Item.__index = Item

--[=[
	@class Item
]=]
--[=[
	@prop Position Vector2
	The position of the Item in a grid ItemManager.

	@within Item
]=]
--[=[
	@prop PositionChanged RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time the Item has it's position changed.

	@within Item
]=]
--[=[
	@prop Size Vector2
	The size of the Item in a grid ItemManager.

	@within Item
]=]
--[=[
	@prop Rotation number
	@readonly
	The current rotation of the item. Use `Item:Rotate()` to edit.

	@within Item
]=]
--[=[
	@prop PotentialRotation number
	@readonly
	The rotation that will be applied if a successful move goes through.

	@within Item
]=]
--[=[
	@prop ItemManager ItemManagerObject?
	@readonly
	The current ItemManger that the Item is in.

	@within Item
]=]
--[=[
	@prop ItemManagerChanged RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time the Item is moved in a new ItemManager.

	@within Item
]=]
--[=[
	@prop HoveringItemManager ItemManagerObject?
	@readonly
	The ItemManager that the Item is hovering over. ItemManagers need to be linked via TranferLinks to register as a hoverable ItemManager.

	@within Item
]=]
--[=[
	@prop HoveringItemManagerChanged RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time the Item is hovering over a new ItemManager.

	@within Item
]=]
--[=[
	@prop MoveMiddleware ((movedItem: Item, newGridPosition: Vector2, lastItemManager: ItemManager, newItemManager: ItemManager) -> boolean)?
	A callback function where you can do additional move checks. The Item will be automatically moved back if the callback function returns false.

	@within Item
]=]

--[=[
	Creates a new Item object.

	@within Item
]=]
function Item.new(properties: Types.ItemProperties): Types.ItemObject
	local self = setmetatable({}, Item)
	self._trove = Trove.new()
	self._itemManagerTrove = self._trove:Add(Trove.new())
	self._draggingTrove = self._trove:Add(Trove.new())
	
	self.Assets = properties.Assets or {}
	if self.Assets.Item == nil then
		self.Assets.Item = self:_createDefaultItemAsset()
	end
	
	self.Position = properties.Position or Vector2.zero
	self.LastItemManagerParentAbsolutePosition = Vector2.zero
	self.PositionChanged = Signal.new()
	self.Size = properties.Size or Vector2.new(2, 2)
	self.Rotation = properties.Rotation or 0
	self.PotentialRotation = self.Rotation
	
	self.ItemElement = self:_generateItemElement()
	
	self.ItemManager = nil
	self.ItemManagerChanged = Signal.new()
	self.HoveringItemManager = nil
	self.HoveringItemManagerChanged = Signal.new()
	
	self.MoveMiddleware = properties.MoveMiddleware
	self.RenderMiddleware = properties.RenderMiddleware
	
	self.IsDraggable = true
	self.IsDragging = false
	self.MouseDraggingPivot = Vector2.zero

	self.RotateKeyCode = Enum.KeyCode.R
	
	self.Metadata = properties.Metadata or {}
	
	-- Remove item from current ItemManager when item gets destroyed
	self._trove:Add(function()
		if self.ItemManager then
			self.ItemManager:RemoveItem(self)
		end
	end)
	
	-- Apply sizing when the item's ItemManager changes
	self._trove:Add(self.ItemManagerChanged:Connect(function(itemManager: Types.ItemManagerObject?, useTween: boolean?)
		self._itemManagerTrove:Clean()
		
		if self.ItemManager then
			self.LastItemManagerParentAbsolutePosition = self.ItemManager.GuiElement.Parent.AbsolutePosition
		end

		self.ItemManager = itemManager
		
		if self.ItemManager ~= nil then
			self.ItemElement.Visible = self.ItemManager.Visible

			local test = self.ItemManager.GuiElement.Parent.AbsolutePosition - self.LastItemManagerParentAbsolutePosition
			self.ItemElement.Position = UDim2.fromOffset(self.ItemElement.Position.X.Offset - test.X, self.ItemElement.Position.Y.Offset - test.Y)
			
			self:_updateItemToItemManagerDimentions(true, true, useTween, useTween)

			self._itemManagerTrove:Add(self.ItemManager.GuiElement:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				self:_updateItemToItemManagerDimentions(true, false, false, false)
			end))
			self._itemManagerTrove:Add(self.ItemManager.GuiElement:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				self:_updateItemToItemManagerDimentions(true, true, false, false)
			end))
			
			self._itemManagerTrove:Add(self.ItemManager.VisibilityChanged:Connect(function(isVisible)
				self.ItemElement.Visible = isVisible
			end))

			self.ItemElement.Parent = self.ItemManager.GuiElement.Parent
		else
			self.ItemElement.Parent = nil
		end
	end))
	
	-- Update the cursor pivot when the item gets resized
	self._trove:Add(self.ItemElement:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if self.IsDragging then
			self:_updateDraggingPosition()
		end
	end))
	
	local interactionButton = self.ItemElement:FindFirstChild("InteractionButton")
	assert(interactionButton, "Couldn't find a button named \"InteractionButton\" in the ItemElement")
	
	self._highlight = nil
	self._trove:Add(interactionButton.MouseButton1Down:Connect(function()
		-- Check if item is in an ItemManager, if there is then start dragging
		if self.ItemManager ~= nil and self.IsDraggable then
			self.IsDraggable = false
			self.IsDragging = true
			
			-- Get mouse pivot to item
			local mousePosition = UserInputService:GetMouseLocation() - guiInset
			local itemStart = self.ItemElement.AbsolutePosition
			local itemEnd = itemStart + self.ItemElement.AbsoluteSize
			self.MouseDraggingPivot = (mousePosition - itemStart) / (itemEnd - itemStart)
			
			TweenService:Create(self.ItemElement, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {GroupTransparency = 0.5}):Play()
			self.ItemElement.ZIndex += 1

			self._draggingTrove:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
				if gameProcessedEvent == false then
					if input.KeyCode == self.RotateKeyCode then
						self:Rotate(1)
					end
				end
			end))
			
			-- Create drop highlight
			local highlightSize = self.Size
			if self.PotentialRotation % 2 == 1 then
				highlightSize = Vector2.new(self.Size.Y, self.Size.X)
			end

			local gridPos = self.ItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size, self.PotentialRotation)
			self._highlight = self._draggingTrove:Add(self.ItemManager:CreateHighlight(100, gridPos, highlightSize, Color3.new(1, 1, 1)))

			-- Update positioning
			self:_updateDraggingPosition()
		end
	end))
	
	self._trove:Add(UserInputService.InputChanged:Connect(function(input)
		-- Update dragging when mouse moves
		if input.UserInputType == Enum.UserInputType.MouseMovement and self.IsDragging == true and self.ItemManager ~= nil then
			-- Check for any transferrable ItemManagers and apply item sizing and highlight to the hovering ItemManager
			if next(self.ItemManager.ConnectedTransferLinks) ~= nil then
				for _, transferLink in pairs(self.ItemManager.ConnectedTransferLinks) do
					local itemManagerToTransferTo = transferLink:GetClosestItemOverlappingItemManagers(self)[1]
					if itemManagerToTransferTo ~= nil and self.HoveringItemManager ~= itemManagerToTransferTo then
						self.HoveringItemManager = itemManagerToTransferTo
						self.HoveringItemManagerChanged:Fire(self.HoveringItemManager)
						self._highlight:SetItemManager(100, self.HoveringItemManager)
						self:_updateItemToItemManagerDimentions(false, true, false, true, self.HoveringItemManager)

						break
					end
				end
			end
			
			-- Check collision in hovering ItemManager and apply highlight color
			local currentItemManager = self.HoveringItemManager or self.ItemManager
			if currentItemManager then
				self:_updateDraggingPosition()
			end
		end
	end))

	self._trove:Add(UserInputService.InputEnded:Connect(function(input)
		-- Drop item when left mouse stops getting clicked
		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.IsDragging == true and self.ItemManager ~= nil then
			self.IsDragging = false

			-- Check if the item is colliding, if not add the item to the itemManager
			local currentItemManager = self.HoveringItemManager or self.ItemManager
			local gridPos = currentItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size, self.PotentialRotation)
			local isColliding = currentItemManager:IsColliding(self, { self }, gridPos, self.PotentialRotation)
			if isColliding == false then
				-- Get new ItemManager, is nil if no new ItemManager is found
				local newItemManager = nil
				if self.HoveringItemManager and self.HoveringItemManager ~= self.ItemManager then
					newItemManager = self.HoveringItemManager
				end

				-- Check for middleware and if it allows item move
				local middlewareReturn = nil
				if self.MoveMiddleware then
					middlewareReturn = self.MoveMiddleware(self, gridPos, self.PotentialRotation, self.ItemManager, newItemManager)
				end

				if middlewareReturn == true or middlewareReturn == nil then
					-- Move item
					self.Position = gridPos
					self.PositionChanged:Fire(gridPos)
					self.Rotation = self.PotentialRotation

					-- Switch ItemManager if the item was hovering above one
					if newItemManager then
						self:SetItemManager(self.HoveringItemManager)
					end
				end
			end

			self.PotentialRotation = self.Rotation

			self.HoveringItemManager = nil
			self.HoveringItemManagerChanged:Fire(self.HoveringItemManager)

			-- Update item positioning to current itemManager
			self:_updateItemToItemManagerDimentions(true, true, true, true)

			TweenService:Create(self.ItemElement, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
			self.ItemElement.ZIndex -= 1

			self._draggingTrove:Clean()

			self.IsDraggable = true
		end
	end))

	if self.RenderMiddleware then
		self.RenderMiddleware(self.ItemElement)
	end
	
	return self
end

--[=[
	@private
	Used to create the default Item GUI asset if the user hasn't specified one.

	@within Item
]=]
function Item:_createDefaultItemAsset(): CanvasGroup
    local itemElement = Instance.new("CanvasGroup")
	itemElement.Name = "ItemElement"
	itemElement.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	itemElement.BorderSizePixel = 0
	itemElement.Size = UDim2.fromOffset(140, 140)
	itemElement.ZIndex = 2

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.Image = ""
	image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Size = UDim2.fromScale(1, 1)
	image.Parent = itemElement

	local interactionButton = Instance.new("TextButton")
	interactionButton.Name = "InteractionButton"
	interactionButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	interactionButton.Text = ""
	interactionButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	interactionButton.TextSize = 14
	interactionButton.TextTransparency = 1
	interactionButton.AutoButtonColor = false
	interactionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	interactionButton.BackgroundTransparency = 1
	interactionButton.Size = UDim2.fromScale(1, 1)
	interactionButton.Parent = itemElement

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 10)
	uICorner.Parent = itemElement

	return itemElement
end

--[=[
	@private
	Clones the specified Item GUI asset in the `Item.Assets.Item` property.

	@within Item
]=]
function Item:_generateItemElement()
	local newItem = self._trove:Add(self.Assets.Item:Clone())
	if self.ItemManager then
		newItem.Visible = self.ItemManager.Visible
	end

	return newItem
end

--[=[
	@private
	Updates the Item's GUI element position to align with the mouse position.

	@within Item
]=]
function Item:_updateDraggingPosition()
	local mousePosition = UserInputService:GetMouseLocation() - guiInset
	local test = self.ItemManager.GuiElement.Parent.AbsolutePosition
	if self.HoveringItemManager and self.ItemManager ~= self.HoveringItemManager then
		--test = self.ItemManager.GuiElement.Parent.AbsolutePosition - self.HoveringItemManager.GuiElement.Parent.AbsolutePosition
	end

	self.ItemElement.Position = UDim2.fromOffset(mousePosition.X - self.MouseDraggingPivot.X * self.ItemElement.AbsoluteSize.X - test.X, mousePosition.Y - self.MouseDraggingPivot.Y * self.ItemElement.AbsoluteSize.Y - test.Y)

	local currentItemManager = self.HoveringItemManager or self.ItemManager
	local gridPos = currentItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size, self.PotentialRotation)
	self._highlight.Position = gridPos

	local isColliding = currentItemManager:IsColliding(self, { self }, gridPos, self.PotentialRotation)
	if isColliding == true then
		self._highlight.Color = Color3.new(1, 0, 0)
	else
		self._highlight.Color = Color3.new(1, 1, 1)
	end
end

--[=[
	@private
	Updates the Item's GUI element size and position to align with the new ItemManager.

	@within Item
]=]
function Item:_updateItemToItemManagerDimentions(applyPosition: boolean?, applySize: boolean?, usePositionTween: boolean?, useSizeTween: boolean?, itemManager: Types.ItemManagerObject?)	
	local selectedItemManager = itemManager or self.ItemManager
	
	if applyPosition then
		local rotationOffset = Vector2.zero
		if self.Rotation % 2 == 1 then
			rotationOffset = Vector2.new(self.Size.Y, self.Size.X) / 2 - self.Size / 2
		end

		local itemManagerOffset = selectedItemManager:GetOffset(self.Rotation)
		local sizeScale = selectedItemManager:GetSizeScale()
		local elementPosition = UDim2.fromOffset((self.Position.X + rotationOffset.X) * sizeScale.X + itemManagerOffset.X - self.ItemManager.GuiElement.Parent.AbsolutePosition.X, (self.Position.Y + rotationOffset.Y) * sizeScale.Y + itemManagerOffset.Y - self.ItemManager.GuiElement.Parent.AbsolutePosition.Y)
		if usePositionTween then
			TweenService:Create(self.ItemElement, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = elementPosition, Rotation = self.Rotation * 90}):Play()
		else
			self.ItemElement.Position = elementPosition
			self.ItemElement.Rotation = self.Rotation * 90
		end
	end
	
	if applySize then
		local absoluteElementSize = selectedItemManager:GetAbsoluteSizeFromItemSize(self.Size, self.Rotation)
		local elementSize = UDim2.fromOffset(absoluteElementSize.X, absoluteElementSize.Y)
		if useSizeTween then
			TweenService:Create(self.ItemElement, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = elementSize}):Play()
		else
			self.ItemElement.Size = elementSize
		end
	end
end

--[=[
	Rotates the Item, has to be dragged to be rotatable.

	@within Item
]=]
function Item:Rotate(quartersOf360: number)
	assert(self.IsDragging, "Must be dragging to rotate an item!")

	self.PotentialRotation += quartersOf360
	if self.PotentialRotation > 3 then
		self.ItemElement.Rotation = -90
		self.PotentialRotation -= 4
	elseif self.PotentialRotation < 0 then
		self.ItemElement.Rotation = 360
		self.PotentialRotation += 4
	end

	if self._highlight then
		local currentItemManager = self.HoveringItemManager or self.ItemManager
		local gridPos = currentItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size, self.PotentialRotation)
		self._highlight.Position = gridPos

		if self.PotentialRotation % 2 == 1 then
			self._highlight.Size = Vector2.new(self.Size.Y, self.Size.X)
		else
			self._highlight.Size = self.Size
		end
	end

	TweenService:Create(self.ItemElement, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Rotation = self.PotentialRotation * 90}):Play()
end

--[=[
	Moves an item to a new ItemManager. This should only be used for transferring Items between ItemManagers that aren't linked using TranferLinks.

	@within Item
]=]
function Item:SetItemManager(itemManager: Types.ItemManagerObject)
	if self.ItemManager ~= nil then
		self.ItemManager:RemoveItem(self)
	end

	repeat
		task.wait()
	until self.ItemManager == nil
	
	if itemManager.Items then
		itemManager:AddItem(self, nil, true)
	else
		itemManager:ChangeItem(self, nil, true)
	end
end

--[=[
	Destroy the Item object.

	@within Item
]=]
function Item:Destroy()
	self._trove:Destroy()
end

return Item