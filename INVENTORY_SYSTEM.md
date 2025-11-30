# Inventory System Documentation

## Overview

The game now features a complete inventory system with persistent storage, preparing it for future skin and case opening features. All players start with 3 pistols in their inventory and can equip different weapons at any time.

## Key Features

### ✅ Persistent Storage
- Player inventories are saved to Roblox DataStore
- Inventories persist between play sessions
- Automatic save on player leave
- Automatic load on player join

### ✅ Starter Weapons
Every new player automatically receives:
- **Rapid Fire** (FastPistol) - Fast firing, low damage
- **Standard Issue** (BalancedPistol) - Balanced stats
- **Hand Cannon** (SlowPistol) - High damage, slow firing

### ✅ Weapon Instances
- Each weapon has a unique ID (GUID)
- Weapons support skin data (currently all "default")
- Ready for skin variants and case opening system

### ✅ Inventory UI
- Press **TAB** to open/close inventory
- View all owned weapons with full stats
- See which weapon is currently equipped (green highlight)
- Click "EQUIP" to switch weapons
- Opens automatically on spawn for first-time weapon selection

## Architecture

### Server-Side: InventoryManager

**Location:** `ServerScriptService > Core > InventoryManager`

**Key Functions:**

```lua
-- Load player's inventory (called on join)
InventoryManager.LoadInventory(player)

-- Save player's inventory (called on leave)
InventoryManager.SaveInventory(player)

-- Get player's inventory
local inventory = InventoryManager.GetInventory(player)

-- Get player's equipped weapon
local weapon = InventoryManager.GetEquippedWeapon(player)

-- Equip a weapon from inventory
InventoryManager.EquipWeapon(player, weaponId)

-- Add weapon to inventory (FOR FUTURE CASE OPENING)
local weaponId = InventoryManager.AddWeapon(player, weaponName, skinId)

-- Remove weapon from inventory (optional - for trading)
InventoryManager.RemoveWeapon(player, weaponId)
```

**Data Structure:**

Each weapon in inventory is stored as:
```lua
{
  Id = "unique-guid-here",          -- Unique weapon instance ID
  WeaponName = "FastPistol",        -- Type of weapon
  SkinId = "default",               -- Skin variant (ready for skins!)
  UnlockedAt = 1234567890           -- Unix timestamp when obtained
}
```

### Client-Side: InventoryUI

**Location:** `StarterPlayer > StarterPlayerScripts > InventoryUI`

**Features:**
- Automatically opens on spawn
- Press TAB to toggle inventory
- Displays all weapons with:
  - Weapon name and skin
  - Damage, RPM (rounds per minute), range, magazine size
  - "EQUIPPED" badge for current weapon
  - "EQUIP" button for other weapons
- Communicates with server via RemoteEvents

### Communication Flow

1. **Player Joins:**
   - Server: InventoryManager.InitializePlayer(player)
   - Loads inventory from DataStore
   - Sets first weapon as equipped

2. **Player Opens Inventory:**
   - Client: Press TAB
   - Client: GetInventory:InvokeServer()
   - Server: Returns formatted inventory data
   - Client: Displays inventory UI with all weapons

3. **Player Equips Weapon:**
   - Client: Clicks "EQUIP" button
   - Client: EquipWeapon:FireServer(weaponId)
   - Server: InventoryManager.EquipWeapon(player, weaponId)
   - Server: Destroys old weapon, gives new weapon
   - Client: Inventory UI refreshes

4. **Player Leaves:**
   - Server: InventoryManager.CleanupPlayer(player)
   - Saves inventory to DataStore
   - Clears cache

## Future: Case Opening System

The inventory system is **ready for case opening**! Here's how to add it:

### Adding Weapons to Inventory

When a player opens a case and gets a weapon:

```lua
-- Server-side code (future case opening system)
local weaponName = "FastPistol"
local skinId = "rare_camo"  -- New skin!

-- Add weapon to player's inventory
local weaponId = InventoryManager.AddWeapon(player, weaponName, skinId)

-- Optionally notify player
print(string.format("Player %s received %s with %s skin!",
  player.Name, weaponName, skinId))
```

### Adding New Skins

1. **Add skin visuals** to weapon Tool objects in `ReplicatedStorage > Weapons`
2. **Update TeamManager.EquipWeapon()** to apply skin visuals based on `skinId`
3. Skins are automatically stored and persisted!

### Example: Skin Application

```lua
-- In TeamManager.EquipWeapon (future enhancement)
local skinId = equippedWeapon.SkinId

if skinId == "rare_camo" then
  -- Apply camo texture to weapon model
  weaponClone.Handle.Texture = "rbxassetid://123456789"
elseif skinId == "gold" then
  -- Make weapon golden
  weaponClone.Handle.Color = Color3.fromRGB(255, 215, 0)
  weaponClone.Handle.Material = Enum.Material.Gold
end
```

## DataStore Details

**DataStore Name:** `PlayerInventories`

**Key Format:** `"Inventory_" .. player.UserId`

**Example Data:**
```lua
{
  {
    Id = "abc-123-def-456",
    WeaponName = "FastPistol",
    SkinId = "default",
    UnlockedAt = 1234567890
  },
  {
    Id = "xyz-789-uvw-012",
    WeaponName = "BalancedPistol",
    SkinId = "rare_camo",
    UnlockedAt = 1234567900
  }
}
```

## Testing the Inventory System

1. **Join the game** - You should get 3 starter weapons
2. **Press TAB** - Inventory UI opens
3. **View weapons** - See all 3 pistols with stats
4. **Equip different weapon** - Click EQUIP on another weapon
5. **Close and reopen** - Press TAB twice, inventory persists
6. **Rejoin game** - Your equipped weapon should be remembered

## RemoteEvents Used

- **GetInventory** (RemoteFunction) - Client requests inventory data
- **EquipWeapon** (RemoteEvent) - Client requests to equip weapon

## Known Limitations

1. **Weapon models:** Currently placeholder tools (will be enhanced in Phase 3)
2. **Skins:** Only "default" skin exists (infrastructure ready for more)
3. **Trading:** RemoveWeapon function exists but no UI for trading yet
4. **Sorting:** Weapons displayed in order received, not sorted by name/type

## Next Steps

After testing Phase 1 with the inventory system:
- **Phase 2:** Movement system
- **Phase 3:** Weapon shooting mechanics
- **Phase 4+:** Game modes and maps
- **Future:** Case opening and skin system!

---

**Questions about the inventory system?** Check the comments in `InventoryManager.lua` for detailed function documentation.
