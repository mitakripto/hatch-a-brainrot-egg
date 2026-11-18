-- WorldBuilder: builds the whole 3D world out of plain Parts at server start.
-- Spawn plaza, the egg hatchery with its pedestals, eight player base plots
-- in a ring, paths, fences, trees and decorations. Everything is anchored.
-- It also hands out the positions other services need: pedestal tops and
-- the six brainrot slots of every plot.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local WorldBuilder = {}

WorldBuilder.pedestalTops = {} -- [eggTierId] = Vector3 (top of the pedestal)
WorldBuilder.plotSlots = {} -- [plotIndex][slotIndex] = Vector3 (floor position)
WorldBuilder.plotCenters = {} -- [plotIndex] = Vector3 (center of the plot)
WorldBuilder.plotSigns = {} -- [plotIndex] = TextLabel (owner name sign)

local workspaceFolder = nil

local function makePart(name, size, color, position, shape, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = true
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Parent = workspaceFolder
	return part
end

local function makeLabelPart(name, size, color, position, text, textColor, textSize)
	local part = makePart(name, size, color, position)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Sign"
	surface.Face = Enum.NormalId.Top
	surface.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = surface
	return part, label
end

function WorldBuilder.buildPlaza()
	-- A round-ish plaza of coloured tiles around the spawn.
	makePart("PlazaFloor", Vector3.new(36, 1, 36), Color3.fromRGB(220, 200, 160), Vector3.new(0, 0.5, 10))
	makePart("PlazaCenter", Vector3.new(14, 1.2, 14), Color3.fromRGB(255, 220, 120), Vector3.new(0, 0.6, 10))
	makePart("PlazaRing", Vector3.new(20, 1.1, 20), Color3.fromRGB(140, 200, 255), Vector3.new(0, 0.55, 10))
	-- A giant egg statue in the middle of the plaza.
	local statue = makePart(
		"GiantEgg",
		Vector3.new(6, 8, 6),
		Color3.fromRGB(255, 240, 200),
		Vector3.new(0, 5.2, 10),
		Enum.PartType.Ball
	)
	statue.Material = Enum.Material.Marble
	makePart("StatueBase", Vector3.new(9, 1, 9), Color3.fromRGB(120, 120, 130), Vector3.new(0, 0.5, 10))
	local _, sign = makeLabelPart(
		"WelcomeSign",
		Vector3.new(10, 4, 0.5),
		Color3.fromRGB(60, 90, 200),
		Vector3.new(0, 3.5, -9),
		"HATCH A\nBRAINROT EGG",
		Color3.fromRGB(255, 255, 255),
		24
	)
	sign.Parent.Face = Enum.NormalId.Back
end

function WorldBuilder.buildHatchery()
	-- Five pedestals in an arc north of the plaza, one per egg tier.
	local tiers = BrainrotData.EggTiers
	local colors = {
		Speckled = Color3.fromRGB(230, 210, 170),
		Striped = Color3.fromRGB(150, 200, 255),
		Crystal = Color3.fromRGB(180, 140, 255),
		Void = Color3.fromRGB(80, 40, 140),
		Golden = Color3.fromRGB(255, 200, 40),
	}
	local arcCenter = Vector3.new(0, 0, -18)
	for index, tier in ipairs(tiers) do
		local angle = math.rad(-60 + (index - 1) * 30)
		local x = arcCenter.X + math.sin(angle) * 16
		local z = arcCenter.Z + math.cos(angle) * 8
		local basePosition = Vector3.new(x, 0, z)
		makePart("PedestalBase" .. tier.id, Vector3.new(4, 1, 4), Color3.fromRGB(150, 150, 160), basePosition + Vector3.new(0, 0.5, 0))
		makePart("Pedestal" .. tier.id, Vector3.new(2.5, 2, 2.5), colors[tier.id], basePosition + Vector3.new(0, 2, 0))
		WorldBuilder.pedestalTops[tier.id] = basePosition + Vector3.new(0, 3, 0)
		local _, label = makeLabelPart(
			"PedestalSign" .. tier.id,
			Vector3.new(4, 2, 0.4),
			Color3.fromRGB(50, 50, 60),
			basePosition + Vector3.new(0, 1.6, 2.4),
			tier.name .. "\n" .. tier.price .. " coins",
			Color3.fromRGB(255, 255, 255),
			18
		)
		label.Parent.Face = Enum.NormalId.Back
	end
	makePart("HatcheryFloor", Vector3.new(40, 1, 16), Color3.fromRGB(200, 170, 220), Vector3.new(0, 0.5, -18))
end

function WorldBuilder.buildPlots()
	-- Eight plots in a ring around the plaza, each with six slots.
	local plotColors = {
		Color3.fromRGB(255, 150, 150),
		Color3.fromRGB(150, 255, 150),
		Color3.fromRGB(150, 150, 255),
		Color3.fromRGB(255, 255, 150),
		Color3.fromRGB(255, 150, 255),
		Color3.fromRGB(150, 255, 255),
		Color3.fromRGB(255, 200, 150),
		Color3.fromRGB(200, 150, 255),
	}
	for index = 1, BrainrotData.PlotCount do
		local angle = math.rad((index - 1) * 45)
		local center = Vector3.new(math.sin(angle) * 48, 0, 10 + math.cos(angle) * 48)
		WorldBuilder.plotCenters[index] = center
		makePart("PlotFloor" .. index, Vector3.new(18, 1, 18), plotColors[index], center + Vector3.new(0, 0.5, 0))
		-- Low fence on three sides, open toward the plaza.
		local fenceColor = Color3.fromRGB(120, 90, 50)
		makePart("FenceBack" .. index, Vector3.new(18, 2, 0.5), fenceColor, center + Vector3.new(0, 1.5, -9))
		-- Fence posts around the edge.
		for side = -1, 1, 2 do
			makePart(
				"FenceSide" .. index .. "_" .. side,
				Vector3.new(0.5, 2, 18),
				fenceColor,
				center + Vector3.new(side * 9, 1.5, 0)
			)
		end
		-- Six slot pads in two rows of three.
		WorldBuilder.plotSlots[index] = {}
		for slot = 1, BrainrotData.BaseSlotsPerPlot do
			local row = math.floor((slot - 1) / 3)
			local col = (slot - 1) % 3
			local slotPosition = center + Vector3.new((col - 1) * 5, 1, (row - 0.5) * 5 + 1)
			makePart(
				"SlotPad" .. index .. "_" .. slot,
				Vector3.new(3.5, 0.4, 3.5),
				Color3.fromRGB(255, 255, 255),
				slotPosition
			)
			WorldBuilder.plotSlots[index][slot] = slotPosition + Vector3.new(0, 0.2, 0)
		end
		-- Owner sign on a post at the front of the plot. A billboard, so it
		-- reads from every direction around the ring.
		local signPost = makePart(
			"PlotSignPost" .. index,
			Vector3.new(0.6, 5, 0.6),
			Color3.fromRGB(80, 60, 40),
			center + Vector3.new(0, 2.5, 9.5)
		)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "PlotSign"
		billboard.Size = UDim2.new(0, 240, 0, 100)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
		billboard.AlwaysOnTop = true
		local signLabel = Instance.new("TextLabel")
		signLabel.Size = UDim2.new(1, 0, 1, 0)
		signLabel.BackgroundTransparency = 1
		signLabel.Text = "BASE " .. index .. "\n(empty)"
		signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		signLabel.TextStrokeTransparency = 0.2
		signLabel.TextScaled = true
		signLabel.Font = Enum.Font.SourceSansBold
		signLabel.Parent = billboard
		billboard.Parent = signPost
		WorldBuilder.plotSigns[index] = signLabel
	end
end

function WorldBuilder.buildPathsAndTrees()
	-- Paths from the plaza out to each plot.
	for index = 1, BrainrotData.PlotCount do
		local center = WorldBuilder.plotCenters[index]
		local direction = (center - Vector3.new(0, 0, 10))
		local distance = direction.Magnitude
		local midpoint = Vector3.new(0, 0, 10) + direction * 0.5
		local path = makePart(
			"Path" .. index,
			Vector3.new(4, 0.2, distance),
			Color3.fromRGB(210, 190, 150),
			Vector3.new(midpoint.X, 0.1, midpoint.Z)
		)
		path.CFrame = CFrame.new(midpoint.X, 0.1, midpoint.Z)
			* CFrame.Angles(0, math.atan2(direction.X, direction.Z), 0)
	end
	-- Trees dotted around the ring.
	local treeSpots = {
		Vector3.new(20, 0, -30), Vector3.new(-24, 0, -26), Vector3.new(34, 0, 30),
		Vector3.new(-34, 0, 34), Vector3.new(10, 0, 52), Vector3.new(-14, 0, 54),
		Vector3.new(52, 0, -8), Vector3.new(-52, 0, -6), Vector3.new(30, 0, -44),
		Vector3.new(-30, 0, -46),
	}
	for index, spot in ipairs(treeSpots) do
		makePart("TreeTrunk" .. index, Vector3.new(1.2, 4, 1.2), Color3.fromRGB(120, 80, 40), spot + Vector3.new(0, 2, 0))
		makePart(
			"TreeLeaves" .. index,
			Vector3.new(4.5, 4.5, 4.5),
			Color3.fromRGB(60, 180, 80),
			spot + Vector3.new(0, 6, 0),
			Enum.PartType.Ball
		)
	end
	-- Lamp posts around the plaza.
	for index = 1, 6 do
		local angle = math.rad((index - 1) * 60)
		local spot = Vector3.new(math.sin(angle) * 20, 0, 10 + math.cos(angle) * 20)
		makePart("LampPost" .. index, Vector3.new(0.6, 5, 0.6), Color3.fromRGB(60, 60, 70), spot + Vector3.new(0, 2.5, 0))
		local bulb = makePart(
			"LampBulb" .. index,
			Vector3.new(1.4, 1.4, 1.4),
			Color3.fromRGB(255, 240, 150),
			spot + Vector3.new(0, 5.5, 0),
			Enum.PartType.Ball
		)
		bulb.Material = Enum.Material.Neon
	end
end

function WorldBuilder.buildWorld()
	workspaceFolder = Instance.new("Folder")
	workspaceFolder.Name = "HatchWorld"
	workspaceFolder.Parent = game:GetService("Workspace")
	WorldBuilder.buildPlaza()
	WorldBuilder.buildHatchery()
	WorldBuilder.buildPlots()
	WorldBuilder.buildPathsAndTrees()
end

function WorldBuilder.setPlotOwnerName(plotIndex, ownerName)
	local label = WorldBuilder.plotSigns[plotIndex]
	if label then
		label.Text = "BASE " .. plotIndex .. "\n" .. ownerName
	end
end

function WorldBuilder.clearPlotOwnerName(plotIndex)
	local label = WorldBuilder.plotSigns[plotIndex]
	if label then
		label.Text = "BASE " .. plotIndex .. "\n(empty)"
	end
end

return WorldBuilder
