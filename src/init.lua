--[[ GridPack, v0.2.2

GridPack is a library used to easily create grid-style inventories
with an API abstraction and much customization.

Author: @iFrexsim

]]

local Item = require(script.Item)
local Grid = require(script.ItemManager.Grid)
local SingleSlot = require(script.ItemManager.SingleSlot)
local TransferLink = require(script.TransferLink)

local Types = require(script.Types)

local functionCollection: {
	createItem: (Types.ItemProperties) -> Types.ItemObject,
	createGrid: (Types.GridProperties) -> Types.GridObject,
	createSingleSlot: (Types.SingleSlotProperties) -> Types.SingleSlotObject,
	createTransferLink: (Types.TransferLinkProperties) -> Types.TransferLinkObject,
} = {
	createItem = Item.new,
	createGrid = Grid.new,
	createSingleSlot = SingleSlot.new,
	createTransferLink = TransferLink.new,
}

return functionCollection