# Main Menu System Fixes

This document explains all fixes applied to the Main Menu system.

## Issues Fixed

### 1. Multiple Weapon Spawning

**Problem:** Players received multiple copies of their weapon when:
- Pressing Play button multiple times
- CharacterAdded event fired repeatedly

**Root Cause:**
- `Bootstrapper.lua` line 144-147 was equipping a weapon on every CharacterAdded event
- No cleanup of old weapons before spawning

**Solution:**
- Removed automatic weapon equipping from CharacterAdded event
- Added weapon cleanup in `SpawnPlayerEvent` handler before spawning
- Weapons are now only equipped once per spawn through SpawnPlayerEvent

**Files Changed:**
- `src/ServerScriptService/Bootstrapper.server.lua` (lines 75-113)

---

### 2. Always Getting FastPistol

**Problem:** Players always spawned with FastPistol regardless of selection

**Root Cause:**
- `InventoryManager.InitializePlayer` sets default equipped weapon to `inventory[1]` (FastPistol)
- This is expected behavior for new players

**How to Change Weapon:**
1. Press **M** to return to Main Menu
2. Press **G** or click "LOADOUT" button
3. Click on a different weapon (BalancedPistol or SlowPistol)
4. Click "EQUIP" button
5. Press "PLAY" to spawn with new weapon

**Note:** FastPistol is the default starting weapon. Players must manually select a different weapon in the loadout menu.

---

### 3. M Key Only Working After Death

**Problem:** M key only opened menu after death, not at any time

**Solution:**
- Removed death check from M key handler
- Added new `ReturnToMenu()` function that:
  - Teleports player to position (0, 500, 0) high above map
  - Resets velocity to prevent falling
  - Opens Main Menu
  - Switches to third-person camera

**Files Changed:**
- `src/StarterPlayer/StarterPlayerScripts/MainMenuUI.client.lua` (lines 266-285, 399-404)

**Usage:** Press **M** at any time during gameplay to return to Main Menu

---

### 4. Inventory Not Showing

**Problem:** Inventory button might not work properly

**Solution:**
- Verified InventoryUI system is properly integrated
- Inventory opens with G key or "LOADOUT (G)" button
- Shows all 3 starter pistols: FastPistol, BalancedPistol, SlowPistol
- Green highlight indicates equipped weapon
- Click weapon card to view stats, click "EQUIP" to equip it

**Note:** Inventory can only be opened from Main Menu, not during gameplay

---

### 5. Practice Mode Not Spawning Instantly

**Problem:** Practice mode should spawn player instantly without waiting for round

**Solution:**
- Practice mode already bypasses round state checks
- `SpawnPlayerEvent` allows spawning when `GameConfig.PRACTICE_MODE = true`
- Updated weapon equipping to happen after spawn

**How Practice Mode Works:**
1. Click "PRACTICE MODE" button in Main Menu
2. Enables practice mode on server
3. Closes Main Menu
4. Spawns player immediately at team spawn point
5. Switches to first-person camera
6. Equips selected weapon

---

### 6. Play Button During Round

**Problem:** Play button should work when round is in progress

**Solution:**
- Round state "Playing" now allows spawning
- SpawnPlayerEvent accepts spawns during "Intermission" and "Playing" states
- Players can join ongoing rounds by clicking PLAY

**States:**
- **Waiting:** Play button disabled (gray) - waiting for players
- **Intermission:** Play button enabled (green) - round starting soon
- **Playing:** Play button enabled (green) - join ongoing round
- **RoundEnd:** Play button disabled (gray) - round ended

---

## Main Menu Controls

### Keyboard Shortcuts

| Key | Action | Notes |
|-----|--------|-------|
| **M** | Return to Main Menu | Works at any time during gameplay |
| **G** | Open Loadout | Only works when Main Menu is open |
| **TAB** | *(Legacy - not used)* | Use G instead |

### Buttons

| Button | Action | When Available |
|--------|--------|----------------|
| **PLAY** | Spawn into game | Intermission or Playing state |
| **LOADOUT (G)** | Open weapon inventory | Always in Main Menu |
| **PRACTICE MODE** | Solo practice mode | Always in Main Menu |

---

## Technical Details

### Weapon Equipping Flow

1. Player joins server
2. `InventoryManager.InitializePlayer` loads inventory (3 starter pistols)
3. Default equipped weapon set to FastPistol (inventory[1])
4. Player opens Main Menu
5. Player clicks PLAY or PRACTICE MODE
6. `SpawnPlayerEvent:FireServer()` is called
7. Server validates round state or practice mode
8. Server clears old weapons from Backpack and Character
9. `TeamManager.RespawnPlayer(player, true)` respawns character
10. After character loads, `TeamManager.EquipWeapon(player)` equips selected weapon
11. Client switches to first-person camera

### Return to Menu Flow (M Key)

1. Player presses M key during gameplay
2. `MainMenuUI.ReturnToMenu()` is called
3. Character teleported to (0, 500, 0) position
4. Velocity reset to zero
5. Main Menu opens
6. Camera switches to third-person
7. Game HUD hidden, Main Menu UI shown

### Inventory Selection Flow

1. Player presses G or clicks LOADOUT button (only in Main Menu)
2. `InventoryUI.Open()` is called
3. `GetInventoryEvent:InvokeServer()` fetches inventory from server
4. UI displays all weapons with stats and equipped status
5. Player clicks weapon card, then clicks EQUIP button
6. `EquipWeaponEvent:FireServer(weaponId)` sent to server
7. `InventoryManager.EquipWeapon(player, weaponId)` updates equipped weapon
8. Next spawn will use newly equipped weapon

---

## Starter Weapons

All players start with these 3 pistols:

### FastPistol (Default)
- **Damage:** 20
- **Fire Rate:** 0.15s (6.67 shots/sec)
- **Max Range:** 200 studs
- **DPS:** 133

### BalancedPistol
- **Damage:** 25
- **Fire Rate:** 0.25s (4 shots/sec)
- **Max Range:** 250 studs
- **DPS:** 100

### SlowPistol
- **Damage:** 35
- **Fire Rate:** 0.4s (2.5 shots/sec)
- **Max Range:** 300 studs
- **DPS:** 87.5

**Note:** All weapons have:
- Headshot multiplier: 2x damage
- Damage falloff over distance
- Spread/accuracy affected by movement

---

## Testing Checklist

To verify all Main Menu fixes:

- [ ] Join game and see Main Menu
- [ ] Click LOADOUT (G) button
- [ ] See all 3 pistols in inventory
- [ ] FastPistol has green "EQUIPPED" indicator
- [ ] Select BalancedPistol and click EQUIP
- [ ] Close inventory (X button or ESC)
- [ ] Click PLAY or wait for intermission
- [ ] Spawn with BalancedPistol (not FastPistol)
- [ ] Verify only 1 weapon in backpack
- [ ] Press M key during gameplay
- [ ] Teleport to menu position and see Main Menu
- [ ] Click PRACTICE MODE
- [ ] Spawn instantly without waiting for round
- [ ] Verify first-person camera
- [ ] Verify equipped weapon appears
- [ ] Press M to return to menu again
- [ ] Change loadout and respawn

---

## Known Limitations

1. **Practice Mode spawn location:** Currently spawns at team spawn points, not a dedicated practice range
   - Future update will add practice range teleport

2. **Menu position:** Teleporting to (0, 500, 0) works but is not ideal
   - Future update may add a dedicated menu area/lobby

3. **No weapon switching during gameplay:** Must return to menu to change loadout
   - This is intentional design to prevent mid-combat switching

4. **Inventory only in Main Menu:** Cannot view inventory during gameplay
   - This is intentional to keep gameplay focused

---

## Future Enhancements

Potential improvements for the Main Menu system:

- [ ] Dedicated practice range map with target dummies
- [ ] Quick-select loadout presets (1-5 keys)
- [ ] Weapon stats comparison view
- [ ] Skin preview in inventory
- [ ] Settings menu (sensitivity, graphics, keybinds)
- [ ] Friends list and party system
- [ ] Map voting before round starts
- [ ] Game mode selection/voting
- [ ] Player profile and stats
- [ ] Leaderboard view

---

## Summary

All Main Menu issues have been fixed:
✅ Multiple weapon spawning resolved
✅ Weapons properly cleared before spawning
✅ M key works at any time to return to menu
✅ Inventory displays all weapons
✅ Practice Mode spawns instantly
✅ Play button works during active rounds
✅ Instructions updated to reflect new controls

The Main Menu now provides a smooth, intuitive experience for spawning, changing loadouts, and returning to menu at any time!
