-- BrainrotFactory: builds each brainrot as a blocky figure out of plain Parts.
-- No external assets: body, head, eyes, feet and a little hat or accessory,
-- plus a floating label with the name, rarity and money-per-second.
-- Shapes: "tall" is a long body, "wide" is short and broad, "small" is tiny.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function makePart(name, size, color, position, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	return part
end

local function addEyes(model, headPosition, headSize, spacing, eyeSize)
	local leftEye = makePart(
		"EyeLeft",
		Vector3.new(eyeSize, eyeSize, 0.2),
		Color3.fromRGB(20, 20, 20),
		headPosition + Vector3.new(-spacing, headSize.Y * 0.15, headSize.Z / 2 + 0.1)
	)
	local rightEye = makePart(
		"EyeRight",
		Vector3.new(eyeSize, eyeSize, 0.2),
		Color3.fromRGB(20, 20, 20),
		headPosition + Vector3.new(spacing, headSize.Y * 0.15, headSize.Z / 2 + 0.1)
	)
	leftEye.Parent = model
	rightEye.Parent = model
end

local function addLabel(model, character, mutation, topY)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 220, 0, 90)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, topY + 1.2, 0)
	billboard.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = billboard

	local rarity = BrainrotData.Rarities[character.rarity]
	local mutationText = ""
	if mutation ~= "None" then
		mutationText = " " .. BrainrotData.Mutations[mutation].label
	end
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.5, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = string.format(
		"%s%s  |  %d/s",
		rarity.label,
		mutationText,
		BrainrotData.incomePerSecond(character, mutation)
	)
	rateLabel.TextColor3 = rarity.color
	rateLabel.TextStrokeTransparency = 0.2
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.Parent = billboard

	billboard.Parent = model
end

-- Builds the figure at a floor position (the feet sit on floorY).
function BrainrotFactory.buildBrainrotModel(character, mutation, floorPosition)
	local model = Instance.new("Model")
	model.Name = character.id

	local bodyColor = character.bodyColor
	local accentColor = character.accentColor
	if mutation == "Golden" then
		bodyColor = Color3.fromRGB(255, 200, 40)
		accentColor = Color3.fromRGB(255, 240, 150)
	elseif mutation == "Rainbow" then
		bodyColor = Color3.fromRGB(140, 90, 255)
		accentColor = Color3.fromRGB(90, 255, 200)
	end

	local bodySize
	local headSize
	local headOffsetY
	if character.shape == "tall" then
		bodySize = Vector3.new(1.4, 2.2, 1.4)
		headSize = Vector3.new(1.6, 1.2, 1.6)
		headOffsetY = 1.7
	elseif character.shape == "wide" then
		bodySize = Vector3.new(2.4, 1.4, 2.0)
		headSize = Vector3.new(1.8, 1.2, 1.8)
		headOffsetY = 1.3
	else
		bodySize = Vector3.new(1.0, 1.0, 1.0)
		headSize = Vector3.new(1.2, 0.9, 1.2)
		headOffsetY = 0.95
	end

	local bodyPosition = floorPosition + Vector3.new(0, bodySize.Y / 2, 0)
	local body = makePart("Body", bodySize, bodyColor, bodyPosition)
	body.Parent = model

	local headPosition = floorPosition + Vector3.new(0, bodySize.Y + headSize.Y / 2 + 0.1, 0)
	local head = makePart("Head", headSize, bodyColor, headPosition, Enum.PartType.Ball)
	head.Parent = model

	addEyes(model, headPosition, headSize, headSize.X * 0.22, 0.28)

	-- Feet: two little blocks under the body.
	local footLeft = makePart(
		"FootLeft",
		Vector3.new(0.5, 0.3, 0.8),
		accentColor,
		floorPosition + Vector3.new(-bodySize.X * 0.25, 0.15, 0.1)
	)
	local footRight = makePart(
		"FootRight",
		Vector3.new(0.5, 0.3, 0.8),
		accentColor,
		floorPosition + Vector3.new(bodySize.X * 0.25, 0.15, 0.1)
	)
	footLeft.Parent = model
	footRight.Parent = model

	-- A little hat or crown on top, so silhouettes differ at a glance.
	local hat = makePart(
		"Hat",
		Vector3.new(headSize.X * 0.7, 0.35, headSize.Z * 0.7),
		accentColor,
		headPosition + Vector3.new(0, headSize.Y / 2 + 0.15, 0)
	)
	hat.Parent = model

	local topY = bodySize.Y + headSize.Y + 0.5
	addLabel(model, character, mutation, topY)

	-- A primary part so the whole figure can be moved as one.
	model.PrimaryPart = body
	return model
end

-- Builds a decorative egg: a squashed sphere on a small nest ring.
function BrainrotFactory.buildEggModel(eggColor, floorPosition, scale)
	local model = Instance.new("Model")
	model.Name = "Egg"
	scale = scale or 1
	local egg = makePart(
		"Shell",
		Vector3.new(1.6 * scale, 2.0 * scale, 1.6 * scale),
		eggColor,
		floorPosition + Vector3.new(0, 1.0 * scale, 0),
		Enum.PartType.Ball
	)
	egg.Parent = model
	local nest = makePart(
		"Nest",
		Vector3.new(2.2 * scale, 0.3, 2.2 * scale),
		Color3.fromRGB(140, 100, 60),
		floorPosition + Vector3.new(0, 0.15, 0),
		Enum.PartType.Cylinder
	)
	nest.Parent = model
	model.PrimaryPart = egg
	return model
end

return BrainrotFactory
