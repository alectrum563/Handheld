# Main Menu System Documentation

## Overview

The game now features a complete Main Menu system that controls player spawning and weapon loadout changes. This creates a proper lobby-style FPS experience where players manually spawn into matches and can only change weapons between rounds.

## Key Features

### ✅ Manual Spawning
- Players start in Main Menu, not automatically spawned into the game
- "PLAY" button to spawn into active rounds
- Control when you enter the match

### ✅ Loadout Management
- Change weapons **only in Main Menu**
- Cannot switch weapons during active gameplay
- Press TAB to open inventory while in Main Menu
- Error message if you try to equip during gameplay

### ✅ Death & Respawn Flow
- After death, press **M** to return to Main Menu
- Change your loadout
- Click PLAY to respawn with new weapon

### ✅ Round-Based Flow
- After round ends, all players sent to Main Menu
- Adjust loadouts during intermission
- Spawn into next round when ready

## Player Flow

### 1. **Join Game**
- Assigned to a team automatically
- Sent to Main Menu
- See "Waiting for players..." message

### 2. **Round Starting (Intermission)**
- Main Menu shows "Round starting in X..."
- PLAY button turns **green** and becomes clickable
- Open inventory (TAB) to change weapon
- Click "LOADOUT" button or press TAB

### 3. **In Main Menu Inventory**
- View all owned weapons with stats
- Currently equipped weapon has green "EQUIPPED" badge
- Click "EQUIP" on another weapon to switch
- Changes take effect immediately

### 4. **Spawn Into Game**
- Click green "PLAY" button
- Character spawns at team spawn point
- Equipped weapon given automatically
- Game HUD appears, Main Menu closes

### 5. **During Gameplay**
- Cannot access Main Menu (until death)
- Cannot change weapons
- If you press TAB → Warning: "RETURN TO MAIN MENU TO CHANGE LOADOUT"

### 6. **After Death**
- Character dies
- Press **M** key to return to Main Menu
- Change loadout if desired
- Click PLAY to respawn

### 7. **Round Ends**
- All players forcefully sent to Main Menu
- See round results message
- PLAY button disabled (gray)
- Wait for next round to start

### 8. **Repeat**
- Cycle continues: Intermission → Playing → Round End → Main Menu

## UI Elements

### Main Menu Screen

**Title:**
```
MAIN MENU
Waiting for round to start...
```

**PLAY Button:**
- Gray (disabled): "Waiting" or "RoundEnd" states
- Green (enabled): "Intermission" or "Playing" states
- Spawns player into game when clicked

**LOADOUT (TAB) Button:**
- Always clickable in Main Menu
- Opens inventory to view/change weapons
- Blue colored button

**Instructions:**
```
Press M to return to menu after death
```

### Inventory UI (in Main Menu)

- Displays all owned weapons
- Shows weapon stats (damage, RPM, range, magazine)
- "EQUIPPED" badge on current weapon
- "EQUIP" button on other weapons
- Clicking EQUIP switches weapon immediately

### Game HUD (during gameplay)

- Team display
- Round timer
- Health bar
- Ammo count (Phase 3)
- Crosshair (Phase 3)

## Key Controls

| Key | Action |
|-----|--------|
| **M** | Return to Main Menu (only after death) |
| **TAB** | Open/close Inventory |
| **Mouse Click** | "PLAY" button to spawn, "EQUIP" to change weapon |

## Technical Implementation

### Client-Side: MainMenuUI.lua

**Location:** `StarterPlayer > StarterPlayerScripts > MainMenuUI`

**Key Functions:**

```lua
-- Open main menu
MainMenuUI.Open()

-- Close main menu
MainMenuUI.Close()

-- Update PLAY button availability
MainMenuUI.UpdatePlayButton(canSpawn, message)

-- Spawn player into game
MainMenuUI.SpawnPlayer()

-- Handle round state changes
MainMenuUI.OnRoundStateChanged(roundData)
```

**States:**
- `IsInMenu` - Whether player is currently in Main Menu
- `CanSpawn` - Whether PLAY button is enabled
- `IsDead` - Whether player died (allows M key)

### Server-Side: Bootstrapper.lua

**Handles:**
- `SpawnPlayer` RemoteEvent - Validates and spawns player
- Checks if round is active (Intermission or Playing)
- Calls TeamManager.RespawnPlayer()

### Integration with Inventory

**InventoryUI.lua Modified:**
- Checks if Main Menu is open before allowing weapon equip
- Shows error if player tries to equip during gameplay
- Warning message: "⚠ RETURN TO MAIN MENU TO CHANGE LOADOUT"

### Integration with Rounds

**RoundManager Integration:**
- Broadcasts round state changes via `RoundState` RemoteEvent
- MainMenuUI listens and updates UI accordingly
- States: "Waiting", "Intermission", "Playing", "RoundEnd"

### Death Handling

**TeamManager.OnPlayerDeath:**
- No longer auto-respawns players
- Player must manually return to menu and click PLAY
- Allows time to change loadout

## RemoteEvents Used

| Event | Type | Purpose |
|-------|------|---------|
| `SpawnPlayer` | RemoteEvent | Client requests to spawn into game |
| `RoundState` | RemoteEvent | Server broadcasts round state changes |
| `EquipWeapon` | RemoteEvent | Client requests weapon equip (menu only) |
| `GetInventory` | RemoteFunction | Client requests inventory data |

## Round State Logic

### Waiting State
- **Main Menu:** Open
- **PLAY Button:** Disabled (gray)
- **Message:** "Waiting for players..."

### Intermission State
- **Main Menu:** Open for all players
- **PLAY Button:** Enabled (green)
- **Message:** "Round starting in X..."
- **Players can:** Change loadouts and spawn in

### Playing State
- **Main Menu:** Closed (for alive players)
- **PLAY Button:** Enabled (for dead players who press M)
- **Players can:** Spawn if dead, cannot change loadouts once spawned

### RoundEnd State
- **Main Menu:** Opened forcefully for ALL players
- **PLAY Button:** Disabled (gray)
- **Message:** Round results (e.g., "Red Team wins!")

## Testing the Main Menu

1. **Start game** - Should begin in Main Menu
2. **Wait for intermission** - PLAY button turns green
3. **Click PLAY** - Spawns into game with weapon
4. **Press TAB during game** - Shows warning (cannot equip)
5. **Die** - Character stays dead
6. **Press M** - Returns to Main Menu
7. **Press TAB** - Opens inventory
8. **Equip different weapon** - Should work
9. **Click PLAY** - Spawns with new weapon
10. **Wait for round end** - Forced back to Main Menu

## Benefits of This System

✅ **Prevents mid-game loadout switching** - More strategic, choose wisely
✅ **Creates proper FPS lobby flow** - Like CS:GO, Valorant, etc.
✅ **Encourages loadout experimentation** - Between rounds
✅ **Reduces chaos** - Players spawn when ready
✅ **Future-proof** - Ready for map voting, match settings, etc.
✅ **Better for case opening** - Open cases in menu, equip immediately

## Known Limitations

1. **First spawn:** Players must manually spawn (good for loadout selection)
2. **Spectating:** Dead players don't spectate teammates (future feature)
3. **Late join:** Players joining mid-round can spawn immediately (intended)

## Future Enhancements

- **Map voting** in Main Menu
- **Match stats** display after round
- **Loadout presets** (save favorite loadouts)
- **Spectator mode** while dead
- **Party system** (join with friends)
- **Case opening UI** integrated into Main Menu

---

**Questions about the Main Menu system?** Check MainMenuUI.lua for detailed comments and implementation details.
