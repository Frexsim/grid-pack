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

function ItemManager:GetOffset(): Vector2
	return self.GuiElement.AbsolutePosition
end

function ItemManager:GetSizeScale(): Vector2
	return Vector2.zero
end

function ItemManager:GetAbsoluteSizeFromItemSize(_): Vector2
	return Vector2.zero
end

function ItemManager:GetItemManagerPositionFromAbsolutePosition(_, _): Vector2
	return Vector2.zero
end

function ItemManager:IsColliding(_, _, _): boolean
	return true
end

function ItemManager:RemoveItem(_) end

function ItemManager:SetVisibility(isVisible: boolean)
	if isVisible ~= self.Visible then
		self.Visible = isVisible
		
		if self.GuiElement then
			self.GuiElement.Visible = self.Visible
		end
		
		self.VisibilityChanged:Fire(self.Visible)
	end
end

function ItemManager:ConnectTransferLink(transferLink: Types.TransferLinkObject)
	table.insert(self.ConnectedTransferLinks, transferLink)

	self.TransferLinkConnected:Fire(transferLink)
	transferLink:AddItemManager(self)
end

function ItemManager:DisconnectTransferLink(transferLink: Types.TransferLinkObject)
	transferLink:AddItemManager(self)
	
	local transferLinkIndex = table.find(self.ConnectedTransferLinks, transferLink)
	assert(transferLink, "Failed to disconnect TransferLink: Could not find a matching TransferLink that was connected")
	
	table.remove(self.ConnectedTransferLinks, transferLinkIndex)
	
	self.TransferLinkDisconnected:Fire(transferLink)
end

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

function ItemManager:RemoveHighlight(highlight: Types.HighlightObject)
	local highlightIndex = table.find(self.Highlights, highlight)
	if highlightIndex then
		self.Highlights[highlightIndex] = nil
		
		highlight.ItemManagerChanged:Fire(nil)
	end
end

function ItemManager:Destroy()
	self._trove:Destroy()
end

return ItemManager