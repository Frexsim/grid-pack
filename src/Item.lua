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

-- Create a new Item object
function Item.new(properties: Types.ItemProperties): Types.ItemObject
	local self = setmetatable({}, Item)
	self._trove = Trove.new()
	self._itemManagerTrove = self._trove:Add(Trove.new())
	self._draggingTrove = self._trove:Add(Trove.new())
	
	self.Assets = properties.Assets or {}
	if self.Assets.Item == nil then
		self.Assets.Item = self:_createDefaultItemAsset()
	end
	
	self.Position = properties.Position or Vector2.new(0, 0)
	self.PositionChanged = Signal.new()
	self.Size = properties.Size or Vector2.new(2, 2)
	
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
		
		self.ItemManager = itemManager
		
		if self.ItemManager ~= nil then
			self.ItemElement.Visible = self.ItemManager.Visible
			
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
	
	local highlight = nil
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
			
			-- Update positioning
			self:_updateDraggingPosition()
			
			TweenService:Create(self.ItemElement, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {GroupTransparency = 0.5}):Play()
			self.ItemElement.ZIndex += 1
			
			-- Create drop highlight
			local gridPos = self.ItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size)
			highlight = self._draggingTrove:Add(self.ItemManager:CreateHighlight(100, gridPos, self.Size, Color3.new(1, 1, 1)))
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
						highlight:SetItemManager(100, self.HoveringItemManager)
						self:_updateItemToItemManagerDimentions(false, true, false, true, self.HoveringItemManager)

						break
					end
				end
			end
			
			-- Check collision in hovering ItemManager and apply highlight color
			local currentItemManager = self.HoveringItemManager or self.ItemManager
			if currentItemManager then
				self:_updateDraggingPosition()
				
				local gridPos = currentItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size)
				highlight.Position = gridPos
				
				local isColliding = currentItemManager:IsColliding(self, { self }, gridPos)
				if isColliding == true then
					highlight.Color = Color3.new(1, 0, 0)
				else
					highlight.Color = Color3.new(1, 1, 1)
				end
			end
		end
	end))
	
	self._trove:Add(UserInputService.InputEnded:Connect(function(input)
		-- Drop item when left mouse stops getting clicked
		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.IsDragging == true and self.ItemManager ~= nil then	
			self.IsDragging = false
			
			-- Check if the item is colliding, if not add the item to the itemManager
			local currentItemManager = self.HoveringItemManager or self.ItemManager
			local gridPos = currentItemManager:GetItemManagerPositionFromAbsolutePosition(self.ItemElement.AbsolutePosition, self.Size)
			local isColliding = currentItemManager:IsColliding(self, { self }, gridPos)
			if isColliding == false then
				-- Get new ItemManager, is nil if no new ItemManager is found
				local newItemManager = nil
				if self.HoveringItemManager and self.HoveringItemManager ~= self.ItemManager then
					newItemManager = self.HoveringItemManager
				end
				
				-- Check for middleware and if it allows item move
				local middlewareReturn = nil
				if self.MoveMiddleware then
					middlewareReturn = self.MoveMiddleware(self, gridPos, self.ItemManager, newItemManager)
				end
				
				if middlewareReturn == true or middlewareReturn == nil then
					-- Move item
					self.Position = gridPos
					self.PositionChanged:Fire(gridPos)
					
					-- Switch ItemManager if the item was hovering above one
					if newItemManager then
						self:SetItemManager(self.HoveringItemManager)
					end
				end
			end
			
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

function Item:_createDefaultItemAsset()
    local itemElement = Instance.new("CanvasGroup")
	itemElement.Name = "ItemElement"
	itemElement.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	itemElement.BorderSizePixel = 0
	itemElement.Size = UDim2.fromOffset(140, 140)
	itemElement.ZIndex = 2

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.Image = "rbxassetid://14499638701"
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

function Item:_generateItemElement()
	local newItem = self._trove:Add(self.Assets.Item:Clone())
	if self.ItemManager then
		newItem.Visible = self.ItemManager.Visible
	end

	return newItem
end

function Item:_updateDraggingPosition()
	local mousePosition = UserInputService:GetMouseLocation() - guiInset
	self.ItemElement.Position = UDim2.fromOffset(mousePosition.X - self.MouseDraggingPivot.X * self.ItemElement.AbsoluteSize.X, mousePosition.Y - self.MouseDraggingPivot.Y * self.ItemElement.AbsoluteSize.Y)
end

function Item:_updateItemToItemManagerDimentions(applyPosition: boolean?, applySize: boolean?, usePositionTween: boolean?, useSizeTween: boolean?, itemManager: Types.ItemManagerObject?)	
	local selectedItemManager = itemManager or self.ItemManager
	
	if applyPosition then
		local itemManagerOffset = selectedItemManager:GetOffset()
		local sizeScale = selectedItemManager:GetSizeScale()
		local elementPosition = UDim2.fromOffset(self.Position.X * sizeScale.X + itemManagerOffset.X, self.Position.Y * sizeScale.Y + itemManagerOffset.Y)
		if usePositionTween then
			TweenService:Create(self.ItemElement, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = elementPosition}):Play()
		else
			self.ItemElement.Position = elementPosition
		end
	end
	
	if applySize then
		local absoluteElementSize = selectedItemManager:GetAbsoluteSizeFromItemSize(self.Size)
		local elementSize = UDim2.fromOffset(absoluteElementSize.X, absoluteElementSize.Y)
		if useSizeTween then
			TweenService:Create(self.ItemElement, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = elementSize}):Play()
		else
			self.ItemElement.Size = elementSize
		end
	end
end

function Item:SetItemManager(itemManager)
	if self.ItemManager ~= nil then
		self.ItemManager:RemoveItem(self)
	end
	
	if itemManager.Items then
		itemManager:AddItem(self, nil, true)
	else
		itemManager:ChangeItem(self, nil, true)
	end
end

function Item:Destroy()
	self._trove:Destroy()
end

return Item