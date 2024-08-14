local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local GridPack = require(ReplicatedStorage.Packages.GridPack)



local InventoryManager = {}

function InventoryManager:Init()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	
	local localInventory = ReplicatedStorage.Remotes.GetLocalInventory:InvokeServer()
	
	self.LocalInventory = GridPack.createGrid({
		Parent = Players.LocalPlayer.PlayerGui:WaitForChild("Test").ScrollingFrame.CanvasGroup,

		GridSize = Vector2.new(8, 15),
		SlotAspectRatio = 1,

		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		
		Metadata = {
			TiedInstance = localInventory.TiedInstance,
		}
	})
	
	self:LoadInventory(self.LocalInventory, localInventory)
	
	self.StorageInventory = GridPack.createGrid({
		Parent = Players.LocalPlayer.PlayerGui:WaitForChild("Test"),

		GridSize = Vector2.new(8, 15),
		SlotAspectRatio = 1,

		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromScale(0.25, 0.5),
	})
	
	self.StorageTransferLink = GridPack.createTransferLink({})
	self.LocalInventory:ConnectTransferLink(self.StorageTransferLink)
	self.StorageInventory:ConnectTransferLink(self.StorageTransferLink)
	
	ReplicatedStorage.Remotes.StorageInventoryOpened.OnClientEvent:Connect(function(storageInventory)
		self:ClearGridPackInventory(self.StorageInventory)
		self:LoadInventory(self.StorageInventory, storageInventory)
		
		self.StorageInventory:SetVisibility(true)
		self.LocalInventory:SetVisibility(true)
	end)
	
	ReplicatedStorage.Remotes.StorageInventoryClosed.OnClientEvent:Connect(function()
		self.StorageInventory:SetVisibility(false)
		self.LocalInventory:SetVisibility(false)
		
		self:ClearGridPackInventory(self.StorageInventory)
	end)
	
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent == false then
			if input.KeyCode == Enum.KeyCode.Tab then
				self.LocalInventory:SetVisibility(not self.LocalInventory.Visible)
				self.StorageInventory:SetVisibility(false)
			end
		end
	end)
end

function InventoryManager:LoadInventory(gridPackItemManager, inventory)
	gridPackItemManager.Metadata.TiedInstance = inventory.TiedInstance
	
	for itemIndex, item in pairs(inventory.Items) do
		if item == nil then
			warn("Could not load item: Item is nil")
			continue
		end
		
		local newInteractiveItem = GridPack.createItem({
			Position = item.Position,
			Size = item.Size,
			Rotation = item.Rotation,
			
			MoveMiddleware = function(movedItem, newGridPosition, newRotation, lastItemManager, newItemManager)
				if newItemManager then
					local result, newItemIndex = ReplicatedStorage.Remotes.MoveItemAcrossItemManager:InvokeServer(movedItem.Metadata.ItemIndex, lastItemManager.Metadata.TiedInstance, newItemManager.Metadata.TiedInstance, newGridPosition, newRotation)
					movedItem.Metadata.ItemIndex = newItemIndex
					return result
				else
					return ReplicatedStorage.Remotes.MoveItem:InvokeServer(movedItem.Metadata.ItemIndex, lastItemManager.Metadata.TiedInstance, newGridPosition, newRotation)
				end
			end,
			
			Metadata = {
				ItemIndex = itemIndex
			}
		})

		local oldParent = nil
		newInteractiveItem.DragStarting:Connect(function(itemElement: GuiObject)
			oldParent = itemElement.Parent
			itemElement.Parent = Players.LocalPlayer.PlayerGui.Test
		end)
		newInteractiveItem.DragEnding:Connect(function(itemElement: GuiObject)
			itemElement.Parent = oldParent
		end)
		
		local success, errorMessage = pcall(function()
			gridPackItemManager:AddItem(newInteractiveItem)
		end)
		
		if not success then
			warn(errorMessage)
		end
	end
end

function InventoryManager:ClearGridPackInventory(gridPackItemManager)
	gridPackItemManager:ClearItems(true)
end

return InventoryManager