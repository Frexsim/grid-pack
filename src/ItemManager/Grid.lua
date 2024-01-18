--// Services
local RunService = game:GetService("RunService")

--// Packages
local Signal = require(script.Parent.Parent.Parent.signal)

--// Classes
local ItemManager = require(script.Parent)

--// Types
local Types = require(script.Parent.Parent.Types)

--// Grid Class
local Grid = setmetatable({}, ItemManager)
Grid.__index = Grid

function Grid.new(properties: Types.GridProperties): Types.GridObject
	local self = setmetatable(ItemManager.new({
		Assets = properties.Assets,
		Metadata = properties.Metadata,
	}), Grid)
	self.GuiElement, self.SlotElements = self:_createGuiElement(properties)
	
	self.GridSize = properties.GridSize
	self.SlotAspectRatio = properties.SlotAspectRatio
	
	self.Items = {}
	self.ItemAdded = Signal.new()
	self.ItemRemoved = Signal.new()
	
	self:_updateGuiGrid()
	
	self._trove:Add(RunService.RenderStepped:Connect(function()
		for _, slotElement in pairs(self.SlotElements) do
			slotElement.GroupColor3 = Color3.new(0, 0, 0)
		end
		
		for _, highlight in self.Highlights do
			for xPosition = highlight.Position.X + 1, highlight.Position.X + highlight.Size.X do
				for yPosition = highlight.Position.Y + 1, highlight.Position.Y + highlight.Size.Y do
					local slotElement = self.SlotElements[xPosition .. ", " .. yPosition]
					slotElement.GroupColor3 = highlight.Color
				end
			end
		end
	end))

	return self
end

function Grid:_createGuiElement(properties: Types.GridProperties): (GuiObject, { GuiObject })
	local slots = {}

	local container = self._trove:Add(Instance.new("CanvasGroup"))
	container.Name = "GridContainer"

	container.BackgroundTransparency = 1

	container.AnchorPoint = properties.AnchorPoint
	container.Position = properties.Position
	container.Size = properties.Size

	local gridLayout = self._trove:Add(Instance.new("UIGridLayout"))
	gridLayout.CellPadding = UDim2.fromOffset(0, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local currentCellNumber = 1
	for gridY = 1, properties.GridSize.Y do
		for gridX = 1, properties.GridSize.X do
			local newGridCell = self._trove:Add(self.Assets.Slot:Clone())
			newGridCell.Name = currentCellNumber
			newGridCell.LayoutOrder = currentCellNumber

			slots[gridX .. ", " .. gridY] = newGridCell

			newGridCell.Parent = container

			currentCellNumber += 1
		end
	end
	
	container.Visible = self.Visible

	gridLayout.Parent = container
	container.Parent = properties.Parent

	return container, slots
end

function Grid:_updateGuiGrid()
	self.GuiElement.UIGridLayout.CellSize = UDim2.fromScale(1 / self.GridSize.X, 1 / self.GridSize.Y)
	
	if self.SlotAspectRatio then
		local aspectRatioConstraint = self.GuiElement:FindFirstChildOfClass("UIAspectRatioConstraint")
		if aspectRatioConstraint then
			aspectRatioConstraint.AspectRatio = self.GridSize.X / self.GridSize.Y * self.SlotAspectRatio
		else
			local newAspectRatio = Instance.new("UIAspectRatioConstraint")
			newAspectRatio.AspectRatio = self.GridSize.X / self.GridSize.Y * self.SlotAspectRatio
			
			newAspectRatio.Parent = self.GuiElement
		end
	else
		local aspectRatioConstraint = self.GuiElement:FindFirstChildOfClass("UIAspectRatioConstraint")
		if aspectRatioConstraint then
			aspectRatioConstraint:Destroy()
		end
	end
end

function Grid:GetSizeScale(): Vector2
	return self.GuiElement.UIGridLayout.AbsoluteCellSize
end

function Grid:GetAbsoluteSizeFromItemSize(itemSize: Vector2): Vector2
	local sizeScale = self:GetSizeScale()
	
	return Vector2.new(math.round(sizeScale.X), math.round(sizeScale.Y)) * itemSize
end

function Grid:GetItemManagerPositionFromAbsolutePosition(absolutePosition: Vector2, itemSize: Vector2): Vector2
	local itemManagerOffset = self.GuiElement.AbsolutePosition
	local sizeScale = self:GetSizeScale()
	local gridPosX = math.floor((absolutePosition.X - itemManagerOffset.X) / sizeScale.X + 0.5)
	local gridPosY = math.floor((absolutePosition.Y - itemManagerOffset.Y) / sizeScale.Y + 0.5)

	gridPosX = math.clamp(gridPosX, 0, self.GridSize.X - itemSize.X)
	gridPosY = math.clamp(gridPosY, 0, self.GridSize.Y - itemSize.Y)

	return Vector2.new(gridPosX, gridPosY)
end

function Grid:GetNextFreePositionForItem(item: Types.ItemObject): Vector2?
	for gridY = 0, self.GridSize.Y - 1 do
		for gridX = 0, self.GridSize.X - 1 do
			local currentPosition = Vector2.new(gridX, gridY)
			local insideBounds = self:IsRegionInBounds(currentPosition, item.Size)
			local collidingItems = self:GetItemsInRegion(currentPosition, item.Size, { item })
			if #collidingItems == 0 and insideBounds then
				return currentPosition
			end
		end
	end
	
	return nil
end

function Grid:GetItemsInRegion(position: Vector2, size: Vector2, ignoredItems: { Types.ItemObject }): { Types.ItemObject }
	local regionEnd = position + size

	local collidingItems = {}
	for _, item in ipairs(self.Items) do
		if table.find(ignoredItems, item) == nil then
			local itemStart = item.Position
			local itemEnd = itemStart + item.Size

			local xOverlapping = (position.X < itemEnd.X) and (regionEnd.X > itemStart.X)
			local yOverlapping = (position.Y < itemEnd.Y) and (regionEnd.Y > itemStart.Y)
			if xOverlapping and yOverlapping then
				table.insert(collidingItems, item)
			end
		end
	end

	return collidingItems
end

function Grid:IsColliding(item: Types.ItemObject, ignoredItems: { Types.ItemObject }, at: Vector2?): boolean
	local collidingItems = self:GetItemsInRegion(at or item.Position, item.Size, ignoredItems)
	return #collidingItems > 0
end

function Grid:IsRegionInBounds(position: Vector2, size: Vector2): boolean
	local regionEnd = position + size

	local isNotInBoundsX = position.X < 0 or regionEnd.X > self.GridSize.X 
	local isNotInBoundsY = position.Y < 0 or regionEnd.Y > self.GridSize.Y
	if isNotInBoundsX or isNotInBoundsY then
		return false
	else
		return true
	end
end

function Grid:SortItemsByVolume()
	local itemsSortedByVolume = table.clone(self.Items)
	table.sort(itemsSortedByVolume, function(a, b)
		local aVolume = a.Size.X * a.Size.Y
		local bVolume = b.Size.X * b.Size.Y

		return aVolume > bVolume
	end)

	for _, item in ipairs(itemsSortedByVolume) do
		self:RemoveItem(item)
	end

	task.wait()

	for _, item in ipairs(itemsSortedByVolume) do
		local nextFreePosition = self:GetNextFreePositionForItem(item)
		self:AddItem(item, nextFreePosition, true)
	end
end

function Grid:AddItem(item: Types.ItemObject, at: Vector2?, useTween: boolean?)
	local itemPosition = at or item.Position
	assert(item.ItemManager == nil, "Could not add item: Item is already in another ItemManager")
	assert(self:IsColliding(item, { item }, itemPosition) == false, "Could not add item: Item is colliding with an already added item")
	assert(self:IsRegionInBounds(itemPosition, item.Size) == true, "Could not add item: Item is out of the grid's bounds")
	
	item.Position = itemPosition
	table.insert(self.Items, item)
	self.ItemAdded:Fire(item)
		
	item.ItemManagerChanged:Fire(self, useTween)
end

function Grid:RemoveItem(item: Types.ItemObject)
	local foundItemIndex = table.find(self.Items, item)
	if foundItemIndex then
		table.remove(self.Items, foundItemIndex)
		self.ItemRemoved:Fire(item)

		item.ItemManagerChanged:Fire(nil)
	else
		error("Unable to remove item: Item could not be found in ItemManager")
	end
end

function Grid:ClearItems()
	for index, item in ipairs(self.Items) do
		self.Items[index] = nil
		self.ItemRemoved:Fire(item)
		
		item.ItemManagerChanged:Fire(nil)
	end
end

return Grid
