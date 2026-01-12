--[[
	MapBuilder_JungleRuins.lua
	ONE-TIME USE SCRIPT: Run this once in Roblox Studio to generate JungleRuins map geometry

	HOW TO USE:
	1. Copy this script into ServerScriptService in Roblox Studio
	2. Press Play (F5)
	3. Wait for "Map generation complete!" message in Output
	4. Stop the game (Shift+F5)
	5. Check Workspace > Maps > JungleRuins > Geometry
	6. Delete this script
	7. Save your place (Ctrl+S)
]]

local Workspace = game:GetService("Workspace")

-- Configuration
local MAP_SIZE = 400
local GROUND_LEVEL = 2 -- Slightly above Y=0 to prevent clipping

-- Color palette
local COLORS = {
	Stone = Color3.fromRGB(163, 162, 165),
	DarkStone = Color3.fromRGB(91, 93, 105),
	Moss = Color3.fromRGB(119, 156, 67),
	DarkGreen = Color3.fromRGB(37, 66, 30),
	LightGreen = Color3.fromRGB(75, 151, 75),
	Sand = Color3.fromRGB(163, 162, 148),
	Water = Color3.fromRGB(12, 84, 92),
	Wood = Color3.fromRGB(91, 60, 40),
}

-- Helper function to create a part
local function CreatePart(name, size, cframe, color, material, parent, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = canCollide ~= false -- Default true unless explicitly false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Main builder function
local function BuildJungleRuinsMap()
	print("[MapBuilder] Starting JungleRuins map generation...")

	-- Ensure Maps folder exists
	local mapsFolder = Workspace:FindFirstChild("Maps")
	if not mapsFolder then
		mapsFolder = Instance.new("Folder")
		mapsFolder.Name = "Maps"
		mapsFolder.Parent = Workspace
	end

	-- Find or create JungleRuins
	local jungleRuins = mapsFolder:FindFirstChild("JungleRuins")
	if not jungleRuins then
		jungleRuins = Instance.new("Folder")
		jungleRuins.Name = "JungleRuins"
		jungleRuins.Parent = mapsFolder
	end

	-- Clear existing Geometry folder
	local geometry = jungleRuins:FindFirstChild("Geometry")
	if geometry then
		print("[MapBuilder] Clearing existing Geometry...")
		geometry:Destroy()
	end

	geometry = Instance.new("Folder")
	geometry.Name = "Geometry"
	geometry.Parent = jungleRuins

	print("[MapBuilder] Building ground plane...")

	-- Create main ground plane
	CreatePart(
		"Ground",
		Vector3.new(MAP_SIZE, 4, MAP_SIZE),
		CFrame.new(0, GROUND_LEVEL - 2, 0),
		COLORS.DarkGreen,
		Enum.Material.Grass,
		geometry,
		true
	)

	-- Add scattered terrain variations (hills)
	for i = 1, 15 do
		local hillSize = Vector3.new(
			math.random(30, 60),
			math.random(2, 6),
			math.random(30, 60)
		)
		local hillX = math.random(-MAP_SIZE/2 + 40, MAP_SIZE/2 - 40)
		local hillZ = math.random(-MAP_SIZE/2 + 40, MAP_SIZE/2 - 40)

		CreatePart(
			"Hill_" .. i,
			hillSize,
			CFrame.new(hillX, GROUND_LEVEL + hillSize.Y/2, hillZ),
			COLORS.LightGreen,
			Enum.Material.Grass,
			geometry,
			true
		)
	end

	print("[MapBuilder] Creating winding stream...")

	-- Create winding stream using flat parts
	local streamSegments = {
		{x = -180, z = -150},
		{x = -140, z = -100},
		{x = -80, z = -80},
		{x = -20, z = -60},
		{x = 40, z = -40},
		{x = 100, z = -20},
		{x = 160, z = 0},
		{x = 180, z = 40},
	}

	for i = 1, #streamSegments - 1 do
		local start = Vector3.new(streamSegments[i].x, GROUND_LEVEL + 0.5, streamSegments[i].z)
		local finish = Vector3.new(streamSegments[i+1].x, GROUND_LEVEL + 0.5, streamSegments[i+1].z)
		local midpoint = (start + finish) / 2
		local length = (finish - start).Magnitude
		local direction = (finish - start).Unit

		-- Create stream segment
		CreatePart(
			"Stream_" .. i,
			Vector3.new(10, 1, length + 5),
			CFrame.new(midpoint, midpoint + direction),
			COLORS.Water,
			Enum.Material.Water,
			geometry,
			false
		)
	end

	print("[MapBuilder] Building LEFT LANE (Long Range Sightline)...")

	-- LEFT LANE: Long sightline corridor
	local leftLaneFolder = Instance.new("Folder")
	leftLaneFolder.Name = "LeftLane_LongRange"
	leftLaneFolder.Parent = geometry

	-- Outer boundary wall
	CreatePart(
		"LeftWall_Outer",
		Vector3.new(6, 14, 320),
		CFrame.new(-195, GROUND_LEVEL + 7, 0),
		COLORS.DarkStone,
		Enum.Material.Slate,
		leftLaneFolder,
		true
	)

	-- Inner corridor wall
	CreatePart(
		"LeftWall_Inner",
		Vector3.new(4, 10, 300),
		CFrame.new(-145, GROUND_LEVEL + 5, 0),
		COLORS.Stone,
		Enum.Material.Brick,
		leftLaneFolder,
		true
	)

	-- Floor for left lane
	CreatePart(
		"LeftLane_Floor",
		Vector3.new(45, 2, 320),
		CFrame.new(-170, GROUND_LEVEL, 0),
		COLORS.Sand,
		Enum.Material.Sand,
		leftLaneFolder,
		true
	)

	-- Pillars for minimal cover
	for z = -140, 140, 70 do
		CreatePart(
			"Pillar_" .. z,
			Vector3.new(5, 16, 5),
			CFrame.new(-170, GROUND_LEVEL + 8, z),
			COLORS.Stone,
			Enum.Material.Brick,
			leftLaneFolder,
			true
		)

		-- Pillar capital (decorative top)
		CreatePart(
			"PillarTop_" .. z,
			Vector3.new(7, 2, 7),
			CFrame.new(-170, GROUND_LEVEL + 17, z),
			COLORS.Moss,
			Enum.Material.Cobblestone,
			leftLaneFolder,
			false
		)
	end

	-- Scattered debris
	for i = 1, 10 do
		local debrisSize = Vector3.new(
			math.random(4, 8),
			math.random(3, 5),
			math.random(4, 8)
		)
		CreatePart(
			"Debris_" .. i,
			debrisSize,
			CFrame.new(
				math.random(-190, -150),
				GROUND_LEVEL + debrisSize.Y/2,
				math.random(-150, 150)
			),
			COLORS.DarkStone,
			Enum.Material.Slate,
			leftLaneFolder,
			true
		)
	end

	print("[MapBuilder] Building RIGHT LANE (Close Quarters Ruins)...")

	-- RIGHT LANE: Dense ruins for CQC
	local rightLaneFolder = Instance.new("Folder")
	rightLaneFolder.Name = "RightLane_CloseQuarters"
	rightLaneFolder.Parent = geometry

	-- Outer boundary wall
	CreatePart(
		"RightWall_Outer",
		Vector3.new(6, 12, 320),
		CFrame.new(195, GROUND_LEVEL + 6, 0),
		COLORS.DarkStone,
		Enum.Material.Slate,
		rightLaneFolder,
		true
	)

	-- Floor for right lane
	CreatePart(
		"RightLane_Floor",
		Vector3.new(50, 2, 320),
		CFrame.new(170, GROUND_LEVEL, 0),
		COLORS.DarkGreen,
		Enum.Material.Grass,
		rightLaneFolder,
		true
	)

	-- Dense ruins (walls and structures)
	for i = 1, 25 do
		local ruinSize = Vector3.new(
			math.random(10, 18),
			math.random(8, 14),
			math.random(10, 18)
		)
		CreatePart(
			"Ruin_" .. i,
			ruinSize,
			CFrame.new(
				math.random(150, 190),
				GROUND_LEVEL + ruinSize.Y/2,
				math.random(-150, 150)
			) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0),
			i % 2 == 0 and COLORS.Stone or COLORS.DarkStone,
			Enum.Material.Brick,
			rightLaneFolder,
			true
		)
	end

	-- Boulders for cover
	for i = 1, 20 do
		local boulderSize = math.random(7, 13)
		local boulder = CreatePart(
			"Boulder_" .. i,
			Vector3.new(boulderSize, boulderSize * 0.9, boulderSize),
			CFrame.new(
				math.random(150, 190),
				GROUND_LEVEL + boulderSize/2,
				math.random(-150, 150)
			),
			COLORS.DarkStone,
			Enum.Material.Slate,
			rightLaneFolder,
			true
		)
		boulder.Shape = Enum.PartType.Ball
	end

	-- Tree trunks (vertical cylinders)
	for i = 1, 12 do
		local treeHeight = math.random(18, 28)
		local trunkDiameter = math.random(2, 4)

		local trunk = CreatePart(
			"TreeTrunk_" .. i,
			Vector3.new(trunkDiameter, treeHeight, trunkDiameter),
			CFrame.new(
				math.random(150, 190),
				GROUND_LEVEL + treeHeight/2,
				math.random(-150, 150)
			),
			COLORS.Wood,
			Enum.Material.Wood,
			rightLaneFolder,
			true
		)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.CFrame = trunk.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- Rotate to be vertical
	end

	-- Tree canopies
	for i = 1, 12 do
		local canopySize = math.random(14, 20)
		local canopy = CreatePart(
			"TreeCanopy_" .. i,
			Vector3.new(canopySize, canopySize * 0.5, canopySize),
			CFrame.new(
				math.random(150, 190),
				GROUND_LEVEL + math.random(22, 30),
				math.random(-150, 150)
			),
			COLORS.DarkGreen,
			Enum.Material.Grass,
			rightLaneFolder,
			false
		)
		canopy.Shape = Enum.PartType.Ball
		canopy.Transparency = 0.3
	end

	print("[MapBuilder] Building MIDDLE LANE (Vertical Central Formation)...")

	-- MIDDLE LANE: Central area with vertical gameplay
	local middleLaneFolder = Instance.new("Folder")
	middleLaneFolder.Name = "MiddleLane_Vertical"
	middleLaneFolder.Parent = geometry

	-- Central raised platform
	CreatePart(
		"CentralPlatform",
		Vector3.new(60, 4, 60),
		CFrame.new(0, GROUND_LEVEL + 20, 0),
		COLORS.Stone,
		Enum.Material.Brick,
		middleLaneFolder,
		true
	)

	-- Ramps to central platform (4 directions)
	local rampData = {
		{x = 0, z = -55, rotY = 0},    -- North
		{x = 0, z = 55, rotY = 180},   -- South
		{x = -55, z = 0, rotY = 90},   -- West
		{x = 55, z = 0, rotY = -90},   -- East
	}

	for i, data in ipairs(rampData) do
		-- Create sloped ramp
		local ramp = CreatePart(
			"Ramp_" .. i,
			Vector3.new(18, 2, 35),
			CFrame.new(data.x, GROUND_LEVEL + 10, data.z),
			COLORS.Stone,
			Enum.Material.Brick,
			middleLaneFolder,
			true
		)
		ramp.CFrame = ramp.CFrame * CFrame.Angles(math.rad(30), math.rad(data.rotY), 0)

		-- Ramp support structure
		CreatePart(
			"RampSupport_" .. i,
			Vector3.new(16, 10, 6),
			CFrame.new(data.x, GROUND_LEVEL + 5, data.z) * CFrame.Angles(0, math.rad(data.rotY), 0),
			COLORS.DarkStone,
			Enum.Material.Slate,
			middleLaneFolder,
			true
		)
	end

	-- Surrounding platforms (hexagonal arrangement)
	for i = 1, 6 do
		local angle = (i - 1) * 60
		local radius = 50
		local x = math.cos(math.rad(angle)) * radius
		local z = math.sin(math.rad(angle)) * radius

		CreatePart(
			"Platform_" .. i,
			Vector3.new(16, 4, 16),
			CFrame.new(x, GROUND_LEVEL + 12, z),
			COLORS.Stone,
			Enum.Material.Brick,
			middleLaneFolder,
			true
		)

		-- Support pillar
		CreatePart(
			"PlatformPillar_" .. i,
			Vector3.new(8, 12, 8),
			CFrame.new(x, GROUND_LEVEL + 6, z),
			COLORS.DarkStone,
			Enum.Material.Slate,
			middleLaneFolder,
			true
		)
	end

	print("[MapBuilder] Building TEAM 1 SPAWN (Ruined Sanctum - North)...")

	-- TEAM 1 SPAWN: Ruined Sanctum
	local team1SpawnFolder = Instance.new("Folder")
	team1SpawnFolder.Name = "Team1Spawn_Sanctum"
	team1SpawnFolder.Parent = geometry

	-- Sanctum floor
	CreatePart(
		"SanctumFloor",
		Vector3.new(80, 3, 60),
		CFrame.new(0, GROUND_LEVEL + 1.5, -185),
		COLORS.Stone,
		Enum.Material.Marble,
		team1SpawnFolder,
		true
	)

	-- Sanctum walls (partially ruined)
	local walls = {
		{name = "LeftWall", size = Vector3.new(6, 18, 60), pos = Vector3.new(-40, GROUND_LEVEL + 9, -185)},
		{name = "RightWall", size = Vector3.new(6, 18, 60), pos = Vector3.new(40, GROUND_LEVEL + 9, -185)},
		{name = "BackWallLeft", size = Vector3.new(32, 18, 6), pos = Vector3.new(-24, GROUND_LEVEL + 9, -213)},
		{name = "BackWallRight", size = Vector3.new(32, 18, 6), pos = Vector3.new(24, GROUND_LEVEL + 9, -213)},
	}

	for _, wall in ipairs(walls) do
		CreatePart(
			wall.name,
			wall.size,
			CFrame.new(wall.pos),
			COLORS.Stone,
			Enum.Material.Brick,
			team1SpawnFolder,
			true
		)
	end

	-- Columns (5 columns in a row)
	for i = -2, 2 do
		CreatePart(
			"Column_" .. i,
			Vector3.new(5, 20, 5),
			CFrame.new(i * 18, GROUND_LEVEL + 10, -185),
			COLORS.Stone,
			Enum.Material.Marble,
			team1SpawnFolder,
			true
		)

		-- Column capital
		CreatePart(
			"Capital_" .. i,
			Vector3.new(7, 3, 7),
			CFrame.new(i * 18, GROUND_LEVEL + 21, -185),
			COLORS.Moss,
			Enum.Material.Cobblestone,
			team1SpawnFolder,
			false
		)
	end

	-- Archway connecting back walls
	CreatePart(
		"Archway",
		Vector3.new(30, 4, 6),
		CFrame.new(0, GROUND_LEVEL + 18, -213),
		COLORS.Stone,
		Enum.Material.Brick,
		team1SpawnFolder,
		false
	)

	-- Scattered debris
	for i = 1, 15 do
		local debrisSize = Vector3.new(
			math.random(4, 10),
			math.random(3, 8),
			math.random(4, 10)
		)
		CreatePart(
			"Debris_" .. i,
			debrisSize,
			CFrame.new(
				math.random(-35, 35),
				GROUND_LEVEL + 3 + debrisSize.Y/2,
				math.random(-210, -160)
			) * CFrame.Angles(
				math.rad(math.random(-15, 15)),
				math.rad(math.random(0, 360)),
				math.rad(math.random(-15, 15))
			),
			COLORS.DarkStone,
			Enum.Material.Slate,
			team1SpawnFolder,
			true
		)
	end

	print("[MapBuilder] Building TEAM 2 SPAWN (Archaeologist Camp - South)...")

	-- TEAM 2 SPAWN: Archaeologist Base Camp
	local team2SpawnFolder = Instance.new("Folder")
	team2SpawnFolder.Name = "Team2Spawn_Camp"
	team2SpawnFolder.Parent = geometry

	-- Camp platform (wooden floor)
	CreatePart(
		"CampFloor",
		Vector3.new(70, 3, 55),
		CFrame.new(0, GROUND_LEVEL + 1.5, 185),
		COLORS.Wood,
		Enum.Material.Wood,
		team2SpawnFolder,
		true
	)

	-- Supply crates
	for i = 1, 12 do
		local crateSize = Vector3.new(
			math.random(5, 8),
			math.random(5, 8),
			math.random(5, 8)
		)
		CreatePart(
			"Crate_" .. i,
			crateSize,
			CFrame.new(
				math.random(-30, 30),
				GROUND_LEVEL + 3 + crateSize.Y/2,
				math.random(165, 205)
			) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0),
			COLORS.Wood,
			Enum.Material.Wood,
			team2SpawnFolder,
			true
		)
	end

	-- Tent structures
	local tents = {
		{x = -22, z = 178},
		{x = 0, z = 192},
		{x = 22, z = 178},
	}

	for i, tent in ipairs(tents) do
		-- Tent poles (4 corners)
		for px = -1, 1, 2 do
			for pz = -1, 1, 2 do
				CreatePart(
					"TentPole_" .. i .. "_" .. px .. pz,
					Vector3.new(0.7, 10, 0.7),
					CFrame.new(tent.x + px * 6, GROUND_LEVEL + 8, tent.z + pz * 6),
					COLORS.Wood,
					Enum.Material.Wood,
					team2SpawnFolder,
					false
				)
			end
		end

		-- Tent canvas roof (wedge-shaped would be better, but using part for simplicity)
		CreatePart(
			"TentRoof_" .. i,
			Vector3.new(14, 1, 14),
			CFrame.new(tent.x, GROUND_LEVEL + 13, tent.z),
			COLORS.Sand,
			Enum.Material.Fabric,
			team2SpawnFolder,
			false
		).Transparency = 0.1
	end

	-- Excavation table
	CreatePart(
		"ExcavationTable",
		Vector3.new(10, 1.5, 5),
		CFrame.new(12, GROUND_LEVEL + 4.25, 185),
		COLORS.Wood,
		Enum.Material.Wood,
		team2SpawnFolder,
		true
	)

	-- Sandbag barriers
	for i = 1, 10 do
		CreatePart(
			"Sandbag_" .. i,
			Vector3.new(8, 3, 4),
			CFrame.new(
				math.random(-32, 32),
				GROUND_LEVEL + 4.5,
				math.random(158, 168)
			) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0),
			COLORS.Sand,
			Enum.Material.Sand,
			team2SpawnFolder,
			true
		)
	end

	-- Lighting poles
	for i = -1, 1 do
		local pole = CreatePart(
			"LightPole_" .. i,
			Vector3.new(1.2, 18, 1.2),
			CFrame.new(i * 28, GROUND_LEVEL + 12, 185),
			COLORS.DarkStone,
			Enum.Material.Metal,
			team2SpawnFolder,
			false
		)

		-- Add spotlight
		local light = Instance.new("SpotLight")
		light.Brightness = 6
		light.Range = 50
		light.Angle = 80
		light.Face = Enum.NormalId.Bottom
		light.Color = Color3.fromRGB(255, 240, 200)
		light.Parent = pole
	end

	print("[MapBuilder] Adding environmental details...")

	-- Environmental Details
	local envDetails = Instance.new("Folder")
	envDetails.Name = "EnvironmentalDetails"
	envDetails.Parent = geometry

	-- Scattered broken pillars
	for i = 1, 20 do
		local pillarHeight = math.random(6, 15)
		CreatePart(
			"BrokenPillar_" .. i,
			Vector3.new(4, pillarHeight, 4),
			CFrame.new(
				math.random(-170, 170),
				GROUND_LEVEL + pillarHeight/2,
				math.random(-170, 170)
			) * CFrame.Angles(
				math.rad(math.random(-10, 10)),
				0,
				math.rad(math.random(-10, 10))
			),
			COLORS.Stone,
			Enum.Material.Brick,
			envDetails,
			true
		)
	end

	-- Ruined arches
	for i = 1, 6 do
		local archX = math.random(-140, 140)
		local archZ = math.random(-140, 140)

		-- Left pillar
		CreatePart(
			"ArchLeft_" .. i,
			Vector3.new(4, 12, 4),
			CFrame.new(archX - 8, GROUND_LEVEL + 6, archZ),
			COLORS.Stone,
			Enum.Material.Brick,
			envDetails,
			true
		)

		-- Right pillar
		CreatePart(
			"ArchRight_" .. i,
			Vector3.new(4, 12, 4),
			CFrame.new(archX + 8, GROUND_LEVEL + 6, archZ),
			COLORS.Stone,
			Enum.Material.Brick,
			envDetails,
			true
		)

		-- Arch top (partial/broken)
		CreatePart(
			"ArchTop_" .. i,
			Vector3.new(20, 3, 4),
			CFrame.new(archX, GROUND_LEVEL + 13, archZ) * CFrame.Angles(0, 0, math.rad(math.random(-20, 20))),
			COLORS.Moss,
			Enum.Material.Cobblestone,
			envDetails,
			false
		)
	end

	-- Moss-covered rocks
	for i = 1, 40 do
		local rockSize = math.random(3, 7)
		local rock = CreatePart(
			"Rock_" .. i,
			Vector3.new(rockSize, rockSize * 0.6, rockSize),
			CFrame.new(
				math.random(-190, 190),
				GROUND_LEVEL + rockSize/3,
				math.random(-190, 190)
			) * CFrame.Angles(
				math.rad(math.random(0, 360)),
				math.rad(math.random(0, 360)),
				math.rad(math.random(0, 360))
			),
			i % 3 == 0 and COLORS.Moss or COLORS.DarkStone,
			Enum.Material.Slate,
			envDetails,
			true
		)
		rock.Shape = Enum.PartType.Ball
	end

	print("[MapBuilder] ========================================")
	print("[MapBuilder] MAP GENERATION COMPLETE!")
	print("[MapBuilder] ========================================")
	print("[MapBuilder] Location: Workspace > Maps > JungleRuins > Geometry")
	print("[MapBuilder] Next steps:")
	print("[MapBuilder]   1. Stop the game (Shift+F5)")
	print("[MapBuilder]   2. Inspect the map in Workspace")
	print("[MapBuilder]   3. Delete this script")
	print("[MapBuilder]   4. Save your place (Ctrl+S)")
	print("[MapBuilder] ========================================")
end

-- Run the builder with error handling
wait(0.5) -- Small delay to ensure workspace is ready
local success, errorMsg = pcall(BuildJungleRuinsMap)

if not success then
	warn("[MapBuilder] ========================================")
	warn("[MapBuilder] ERROR GENERATING MAP!")
	warn("[MapBuilder] " .. tostring(errorMsg))
	warn("[MapBuilder] ========================================")
else
	print("[MapBuilder] Build completed successfully!")
end
