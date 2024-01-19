local GridPack = require(game:GetService("ReplicatedStorage").Packages.GridPack)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GridPack"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

local grid = GridPack.createGrid({
    Parent = screenGui, -- Parent of the grid container

    Visible = true -- If the grid is visible, changes the containers visible property. Also disables item interaction on all items inside.

    Assets = {
        Slot = nil -- Add your own GuiObject here to customize the slots in the grid.
    }

    GridSize = Vector2.new(8, 15), -- How many slots the grid has on the X and Y axes.
    SlotAspectRatio = 1, -- Aspect ratio of one slot in the grid, helps with different resolutions if you're using scale instead of offset.

    AnchorPoint = Vector2.new(0, 0.5), -- Anchor point of the grid container
    Position = UDim2.new(0, 20, 0.5, 0), -- Position of the grid container
    Size = UDim2.fromScale(0.25, 0.5), -- Size of the grid container
	
    Metadata = {
        -- Here you are free to store any values you want.
    }
})