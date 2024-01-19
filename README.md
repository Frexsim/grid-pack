# GridPack
An easy way to create grid-style inventories on Roblox.

## How to Install
Head to the releases page and download the latest gridpack.rbxm file.
Then insert the downloaded file in Roblox Studio by right clicking on ReplicatedStorage and choosing "Insert from File...".

![InsertFromFile](./readme/InsertFromFile.png)

## Getting Started
Here are some small guides to help you get started!
Start by creating a LocalScript and follow along:

### Creating Your First Grid
To create a grid your first grid item manager you will need to use the `.createGrid()` method in GridPack.
Here is an example:

![FirstGrid](./readme/FirstGrid.lua)

You should now have a grid on your screen once you join the game!

### Adding Items
Adding items to grids is really easy. But before adding you will have to create a new item. This is done in a simmilar way as creating a grid, but instead you use the `.createItem()` method.
Here is an example showing an item being created and added to the grid we just created:

![AddingItems](./readme/AddingItems.lua)

The item should now be added to the grid and should also be draggable!

### Connecting Item Managers
To connect two item managers together you use a TransferLink. Both Grids and SingleSlots can be connected to eachother and Grid to SingleSlot.
This is done like:

![ConnectingItemManagers](./readme/ConnectingItemManagers.lua)

You will now be able to drag an item over to the other inventory and it should adjust to the new inventory.

## Single Slots
With SingleSlots you are able to drag any item into it, disreguarding the size and position of the item. This can be used as an equip slot where you have your primary weapon, tool or armor stored.

The SingleSlot setup is a little different than the Grid setup.
Here is and example:

![SingleSlots](./readme/SingleSlotExample.lua)