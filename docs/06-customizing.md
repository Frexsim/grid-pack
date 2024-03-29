# Customizing

## Item Managers
All ItemManagers have a `.Assets.Slot` property where you can put your own custom CanvasGroups, these CanvasGroups can have anything parented to them.

## Items
Like the ItemManagers, the Items also has a `.Assets.Item` property where you also can add your own CanvasGroups. Although all Item assets require a transparent TextButton or ImageButton named `InteractionButton` to be able to detect any mouse inputs.

## Examples
Here are some examples of how the properties will be setup:

### Grid/SingleSlot Asset Property
```lua
local myFirstGrid = GridPack.createGrid({
    Assets = {
        Slot = [[Insert CanvasGroup here]],
    },
})
```

### Item Asset Property
```lua
local myFirstItem = GridPack.createItem({
    Assets = {
        Item = [[Insert CanvasGroup here]],
    },
})
```