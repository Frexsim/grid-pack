local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")



local InventoryManager = {
	ActiveInventories = {}
}

function InventoryManager:Init()
	ServerStorage.Bindables.PlayerDataLoaded.Event:Connect(function(player, playerData)
		local newPlayerInventory = self:CreateNewInventory(player, playerData.Inventory)
	end)
	
	ServerStorage.Bindables.GetPlayerInventory.OnInvoke = function(player)
		return self:GetInventoryFromTiedInstance(player)
	end
	
	ReplicatedStorage.Remotes.GetLocalInventory.OnServerInvoke = function(player)
		local inventory = self:GetInventoryFromTiedInstance(player)
		
		if inventory == nil then
			repeat
				task.wait(1)
			until self:GetInventoryFromTiedInstance(player)
			
			return self:GetInventoryFromTiedInstance(player)
		end
		
		return inventory
	end
	
	for _, storage in ipairs(CollectionService:GetTagged("Storage")) do
		local storageInventory = self:CreateNewInventory(storage)
		storageInventory.Items[1] = {
			Position = Vector2.zero,
			Size = Vector2.new(2, 5),
		}
		
		local openProximityPrompt = Instance.new("ProximityPrompt")
		openProximityPrompt.Name = "InteractionPrompt"
		openProximityPrompt.ActionText = "Open"
		openProximityPrompt.ObjectText = storage.Name
		
		openProximityPrompt.Triggered:Connect(function(player: Player)
			ReplicatedStorage.Remotes.StorageInventoryOpened:FireClient(player, storageInventory)
		end)
		
		openProximityPrompt.Parent = storage
	end
	
	ReplicatedStorage.Remotes.MoveItemAcrossItemManager.OnServerInvoke = function(_, itemIndex, lastInventoryTiedInstance, newInventoryTiedInstance, newGridPosition)
		local success, result, newIndexResult = pcall(function()
			local lastInventory = self:GetInventoryFromTiedInstance(lastInventoryTiedInstance)
			local newInventory = self:GetInventoryFromTiedInstance(newInventoryTiedInstance)
			local item = lastInventory.Items[itemIndex]
			local newIndex = nil
			if item then
				lastInventory.Items[itemIndex] = nil
				item.Position = newGridPosition
				local newInventoryItemAmount = 1
				for _, _ in pairs(newInventory.Items) do
					newInventoryItemAmount += 1
				end

				for index = 1, newInventoryItemAmount do
					if newInventory.Items[index] == nil then
						newIndex = index
						break
					end
				end
				newInventory.Items[newIndex] = item
			else
				return false, newIndex
			end

			return true, newIndex
		end)

		if success then
			return result, newIndexResult
		else
			warn(result)
			return false, newIndexResult
		end
	end
	
	ReplicatedStorage.Remotes.MoveItem.OnServerInvoke = function(_, itemIndex, inventoryTiedInstance, newGridPosition)
		local success, result = pcall(function()
			local inventory = self:GetInventoryFromTiedInstance(inventoryTiedInstance)
			inventory.Items[itemIndex].Position = newGridPosition
			
			return true
		end)
		
		if success then
			return result
		else
			warn(result)
			return false
		end
	end
end

function InventoryManager:CreateNewInventory(tiedInstance: Instance?, items: { any }?)
	local newInventory = {
		TiedInstance = tiedInstance,
		Items = items or {},
	}
	
	table.insert(self.ActiveInventories, newInventory)
	
	if tiedInstance then
		local tiedInstanceDestroyedConnection = nil
		tiedInstanceDestroyedConnection = tiedInstance:GetPropertyChangedSignal("Parent"):Connect(function()
			if tiedInstance.Parent == nil then
				local inventoryIndex = table.find(self.ActiveInventories, newInventory)
				if inventoryIndex then
					table.remove(self.ActiveInventories, inventoryIndex)
					
					tiedInstanceDestroyedConnection:Disconnect()
				end
			end
		end)
	end
	
	return newInventory
end

function InventoryManager:GetInventoryFromTiedInstance(instance: Instance)
	for _, inventory in ipairs(self.ActiveInventories) do
		if inventory.TiedInstance == instance then
			return inventory
		end
	end
	
	return nil
end

return InventoryManager