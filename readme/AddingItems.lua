-- Continuing from last example.

local item = GridPack.createItem({
    Position = Vector2.new(0, 0), -- Position in a grid.
	Size = Vector.new(2, 3), -- Size in a grid.

	Assets = {
		Item = nil, -- Add a custom GuiObject here to change the item's gui element.
	},
	
	Metadata = {
        -- Here you are free to store any values you want.
    },
})

grid:AddItem(item) -- Add the item to the grid.