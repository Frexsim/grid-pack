# Server Communication
Since GridPack doesn't handle the server-side for you, items come with the `.MoveMiddleware` property which is run before the item actually gets moved on the client.
And you can use this property to validate your item movements by return true or false is the movement is valid.
Item collision is still checked before `.MoveMiddleware` but it's also good to check for collision on the server to prevent cheating or client desync.
Here's and example of how client to server communication would work:

```lua
local item = GridPack.createItem({
    -- Other Item properties

    MoveMiddleware = function(movedItem, newGridPosition, newRotation, lastItemManager, newItemManager)
        --[[
            movedItem: This Item
            newGridPosition: This Item's new position in a Grid. (Doesn't apply with SingleSlots)
            newRotation: This Item's new rotation.
            lastItemManager: The ItemManager that the Item was in before it got moved.
            newItemManager: The new ItemManager the item was moved to. (If there is one)
        ]]

        if newItemManager then
            -- Ask server to validate the Item movement between ItemManagers and return the result to the Item
            return ReplicatedStorage.Remotes.MoveItemAcrossItemManager:InvokeServer()
        else
            -- Ask server to validate the Item movement between positions and return the result to the Item
            return ReplicatedStorage.Remotes.MoveItem:InvokeServer()
        end

        -- If the result if false then the Item will move back to it's last position.
    end,

    Metadata = {
        -- Tip: Here you can any values you need for MoveMiddleware!
    },

    -- Other Item properties
})
```