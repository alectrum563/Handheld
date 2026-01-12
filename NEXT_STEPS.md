# Next Steps - Weapons and Maps

I've prepared everything you need to start building weapons and maps in Roblox Studio. Here's what to do next!

## What I Just Did

### 1. Code Updates (Already Synced via Rojo!)
- ✅ Created **MapManager** - Handles loading/unloading maps dynamically
- ✅ Updated **RoundManager** - Now loads random maps each round
- ✅ Updated **TeamManager** - Uses MapManager for spawn points
- ✅ Updated **Bootstrapper** - Initializes MapManager on server start

### 2. Created Guides
- ✅ **WEAPON_CREATION_GUIDE.md** - Step-by-step weapon creation
- ✅ **MAP_DESIGN_GUIDE.md** - Detailed specs for all 4 maps

## What You Need to Do in Roblox Studio

### Priority 1: Create Weapons (30 minutes)

Follow **WEAPON_CREATION_GUIDE.md** to create:

1. **Quick Setup** (minimum viable):
   - Create folder: ReplicatedStorage > Weapons
   - Create 3 Tools: FastPistol, BalancedPistol, SlowPistol
   - Each needs: Handle (Part) and WeaponType (StringValue)
   - Test: Press F5, open inventory (TAB), equip weapon

2. **Polish Later** (optional):
   - Add better 3D models (from Toolbox or Blender)
   - Add muzzle flash effects
   - Add shooting sounds

### Priority 2: Build First Map (1-2 hours)

Start with **Jungle Ruins** (easiest):

1. Create structure in Workspace:
   ```
   Workspace > Maps > JungleRuins
   ```

2. Build basic geometry:
   - Use Terrain or Parts for ground (400x400 studs)
   - Add walls, pillars, platforms
   - Create open center area (80x80 studs)
   - Add side corridors and elevated platforms

3. Add spawn points:
   ```
   JungleRuins > SpawnLocations > Team1Spawns (6-8 spawns)
   JungleRuins > SpawnLocations > Team2Spawns (6-8 spawns)
   ```
   - Insert SpawnLocation parts
   - Position on opposite sides of map
   - Set TeamColor to match teams
   - Make invisible (Transparency = 1)

4. Add game mode objects:
   ```
   JungleRuins > GameModeObjects > DominationZones (3-5 zones)
   JungleRuins > GameModeObjects > BombSites (2 sites: A and B)
   JungleRuins > GameModeObjects > HardpointLocations (5-7 spots)
   ```
   - Create Parts for each objective
   - Name them appropriately
   - Position strategically around map
   - See MAP_DESIGN_GUIDE.md for specifications

5. Test:
   - F7 (server simulation with 2+ players)
   - Verify spawns work for both teams
   - Check sightlines and balance
   - Iterate and improve!

### Priority 3: Build Remaining Maps (When Ready)

After Jungle Ruins works well:
- **Mine** - Underground mining facility
- **City Square** - Urban downtown
- **Virtual Matrix** - Futuristic cyberspace

Each follows the same structure as Jungle Ruins.

## How It Works Now

### Map Loading System

1. **Round Start**:
   - MapManager selects random map from GameConfig.AVAILABLE_MAPS
   - Clones map from Workspace > Maps into Workspace > CurrentMap
   - TeamManager uses map's spawn points to respawn players

2. **During Round**:
   - Players spawn at team-specific spawn points
   - Game mode uses map's GameModeObjects for objectives

3. **Round End**:
   - MapManager destroys CurrentMap
   - Next round loads a new random map

### Map Requirements

For maps to work properly, they MUST have this structure:

```
Maps/
└── [MapName]/
    ├── SpawnLocations/
    │   ├── Team1Spawns/
    │   └── Team2Spawns/
    └── GameModeObjects/
        ├── DominationZones/
        ├── BombSites/
        └── HardpointLocations/
```

## Testing Checklist

### After Creating Weapons:
- [ ] Weapons appear in inventory (TAB key)
- [ ] Can equip each weapon
- [ ] Weapons show in hand
- [ ] Can shoot (left click)
- [ ] Damage is correct (check Output for logs)

### After Building First Map:
- [ ] Both teams spawn correctly
- [ ] Spawns are safe (not visible to enemies)
- [ ] Map has good flow (can reach all areas)
- [ ] Cover is abundant
- [ ] All game mode objects are present
- [ ] Performance is good (not laggy)

## Troubleshooting

**Map won't load?**
- Check that map folder is in Workspace > Maps
- Verify folder name matches GameConfig.AVAILABLE_MAPS
- Check Output window for error messages

**Players spawning at 0,0,0?**
- Verify SpawnLocations folder exists in map
- Check Team1Spawns and Team2Spawns have spawn points
- Ensure spawns are Parts or SpawnLocation objects

**Weapons not working?**
- Verify weapons are in ReplicatedStorage > Weapons
- Check that each Tool has Handle and WeaponType
- WeaponType value must match exactly (case-sensitive)

## Resources

- **Toolbox**: Search "fps map" or "pistol gun" for free models
- **Terrain Editor**: Build natural-looking outdoor maps
- **MAP_DESIGN_GUIDE.md**: Detailed specifications for each map
- **WEAPON_CREATION_GUIDE.md**: Step-by-step weapon creation

## Current Game Features

Your FPS game now has:
- ✅ Team system with auto-balancing
- ✅ Round management with states and timer
- ✅ Inventory system with 3 weapons
- ✅ Weapon shooting with hit detection
- ✅ Headshots and damage falloff
- ✅ Team Deathmatch game mode
- ✅ Practice mode for solo testing
- ✅ Map loading system
- ✅ Economy and scoring system

**What's Missing:**
- ⏳ Actual weapon Tool objects (you need to create these)
- ⏳ Maps (you need to build these)
- ⏳ Additional game modes (Phase 5)
- ⏳ Polish and effects (Phase 7)

## Recommended Order

1. **Create weapons** (quick, gets you shooting)
2. **Build Jungle Ruins map** (most important, unlocks full gameplay)
3. **Test thoroughly** (fix any issues)
4. **Build remaining 3 maps** (when you have time)
5. **Polish weapons** (better models, sounds, effects)
6. **Polish maps** (lighting, details, atmosphere)

Once you have weapons and at least one map, your game will be fully playable!

## Questions?

If you run into issues or need help:
- Check the Output window in Studio for error messages
- Review the guide documents (WEAPON_CREATION_GUIDE.md, MAP_DESIGN_GUIDE.md)
- Ask me for help with specific problems!

Happy building! 🎮
