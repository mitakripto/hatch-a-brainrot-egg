-- HatcheryService: runs the egg pedestals. Each pedestal holds one egg at a
-- time; hatching it (via its ProximityPrompt) spends coins, rolls a random
-- brainrot from the cast, and places it on the player's base. Eggs regrow
-- on empty pedestals after a short delay, and the Golden Egg pedestal only
-- stocks during an Egg Rush.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GameState = require(script.Parent:WaitForChild("GameState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local HatcheryService = {}

local EGG_REGROW_SECONDS = 10
local EGG_COLORS = {
	Speckled = Color3.fromRGB(230, 210, 170),
	Striped = Color3.fromRGB(150, 200, 255),
	Crystal = Color3.fromRGB(180, 140, 255),
	Void = Color3.fromRGB(80, 40, 140),
	Golden = Color3.fromRGB(255, 200, 40),
}

-- pedestals[tierId] = { prompt = ProximityPrompt, eggModel = Model | nil, stocked = boolean }
HatcheryService.pedestals = {}
HatcheryService.hatchResultEvent = nil

function HatcheryService.setHatchResultEvent(remoteEvent)
	HatcheryService.hatchResultEvent = remoteEvent
end

function HatcheryService.stockEgg(tierId)
	local pedestal = HatcheryService.pedestals[tierId]
	if not pedestal or pedestal.stocked then
		return
	end
	local top = WorldBuilder.pedestalTops[tierId]
	if not top then
		return
	end
	local eggModel = BrainrotFactory.buildEggModel(EGG_COLORS[tierId], top, 1)
	eggModel.Parent = game:GetService("Workspace"):WaitForChild("HatchWorld")
	pedestal.eggModel = eggModel
	pedestal.stocked = true
	pedestal.prompt.Enabled = true
end

function HatcheryService.clearEgg(tierId)
	local pedestal = HatcheryService.pedestals[tierId]
	if not pedestal then
		return
	end
	if pedestal.eggModel then
		pedestal.eggModel:Destroy()
		pedestal.eggModel = nil
	end
	pedestal.stocked = false
	pedestal.prompt.Enabled = false
end

function HatcheryService.scheduleRegrow(tierId)
	task.delay(EGG_REGROW_SECONDS, function()
		local tier = BrainrotData.getEggTierById(tierId)
		if tier and tier.eventOnly and not GameState.eggRushActive then
			return
		end
		HatcheryService.stockEgg(tierId)
	end)
end

function HatcheryService.hatchEgg(player, tierId)
	local tier = BrainrotData.getEggTierById(tierId)
	if not tier then
		return false, "Unknown egg."
	end
	local pedestal = HatcheryService.pedestals[tierId]
	if not pedestal or not pedestal.stocked then
		return false, "No egg on that pedestal right now."
	end
	if tier.eventOnly and not GameState.eggRushActive then
		return false, "The Golden Egg only appears during an Egg Rush."
	end
	local record = GameState.getPlayerRecord(player)
	if not record then
		return false, "You have no base yet."
	end
	if record.rebirths < tier.minRebirths then
		return false, "This egg needs " .. tier.minRebirths .. " rebirth first."
	end
	if not record.plotIndex then
		return false, "You have no base plot."
	end
	local plot = GameState.plots[record.plotIndex]
	local hasFreeSlot = false
	for slot = 1, BrainrotData.BaseSlotsPerPlot do
		if plot.slots[slot] == nil then
			hasFreeSlot = true
			break
		end
	end
	if not hasFreeSlot then
		return false, "Your base is full (6 brainrots)."
	end
	if not GameState.spendCoins(player, tier.price) then
		return false, "Not enough coins for the " .. tier.name .. "."
	end
	local character, mutation = BrainrotData.rollCharacter(tier.luckBoost, GameState.eggRushActive)
	local brainrot = GameState.addBrainrot(player, character, mutation)
	if not brainrot then
		GameState.addCoins(player, tier.price)
		return false, "Your base is full (6 brainrots)."
	end
	BaseService.placeBrainrotModel(brainrot)
	HatcheryService.clearEgg(tierId)
	HatcheryService.scheduleRegrow(tierId)
	if HatcheryService.hatchResultEvent then
		HatcheryService.hatchResultEvent:FireClient(player, {
			characterId = character.id,
			characterName = character.name,
			rarity = character.rarity,
			mutation = mutation,
			coinsPerSecond = BrainrotData.incomePerSecond(character, mutation),
		})
	end
	return true, "Hatched " .. character.name .. "!"
end

function HatcheryService.buildPedestalPrompts()
	local world = game:GetService("Workspace"):WaitForChild("HatchWorld")
	for _, tier in ipairs(BrainrotData.EggTiers) do
		local top = WorldBuilder.pedestalTops[tier.id]
		if top then
			local promptPart = Instance.new("Part")
			promptPart.Name = "HatchPrompt" .. tier.id
			promptPart.Size = Vector3.new(3, 3, 3)
			promptPart.Position = top + Vector3.new(0, 2, 0)
			promptPart.Anchored = true
			promptPart.CanCollide = false
			promptPart.Transparency = 1
			promptPart.Parent = world
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Hatch " .. tier.name
			prompt.ObjectText = tier.price .. " coins"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = promptPart
			HatcheryService.pedestals[tier.id] = { prompt = prompt, eggModel = nil, stocked = false }
			prompt.Triggered:Connect(function(player)
				local ok, message = HatcheryService.hatchEgg(player, tier.id)
				if not ok and HatcheryService.hatchResultEvent then
					HatcheryService.hatchResultEvent:FireClient(player, { error = message })
				end
			end)
		end
	end
end

function HatcheryService.stockInitialEggs()
	for _, tier in ipairs(BrainrotData.EggTiers) do
		if not tier.eventOnly then
			HatcheryService.stockEgg(tier.id)
		end
	end
end

function HatcheryService.stockGoldenEgg()
	HatcheryService.stockEgg("Golden")
end

function HatcheryService.clearGoldenEgg()
	HatcheryService.clearEgg("Golden")
end

return HatcheryService
