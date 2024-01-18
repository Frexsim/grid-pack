local loadingOrder = {
	script.InventoryManager,
}

for _, moduleScript in ipairs(loadingOrder) do
	local loadedModule = require(moduleScript)
	loadedModule:Init()
end