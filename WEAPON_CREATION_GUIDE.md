# Weapon Creation Guide

This guide explains how to create the 3 pistol weapons in Roblox Studio.

## Overview

We need to create 3 weapon Tools in ReplicatedStorage > Weapons:
1. **FastPistol** (Rapid Fire) - High fire rate, low damage
2. **BalancedPistol** (Standard Issue) - Balanced stats
3. **SlowPistol** (Hand Cannon) - High damage, slow fire rate

All weapon stats are configured in `ReplicatedStorage > Modules > WeaponStats.lua`.

## Step-by-Step Instructions

### 1. Create the Weapons Folder

1. In Roblox Studio, open **FirstGameNew.rbxl**
2. In Explorer, navigate to **ReplicatedStorage**
3. Right-click ReplicatedStorage → Insert Object → **Folder**
4. Rename it to **"Weapons"**

### 2. Create Each Weapon Tool

For each weapon (FastPistol, BalancedPistol, SlowPistol), follow these steps:

#### A. Create the Tool Object

1. Right-click **ReplicatedStorage > Weapons** → Insert Object → **Tool**
2. Rename the Tool to the weapon name (e.g., "FastPistol")
3. Set Tool properties:
   - **RequiresHandle**: true
   - **CanBeDropped**: false
   - **ManualActivationOnly**: false

#### B. Create the Handle (Visual Model)

1. Right-click the Tool → Insert Object → **Part**
2. Rename it to **"Handle"** (MUST be named Handle for Tool to work)
3. Set Handle properties:
   - **Size**: Vector3.new(0.4, 0.8, 1.5) - Adjust as needed
   - **Material**: SmoothPlastic
   - **Color**: Choose a color based on weapon type
     - FastPistol: Bright blue (0, 150, 255)
     - BalancedPistol: Dark gray (70, 70, 70)
     - SlowPistol: Dark red (180, 40, 40)
   - **CanCollide**: false
   - **Locked**: true

4. Optional: Make it look more like a gun
   - Add more Parts to create a barrel, grip, trigger
   - Use Unions or MeshParts for better visuals
   - Keep the main part named "Handle"

#### C. Add Attachment Points

1. Right-click Handle → Insert Object → **Attachment**
2. Rename to **"MuzzlePoint"**
3. Position it at the front of the barrel (where bullets come out)
4. This is used for muzzle flash and bullet tracer effects

#### D. Add Weapon Configuration

1. Right-click the Tool → Insert Object → **StringValue**
2. Rename to **"WeaponType"**
3. Set **Value** to the weapon name (e.g., "FastPistol")

This tells the weapon client scripts which stats to use.

#### E. Optional: Add Animations

1. Create or find gun animations (idle, shoot, reload)
2. Right-click the Tool → Insert Object → **Animation**
3. Rename to "ShootAnimation", "ReloadAnimation", etc.
4. Set the AnimationId to your animation asset

### 3. Visual Improvements (Optional but Recommended)

For better-looking weapons:

1. **Use Free Models**:
   - Toolbox → Search "pistol gun tool"
   - Find a good-looking pistol model
   - Make sure it has a "Handle" part
   - Customize it to fit your needs

2. **Create Custom Models**:
   - Use Blender to create 3D gun models
   - Import as MeshPart
   - Attach to Tool as Handle

3. **Add Effects**:
   - ParticleEmitter at MuzzlePoint for muzzle flash
   - Sound effects for shooting/reloading

### 4. Quick Setup (Minimum Viable Weapons)

If you want to get started quickly:

1. Create 3 Tools in ReplicatedStorage > Weapons
2. Name them: FastPistol, BalancedPistol, SlowPistol
3. For each, add a simple Part named "Handle"
4. Add a StringValue named "WeaponType" with the weapon name
5. Done! The scripts will handle the rest.

You can improve the visuals later.

## Weapon Stats Reference

All stats are in `WeaponStats.lua`:

### FastPistol (Rapid Fire)
- Damage: 20 (40 headshot)
- Fire Rate: 0.1s (10 shots/sec)
- Magazine: 15 rounds
- Range: 80 studs
- Best for: Close-range spam

### BalancedPistol (Standard Issue)
- Damage: 35 (70 headshot)
- Fire Rate: 0.25s (4 shots/sec)
- Magazine: 10 rounds
- Range: 120 studs
- Best for: All-around versatility

### SlowPistol (Hand Cannon)
- Damage: 50 (100 headshot - instant kill)
- Fire Rate: 0.5s (2 shots/sec)
- Magazine: 6 rounds
- Range: 150 studs
- Best for: Accurate long-range shots

## Testing

After creating the weapons:

1. Press F5 to test locally
2. Open inventory (TAB key)
3. You should see all 3 weapons
4. Click to equip a weapon
5. Click to shoot, verify damage is correct

## Troubleshooting

- **Weapon doesn't appear in inventory**: Check that Tool is in ReplicatedStorage > Weapons
- **Can't equip weapon**: Ensure Tool has a Part named "Handle"
- **Shooting doesn't work**: Check that WeaponType StringValue exists with correct name
- **Wrong damage**: Verify WeaponType value matches exactly (case-sensitive)

## Next Steps

Once weapons are created and working:
- Add better 3D models
- Add shooting sounds
- Add muzzle flash particle effects
- Add reload animations
- Add weapon skins (future feature)
