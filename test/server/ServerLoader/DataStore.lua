local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local RobloxDataStore = DataStoreService:GetDataStore("DataStoreV1")



local DataStore = {
	LoadedPlayerData = {},
	DefaultPlayerData = {
		Inventory = {}
	},
	
	PlayersSavingData = 0,
}

local function areTablesEqual(a: { any }, b: { any })
	for key, aValue in pairs(a) do
		if typeof(aValue) ~= "table" then
			if b[key] ~= aValue then
				return false
			end
		else
			if typeof(b[key]) == "table" then
				if areTablesEqual(aValue, b[key]) == false then
					return false
				end
			else
				return false
			end
		end
	end
	
	return true
end

function DataStore:Init()
	game:BindToClose(function()
		repeat
			task.wait(0.5)
		until self.PlayersSavingData <= 0
	end)
	
	Players.PlayerAdded:Connect(function(player: Player)
		local playerData = RobloxDataStore:GetAsync(player.UserId)
		
		local utf8DecodedInventory = {}
		for key, item in pairs(playerData.Inventory) do
			local parsedItem = {}

			for itemValueKey, itemValue in pairs(item) do
				if typeof(itemValue) == "table" then
					if itemValue.X ~= nil and itemValue.Y ~= nil and itemValue.Z == nil then
						parsedItem[itemValueKey] = Vector2.new(itemValue.X, itemValue.Y)
					elseif itemValue.X ~= nil and itemValue.Y ~= nil and itemValue.Z ~= nil then
						parsedItem[itemValueKey] = Vector3.new(itemValue.X, itemValue.Y, itemValue.Z)
					elseif itemValue.R ~= nil and itemValue.G ~= nil and itemValue.B ~= nil then
						parsedItem[itemValueKey] = Color3.new(itemValue.R, itemValue.G, itemValue.B)
					end
				else
					parsedItem[itemValueKey] = itemValue
				end
			end

			utf8DecodedInventory[key] = parsedItem
		end
		
		playerData.Inventory = utf8DecodedInventory
		
		self.LoadedPlayerData[player.UserId] = self:ReconcilePlayerData(playerData)
		print("Player Data Loaded (" .. player.UserId .. ")")
		print(self.LoadedPlayerData[player.UserId])
		
		ServerStorage.Bindables.PlayerDataLoaded:Fire(player, playerData)
	end)
	
	Players.PlayerRemoving:Connect(function(player: Player)
		self.PlayersSavingData += 1
		
		local playerData = self.LoadedPlayerData[player.UserId]
		if playerData then
			local playerInventory = ServerStorage.Bindables.GetPlayerInventory:Invoke(player)
			local utf8EncodedInventory = {}
			for key, item in pairs(playerInventory.Items) do
				local parsedItem = {}
				
				for itemValueKey, itemValue in pairs(item) do
					if typeof(itemValue) == "Vector2" then
						parsedItem[itemValueKey] = {
							X = itemValue.X,
							Y = itemValue.Y,
						}
					elseif typeof(itemValue) == "Vector3" then
						parsedItem[itemValueKey] = {
							X = itemValue.X,
							Y = itemValue.Y,
							Z = itemValue.Z,
						}
					elseif typeof(itemValue) == "Color3" then
						parsedItem[itemValueKey] = {
							R = itemValue.R,
							G = itemValue.G,
							B = itemValue.B,
						}
					else
						parsedItem[itemValueKey] = itemValue
					end
				end
				
				utf8EncodedInventory[key] = parsedItem
			end
			playerData.Inventory = utf8EncodedInventory
			
			if areTablesEqual(playerData, self.DefaultPlayerData) == false then
				RobloxDataStore:SetAsync(player.UserId, playerData)
				print("Player Data Saved (" .. player.UserId .. ")")
			end
		end
		
		self.PlayersSavingData -= 1
	end)
end

local function reconcileTable(defaultTable: { any }, valueTable: { any })
	for key, defaultValue in pairs(defaultTable) do
		if valueTable[key] == nil then
			valueTable[key] = defaultValue
		elseif type(valueTable[key]) == "table" then
			if type(defaultValue) ~= "table" then
				valueTable[key] = defaultValue
			else
				reconcileTable(defaultValue, valueTable)
			end
		end
	end
	
	return valueTable
end

local function deepCopyTable(tableToCopy: { any })
	local newTable = {}
	
	for key, value in pairs(tableToCopy) do
		if type(value) ~= "table" then
			newTable[key] = value
		else
			newTable[key] = deepCopyTable(value)
		end
	end
	
	return newTable
end

function DataStore:ReconcilePlayerData(data: { any }?)
	if data then
		return reconcileTable(self.DefaultPlayerData, data)
	else
		return deepCopyTable(self.DefaultPlayerData)
	end
end

return DataStore