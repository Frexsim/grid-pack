--// Services
local RunService = game:GetService("RunService")

--// Classes
local ItemManager = require(script.Parent)

--// Packages
local Signal = require(script.Parent.Parent.Parent.signal)

--// Types
local Types = require(script.Parent.Parent.Types)

--// SingleSlot Class
local SingleSlot = setmetatable({}, ItemManager)
SingleSlot.__index = SingleSlot

--[=[
	@class SingleSlot
]=]
--[=[
	@prop GuiElement GuiObject
	@readonly
	The SingleSlot's GUI element.

	@within SingleSlot
]=]
--[=[
	@prop Item ItemObject
	@readonly
	The current Item in the SingleSlot.

	@within SingleSlot
]=]
--[=[
	@prop ItemChanged RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time a new Item replaces the old Item.

	@within SingleSlot
]=]

--[=[
	Creates a new SingleSlot ItemManager object.

	@within SingleSlot
]=]
function SingleSlot.new(properties: Types.SingleSlotProperties): Types.SingleSlotObject
	local self = setmetatable(ItemManager.new({
		Assets = properties.Assets,
		Metadata = properties.Metadata,
	}), SingleSlot)
	self.GuiElement = self:_createGuiElement(properties)
	
	self.Item = nil
	self.ItemChanged = Signal.new()
	
	self._trove:Add(RunService.RenderStepped:Connect(function()
		self.GuiElement.GroupColor3 = Color3.new(0, 0, 0)
		
		for _, highlight in self.Highlights do
			self.GuiElement.GroupColor3 = highlight.Color
		end
	end))

	return self
end

--[=[
	@private
	Creates a new SingleSlot GUI element.

	@within SingleSlot
]=]
function SingleSlot:_createGuiElement(properties: Types.SingleSlotProperties): { GuiObject }
	local container = self._trove:Add(self.Assets.Slot:Clone())
	container.Name = "SingleSlot"

	container.AnchorPoint = properties.AnchorPoint
	container.Position = properties.Position
	container.Size = properties.Size
	
	container.Visible = self.Visible

	container.Parent = properties.Parent

	return container
end

--[=[
	Gets the AbsoluteSize of the slot.

	@tag ItemManager Override
	@within SingleSlot
]=]
function SingleSlot:GetSizeScale(): Vector2
	return self.GuiElement.AbsoluteSize
end

--[=[
	Gets the AbsoluteSize of an Item with the ItemManager's size scale.

	@tag ItemManager Override
	@within SingleSlot
]=]
function SingleSlot:GetAbsoluteSizeFromItemSize(itemSize: Vector2): Vector2
	return self.GuiElement.AbsoluteSize
end

--[=[
	Checks if an Item is colliding. Use the `at` parameter to override the collision check position, else it will use the Item's position.

	@tag ItemManager Override
	@within SingleSlot
]=]
function SingleSlot:IsColliding(item: Types.ItemObject, ignoredItems: { Types.ItemObject }, at: Vector2?): boolean
	if table.find(ignoredItems, self.Item) then
		return false
	end

	return self.Item ~= nil
end

--[=[
	Changes the current item in the SingleSlot.

	@tag ItemManager Override
	@within SingleSlot
]=]
function SingleSlot:ChangeItem(item: Types.ItemObject)
	assert(item.ItemManager == nil, "Could not add item: Item is already in another ItemManager")
	
	if self.Item then
		self:RemoveItem()
	end
	
	self.Item = item
	self.ItemChanged:Fire(item)
	
	item.ItemManagerChanged:Fire(self, true)
end

--[=[
	Removes the item from the SingleSlot.

	@tag ItemManager Override
	@within SingleSlot
]=]
function SingleSlot:RemoveItem()
	if self.Item then
		self.Item.ItemManagerChanged:Fire(nil)
	end
	
	self.Item = nil
	self.ItemChanged:Fire(nil)
end

return SingleSlot
