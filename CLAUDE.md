# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multiplayer FPS game project for Roblox featuring:
- Team-based combat with automatic team balancing
- 4 game modes: Team Deathmatch, Domination, Search & Destroy, Hardpoint
- 4 maps: Jungle Ruins, Mine, City Square, Virtual Matrix
- 3 pistol weapons with different stats (damage, fire rate, range)
- Custom movement system (walk, run, sprint, wall-jump)
- Server-authoritative hit detection with headshot multipliers and damage falloff

**Important:** All game content exists within the binary `FirstGame.rbxl` file. The `src/` directory contains reference Lua scripts that must be manually copied into Roblox Studio.

## Repository Structure

- `FirstGame.rbxl` - Binary Roblox Studio place file containing the entire game
- `FirstGame.rbxl.lock` - Lock file created by Roblox Studio when the place is open
- `src/` - Reference Lua scripts organized by their location in Roblox Studio
  - `ServerScriptService/` - Server-side scripts
  - `ReplicatedStorage/Modules/` - Shared modules
  - `StarterPlayer/StarterPlayerScripts/` - Client scripts
- `SETUP_INSTRUCTIONS.md` - Detailed instructions for setting up the game in Roblox Studio
- Implementation plan: `~/.claude/plans/rippling-zooming-teapot.md`

## Architecture Overview

### Client-Server Model
- **Server-authoritative:** All critical gameplay (damage, scores, win conditions) calculated on server
- **Client prediction:** Movement and shooting provide instant visual feedback
- **Server validation:** All actions verified server-side to prevent exploits

### Core Systems

1. **TeamManager** (ServerScriptService/Core/TeamManager.lua)
   - Auto-balances teams when players join
   - Handles respawning (instant for most modes, none for Search & Destroy)
   - Manages player loadouts and stats
   - Equips weapons to players

2. **RoundManager** (ServerScriptService/Core/RoundManager.lua)
   - State machine: Waiting → Intermission → Playing → RoundEnd
   - 10-minute round timer with early end if objective achieved
   - Delegates win condition checks to current game mode

3. **InventoryManager** (ServerScriptService/Core/InventoryManager.lua)
   - Persistent weapon inventory using DataStore
   - All players start with 3 pistols in their inventory
   - Each weapon instance has unique ID and skin support
   - Functions: LoadInventory, SaveInventory, EquipWeapon, AddWeapon, RemoveWeapon
   - Ready for future case opening/skin system

4. **Game Mode Framework** (ServerScriptService/GameModes/)
   - BaseGameMode provides interface for all modes
   - Each mode implements: Initialize, OnPlayerSpawn, OnPlayerKilled, CheckWinCondition, Cleanup
   - Currently implemented: (Phase 4 will add these)

5. **Weapon System**
   - Inventory-based loadout system (press TAB to open)
   - Three starter pistols with different damage/fire rate/range profiles
   - Headshot multiplier: 2x damage
   - Damage falloff over distance
   - Server validates all shots
   - Weapons stored with unique IDs and skin data

6. **Movement System** (Phase 2 - not yet implemented)
   - Custom character controller
   - Walk (16 studs/s), Run (24 studs/s), Sprint (32 studs/s)
   - Wall-jump mechanic when sprinting near walls

### Key Configuration Files

- **GameConfig.lua** - All game constants (round time, speeds, team names)
- **WeaponStats.lua** - Weapon configurations and damage calculation
- **Utilities.lua** - Helper functions (get player from part, format time, etc.)

## Development Workflow

Since this project uses Roblox Studio without external tooling:

1. **Open** `FirstGame.rbxl` in Roblox Studio
2. **Edit** scripts by copying code from `src/` directory into Studio
3. **Test** with F5 (local) or F7 (server simulation)
4. **Save** with Ctrl+S to persist changes to .rbxl file

### Testing Multiplayer
- In Roblox Studio: Test tab → Clients and Servers → Start
- Select 2+ players to test team balancing and multiplayer features
- Use Output window (View → Output) to see debug messages

## Development Status

### ✅ Phase 1 Complete (Foundation)
- Team system with auto-balancing
- Round management with states and timer
- Weapon loadout selection
- Basic HUD showing team, timer, health
- Weapon selection UI

### 🔄 Next: Phase 2 (Movement System)
Implement custom character controller with:
- Walk/Run/Sprint mechanics
- Wall-jump detection
- First-person camera

### 📋 Remaining Phases
- Phase 3: Weapon shooting mechanics with hit detection
- Phase 4: Game mode framework + Team Deathmatch
- Phase 5: Domination, Search & Destroy, Hardpoint modes
- Phase 6: Build 4 maps
- Phase 7: Polish, effects, playtesting

## Development Workflow (Using Rojo)

**Start Rojo Server:**
```bash
cd C:\Users\nikol\Projects\Roblox
rojo serve
```

**Open in Roblox Studio:**
```bash
start FirstGame.rbxl
```

**Connect Rojo:**
1. Open Roblox Studio
2. Click Rojo plugin button
3. Click "Connect"
4. Status turns green → Connected!

**Make Changes:**
1. Edit files in `src/` folder
2. Save (Ctrl+S)
3. Changes appear in Studio instantly! ✨

**Test with multiple players:**
- F5: Local playtest
- F7: Server simulation
- Test tab → Clients and Servers: Multiplayer test

## Important Notes for Future Development

1. **Modifying Scripts:** Edit files in `src/` folder - Rojo syncs them to Studio automatically
2. **Remote Events:** Located in ReplicatedStorage > Remotes
   - RoundState (RemoteEvent): Round state updates
   - WeaponFired (RemoteEvent): Client notifies server of shots
   - DamagePlayer (RemoteEvent): Server tells client to show damage
   - EquipWeapon (RemoteEvent): Client requests weapon equip
   - GetInventory (RemoteFunction): Client requests inventory data
3. **Spawn Points:** Must exist in Workspace > SpawnLocations > Team1Spawns and Team2Spawns
4. **Weapon Tools:** Placeholder tools in ReplicatedStorage > Weapons (will be enhanced in Phase 3)
5. **Configuration:** Modify GameConfig.lua for round time, speeds, team settings
6. **Inventory System:**
   - Inventories saved to DataStore automatically
   - Use InventoryManager.AddWeapon(player, weaponName, skinId) to add weapons (for future case openings)
   - Each weapon instance has unique ID stored in weapon.WeaponData.WeaponId
   - Skins stored in weapon.WeaponData.SkinId (currently all "default")
7. **UI Controls:**
   - TAB key opens/closes inventory
   - Inventory UI shows all owned weapons with stats
   - Green highlight indicates equipped weapon

## Debugging Tips

- Check Output window for errors and debug prints
- Each system logs with tags: `[TeamManager]`, `[RoundManager]`, `[UIController]`, `[Server]`
- Common issues:
  - "Infinite yield" = missing folders or RemoteEvents
  - Players not spawning = check spawn points exist and are positioned correctly
  - Scripts not running = verify they're in correct location and type (Script vs ModuleScript vs LocalScript)
