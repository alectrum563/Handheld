# Roblox Multiplayer FPS Game

A team-based multiplayer first-person shooter built in Roblox with custom movement mechanics, multiple game modes, and competitive gameplay.

## 🎮 Game Features

- **Team-Based Combat:** Automatic team balancing keeps matches fair
- **4 Game Modes:** Team Deathmatch, Domination, Search & Destroy, Hardpoint
- **4 Unique Maps:** Jungle Ruins, Mine, City Square, Virtual Matrix
- **3 Pistol Weapons:** Each with unique damage, fire rate, and range characteristics
- **Advanced Movement:** Walk, run, sprint, and wall-jump mechanics
- **Realistic Combat:** Headshot multipliers, damage falloff, server-authoritative hit detection

## 📊 Current Status

### ✅ Phase 1 Complete - Foundation
The core multiplayer infrastructure is ready:
- ✅ Team system with auto-balancing
- ✅ Round management (Waiting → Intermission → Playing → RoundEnd)
- ✅ **Main Menu system with manual spawning**
- ✅ **Inventory system with persistent storage (DataStore)**
- ✅ **All players start with 3 pistols in their inventory**
- ✅ **Inventory UI to view and equip weapons (Press TAB)**
- ✅ **Weapon equipping restricted to Main Menu only**
- ✅ **Press M after death to return to Main Menu**
- ✅ **Ready for future skin/case opening system**
- ✅ Basic HUD (team display, round timer, health bar)

### 🚀 Quick Start

1. **Open the game:**
   ```bash
   start FirstGame.rbxl
   ```

2. **Follow setup instructions:**
   - See `SETUP_INSTRUCTIONS.md` for detailed steps
   - Copy scripts from `src/` into Roblox Studio
   - Create required folder structure and RemoteEvents

3. **Test multiplayer:**
   - In Studio: Test tab → Clients and Servers
   - Select 2+ players
   - Observe team balancing and round cycling

## 📁 Project Structure

```
C:\Users\nikol\Projects\Roblox\
├── FirstGame.rbxl              # Main Roblox Studio file
├── src/                        # Reference Lua scripts
│   ├── ServerScriptService/
│   │   ├── Bootstrapper.lua
│   │   └── Core/
│   │       ├── TeamManager.lua
│   │       └── RoundManager.lua
│   ├── ReplicatedStorage/
│   │   └── Modules/
│   │       ├── GameConfig.lua
│   │       ├── WeaponStats.lua
│   │       └── Utilities.lua
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           └── UIController.lua
├── SETUP_INSTRUCTIONS.md       # Detailed setup guide
├── CLAUDE.md                   # AI assistant reference
└── README.md                   # This file
```

## 🎯 Weapon Stats

| Weapon | Damage | Fire Rate | Range | TTK (Time to Kill) |
|--------|--------|-----------|-------|-------------------|
| **Rapid Fire** | 20 (40 headshot) | 10/sec | 80 studs | ~0.5s (5 shots) |
| **Standard Issue** | 35 (70 headshot) | 4/sec | 120 studs | ~0.5s (3 shots) |
| **Hand Cannon** | 50 (100 headshot) | 2/sec | 150 studs | ~0.5s (2 shots, 1 headshot) |

*All weapons have 2x headshot multiplier and damage falloff at range*

## 🎮 Gameplay Mechanics

### Movement
- **Walk:** 16 studs/second (WASD)
- **Run:** 24 studs/second (Shift + WASD)
- **Sprint:** 32 studs/second (Shift + W)
- **Wall Jump:** Extra height when jumping near walls while sprinting

### Combat
- **100 HP per player**
- **Headshot bonus:** 2x damage
- **Damage falloff:** Weapons deal less damage at range
- **Instant respawn** (except in Search & Destroy mode)

### Inventory System
- **Persistent storage:** Inventory saved between play sessions using DataStore
- **Starter weapons:** All players start with 3 pistols (Rapid Fire, Standard Issue, Hand Cannon)
- **Equip from inventory:** Press **TAB** to open inventory and switch weapons
- **Unique weapon instances:** Each weapon has a unique ID (ready for skins)
- **Skin support:** Infrastructure in place for future skin/case system
- **Add weapons:** InventoryManager.AddWeapon() function ready for case openings

### Main Menu & Spawning
- **Start in Main Menu:** Players begin in a menu lobby, not spawned into the game
- **Manual spawning:** Click "PLAY" button to spawn into the match
- **PLAY button:** Only enabled during Intermission or while a round is active
- **Change loadout:** Open inventory (TAB) and equip weapons in Main Menu
- **After death:** Press **M** to return to Main Menu and change loadout
- **After round ends:** All players sent back to Main Menu automatically
- **Restriction:** Cannot change weapons during active gameplay (only in Main Menu)

### Round Structure
- **10-minute time limit**
- **Auto-balance teams** when players join
- **Early end** if objective is achieved
- States: Waiting → Intermission (15s) → Playing (10min) → Round End → Main Menu

## 🛠️ Next Steps (Phases 2-7)

### Phase 2: Movement System
- [ ] Custom character controller
- [ ] Implement walk/run/sprint mechanics
- [ ] Add wall-jump detection
- [ ] Create first-person camera

### Phase 3: Weapon System
- [ ] Weapon Tool models and animations
- [ ] Client-side shooting with visual feedback
- [ ] Server-side hit detection with headshots
- [ ] Damage calculation with falloff

### Phase 4: Game Modes
- [ ] BaseGameMode framework
- [ ] Team Deathmatch implementation
- [ ] Win condition checking

### Phase 5: Additional Modes
- [ ] Domination (control zones)
- [ ] Search & Destroy (bomb plant/defuse)
- [ ] Hardpoint (rotating control point)

### Phase 6: Maps
- [ ] Build 4 unique maps
- [ ] Add spawn points and objectives
- [ ] Map rotation system

### Phase 7: Polish
- [ ] Enhanced UI and HUD
- [ ] Sound effects and visual effects
- [ ] Playtesting and balancing

## 📚 Documentation

- **Setup Guide:** `SETUP_INSTRUCTIONS.md` - Step-by-step setup in Roblox Studio
- **AI Reference:** `CLAUDE.md` - Architecture and development notes
- **Implementation Plan:** `~/.claude/plans/rippling-zooming-teapot.md` - Detailed technical plan

## 🔧 Development

**Testing:**
- Use Roblox Studio's built-in multiplayer test (F7 or Test → Clients and Servers)
- Check Output window for debug logs
- Each system has tagged logs: `[TeamManager]`, `[RoundManager]`, `[UIController]`

**Modifying Code:**
1. Update scripts in `src/` directory
2. Copy changes into Roblox Studio
3. Test thoroughly
4. Save `FirstGame.rbxl` (Ctrl+S)

## 🐛 Troubleshooting

**Players not spawning?**
- Check that spawn points exist in `Workspace > SpawnLocations > Team1Spawns` and `Team2Spawns`
- Ensure spawn parts are above ground (Y > 0)

**Scripts not running?**
- Verify scripts are in correct locations
- Check Output window for errors
- Ensure RemoteEvents are created in ReplicatedStorage > Remotes

**"Infinite yield" warnings?**
- Script is waiting for a child that doesn't exist
- Check all folders and RemoteEvents are created with exact names

## 📝 License

This is a personal project for learning game development in Roblox.

---

**Ready to continue development?** Check `SETUP_INSTRUCTIONS.md` to get Phase 1 running, then proceed to Phase 2!
