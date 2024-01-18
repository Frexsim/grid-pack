--// Services
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

--// Constants
local guiInset = GuiService:GetGuiInset()

--// Types
local Types = require(script.Parent.Types)

--// TransferLink Class
local TransferLink = {}
TransferLink.__index = TransferLink

-- Create a new TransferLink object
function TransferLink.new(properties: Types.TransferLinkProperties): Types.TransferLinkObject
	local self = setmetatable({}, TransferLink)
	self.ConnectedItemManagers = properties.ConnectedItemManagers or {}

	return self
end

-- Add an ItemManager to transfer between
function TransferLink:AddItemManager(itemManager: Types.ItemManagerObject)
	table.insert(self.ConnectedItemManagers, itemManager)
end

-- Remove a connected ItemManager to disallow transferring between
function TransferLink:RemoveItemManager(itemManager: Types.ItemManagerObject)
	local itemManagerIndex = table.find(self.ConnectedItemManagers, itemManager)
	assert(itemManagerIndex, "Failed to remove ItemManager connection: Could not find connected ItemManager in TransferLink")
	
	table.remove(self.ConnectedItemManagers, itemManagerIndex)
end

-- Get a the first item-overlapping ItemManager
function TransferLink:GetItemOverlappingItemManagers(item): { Types.ItemManagerObject }
	local itemStart = item.ItemElement.AbsolutePosition
	local itemEnd = itemStart + item.ItemElement.AbsoluteSize

	local overlappingItemManagers =  {}
	for _, itemManager in pairs(self.ConnectedItemManagers) do
		if itemManager.Visible then
			local itemManagerStart = itemManager.GuiElement.AbsolutePosition
			local itemManagerEnd = itemManagerStart + itemManager.GuiElement.AbsoluteSize

			local xOverlapping = (itemStart.X <= itemManagerEnd.X) and (itemEnd.X >= itemManagerStart.X)
			local yOverlapping = (itemStart.Y <= itemManagerEnd.Y) and (itemEnd.Y >= itemManagerStart.Y)
			if xOverlapping and yOverlapping then
				table.insert(overlappingItemManagers, itemManager)
			end
		end
	end

	return overlappingItemManagers
end

-- Same as TransferLink:GetItemOverlappingItemManagers() but takes distance into account
function TransferLink:GetClosestItemOverlappingItemManagers(item): { Types.ItemManagerObject }
	local overlappingItemManagers = self:GetItemOverlappingItemManagers(item)
	local mousePosition = UserInputService:GetMouseLocation() - guiInset
	
	table.sort(overlappingItemManagers, function(a, b)
		local aBorderPosition = Vector2.new(
			math.clamp(mousePosition.X, a.GuiElement.AbsolutePosition.X, a.GuiElement.AbsolutePosition.X + a.GuiElement.AbsoluteSize.X),
			math.clamp(mousePosition.Y, a.GuiElement.AbsolutePosition.Y, a.GuiElement.AbsolutePosition.Y + a.GuiElement.AbsoluteSize.Y)
		)
		local bBorderPosition = Vector2.new(
			math.clamp(mousePosition.X, b.GuiElement.AbsolutePosition.X, b.GuiElement.AbsolutePosition.X + b.GuiElement.AbsoluteSize.X),
			math.clamp(mousePosition.Y, b.GuiElement.AbsolutePosition.Y, b.GuiElement.AbsolutePosition.Y + b.GuiElement.AbsoluteSize.Y)
		)
		local aDistance = (aBorderPosition - mousePosition).Magnitude
		local bDistance = (bBorderPosition - mousePosition).Magnitude
		
		return aDistance < bDistance
	end)
	
	return overlappingItemManagers
end

return TransferLink
