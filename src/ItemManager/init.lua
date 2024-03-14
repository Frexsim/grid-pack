--// Packages
local Signal = require(script.Parent.Parent.signal)
local Trove = require(script.Parent.Parent.trove)

--// Classes
local Highlight = require(script.Parent.Highlight)

--// Types
local Types = require(script.Parent.Types)

--// ItemManager Class
local ItemManager = {}
ItemManager.__index = ItemManager

--[=[
	@class ItemManager
	The base class for all ItemManagers.
]=]
--[=[
	@prop Visible boolean
	@readonly
	If the ItemManager is visible or not, disables all interactions with Items. Should not be edited, use `ItemManager:SetVisibility()` to change it.

	@within ItemManager
]=]
--[=[
	@prop VisibilityChanged RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time the ItemManager's visibility changes.

	@within ItemManager
]=]
--[=[
	@prop Highlights { HighlightObject }
	@readonly
	All of the Highlights that are currently on the ItemManager. Use `ItemManager:CreateHighlight()`, `ItemManager:AddHighlight()` or `ItemManager:RemoveHighlight()` to edit.

	@within ItemManager
]=]
--[=[
	@prop ConnectedTransferLinks { TransferLinkObject }
	@readonly
	All of the TransferLinks that are currently connected to the ItemManager.

	@within ItemManager
]=]
--[=[
	@prop TransferLinkConnected RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time a new TransferLink is connected to the ItemManager.

	@within ItemManager
]=]
--[=[
	@prop TransferLinkDisconnected RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time a new TransferLink is disconnected from the ItemManager.

	@within ItemManager
]=]
--[=[
	@prop Metadata { any }
	Any custom data that you would want to store.

	@within ItemManager
]=]

--[=[
	@private
	Creates a new ItemManager object. Do not create a raw ItemManager object and instead create a Grid or a SingleSlot object.

	@within ItemManager
]=]
function ItemManager.new(properties: Types.ItemManagerProperties): Types.ItemManagerObject
	local self = setmetatable({}, ItemManager)
	self._trove = Trove.new()
	
	self.Assets = properties.Assets or {}
	if self.Assets.Slot == nil then
		self.Assets.Slot = self:_createDefaultSlotAsset()
	end
	
	self.Visible = properties.Visible or false
	self.VisibilityChanged = Signal.new()
	
	self.Highlights = {}
	
	self.ConnectedTransferLinks = {}
	self.TransferLinkConnected = Signal.new()
	self.TransferLinkDisconnected = Signal.new()
	
	self.Metadata = properties.Metadata or {}
	
	return self
end

function ItemManager:_createDefaultSlotAsset()
    local slotElement = Instance.new("CanvasGroup")
    slotElement.Name = "SlotElement"
    slotElement.GroupColor3 = Color3.fromRGB(0, 0, 0)
    slotElement.GroupTransparency = 0.5
    slotElement.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    slotElement.BackgroundTransparency = 1
    slotElement.BorderSizePixel = 0
    slotElement.Size = UDim2.fromOffset(10, 10)

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BorderSizePixel = 0
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromScale(0.9, 0.9)
	frame.Parent = slotElement

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "UICorner"
    uICorner.Parent = frame

    return slotElement
end

--[=[
	Gets the AbsolutePosition property from the ItemManager's GUI element.

	@within ItemManager
]=]
function ItemManager:GetOffset(): Vector2
	return self.GuiElement.AbsolutePosition
end

--[=[
	Gets the AbsoluteSize of one slot.

	@within ItemManager
]=]
function ItemManager:GetSizeScale(): Vector2
	return Vector2.zero
end

--[=[
	Gets the AbsoluteSize of an Item with the ItemManager's size scale.

	@within ItemManager
]=]
function ItemManager:GetAbsoluteSizeFromItemSize(itemSize: Vector2): Vector2
	return Vector2.zero
end

--[=[
	Converts an AbsolutePosition to a ItemManager position.

	@within ItemManager
]=]
function ItemManager:GetItemManagerPositionFromAbsolutePosition(absolutePosition: Vector2, itemSize: Vector2, itemRotation: number): Vector2
	return Vector2.zero
end

--[=[
	Checks if an Item is colliding. Use the `at` parameter to override the collision check position, else it will use the Item's position.

	@within ItemManager
]=]
function ItemManager:IsColliding(item: Types.ItemObject, ignoredItems: { Types.ItemObject }, at: Vector2?): boolean
	return true
end

--[=[
	Removes an item from the ItemManager.

	@within ItemManager
]=]
function ItemManager:RemoveItem(item: Types.ItemObject) end

--[=[
	Sets the visibility property on all GUI elements and disables interactivity on all Items in the ItemManager.

	@within ItemManager
]=]
function ItemManager:SetVisibility(isVisible: boolean)
	if isVisible ~= self.Visible then
		self.Visible = isVisible
		
		if self.GuiElement then
			self.GuiElement.Visible = self.Visible
		end
		
		self.VisibilityChanged:Fire(self.Visible)
	end
end

--[=[
	Connect a TranferLink. Allows tranferring Items between all of the ItemManagers that the TransferLink is connected to.

	@within ItemManager
]=]
function ItemManager:ConnectTransferLink(transferLink: Types.TransferLinkObject)
	table.insert(self.ConnectedTransferLinks, transferLink)

	self.TransferLinkConnected:Fire(transferLink)
	transferLink:AddItemManager(self)
end

--[=[
	Disconnect a TransferLink.

	@within ItemManager
]=]
function ItemManager:DisconnectTransferLink(transferLink: Types.TransferLinkObject)
	transferLink:AddItemManager(self)
	
	local transferLinkIndex = table.find(self.ConnectedTransferLinks, transferLink)
	assert(transferLink, "Failed to disconnect TransferLink: Could not find a matching TransferLink that was connected")
	
	table.remove(self.ConnectedTransferLinks, transferLinkIndex)
	
	self.TransferLinkDisconnected:Fire(transferLink)
end

--[=[
	Creates a new Highlight, used for highlighting where an Item will be dropped. Highlights are not only limited to Item dropping and can be used to highlight anything!
	Use `ItemManager:AddHighlight()` to add an already existing highlight.

	@within ItemManager
]=]
function ItemManager:CreateHighlight(priority: number, position: Vector2, size: Vector2, color: Color3): Types.HighlightObject
	local highlight: Types.HighlightObject = Highlight.new({
		Position = position,
		Size = size,
		Color = color,
	})

	priority = priority or 1
	while self.Highlights[priority] ~= nil do
		priority += 1
	end

	local itemManagerChangedConnection = nil
	itemManagerChangedConnection = highlight.ItemManagerChanged:Connect(function()
		self.Highlights[priority] = nil

		itemManagerChangedConnection:Disconnect()
		itemManagerChangedConnection = nil
	end)

	self.Highlights[priority] = highlight

	return highlight
end

--[=[
	Adds an already existing highlight, use `ItemManager:CreateHighlight()` to create a new Highlight.

	@within ItemManager
]=]
function ItemManager:AddHighlight(priority: number, highlight: Types.HighlightObject)
	priority = priority or 1
	while self.Highlights[priority] ~= nil do
		priority += 1
	end

	local itemManagerChangedConnection = nil
	itemManagerChangedConnection = highlight.ItemManagerChanged:Connect(function()
		self.Highlights[priority] = nil

		itemManagerChangedConnection:Disconnect()
		itemManagerChangedConnection = nil
	end)

	self.Highlights[priority] = highlight
end

--[=[
	Removes a Highlight from the ItemManager.

	@within ItemManager
]=]
function ItemManager:RemoveHighlight(highlight: Types.HighlightObject)
	local highlightIndex = table.find(self.Highlights, highlight)
	if highlightIndex then
		self.Highlights[highlightIndex] = nil
		
		highlight.ItemManagerChanged:Fire(nil)
	end
end

--[=[
	Destroys the ItemManager.

	@within ItemManager
]=]
function ItemManager:Destroy()
	self._trove:Destroy()
end

return ItemManager