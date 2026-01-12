# Map Design Guide

This guide provides specifications for creating the 4 maps for the FPS game.

## Overview

We need 4 distinct maps, each supporting all 4 game modes:
1. **Jungle Ruins** - Overgrown ancient temple
2. **Mine** - Underground mining facility
3. **City Square** - Urban downtown area
4. **Virtual Matrix** - Futuristic cyberspace

## General Map Requirements

### Map Structure

Each map should be in **Workspace > Maps > [MapName]**:

```
Maps/
├── JungleRuins/
│   ├── Geometry/          -- Terrain, walls, floors
│   ├── SpawnLocations/
│   │   ├── Team1Spawns/   -- 6-8 spawn points for Team 1
│   │   └── Team2Spawns/   -- 6-8 spawn points for Team 2
│   ├── GameModeObjects/
│   │   ├── DominationZones/   -- 3-5 capture zones
│   │   ├── BombSites/         -- 2 bomb sites (A and B)
│   │   └── HardpointLocations/ -- 5-7 hardpoint positions
│   └── Lighting/          -- Lighting settings, atmosphere
```

### Map Size Guidelines

- **Total Play Area**: 300-500 studs per side (roughly square or rectangular)
- **Height Variation**: 30-100 studs of vertical gameplay space
- **Sightlines**: Mix of long (100+ studs) and short (20-40 studs) sightlines
- **Cover**: Abundant cover objects (walls, crates, pillars) every 10-20 studs

### Spawn Points

For each team:
- **Quantity**: 6-8 spawn points minimum
- **Distribution**: Spread across team's side of map
- **Safety**: Protected from direct enemy line of sight
- **Spacing**: At least 10 studs apart to prevent spawn overlap

**How to create**:
1. Insert **SpawnLocation** part
2. Position it in team territory
3. Set TeamColor to match team
4. Set properties:
   - Duration: 0 (disable spawn forcing)
   - CanCollide: false
   - Transparency: 1 (invisible in game)
5. Name: "Spawn1", "Spawn2", etc.

### Game Mode Objects

#### Domination Zones (3-5 per map)
- **Object**: Part with special properties
- **Size**: 20x2x20 studs (circular or square platform)
- **Position**: Strategic locations (center, flanks, high ground)
- **Properties**:
  - Name: "ZoneA", "ZoneB", "ZoneC", etc.
  - Anchored: true
  - CanCollide: false
  - Transparency: 0.7
  - Color: Neutral gray (will change when captured)
- Add **BoolValue** named "Neutral" = true

#### Bomb Sites (2 per map - A and B)
- **Object**: Part representing bomb site
- **Size**: 15x0.5x15 studs
- **Position**: One in each team's territory
- **Properties**:
  - Name: "BombSiteA" or "BombSiteB"
  - Anchored: true
  - CanCollide: false
  - Transparency: 0.8
  - Color: Orange/yellow

#### Hardpoint Locations (5-7 per map)
- **Object**: Part representing hardpoint zone
- **Size**: 18x2x18 studs
- **Position**: Rotate through different areas of map
- **Properties**:
  - Name: "Hardpoint1", "Hardpoint2", etc.
  - Anchored: true
  - CanCollide: false
  - Transparency: 0.7
  - Color: White (will change when active)

## Map 1: Jungle Ruins

**Theme**: Ancient temple overtaken by jungle vegetation

### Visual Style
- Overgrown stone structures
- Vines, trees, and foliage
- Moss-covered walls
- Crumbling architecture
- Ambient: Foggy, green tint lighting

### Layout
- **Size**: 400x400 studs
- **Symmetrical**: Mirror layout for fairness
- **Center**: Large temple courtyard (open area)
- **Sides**: Ruined corridors and rooms (close quarters)
- **Elevation**: Multi-level temple platforms (stairs, ledges)

### Key Features
1. **Central Temple Plaza**
   - 80x80 stud open area
   - Good for Team Deathmatch combat
   - Domination Zone C in center

2. **Side Passages**
   - Narrow 10-stud wide corridors
   - Stone pillars for cover
   - Good for flanking

3. **Upper Platforms**
   - Elevated positions 20-30 studs high
   - Accessible via stairs
   - Good sniping positions

4. **Jungle Areas**
   - Dense foliage (use Terrain or Parts)
   - Limited visibility
   - Cover from long-range shots

### Color Palette
- Stone: Gray/brown (163, 162, 165)
- Foliage: Dark green (37, 66, 30)
- Moss: Lime green (119, 156, 67)
- Accents: Gold/yellow for ancient decorations

### Lighting
- **Ambient**: Color3.fromRGB(150, 180, 150)
- **OutdoorAmbient**: Color3.fromRGB(100, 120, 100)
- **Brightness**: 2
- **Atmosphere**: Density 0.3, Haze 1.5

## Map 2: Mine

**Theme**: Industrial underground mining facility

### Visual Style
- Metal support beams
- Mining cart tracks
- Ore deposits (gems, crystals)
- Industrial lighting (yellow/orange)
- Dark, enclosed spaces

### Layout
- **Size**: 350x350 studs
- **Asymmetrical**: Organic cave layout
- **Center**: Large mining chamber
- **Sides**: Winding tunnels
- **Elevation**: Multilevel cave system

### Key Features
1. **Main Chamber**
   - 60x60 stud central area
   - Mining equipment scattered around
   - Good for objective-based modes

2. **Tunnel Network**
   - 8-12 stud wide tunnels
   - Branching paths
   - Strategic choke points

3. **Vertical Shafts**
   - Elevator platforms
   - Ladders or stairs
   - High ground advantage

4. **Crystal Caverns**
   - Glowing ore deposits
   - Provides ambient lighting
   - Visual landmarks

### Color Palette
- Rock: Dark gray/brown (91, 93, 105)
- Metal: Steel gray (163, 162, 165)
- Crystals: Cyan/blue (0, 150, 255)
- Lighting: Warm yellow (255, 200, 100)

### Lighting
- **Ambient**: Color3.fromRGB(80, 80, 100)
- **OutdoorAmbient**: Color3.fromRGB(40, 40, 50)
- **Brightness**: 1
- **Atmosphere**: None (underground)
- Add **PointLights** on walls (every 20 studs)

## Map 3: City Square

**Theme**: Modern urban downtown area

### Visual Style
- Concrete buildings
- Glass windows
- Street roads
- Urban furniture (benches, lights, signs)
- Clean, modern aesthetic

### Layout
- **Size**: 450x450 studs
- **Grid-based**: Street grid with buildings
- **Center**: Open plaza/square
- **Sides**: Building interiors and alleys
- **Elevation**: 2-3 story buildings

### Key Features
1. **Central Plaza**
   - 70x70 stud open square
   - Fountain or statue in center
   - Exposed, risky position

2. **Building Interiors**
   - 2-3 accessible buildings per side
   - Multiple rooms and hallways
   - Windows for sightlines

3. **Streets and Alleys**
   - Main roads: 15 studs wide
   - Alleys: 8 studs wide
   - Parked cars for cover

4. **Rooftops**
   - Accessible via stairs
   - Long-range vantage points
   - Risky, exposed positions

### Color Palette
- Concrete: Light gray (230, 230, 230)
- Glass: Transparent blue
- Asphalt: Dark gray (60, 60, 60)
- Accents: Red brick, green plants

### Lighting
- **Ambient**: Color3.fromRGB(150, 150, 150)
- **OutdoorAmbient**: Color3.fromRGB(120, 120, 120)
- **Brightness**: 2.5
- **ClockTime**: 14 (2 PM - bright daylight)
- **Atmosphere**: Light haze

## Map 4: Virtual Matrix

**Theme**: Digital cyberspace environment

### Visual Style
- Neon grid floors
- Floating platforms
- Digital particles
- Glowing edges and lines
- Dark background with bright accents

### Layout
- **Size**: 400x400 studs
- **Geometric**: Perfect symmetry, grid patterns
- **Center**: Large platform arena
- **Sides**: Floating platform islands
- **Elevation**: Multiple floating levels

### Key Features
1. **Main Platform**
   - 80x80 stud central arena
   - Glowing grid pattern floor
   - Neon edges

2. **Floating Platforms**
   - 15-25 stud platforms
   - Connected by bridges or gaps
   - Require jumping/movement skill

3. **Data Streams**
   - Vertical pillars of light
   - Visual landmarks
   - Can provide cover

4. **Void Areas**
   - Gaps between platforms
   - Falling = instant death (kill volume)
   - High risk, high reward pathing

### Color Palette
- Background: Black (0, 0, 0)
- Floor grid: Cyan (0, 255, 255)
- Edges: Magenta/purple (255, 0, 255)
- Accents: Neon green (0, 255, 0)
- Platforms: Dark blue (20, 20, 60)

### Lighting
- **Ambient**: Color3.fromRGB(0, 50, 100)
- **OutdoorAmbient**: Color3.fromRGB(0, 0, 0)
- **Brightness**: 0.5
- **Atmosphere**: None
- Add **SurfaceLights** on all platform edges
- Add **Neon** material to all edges

### Special Effects
- ParticleEmitters floating around
- Beams connecting platforms
- ColorCorrection for digital look

## Building Process

### Step 1: Create Map Folder
1. In Workspace, create folder "Maps"
2. Inside Maps, create folder for map (e.g., "JungleRuins")
3. Create subfolders: Geometry, SpawnLocations, GameModeObjects

### Step 2: Build Terrain/Geometry
1. Use Terrain tools or Parts to build ground
2. Add walls, floors, obstacles
3. Test scale by walking around (player is ~5 studs tall)
4. Ensure interesting geometry (not flat/boring)

### Step 3: Add Spawn Points
1. Insert SpawnLocation parts in SpawnLocations folder
2. Create Team1Spawns and Team2Spawns folders
3. Position 6-8 spawns per team
4. Test that players spawn safely

### Step 4: Add Game Mode Objects
1. Create Domination zones (3-5)
2. Create Bomb sites (A and B)
3. Create Hardpoint locations (5-7)
4. Place strategically around map

### Step 5: Lighting and Atmosphere
1. Adjust Lighting properties
2. Add Atmosphere if needed
3. Add point lights for dark areas
4. Test visibility and mood

### Step 6: Playtesting
1. Test with F7 (server simulation)
2. Check sightlines, balance, flow
3. Ensure no spawn camping
4. Verify all game modes work
5. Iterate and improve

## Map Balance Checklist

For each map, verify:
- [ ] Both teams have equal advantages
- [ ] No spawn camping opportunities
- [ ] Mix of long and short range combat areas
- [ ] Multiple paths between objectives
- [ ] Adequate cover throughout map
- [ ] Clear visual landmarks for navigation
- [ ] Good performance (not too many parts)
- [ ] All game mode objects placed correctly
- [ ] Spawn points work and are safe
- [ ] Fun and interesting to play on

## Tips for Good Map Design

1. **Three-Lane Design**: Create 3 main paths (left, center, right) for flow
2. **Power Positions**: Add elevated or strategic spots, but make them risky
3. **Flanking Routes**: Always provide alternate paths
4. **Visual Clarity**: Make sure players can see enemies clearly
5. **Performance**: Keep part count reasonable (<2000 parts per map)
6. **Testing**: Playtest extensively with multiple players

## Next Steps

Start with **Jungle Ruins** as it's the most forgiving map to build:
1. Simple geometry (boxes for temple walls)
2. Use Terrain for ground and foliage
3. Add spawn points and test
4. Add game mode objects
5. Polish with details and lighting

Once you're comfortable, move to the other maps!
