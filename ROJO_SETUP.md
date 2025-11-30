# Rojo Setup Guide

This guide will help you set up Rojo to automatically sync your code from the filesystem to Roblox Studio.

## What is Rojo?

Rojo is a tool that syncs files from your computer → Roblox Studio in real-time. This means:
- ✅ **No more manual copying** - Edit files, save, and they instantly appear in Studio
- ✅ **Version control friendly** - All your code is in `.lua` files you can commit to Git
- ✅ **Professional workflow** - Industry-standard approach used by top Roblox developers

## Step 1: Install Rojo

### Option A: Direct Download (Recommended)

1. Go to https://github.com/rojo-rbx/rojo/releases/latest
2. Download `rojo-7.x.x-windows.zip` (get the latest version)
3. Extract the `rojo.exe` file
4. Move it to a permanent location like `C:\Users\nikol\rojo\`
5. **(Optional)** Add to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add `C:\Users\nikol\rojo\`
   - Restart terminal/PowerShell

### Option B: Via Foreman (For advanced users)

```bash
# Install Foreman: https://github.com/Roblox/foreman/releases/latest
# Then run:
foreman install
```

### Verify Installation

Open PowerShell or Command Prompt and run:

```bash
rojo --version
```

You should see something like: `Rojo 7.x.x`

## Step 2: Install Rojo Studio Plugin

**⚠️ IMPORTANT: Rojo is NOT in the plugin marketplace. You must install it manually.**

### Method 1: Direct Install (Recommended)

1. **Download the plugin:**
   - Go to: https://github.com/rojo-rbx/rojo/releases/latest
   - Scroll down to the **Assets** section
   - Download: **`Rojo.rbxm`** (the plugin file)

2. **Install the plugin:**
   - Double-click the downloaded `Rojo.rbxm` file
   - It will open in Roblox Studio
   - Studio will prompt: **"Install this plugin?"**
   - Click **"Install"** or **"Yes"**

3. **Restart Roblox Studio**

### Method 2: Manual File Copy

1. **Download `Rojo.rbxm`** from the link above

2. **Open Plugins folder:**
   - Press `Windows + R`
   - Type: `%LOCALAPPDATA%\Roblox\Plugins`
   - Press Enter

3. **Copy the file:**
   - Copy `Rojo.rbxm` into the Plugins folder

4. **Restart Roblox Studio**

### Verify Installation

After restarting Studio:
- Look in the **Plugins** tab toolbar
- You should see a **Rojo** button (red/orange icon)
- Clicking it opens the Rojo connection panel

## Step 3: Start Rojo Server

1. **Open PowerShell/Command Prompt**
2. **Navigate to your project folder:**
   ```bash
   cd C:\Users\nikol\Projects\Roblox
   ```

3. **Start Rojo:**
   ```bash
   rojo serve
   ```

   You should see:
   ```
   Rojo server listening on http://localhost:34872
   ```

4. **Keep this terminal open** - Rojo needs to run while you're developing

## Step 4: Connect Rojo to Studio

1. **Open Roblox Studio**
2. **Open your game** (`FirstGame.rbxl`)
3. **Click the Rojo plugin button** in the toolbar (it should appear after installing the plugin)
4. **Click "Connect"** in the Rojo panel
5. **Status should turn green** and say "Connected"

## Step 5: Sync Your Project

1. **In the Rojo panel**, click **"Sync In"**
2. **WARNING:** This will replace Studio content with filesystem content
3. **Confirm the sync**

Your filesystem code is now in Studio! 🎉

## How Rojo Works Now

### Old Workflow (Manual):
```
Me: Edit src/*.lua
  ↓
You: Copy to Studio manually 😫
  ↓
Studio: Test the game
```

### New Workflow (Automatic):
```
Me: Edit src/*.lua
  ↓
Rojo: Auto-syncs to Studio ✨
  ↓
Studio: Instantly see changes! Test the game
```

## Daily Usage

1. **Start Rojo server:**
   ```bash
   cd C:\Users\nikol\Projects\Roblox
   rojo serve
   ```

2. **Open Roblox Studio** and your game

3. **Connect Rojo plugin** (click Connect button)

4. **Edit files** in VS Code or your editor

5. **Save files** - Changes appear in Studio instantly!

6. **Test in Studio** - Press F5 to play

## File Structure

Rojo uses `default.project.json` to map filesystem → Studio:

```
src/
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── GameConfig.lua → ReplicatedStorage.Modules.GameConfig
│   │   ├── WeaponStats.lua → ReplicatedStorage.Modules.WeaponStats
│   │   └── Utilities.lua → ReplicatedStorage.Modules.Utilities
│   └── ...
├── ServerScriptService/
│   ├── Bootstrapper.lua → ServerScriptService.Bootstrapper
│   └── Core/
│       ├── TeamManager.lua → ServerScriptService.Core.TeamManager
│       └── ...
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── UIController.lua
        ├── InventoryUI.lua
        └── MainMenuUI.lua
```

## Troubleshooting

### "Rojo is not recognized as a command"
- Rojo is not in PATH. Either:
  - Add it to PATH (see Step 1)
  - OR run it with full path: `C:\Users\nikol\rojo\rojo.exe serve`

### Plugin not showing in Studio
- Restart Roblox Studio after installing the plugin
- Check Plugins → Manage Plugins → Ensure Rojo is enabled

### Connection failed
- Make sure `rojo serve` is running in the terminal
- Check firewall isn't blocking `localhost:34872`
- Try running as Administrator

### Changes not appearing
- Make sure Rojo server is running
- Click "Connect" in Rojo plugin
- Save your file (Ctrl+S)
- Check terminal for errors

### "Sync In" replaces my Studio work
- **IMPORTANT:** Rojo treats filesystem as source of truth
- Any changes made in Studio (spawn points, models, etc.) need to be:
  - Added to filesystem (via Rojo's `$ignoreUnknownInstances` flag)
  - OR kept only in Studio (manual placement)
- For this project: Spawn points and maps stay in Studio, code syncs via Rojo

## What Gets Synced vs What Stays in Studio

### Synced via Rojo (Code):
- ✅ All Lua scripts (.lua files)
- ✅ ModuleScripts
- ✅ RemoteEvents/RemoteFunctions (structure)
- ✅ Folder structure

### Stays in Studio (Manual):
- 🏗️ Spawn points (Parts in Workspace.SpawnLocations)
- 🗺️ Maps and terrain
- 🎨 Models and assets
- 🔧 Tool handles and attachments
- ⚙️ Properties of existing instances

The `$ignoreUnknownInstances` flag in `default.project.json` lets Rojo coexist with Studio-only content.

## Benefits of Rojo

1. **Instant Updates** - No more copying code
2. **Version Control** - Commit `.lua` files to Git
3. **External Editors** - Use VS Code, Sublime, etc.
4. **Multi-file Editing** - Change multiple files at once
5. **Professional Workflow** - Industry standard

## Next Steps

Once Rojo is set up and working:
1. I'll edit files in `src/`
2. You'll see changes instantly in Studio
3. We can iterate much faster! 🚀

---

**Need help?** Check the official docs: https://rojo.space/docs/
