--[[
	GameConfig.lua
	Stores all game configuration constants
	Location: ReplicatedStorage > Modules > GameConfig
]]

local GameConfig = {}

-- Round Settings
GameConfig.ROUND_TIME = 600 -- 10 minutes in seconds
GameConfig.INTERMISSION_TIME = 15 -- seconds between rounds
GameConfig.MIN_PLAYERS = 2 -- minimum players to start a round
GameConfig.PRACTICE_MODE = false -- Set to true to bypass player requirement (for solo testing)

-- Team Settings
GameConfig.TEAM_1_NAME = "Red Team"
GameConfig.TEAM_2_NAME = "Blue Team"
GameConfig.TEAM_1_COLOR = Color3.fromRGB(255, 0, 0)
GameConfig.TEAM_2_COLOR = Color3.fromRGB(0, 100, 255)

-- Player Settings
GameConfig.MAX_HEALTH = 100
GameConfig.DEFAULT_WALKSPEED = 16
GameConfig.RUN_SPEED = 24
GameConfig.SPRINT_SPEED = 32
GameConfig.JUMP_POWER = 50
GameConfig.WALL_JUMP_POWER = 75

-- Game Mode Settings
GameConfig.AVAILABLE_MODES = {"TeamDeathmatch", "Domination", "SearchAndDestroy", "Hardpoint"}
GameConfig.GAME_MODE_ROTATION = {"TeamDeathmatch", "Domination", "Hardpoint", "SearchAndDestroy"} -- Order of mode rotation

-- Team Deathmatch
GameConfig.TDM_KILL_LIMIT = 50

-- Domination
GameConfig.DOM_SCORE_LIMIT = 200

-- Search & Destroy
GameConfig.SAD_ROUNDS_TO_WIN = 6 -- first to 6 rounds wins

-- Hardpoint
GameConfig.HP_SCORE_LIMIT = 250
GameConfig.HP_ROTATION_TIME = 60 -- seconds before hardpoint moves

-- Map Settings
GameConfig.AVAILABLE_MAPS = {"JungleRuins", "Mine", "CitySquare", "VirtualMatrix"}

-- Economy Settings
GameConfig.BASE_KILL_SCORE = 100
GameConfig.HEADSHOT_BONUS = 10
GameConfig.LONGSHOT_BONUS = 10
GameConfig.MOVING_KILL_BONUS = 20
GameConfig.MULTIKILL_BONUS_PER_LEVEL = 10  -- Double Kill +10, Triple +20, etc.
GameConfig.LONGSHOT_DISTANCE = 100  -- studs
GameConfig.MULTIKILL_WINDOW = 4  -- seconds between kills to count as multi-kill
GameConfig.SHARDS_PER_SCORE = 0.1  -- Shards = Score / 10

return GameConfig
