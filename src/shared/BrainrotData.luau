-- BrainrotData: the whole cast of Hatch a Brainrot Egg.
-- Every character here is invented for this game: an absurd little creature
-- with its own name, rarity, income rate and blocky look. Both the server
-- (hatching, income) and the client (rarity guide) read this one module.

local BrainrotData = {}

-- Rarity ladder, cheapest first. Weight is the share of a hatch roll.
BrainrotData.Rarities = {
	Common = { weight = 55, color = Color3.fromRGB(120, 200, 120), label = "COMMON" },
	Rare = { weight = 26, color = Color3.fromRGB(90, 160, 255), label = "RARE" },
	Epic = { weight = 12, color = Color3.fromRGB(190, 110, 255), label = "EPIC" },
	Legendary = { weight = 5, color = Color3.fromRGB(255, 190, 40), label = "LEGENDARY" },
	Mythic = { weight = 2, color = Color3.fromRGB(255, 80, 160), label = "MYTHIC" },
}

-- Mutations roll on top of every hatch. They multiply the income rate.
BrainrotData.Mutations = {
	None = { chance = 0, multiplier = 1, label = "" },
	Golden = { chance = 0.05, multiplier = 3, label = "GOLDEN" },
	Rainbow = { chance = 0.015, multiplier = 8, label = "RAINBOW" },
}

-- The cast: 12 original characters. bodyColor is the main block color,
-- accentColor the trim, shape picks the silhouette the factory builds.
BrainrotData.Characters = {
	{
		id = "SirSlurpsalot",
		name = "Sir Slurpsalot",
		rarity = "Common",
		coinsPerSecond = 5,
		bodyColor = Color3.fromRGB(255, 220, 100),
		accentColor = Color3.fromRGB(200, 60, 60),
		shape = "tall",
		blurb = "A noodle knight who duels with a fork.",
	},
	{
		id = "ToasterToad",
		name = "Toaster Toad",
		rarity = "Common",
		coinsPerSecond = 8,
		bodyColor = Color3.fromRGB(180, 180, 190),
		accentColor = Color3.fromRGB(255, 140, 40),
		shape = "wide",
		blurb = "Ribbits, then pops up perfectly browned.",
	},
	{
		id = "CaptainCrumb",
		name = "Captain Crumb",
		rarity = "Common",
		coinsPerSecond = 12,
		bodyColor = Color3.fromRGB(200, 150, 90),
		accentColor = Color3.fromRGB(40, 60, 140),
		shape = "tall",
		blurb = "A biscuit pirate hunting the lost jam.",
	},
	{
		id = "DJPickle",
		name = "DJ Pickle",
		rarity = "Rare",
		coinsPerSecond = 25,
		bodyColor = Color3.fromRGB(90, 190, 80),
		accentColor = Color3.fromRGB(255, 220, 40),
		shape = "tall",
		blurb = "Drops beats and brine in equal measure.",
	},
	{
		id = "WaffleWizard",
		name = "Waffle Wizard",
		rarity = "Rare",
		coinsPerSecond = 35,
		bodyColor = Color3.fromRGB(220, 170, 90),
		accentColor = Color3.fromRGB(120, 60, 200),
		shape = "wide",
		blurb = "Casts syrup spells from a gridiron tower.",
	},
	{
		id = "ProfessorPigeon",
		name = "Professor Pigeon",
		rarity = "Rare",
		coinsPerSecond = 45,
		bodyColor = Color3.fromRGB(150, 160, 180),
		accentColor = Color3.fromRGB(255, 255, 255),
		shape = "small",
		blurb = "Holds a tiny chair in crumb economics.",
	},
	{
		id = "LlamaDrama",
		name = "Llama Drama",
		rarity = "Epic",
		coinsPerSecond = 90,
		bodyColor = Color3.fromRGB(255, 180, 220),
		accentColor = Color3.fromRGB(255, 255, 255),
		shape = "tall",
		blurb = "Faints theatrically at the smallest slight.",
	},
	{
		id = "QuantumQuokka",
		name = "Quantum Quokka",
		rarity = "Epic",
		coinsPerSecond = 120,
		bodyColor = Color3.fromRGB(140, 110, 80),
		accentColor = Color3.fromRGB(80, 220, 220),
		shape = "small",
		blurb = "Smiles in two places at once.",
	},
	{
		id = "BarkTwain",
		name = "Bark Twain",
		rarity = "Epic",
		coinsPerSecond = 150,
		bodyColor = Color3.fromRGB(200, 140, 70),
		accentColor = Color3.fromRGB(60, 60, 60),
		shape = "wide",
		blurb = "A poet hound. Every howl is a sonnet.",
	},
	{
		id = "EmperorEggbert",
		name = "Emperor Eggbert",
		rarity = "Legendary",
		coinsPerSecond = 350,
		bodyColor = Color3.fromRGB(255, 240, 180),
		accentColor = Color3.fromRGB(255, 180, 0),
		shape = "wide",
		blurb = "Rules the hatchery from a golden nest.",
	},
	{
		id = "BaronVonBubble",
		name = "Baron von Bubble",
		rarity = "Legendary",
		coinsPerSecond = 500,
		bodyColor = Color3.fromRGB(150, 220, 255),
		accentColor = Color3.fromRGB(255, 255, 255),
		shape = "tall",
		blurb = "Floats above it all. Literally. Always.",
	},
	{
		id = "ChronoCroissant",
		name = "Chrono Croissant",
		rarity = "Mythic",
		coinsPerSecond = 1500,
		bodyColor = Color3.fromRGB(230, 180, 90),
		accentColor = Color3.fromRGB(255, 80, 160),
		shape = "wide",
		blurb = "A time-travelling pastry. Tastes like tomorrow.",
	},
}

-- Egg tiers sold at the hatchery. minRebirths gates the Void Egg behind a rebirth.
BrainrotData.EggTiers = {
	{ id = "Speckled", name = "Speckled Egg", price = 50, minRebirths = 0, luckBoost = 0 },
	{ id = "Striped", name = "Striped Egg", price = 250, minRebirths = 0, luckBoost = 1 },
	{ id = "Crystal", name = "Crystal Egg", price = 1000, minRebirths = 0, luckBoost = 2 },
	{ id = "Void", name = "Void Egg", price = 5000, minRebirths = 1, luckBoost = 4 },
	{ id = "Golden", name = "Golden Egg", price = 1500, minRebirths = 0, luckBoost = 3, eventOnly = true },
}

BrainrotData.StartingCoins = 100
BrainrotData.RebirthCost = 10000
BrainrotData.RebirthMultiplierStep = 0.5 -- each rebirth adds +50% income
BrainrotData.BaseSlotsPerPlot = 6
BrainrotData.PlotCount = 8
BrainrotData.LockDurationSeconds = 60
BrainrotData.LockCooldownSeconds = 120
BrainrotData.EggRushIntervalSeconds = 240
BrainrotData.EggRushDurationSeconds = 60

function BrainrotData.getCharacterById(id)
	for _, character in ipairs(BrainrotData.Characters) do
		if character.id == id then
			return character
		end
	end
	return nil
end

function BrainrotData.getCharactersOfRarity(rarity)
	local found = {}
	for _, character in ipairs(BrainrotData.Characters) do
		if character.rarity == rarity then
			table.insert(found, character)
		end
	end
	return found
end

function BrainrotData.getEggTierById(id)
	for _, tier in ipairs(BrainrotData.EggTiers) do
		if tier.id == id then
			return tier
		end
	end
	return nil
end

-- Weighted rarity roll. luckBoost nudges the roll toward rarer tiers.
function BrainrotData.rollRarity(luckBoost, rushActive)
	local order = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
	local total = 0
	local weights = {}
	for index, rarity in ipairs(order) do
		local weight = BrainrotData.Rarities[rarity].weight
		-- Each luck point shifts weight upward one rung for the top rarities.
		local boost = math.min(luckBoost, index - 1)
		weight = weight * (1 + 0.5 * boost)
		if rushActive and index >= 3 then
			weight = weight * 2
		end
		weights[index] = weight
		total += weight
	end
	local roll = math.random() * total
	local running = 0
	for index, rarity in ipairs(order) do
		running += weights[index]
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

function BrainrotData.rollMutation()
	local roll = math.random()
	if roll < BrainrotData.Mutations.Rainbow.chance then
		return "Rainbow"
	elseif roll < BrainrotData.Mutations.Rainbow.chance + BrainrotData.Mutations.Golden.chance then
		return "Golden"
	end
	return "None"
end

function BrainrotData.rollCharacter(luckBoost, rushActive)
	local rarity = BrainrotData.rollRarity(luckBoost, rushActive)
	local pool = BrainrotData.getCharactersOfRarity(rarity)
	local character = pool[math.random(#pool)]
	local mutation = BrainrotData.rollMutation()
	return character, mutation
end

function BrainrotData.incomePerSecond(character, mutation)
	local multiplier = BrainrotData.Mutations[mutation].multiplier
	return character.coinsPerSecond * multiplier
end

return BrainrotData
