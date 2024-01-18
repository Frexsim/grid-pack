--// Libraries
local Signal = require(script.Parent.Parent.signal)

--// Types
-- Item
export type ItemProperties = {
	Position: Vector2?,
	Size: Vector2?,

	Assets: {
		Item: GuiObject,
	}?,
	
	MoveMiddleware: ((item: ItemObject, newGridPosition: Vector2, lastItemManager: ItemManagerObject, newItemManager: ItemManagerObject?) -> boolean)?,
	
	Metadata: { any }?,
}
export type ItemObject = {
	Position: Vector2,
	PositionChanged: Signal.Signal<Vector2>,
	Size: Vector2,

	Assets: {
		Item: GuiObject,
	},
	
	ItemElement: GuiObject,
	
	ItemManager: ItemManagerObject?,
	ItemManagerChanged: Signal.Signal<ItemManagerObject?, boolean?>,
	HoveringItemManager: ItemManagerObject?,
	HoveringItemManagerChanged: Signal.Signal<ItemManagerObject?>,
	
	MoveMiddleware: ((item: ItemObject, newGridPosition: Vector2, lastItemManager: ItemManagerObject, newItemManager: ItemManagerObject?) -> boolean)?,
	RenderMiddleware: ((GuiObject) -> nil)?,
	
	Dragging: boolean,
	MouseDraggingPivot: Vector2,
	
	Metadata: { any },
}

-- ItemManager
export type ItemManagerProperties = {
	Parent: GuiObject?,
	Assets: { [string]: GuiObject },
	
	Visible: boolean?,
	
	Metadata: { any }?,
}
export type ItemManagerObject = {
	GuiElement: GuiObject?,
	
	Highlights: { HighlightObject },

	ConnectedTransferLinks: { TransferLinkObject },
	TransferLinkConnected: Signal.Signal<TransferLinkObject>,
	TransferLinkDisconnected: Signal.Signal<TransferLinkObject>,
	
	GetSizeScale: () -> Vector2,
	GetAbsoluteSizeFromItemSize: (itemSize: Vector2) -> Vector2,
	GetItemManagerPositionFromAbsolutePosition: (absolutePosition: Vector2, itemSize: Vector2) -> Vector2,
	
	IsColliding: (item: ItemObject, ignoredItems: { ItemObject }, at: Vector2?) -> boolean,
	
	RemoveItem: (item: ItemObject) -> nil,
	
	ConnectTransferLink: (transferLink: TransferLinkObject) -> nil,
	DisconnectTransferLink: (transferLink: TransferLinkObject) -> nil,
	
	CreateHighlight: (priority: number, position: Vector2, size: Vector2, color: Color3) -> HighlightObject,
	AddHighlight: (priority: number, highlight: HighlightObject) -> nil,
	
	Destroy: () -> nil,
	
	Metadata: { any },
}

-- Grid
export type GridProperties = ItemManagerProperties & {
	Assets: {
		Slot: GuiObject,
	}?,
	
	Visible: boolean?,
	
	GridSize: Vector2,
	SlotAspectRatio: number?,
	
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
	
	Metadata: { any }?,
}
export type GridObject = ItemManagerObject & {
	GuiElement: GuiObject,
	SlotElements: { GuiObject },

	GridSize: Vector2,
	SlotAspectRatio: number?,

	Items: { ItemObject },
	ItemAdded: Signal.Signal<ItemObject>,
	ItemRemoved: Signal.Signal<ItemObject>,
	
	GetNextFreePositionForItem: (item: ItemObject) -> Vector2?,
	GetItemsInRegion: (position: Vector2, size: Vector2, ignoredItems: { ItemObject }) -> { ItemObject },
	
	IsRegionInBounds: (position: Vector2, size: Vector2) -> boolean,
	
	SortItemsByVolume: () -> nil,
	
	AddItem: (item: ItemObject) -> nil,
}

-- SingleSlot
export type SingleSlotProperties = ItemManagerProperties & {
	Assets: {
		Slot: GuiObject,
	}?,
	
	Visible: boolean?,
	
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
	
	Metadata: { any }?,
}
export type SingleSlotObject = ItemManagerObject & {
	GuiElement: GuiObject,
	
	Item: ItemObject?,
	ItemChanged: Signal.Signal<ItemObject>,
	
	ChangeItem: (item: ItemObject) -> nil,
}

-- TransferLink
export type TransferLinkProperties = {
	ConnectedItemManagers: {}?,
}
export type TransferLinkObject = {
	ConnectedItemManagers: { ItemManagerObject },
	
	AddItemManager: (itemManager: ItemManagerObject) -> nil,
	RemoveItemManager: (itemManager: ItemManagerObject) -> nil,
	
	GetItemOverlappingItemManagers: (item: ItemObject) -> { ItemManagerObject },
	GetClosestItemOverlappingItemManagers: (item: ItemObject) -> { ItemManagerObject },
}

-- Highlight
export type HighlightProperties = {
	Position: Vector2?,
	Size: Vector2?,
	Color: Color3?,
}
export type HighlightObject = {
	Position: Vector2,
	Size: Vector2,
	Color: Color3,

	ItemManager: ItemManagerObject?,
	ItemManagerChanged: Signal.Signal<ItemManagerObject?>,
}

return nil