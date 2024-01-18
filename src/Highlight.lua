--// Packages
local Signal = require(script.Parent.Parent.signal)
local Trove = require(script.Parent.Parent.trove)

--// Types
local Types = require(script.Parent.Types)

--// Highlight Class
local Highlight = {}
Highlight.__index = Highlight

-- Create a new Highlight object
function Highlight.new(properties: Types.HighlightProperties): Types.HighlightObject
	local self = setmetatable({}, Highlight)
	self._trove = Trove.new()
	
	self.Position = properties.Position or Vector2.new(0, 0)
	self.Size = properties.Size or Vector2.new(1, 1)
	self.Color = properties.Color or Color3.new(1, 1, 1)
	
	self.ItemManager = nil
	self.ItemManagerChanged = Signal.new()
	
	self._trove:Add(function()
		if self.ItemManager then
			self.ItemManager:RemoveHighlight(self)
		end
		
		self.ItemManagerChanged:Fire(nil)
	end)
	
	return self
end

-- Change the ItemManager where the Highlight is active 
function Highlight:SetItemManager(priority: number, itemManager: Types.ItemManagerObject)
	self.ItemManager = itemManager
	self.ItemManagerChanged:Fire(itemManager)
	
	self.ItemManager:AddHighlight(priority, self)
end

function Highlight:Destroy()
	self._trove:Destroy()
end

return Highlight
