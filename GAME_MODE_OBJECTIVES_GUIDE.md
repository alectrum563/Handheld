# Game Mode Objectives Quick Reference

This guide provides a quick reference for setting up objective-based game modes in your maps.

## Required Map Structure

```
Workspace/
└── Maps/
    └── [YourMapName]/
        ├── Geometry/                  (visual parts)
        ├── SpawnLocations/
        │   ├── Team1Spawns/          (6-8 SpawnLocation parts)
        │   └── Team2Spawns/          (6-8 SpawnLocation parts)
        └── GameModeObjects/
            ├── DominationZones/      (3-5 Parts for Domination mode)
            ├── BombSites/            (2 Parts for Search & Destroy mode)
            └── HardpointLocations/   (3-5 Parts for Hardpoint mode)
```

---

## Game Mode: Domination

**Objective:** Control zones to earn points (1 point/second per zone). First to 200 points wins.

### Setup Requirements

Create **3-5 Parts** in `GameModeObjects/DominationZones/`

**Part Configuration:**
- **Size:** `Vector3.new(30, 1, 30)` or similar
- **Anchored:** `true`
- **CanCollide:** `false`
- **Transparency:** `0.7`
- **BrickColor:** `"Medium stone grey"` (changes during game)

**Placement Tips:**
- Space zones evenly across the map
- Place in open, accessible areas
- Ensure multiple approach routes to each zone
- Mix of safe/risky zone locations adds strategy

**Gameplay Mechanics:**
- 15 studs capture radius
- 5 seconds to capture from neutral
- Multiple players capture faster (up to 2x speed)
- Contested zones (both teams present) = no capture progress
- Visual feedback: Blue = Team1, Red = Team2, Grey = Neutral

---

## Game Mode: Search & Destroy

**Objective:** Attackers plant bomb at sites, defenders prevent/defuse. First to 6 rounds wins. No respawns!

### Setup Requirements

Create **exactly 2 Parts** in `GameModeObjects/BombSites/`

**Part Configuration:**
- **Size:** `Vector3.new(20, 1, 20)` or similar
- **Anchored:** `true`
- **CanCollide:** `false`
- **Transparency:** `0.8`
- **BrickColor:** `"Bright yellow"`
- **Name:** "Site_A" and "Site_B" (recommended for clarity)

**Placement Tips:**
- Site A and Site B should be on opposite sides of the map
- Both sites should be accessible from multiple angles
- Provide cover near sites for defenders to hold
- Avoid making sites too close together

**Gameplay Mechanics:**
- Teams alternate attack/defend each round
- Random attacker receives the bomb
- Plant time: 5 seconds (within 10 stud radius)
- Defuse time: 7 seconds (within 5 stud radius)
- Explosion timer: 30 seconds after plant
- No respawns - eliminated players wait for next round
- Round ends: Team elimination, bomb explode, bomb defused, or time limit

---

## Game Mode: Hardpoint

**Objective:** Control the rotating hardpoint to earn points (1 point/second). First to 250 points wins.

### Setup Requirements

Create **3-5 Parts** in `GameModeObjects/HardpointLocations/`

**Part Configuration:**
- **Size:** `Vector3.new(30, 1, 30)`
- **Anchored:** `true`
- **CanCollide:** `false`
- **Transparency:** `1` (invisible initially, becomes visible when active)
- **BrickColor:** `"White"`

**Placement Tips:**
- Spread locations across the entire map
- Mix of open and enclosed areas
- Include some high ground and low ground locations
- Variety encourages map movement and repositioning

**Gameplay Mechanics:**
- Hardpoints activate sequentially
- Each hardpoint active for 60 seconds
- 5-second delay between hardpoint rotations
- 15 studs control radius
- Only the controlling team earns points
- Contested hardpoints (both teams present) = no points
- Visual feedback: Blue = Team1, Red = Team2, White = Neutral/Contested

---

## Game Mode: Team Deathmatch

**Objective:** Eliminate enemies. First to 50 kills wins.

### Setup Requirements

**No objective parts needed!** Team Deathmatch only requires spawn points.

**Recommended Map Features:**
- Varied engagement distances (close, medium, long)
- Multiple routes and flanking paths
- Cover throughout the map
- Balance open areas with corridors

---

## Testing Your Map

### In Roblox Studio

1. **Start Server Test:** Test tab → Clients and Servers → 2 Players
2. **Check Each Mode:**
   - Domination: Verify zones appear and change color
   - Search & Destroy: Check bomb sites are visible
   - Hardpoint: Confirm locations activate in sequence
   - Team Deathmatch: Ensure spawns work correctly

3. **Console Output:** View → Output window to see debug messages

### Common Issues

**"No [ObjectType] found in map!"**
- Ensure `GameModeObjects/` folder exists in your map
- Check subfolder names match exactly: `DominationZones`, `BombSites`, `HardpointLocations`
- Verify Parts are direct children of these folders

**Objects not appearing in game:**
- Check `Transparency` is not 1 (unless Hardpoint, which is intentional)
- Verify `Anchored = true`
- Ensure Parts aren't hidden inside geometry

**Players spawning incorrectly:**
- Verify `SpawnLocations/Team1Spawns/` and `SpawnLocations/Team2Spawns/` exist
- Check spawn points are SpawnLocation objects or BaseParts
- Ensure spawns are positioned safely

---

## Quick Setup Checklist

For a complete map supporting all game modes:

- [ ] Create map folder in `Workspace/Maps/[MapName]`
- [ ] Add `Geometry/` folder with visual parts
- [ ] Add `SpawnLocations/Team1Spawns/` with 6-8 spawns
- [ ] Add `SpawnLocations/Team2Spawns/` with 6-8 spawns
- [ ] Add `GameModeObjects/DominationZones/` with 3-5 Parts
- [ ] Add `GameModeObjects/BombSites/` with 2 Parts
- [ ] Add `GameModeObjects/HardpointLocations/` with 3-5 Parts
- [ ] Configure all Parts according to specifications above
- [ ] Test each game mode
- [ ] Add map name to `GameConfig.AVAILABLE_MAPS`

---

## Game Mode Rotation

The game automatically rotates through modes in this order:
1. **Team Deathmatch**
2. **Domination**
3. **Hardpoint**
4. **Search & Destroy**

After Search & Destroy, it cycles back to Team Deathmatch.

You can modify the rotation order in `GameConfig.lua`:
```lua
GameConfig.GAME_MODE_ROTATION = {"TeamDeathmatch", "Domination", "Hardpoint", "SearchAndDestroy"}
```

---

## Configuration Values

Located in `src/ReplicatedStorage/Modules/GameConfig.lua`:

```lua
-- Domination
GameConfig.DOM_SCORE_LIMIT = 200

-- Search & Destroy
GameConfig.SAD_ROUNDS_TO_WIN = 6

-- Hardpoint
GameConfig.HP_SCORE_LIMIT = 250
GameConfig.HP_ROTATION_TIME = 60

-- Team Deathmatch
GameConfig.TDM_KILL_LIMIT = 50
```

---

Ready to build your maps! For detailed map design guidance, see `MAP_DESIGN_GUIDE.md`.
