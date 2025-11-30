# FPS Game - Setup Instructions

This guide will walk you through setting up the Roblox FPS game in Roblox Studio.

## Phase 1: Foundation Setup

### Step 1: Open Your Game in Roblox Studio

1. Open Roblox Studio
2. Open `FirstGame.rbxl`

### Step 2: Create Folder Structure

Create the following folder structure in your game:

#### In ReplicatedStorage:
1. Create a **Folder** named `Modules`
2. Create a **Folder** named `Weapons`
3. Create a **Folder** named `Remotes`

#### In ServerScriptService:
1. Create a **Folder** named `Core`
2. Create a **Folder** named `GameModes`

#### In Workspace:
1. Create a **Folder** named `SpawnLocations`
2. Inside SpawnLocations, create two **Folders**: `Team1Spawns` and `Team2Spawns`

#### In ServerStorage:
1. Create a **Folder** named `MapTemplates`

### Step 3: Create RemoteEvents and RemoteFunctions

In `ReplicatedStorage > Remotes`, create the following:

**RemoteEvents:**
1. **RemoteEvent** named `RoundState`
2. **RemoteEvent** named `WeaponFired`
3. **RemoteEvent** named `DamagePlayer`
4. **RemoteEvent** named `EquipWeapon`
5. **RemoteEvent** named `SpawnPlayer`

**RemoteFunctions:**
6. **RemoteFunction** named `GetInventory`
7. **RemoteFunction** named `GetEconomy`

To create:
- RemoteEvent: Right-click Remotes folder → Insert Object → RemoteEvent → Rename
- RemoteFunction: Right-click Remotes folder → Insert Object → RemoteFunction → Rename

### Step 4: Copy Server Scripts

Copy the Lua code from the `src/` folder into Roblox Studio:

#### ServerScriptService:
1. Create a **Script** named `Bootstrapper` in ServerScriptService
   - Copy code from `src/ServerScriptService/Bootstrapper.lua`

#### ServerScriptService > Core:
1. Create a **ModuleScript** named `TeamManager` in ServerScriptService/Core
   - Copy code from `src/ServerScriptService/Core/TeamManager.lua`

2. Create a **ModuleScript** named `RoundManager` in ServerScriptService/Core
   - Copy code from `src/ServerScriptService/Core/RoundManager.lua`

3. Create a **ModuleScript** named `InventoryManager` in ServerScriptService/Core
   - Copy code from `src/ServerScriptService/Core/InventoryManager.lua`

4. Create a **ModuleScript** named `EconomyManager` in ServerScriptService/Core
   - Copy code from `src/ServerScriptService/Core/EconomyManager.lua`

#### ReplicatedStorage > Modules:
1. Create a **ModuleScript** named `GameConfig`
   - Copy code from `src/ReplicatedStorage/Modules/GameConfig.lua`

2. Create a **ModuleScript** named `WeaponStats`
   - Copy code from `src/ReplicatedStorage/Modules/WeaponStats.lua`

3. Create a **ModuleScript** named `Utilities`
   - Copy code from `src/ReplicatedStorage/Modules/Utilities.lua`

#### StarterPlayer > StarterPlayerScripts:
1. Create a **LocalScript** named `UIController`
   - Copy code from `src/StarterPlayer/StarterPlayerScripts/UIController.lua`

2. Create a **LocalScript** named `InventoryUI`
   - Copy code from `src/StarterPlayer/StarterPlayerScripts/InventoryUI.lua`

3. Create a **LocalScript** named `MainMenuUI`
   - Copy code from `src/StarterPlayer/StarterPlayerScripts/MainMenuUI.lua`

### Step 5: Create Spawn Points

You need to create spawn points for each team:

#### Team 1 Spawns:
1. In Workspace, insert a **Part**
2. Move it to `Workspace > SpawnLocations > Team1Spawns`
3. Rename it to `Spawn1`
4. Position it where you want Team 1 to spawn (e.g., X: -50, Y: 5, Z: 0)
5. Create 2-3 more spawn parts for Team 1

#### Team 2 Spawns:
1. In Workspace, insert a **Part**
2. Move it to `Workspace > SpawnLocations > Team2Spawns`
3. Rename it to `Spawn1`
4. Position it where you want Team 2 to spawn (e.g., X: 50, Y: 5, Z: 0)
5. Create 2-3 more spawn parts for Team 2

**Tip:** Make the spawn parts semi-transparent and non-collidable:
- Set `Transparency` to 0.8
- Set `CanCollide` to false

### Step 6: Create Placeholder Weapon Tools

For now, we'll create basic weapon tools. We'll add proper models later.

In `ReplicatedStorage > Weapons`:

1. Create a **Tool** named `FastPistol`
   - Set `RequiresHandle` to false

2. Create a **Tool** named `BalancedPistol`
   - Set `RequiresHandle` to false

3. Create a **Tool** named `SlowPistol`
   - Set `RequiresHandle` to false

**Note:** These are placeholder tools. We'll add proper weapon models and functionality in Phase 3.

### Step 7: Create Teams

The TeamManager will create teams automatically, but you can also create them manually:

1. In the Explorer, find the **Teams** service
2. If Teams service doesn't exist, insert it (Insert Object → Teams)

Teams will be created automatically by the TeamManager when the game starts.

### Step 8: Test the Basic Foundation

1. Click the **Play** button (F5) in Roblox Studio
2. Select **2 Players** or more from the test options
3. Observe the Output window for debug messages

**Expected Behavior:**
- Server starts and initializes TeamManager, RoundManager, InventoryManager, and EconomyManager
- Players are automatically assigned to teams (balanced)
- Players receive 3 starter pistols in their inventory
- Players start with 0 Shards and 0 Score
- **Players start in Main Menu** (not spawned in-game)
- Main Menu shows "Waiting for players..." or "Round starting in X..."
- **During Intermission/Playing:** "PLAY" button becomes available (green)
- **Click PLAY to spawn** into the game with equipped weapon
- **HUD displays:** Team, Timer, Shards (💎), Score (⭐), Health
- **Press TAB** to open inventory and view weapons
- **Weapon equipping only works in Main Menu** (not during gameplay)
- **After death:** Press **M** to return to Main Menu and change loadout
- **After round ends:** All players sent back to Main Menu
- **Kills award Score and Shards** (visible in Output for now, Phase 3 will add notifications)
- Round state changes: Waiting → Intermission → Playing → RoundEnd → repeat

**Troubleshooting:**
- Check the Output window for errors (View → Output)
- Ensure all scripts are in the correct locations
- Verify that RemoteEvents are created in ReplicatedStorage > Remotes
- Make sure spawn points exist in Workspace > SpawnLocations

## Next Steps

Once Phase 1 is working:
- **Phase 2:** Implement custom movement system (walk, run, sprint, wall jump)
- **Phase 3:** Implement weapon shooting mechanics
- **Phase 4:** Add game modes
- **Phase 5-7:** Maps, polish, and testing

## Common Issues

### "DataStore not available" warnings (EXPECTED IN STUDIO)
**This is NORMAL and expected behavior when testing in Studio!**

You will see warnings like:
```
[InventoryManager] DataStore not available (Studio testing mode) - using in-memory storage only
[EconomyManager] DataStore not available (Studio testing mode) - using in-memory storage only
```

**What this means:**
- DataStore requires your game to be published to Roblox to work in Studio
- The game will work perfectly fine in Studio testing mode
- Inventories and economy data will be stored in memory during the test
- Data will reset when you stop the test (this is expected)

**To enable DataStore persistence:**
1. **File** → **Publish to Roblox**
2. Create a new game or update existing
3. In **Game Settings** → **Security** → Enable **Studio Access to API Services**
4. Now DataStore will work in Studio and persist data

**For now, you can safely ignore these warnings and continue testing!**

### "Infinite yield possible" warnings
- This means a script is waiting for a child that doesn't exist
- Double-check that all folders, scripts, and RemoteEvents are created with the correct names

### Players not spawning
- Check that spawn points exist in `Workspace > SpawnLocations > Team1Spawns` and `Team2Spawns`
- Ensure spawn parts are positioned above the ground (Y > 0)

### Scripts not running
- Make sure scripts in ServerScriptService are **Script** objects (not LocalScript)
- Ensure ModuleScripts are **ModuleScript** objects
- Check for syntax errors in the Output window

## File Structure Reference

```
ReplicatedStorage/
├── Modules/
│   ├── GameConfig (ModuleScript)
│   ├── WeaponStats (ModuleScript)
│   └── Utilities (ModuleScript)
├── Weapons/
│   ├── FastPistol (Tool)
│   ├── BalancedPistol (Tool)
│   └── SlowPistol (Tool)
└── Remotes/
    ├── RoundState (RemoteEvent)
    ├── WeaponFired (RemoteEvent)
    ├── DamagePlayer (RemoteEvent)
    ├── EquipWeapon (RemoteEvent)
    ├── SpawnPlayer (RemoteEvent)
    └── GetInventory (RemoteFunction)

ServerScriptService/
├── Bootstrapper (Script)
├── Core/
│   ├── TeamManager (ModuleScript)
│   ├── RoundManager (ModuleScript)
│   ├── InventoryManager (ModuleScript)
│   └── EconomyManager (ModuleScript)
└── GameModes/ (empty for now)

StarterPlayer/
└── StarterPlayerScripts/
    ├── UIController (LocalScript)
    ├── InventoryUI (LocalScript)
    └── MainMenuUI (LocalScript)

Workspace/
└── SpawnLocations/
    ├── Team1Spawns/
    │   ├── Spawn1 (Part)
    │   ├── Spawn2 (Part)
    │   └── Spawn3 (Part)
    └── Team2Spawns/
        ├── Spawn1 (Part)
        ├── Spawn2 (Part)
        └── Spawn3 (Part)

ServerStorage/
└── MapTemplates/ (empty for now)

Teams/
(Teams created automatically by TeamManager)
```

## Questions?

If you encounter any issues or have questions, double-check:
1. All scripts are copied exactly as shown
2. Scripts are in the correct locations
3. All RemoteEvents are created
4. Spawn points exist in the correct folders
