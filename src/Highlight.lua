--// Packages
local Signal = require(script.Parent.Parent.signal)
local Trove = require(script.Parent.Parent.trove)

--// Types
local Types = require(script.Parent.Types)

--// Highlight Class
local Highlight = {}
Highlight.__index = Highlight

--[=[
	@class Highlight
]=]
--[=[
	@prop Position Vector2
	The Grid position of the Highlight.

	@within Highlight
]=]
--[=[
	@prop Size Vector2
	The Grid size of the Highlight.

	@within Highlight
]=]
--[=[
	@prop Color Color3
	The color of the Highlight.

	@within Highlight
]=]
--[=[
	@prop ItemManager ItemManagerObject
	@readonly
	The current ItemManager that the Highlight effects. Change via `Highlight:SetItemManager()`.

	@within Highlight
]=]
--[=[
	@prop ItemManagerChanged RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time the ItemManager is switched.

	@within Highlight
]=]

--[=[
	Creates a new Highlight object

	@within Highlight
]=]
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

--[=[
	Change the ItemManager that the Highlight effects.

	@within Highlight
]=]
function Highlight:SetItemManager(priority: number, itemManager: Types.ItemManagerObject)
	self.ItemManager = itemManager
	self.ItemManagerChanged:Fire(itemManager)
	
	self.ItemManager:AddHighlight(priority, self)
end

--[=[
	Destroy the Highlight object.

	@within Highlight
]=]
function Highlight:Destroy()
	self._trove:Destroy()
end

return Highlight
