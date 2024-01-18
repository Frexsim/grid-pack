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


-- Create a new SingleSlot object
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

function SingleSlot:GetSizeScale(): Vector2
	return self.GuiElement.AbsoluteSize
end

function SingleSlot:GetAbsoluteSizeFromItemSize(_): Vector2
	return self.GuiElement.AbsoluteSize
end

function SingleSlot:IsColliding(_, ignoredItems: { [number]: Types.ItemObject }, _): boolean
	if table.find(ignoredItems, self.Item) then
		return false
	end

	return self.Item ~= nil
end

function SingleSlot:ChangeItem(item)
	assert(item.ItemManager == nil, "Could not add item: Item is already in another ItemManager")
	
	if self.Item then
		self:RemoveItem()
	end
	
	self.Item = item
	self.ItemChanged:Fire(item)
	
	item.ItemManagerChanged:Fire(self, true)
end

function SingleSlot:RemoveItem()
	if self.Item then
		self.Item.ItemManagerChanged:Fire(nil)
	end
	
	self.Item = nil
	self.ItemChanged:Fire(nil)
end

return SingleSlot
