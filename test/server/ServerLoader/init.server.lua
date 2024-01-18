local loadingOrder = {
	script.DataStore,
	script.InventoryManager,
}

for _, moduleScript in ipairs(loadingOrder) do
	local loadedModule = require(moduleScript)
	loadedModule:Init()
end