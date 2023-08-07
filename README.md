# AutoCraft - Minecraft Automation Bot
AutoCraft is a Minecraft bot that can be used to automate tasks in Minecraft. It is written in Lua using the [Advanced Macros](https://www.curseforge.com/minecraft/mc-mods/advanced-macros) mod for Minecraft 1.15.2.

## How it works
AutoCraft uses a GOAP (Goal Oriented Action Planning) algorithm and a pathfinding algorithm as the core of the bot. The GOAP algorithm is used to determine how to achieve a goal, either by crafting an item or by using a pre-defined macro to obtain the item. The pathfinding algorithm is used to walk and explore the world. The bot is controlled using a command system that can be accessed from in-game.

## Installation
1. Install [Advanced Macros](https://www.curseforge.com/minecraft/mc-mods/advanced-macros) mod for Minecraft 1.15.2.
2. Clone this repository into the `macros` folder of Advanced Macros.
3. In-game, configure the scripts in the listening events:
    - `chat.lua` event: `ChatFilter` Required to execute commands.
    - `main.lua` event: `JoinWorld` Only needed when the bot works completely autonomously without using commands or external applications.
    - `event_chat.lua` event: `ChatFilter` Only needed when using external applications, to send chat events to a list in the bot state.
    - `event_anything.lua` event: `Anything` Only needed when using external applications, to send events to a list in the bot state.
    - `loop.lua` event: `JoinWorld` Only needed when using external applications, to listen for commands from a list in the bot state.
4. If you want to use external applications, your application needs to acess the `macros\state.json` file to get the bot state, the events queue, and the commands queue. The `state.json` file is updated automatically by the bot.

## Features
- **Pathfinding:** Walk to any location, swimming, breaking blocks, and placing blocks as needed.
- **Crafting:** Craft any item that has a recipe or has a mapped method to obtain it.
- **Smelting:** Smelt items.
- **Mining:** Mine ores and other blocks.
- **Chopping:** Chop trees.
- **Command:** Command system to control the bot from in-game.

## Commands
The prefix for all commands is `!`.
- **!help:** List all commands.
- **!follow:** Follow continuously a entity in the world (player or mob).
- **!goto:** Go to a location in the world or to a entity (player or mob).
- **!say:** Say something in the chat.
- **!craft:** Craft/Get an item (if the item has a recipe or a method to obtain it).
- **!drop:** Drop an item from the inventory.
- **!give:** Give an item to an entity (player or mob) in the world (same as -> !craft -> !goto -> !drop).
- **!stop:** Stop all commands.
- **!test:** Test the bot with a test script (useful to debug and generate data for analysis).


## GOAP
The GOAP algorithm is used to go through a recipe and determine how to obtain the items needed to craft the recipe. The algorithm works by creating a tree of actions that can be performed to obtain the items needed to craft the recipe. Because the random nature of Minecraft, the algorithm needs to be able to dinamically calculate the tree of recipes, being tolerable to errors and changes in the environment. The algorithm is also able to use pre-defined macros to obtain items, such as mining ores or chopping trees.

## Pathfinding
The pathfinding algorithm is used to walk and explore the world. The algorithm is based on the A* algorithm, but with some modifications to make it work in Minecraft. The algorithm is able to break and place blocks, and swim. The algorithm is also able to avoid lava and water, and to avoid falling from high places.

### Configuration
The pathfinding algorithm can be dynamically configured using the `pathFinderConfig` argument in the `Walk.walkTo` function.

- **maxJump:** Maximum height that the bot can jump. Default: 1 block
- **maxFall:** Maximum height that the bot can fall. Default: 5 blocks
- **pathFinderTimeout:** Maximum time in seconds that the pathfinding algorithm can take to find a path. Default: 10 seconds
- **reverse:** If the bot needs to leave an area, it will reverse the pathfinding algorithm to find a path to the exit. Default: false
- **weightMask:** Weight for each alteration that the bot does to the world, like breaking blocks and placing blocks. Default: 1
- **canPlace:** If the bot can place blocks. Default: true
- **canBreak:** If the bot can break blocks. Default: true

### Blocks to place
The pathfinding algorithm can place the blocks listed in the `Walk.placeableBlocks` table.

- **Dirt**
- **Cobblestone**
- **Planks**

## Scripts
The scripts are triggered by the mod Advanced Macros.
- **block_info.lua:** Get information about the block that the bot is looking at (useful to debug).
- **chat.lua:** Listen for execute commands (commands only work if this script is running in the `ChatFilter` event from Advanced Macros).
- **entity.lua:** List all entities in the world (useful to debug).
- **event_anything.lua:** Listen for any event and send it to external event queue.
- **event_chat.lua:** Listen for chat messages, execute commands, and send messages to external event queue.
- **loop.lua:** Listen for polling commands from external command queue.
- **main.lua:** Main script that is executed when the bot enters the world.
- **stop.lua:** Force stop all scripts and commands.

If you don't want to use external applications, you don't need to use the `event_anything.lua`, `event_chat.lua`, and `loop.lua` scripts.

## External applications
The bot can be controlled by external applications. The bot has a state that is stored in the `macros\state.json` file. The state contains basic information about the bot, the events queue, and the commands queue.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

