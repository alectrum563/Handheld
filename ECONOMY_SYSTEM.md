# Economy System Documentation

## Overview

The game features a comprehensive economy system with Score and Shards. Players earn rewards for kills with various bonuses based on skill and playstyle. This system is ready for future Streaks and Case Opening features.

## Key Features

### ✅ Score System
- **Base:** 100 Score per kill
- **Bonuses:** Headshot, Long Shot, Moving Kill, Multi-Kill
- **Persistent:** Tracked lifetime across all sessions
- **Purpose:** Progression metric, unlocks Streaks (future)

### ✅ Shards Currency
- **Earned:** Automatically from Score (Score ÷ 10, rounded down)
- **Persistent:** Saved to DataStore between sessions
- **Purpose:** In-game currency to purchase Cases

### ✅ Kill Bonus System
Rewards skillful and stylish kills with extra Score:

| Bonus Type | Requirement | Score Bonus | Example Total |
|------------|-------------|-------------|---------------|
| **Base Kill** | Any kill | +100 | 100 |
| **Headshot** | Hit head hitbox | +10 | 110 |
| **Long Shot** | 100+ studs away | +10 | 110 |
| **Moving Kill** | Airborne or sliding | +20 | 120 |
| **Double Kill** | 2 kills in 4 sec | +10 | 110 |
| **Triple Kill** | 3 kills in 4 sec | +20 | 120 |
| **Combo** | Multiple bonuses | Stacks! | 150+ |

### ✅ Multi-Kill System
Track consecutive kills within a time window:

- **Time Window:** 4 seconds between kills
- **Streak Tracking:** Automatic per player
- **Bonus Calculation:** +10 Score per kill level
  - Double Kill (2 kills): +10 Score
  - Triple Kill (3 kills): +20 Score
  - Quad Kill (4 kills): +30 Score
  - Penta Kill (5 kills): +40 Score
  - And so on...

## Scoring Examples

### Example 1: Basic Kill
```
Weapon: Standard Issue
Hit: Body shot
Distance: 50 studs
State: Standing

Score: 100 (base)
Shards: 10
```

### Example 2: Skilled Kill
```
Weapon: Hand Cannon
Hit: Headshot ✓
Distance: 120 studs (Long Shot) ✓
State: Airborne (Moving Kill) ✓

Score: 100 + 10 + 10 + 20 = 140
Shards: 14
Bonuses: Headshot, Long Shot, Moving Kill
```

### Example 3: Triple Kill Combo
```
Kill 1 at 0:00 - Headshot
  Score: 100 + 10 = 110
  Shards: 11

Kill 2 at 0:02 - Body shot, Airborne (Double Kill)
  Score: 100 + 20 + 10 = 130
  Shards: 13
  Bonuses: Moving Kill, Double Kill

Kill 3 at 0:04 - Long Shot (Triple Kill)
  Score: 100 + 10 + 20 = 130
  Shards: 13
  Bonuses: Long Shot, Triple Kill

TOTAL: 370 Score, 37 Shards
```

## Architecture

### Server-Side: EconomyManager

**Location:** `ServerScriptService > Core > EconomyManager`

**Key Functions:**

```lua
-- Initialize player economy
EconomyManager.InitializePlayer(player)

-- Get player's economy data
local economy = EconomyManager.GetEconomy(player)
-- Returns: { Shards = 0, TotalScore = 0, TotalKills = 0 }

-- Award kill rewards
local rewards = EconomyManager.AwardKill(player, killData)
-- killData: { IsHeadshot, Distance, IsAirborne, IsSliding }
-- Returns: { ScoreEarned, ShardsEarned, TotalScore, TotalShards, Bonuses, MultiKillLevel }

-- Spend shards (for case opening)
local success = EconomyManager.SpendShards(player, amount)

-- Add shards (admin/rewards)
EconomyManager.AddShards(player, amount)

-- Save economy to DataStore
EconomyManager.SaveEconomy(player)
```

**Kill Data Structure:**
```lua
local killData = {
  IsHeadshot = true/false,      -- Hit the head
  Distance = 95.5,              -- Distance in studs
  IsAirborne = true/false,      -- Killer was airborne
  IsSliding = true/false,       -- Killer was sliding (Phase 2)
  -- MultiKillLevel is calculated automatically
}
```

### Client-Side: HUD Display

**Location:** `StarterPlayer > StarterPlayerScripts > UIController`

**HUD Elements:**
- **💎 Shards:** Blue display showing current Shards
- **⭐ Score:** Gold display showing total Score
- **Updates:** Every 2 seconds automatically

### DataStore Persistence

**DataStore Name:** `PlayerEconomy`

**Key Format:** `"Economy_" .. player.UserId`

**Stored Data:**
```lua
{
  Shards = 127,           -- Current Shards
  TotalScore = 3450,      -- Lifetime Score
  TotalKills = 23,        -- Total kills (for stats)
}
```

**Auto-Save:**
- Saves every 5 kills automatically
- Saves on player leave
- Prevents data loss

## Configuration

**Location:** `ReplicatedStorage > Modules > GameConfig`

```lua
-- Economy Settings
GameConfig.BASE_KILL_SCORE = 100
GameConfig.HEADSHOT_BONUS = 10
GameConfig.LONGSHOT_BONUS = 10
GameConfig.MOVING_KILL_BONUS = 20
GameConfig.MULTIKILL_BONUS_PER_LEVEL = 10
GameConfig.LONGSHOT_DISTANCE = 100  -- studs
GameConfig.MULTIKILL_WINDOW = 4  -- seconds
GameConfig.SHARDS_PER_SCORE = 0.1  -- Score / 10
```

## Integration with Kill System

### Phase 1 (Current):
Kill rewards are awarded but **kill data is mostly placeholder** since weapons don't actually shoot yet. In Phase 3 when we implement shooting:

```lua
-- In HitDetection.lua (Phase 3)
local killData = {
  IsHeadshot = (hitPart.Name == "Head"),
  Distance = (shooterPos - victimPos).Magnitude,
  IsAirborne = (killerHumanoid.FloorMaterial == Enum.Material.Air),
  IsSliding = killerIsSliding,  -- From movement system
}

TeamManager.OnPlayerDeath(victim, killer, killData)
```

### Current Behavior:
```lua
-- TeamManager.OnPlayerDeath gets kill data
-- Awards Score and Shards via EconomyManager
-- Logs to Output window:
-- "[EconomyManager] Player1 earned +100 Score, +10 Shards"
-- "[TeamManager] Player1 killed Player2 - Earned 100 Score, 10 Shards"
```

## Multi-Kill Tracking

**How it Works:**
1. Player gets a kill → Record timestamp
2. Next kill within 4 seconds? → Increment streak
3. Calculate bonus: (StreakLevel - 1) × 10
4. Next kill after 4 seconds? → Reset streak to 1

**Multi-Kill Names:**
- 2 kills: "Double Kill"
- 3 kills: "Triple Kill"
- 4 kills: "Quad Kill"
- 5 kills: "Penta Kill"
- 6 kills: "Mega Kill"
- 7 kills: "Ultra Kill"
- 8+ kills: "Monster Kill"

## Future Features (Ready for Implementation)

### Case Opening System
```lua
-- Server-side
local CASE_PRICE = 100  -- Shards

if EconomyManager.SpendShards(player, CASE_PRICE) then
  -- Open case, give weapon/skin
  InventoryManager.AddWeapon(player, weaponName, skinId)
else
  -- Not enough Shards
end
```

### Streak System (Phase 8+)
```lua
-- Use TotalScore to unlock streaks
local economy = EconomyManager.GetEconomy(player)

if economy.TotalScore >= 1000 then
  -- Unlock UAV streak
end

if economy.TotalScore >= 5000 then
  -- Unlock Airstrike streak
end
```

### Leaderboards
```lua
-- Query top players by Score
-- DataStore OrderedDataStore for rankings
```

## RemoteEvents Used

| Event | Type | Purpose |
|-------|------|---------|
| `GetEconomy` | RemoteFunction | Client requests economy data for HUD |

## Testing the Economy System

1. **Join game** - Start with 0 Shards, 0 Score
2. **Spawn and test kills** - Output will show rewards
3. **Check HUD** - Shards and Score update every 2 seconds
4. **Rejoin game** - Shards and Score persist!
5. **Multi-kills** - Kill multiple players within 4 seconds
6. **Check Output** - See bonus messages

**Example Output:**
```
[EconomyManager] Player1 earned +110 Score, +11 Shards [Headshot]
[TeamManager] Player1 killed Player2 - Earned 110 Score, 11 Shards
[EconomyManager] Player1 earned +130 Score, +13 Shards [Moving Kill, Double Kill]
```

## Known Limitations

### Phase 1 (Current):
- **No actual shooting yet** - Kill data is placeholder
- **No kill notifications** - Only Output logs
- **No visual feedback** - HUD updates but no popups
- **No streak system** - Score tracked but no unlocks

### Phase 3 (Shooting Implementation):
- ✅ Real headshot detection
- ✅ Accurate distance calculation
- ✅ Airborne state detection
- ✅ Visual kill notifications

### Phase 2 (Movement):
- ✅ Sliding detection for Moving Kill bonus

## Balancing Notes

### Current Values:
- **100 Shards** = 1000 Score = ~10 kills
- **Double Kill** = 10% bonus
- **Headshot** = 10% bonus
- **Long Shot** = 10% bonus
- **Moving Kill** = 20% bonus

### Adjustments (if needed):
Modify values in `GameConfig.lua`:
- Increase `HEADSHOT_BONUS` to reward accuracy
- Decrease `MULTIKILL_WINDOW` for harder multi-kills
- Increase `SHARDS_PER_SCORE` for more generous rewards

## Case Opening Price Suggestions

Based on earning rates:
- **Common Case:** 50 Shards (~5 kills)
- **Rare Case:** 150 Shards (~15 kills)
- **Epic Case:** 500 Shards (~50 kills)
- **Legendary Case:** 1000+ Shards

---

**Questions about the economy system?** Check EconomyManager.lua for detailed implementation and comments.
