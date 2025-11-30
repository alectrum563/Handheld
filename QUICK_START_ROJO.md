# Quick Start with Rojo

Follow these steps to get Rojo up and running in **under 5 minutes**! 🚀

## ⚡ Fast Track Setup

### 1. Install Rojo (2 minutes)

**Download Method (Easiest):**
1. Go to: https://github.com/rojo-rbx/rojo/releases/latest
2. Download: `rojo-7.x.x-windows.zip`
3. Extract `rojo.exe`
4. Place in: `C:\Users\nikol\rojo\`

**Verify:**
```bash
C:\Users\nikol\rojo\rojo.exe --version
```

### 2. Install Rojo Plugin (1 minute)

**⚠️ Rojo is NOT in the plugin marketplace - you need to install it manually:**

1. **Download the plugin:**
   - Go to: https://github.com/rojo-rbx/rojo/releases/latest
   - Scroll to **Assets** section
   - Download: **`Rojo.rbxm`** (the plugin file)

2. **Install it:**
   - Double-click the downloaded `Rojo.rbxm` file
   - It will open in Roblox Studio
   - Click **"Install"** when prompted

3. **Restart Roblox Studio**

### 3. Start Rojo (30 seconds)

**Open PowerShell/Command Prompt:**
```bash
cd C:\Users\nikol\Projects\Roblox
C:\Users\nikol\rojo\rojo.exe serve
```

**OR** if you added Rojo to PATH:
```bash
cd C:\Users\nikol\Projects\Roblox
rojo serve
```

You should see:
```
Rojo server listening on http://localhost:34872
```

✅ **Keep this terminal open!**

### 4. Connect to Studio (30 seconds)

1. **Open Roblox Studio**
2. **Open `FirstGame.rbxl`**
3. **Click Rojo button** in toolbar
4. **Click "Connect"**
5. **Status turns green** ✅

### 5. Sync Your Code (30 seconds)

**⚠️ IMPORTANT - First Time Only:**

The first sync will replace Studio content with filesystem content. Since you've already set things up in Studio, we need to be careful:

**Option A: Fresh Start (Recommended)**
1. Click **"Sync In"** in Rojo panel
2. Confirm the sync
3. Your code from `src/` is now in Studio!
4. **Manually add back:**
   - Spawn points (Parts in Workspace.SpawnLocations.Team1Spawns/Team2Spawns)
   - Baseplate or terrain
   - Any weapons tools you created

**Option B: Keep Studio Work (Advanced)**
1. Don't click "Sync In" yet
2. In Studio, delete all scripts we've been manually copying
3. Then click "Sync In"
4. This way spawn points stay, but code comes from Rojo

## ✨ You're Done!

Now when you (or I) edit files in `src/`, they'll instantly appear in Studio!

## 🎮 Test It Out

1. **Make sure Rojo is running** (`rojo serve` in terminal)
2. **Studio is connected** (green status in Rojo plugin)
3. **Edit a file** - Let's test with a simple change:

Open `src/ReplicatedStorage/Modules/GameConfig.lua` and change:
```lua
GameConfig.MAX_HEALTH = 100
```
to:
```lua
GameConfig.MAX_HEALTH = 150
```

4. **Save the file** (Ctrl+S)
5. **Check Studio** - The change appears instantly!
6. **Change it back** to 100 and save again

## 🔄 Daily Workflow

From now on:

1. **Start Rojo server** (keep terminal open)
   ```bash
   cd C:\Users\nikol\Projects\Roblox
   rojo serve
   ```

2. **Open Studio** and your game

3. **Connect Rojo** (one button click)

4. **Edit code** - I make changes in `src/`

5. **See changes** - Instantly in Studio!

6. **Test** - Press F5 in Studio

## 📝 What Changed?

### Before (Manual Copy):
```
Claude: Edit src/file.lua
You: Read what Claude edited
You: Copy code to Studio manually
You: Paste into Script in Studio
You: Test
```

### After (Rojo):
```
Claude: Edit src/file.lua
Rojo: Auto-sync to Studio ✨
You: Test immediately!
```

## ⚠️ Important Notes

**What Rojo Syncs:**
- ✅ All `.lua` script files
- ✅ Folder structure
- ✅ RemoteEvent/RemoteFunction instances

**What Stays in Studio:**
- 🏗️ Spawn points (Parts you place manually)
- 🗺️ Maps and terrain
- 🎨 Models and tools
- 🔧 Parts and attachments

## 🆘 Quick Troubleshooting

**"rojo: command not found"**
→ Use full path: `C:\Users\nikol\rojo\rojo.exe serve`

**Plugin doesn't appear**
→ Restart Roblox Studio

**Connection failed**
→ Make sure `rojo serve` is running in terminal

**Changes don't appear**
→ Check Rojo connection status is green

## 🎉 Next Steps

Once Rojo is working:
1. I can make changes much faster
2. You can test immediately
3. We'll finish Phase 1 testing
4. Move on to Phase 2 (Movement System)!

---

**Need detailed help?** See `ROJO_SETUP.md` for full documentation.

**Ready to continue?** Let me know when Rojo is connected and we'll test the game!
