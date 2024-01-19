-- Continuing from last example.

local transferGrid = GridPack.createGrid({
    Parent = screenGui,

    Visible = true

    GridSize = Vector2.new(8, 15),
    SlotAspectRatio = 1,

    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -20, 0.5, 0),
    Size = UDim2.fromScale(0.25, 0.5),
})

local transferLink = GridPack.createTransferLink({}) -- Create TransferLink
grid:ConnectTransferLink(transferLink) -- Connect TransferLink to our first grid.
transferGrid:ConnectTransferLink(transferLink) -- Connect the TransferLink to our new grid.