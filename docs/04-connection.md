# Connecting ItemManagers

To connect two item managers together you use a TransferLink. Both Grids and SingleSlots can be connected to eachother and Grid to SingleSlot.
This is done like:

```lua
-- Continuing from last example.

local transferGrid = GridPack.createGrid({
    Parent = screenGui,

    Visible = true,

    GridSize = Vector2.new(8, 15),
    SlotAspectRatio = 1,

    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -20, 0.5, 0),
    Size = UDim2.fromScale(0.25, 0.5),
})

local transferLink = GridPack.createTransferLink({}) -- Create TransferLink
myFirstGrid:ConnectTransferLink(transferLink) -- Connect TransferLink to our first grid.
transferGrid:ConnectTransferLink(transferLink) -- Connect the TransferLink to our new grid.
```

You will now be able to drag an item over to the other inventory and it should adjust to the new inventory.

![](/ItemTransfer.gif)
