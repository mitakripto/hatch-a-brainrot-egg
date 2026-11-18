-- GameState: the one place the server keeps game state.
-- Money, ownership, bases, locks, rebirths and events all live here so no
-- other module keeps its own copy. Every other server module reads and
-- writes through these functions.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GameState = {}

-- players[userId] = {
--   player = Player, coins = number, rebirths = number,
--   plotIndex = number | nil, brainrots = { [brainrotId] = brainrot },
--   lockedUntil = number (os.clock), lockReadyAt = number (os.clock),
--   stealReadyAt = number (os.clock),
-- }
GameState.players = {}

-- plots[plotIndex] = { ownerUserId = number | nil, slots = { [slot] = brainrotId | nil } }
GameState.plots = {}

-- brainrots[brainrotId] = {
--   id, characterId, mutation, ownerUserId, plotIndex, slotIndex, model (Model | nil)
-- }
GameState.brainrots = {}

GameState.nextBrainrotId = 1
GameState.eggRushActive = false
GameState.eggRushEndsAt = 0
GameState.nextEggRushAt = os.clock() + BrainrotData.EggRushIntervalSeconds
GameState.goldenEggAvailable = false

function GameState.createPlots()
	for index = 1, BrainrotData.PlotCount do
		local slots = {}
		for slot = 1, BrainrotData.BaseSlotsPerPlot do
			slots[slot] = nil
		end
		GameState.plots[index] = { ownerUserId = nil, slots = slots }
	end
end

function GameState.registerPlayer(player)
	local record = {
		player = player,
		coins = BrainrotData.StartingCoins,
		rebirths = 0,
		plotIndex = nil,
		brainrots = {},
		lockedUntil = 0,
		lockReadyAt = 0,
		stealReadyAt = 0,
	}
	GameState.players[player.UserId] = record
	return record
end

function GameState.getPlayerRecord(player)
	return GameState.players[player.UserId]
end

function GameState.removePlayer(player)
	local record = GameState.players[player.UserId]
	if not record then
		return
	end
	if record.plotIndex then
		local plot = GameState.plots[record.plotIndex]
		plot.ownerUserId = nil
		for slot = 1, BrainrotData.BaseSlotsPerPlot do
			plot.slots[slot] = nil
		end
	end
	for id, brainrot in pairs(record.brainrots) do
		if brainrot.model then
			brainrot.model:Destroy()
		end
		GameState.brainrots[id] = nil
	end
	GameState.players[player.UserId] = nil
end

function GameState.claimFreePlot(player)
	local record = GameState.players[player.UserId]
	if not record or record.plotIndex then
		return record and record.plotIndex or nil
	end
	for index, plot in ipairs(GameState.plots) do
		if plot.ownerUserId == nil then
			plot.ownerUserId = player.UserId
			record.plotIndex = index
			return index
		end
	end
	return nil
end

function GameState.incomeMultiplier(player)
	local record = GameState.players[player.UserId]
	if not record then
		return 1
	end
	return 1 + record.rebirths * BrainrotData.RebirthMultiplierStep
end

function GameState.addCoins(player, amount)
	local record = GameState.players[player.UserId]
	if not record then
		return false
	end
	record.coins += amount
	return true
end

function GameState.spendCoins(player, amount)
	local record = GameState.players[player.UserId]
	if not record or record.coins < amount then
		return false
	end
	record.coins -= amount
	return true
end

function GameState.earnPerSecond(player)
	local record = GameState.players[player.UserId]
	if not record then
		return 0
	end
	local total = 0
	for _, brainrot in pairs(record.brainrots) do
		local character = BrainrotData.getCharacterById(brainrot.characterId)
		if character then
			total += BrainrotData.incomePerSecond(character, brainrot.mutation)
		end
	end
	return total * GameState.incomeMultiplier(player)
end

function GameState.isPlotLocked(plotIndex)
	local plot = GameState.plots[plotIndex]
	if not plot or not plot.ownerUserId then
		return false
	end
	local owner = GameState.players[plot.ownerUserId]
	if not owner then
		return false
	end
	return os.clock() < owner.lockedUntil
end

function GameState.addBrainrot(player, character, mutation)
	local record = GameState.players[player.UserId]
	if not record or not record.plotIndex then
		return nil
	end
	local plot = GameState.plots[record.plotIndex]
	local freeSlot = nil
	for slot = 1, BrainrotData.BaseSlotsPerPlot do
		if plot.slots[slot] == nil then
			freeSlot = slot
			break
		end
	end
	if not freeSlot then
		return nil
	end
	local id = GameState.nextBrainrotId
	GameState.nextBrainrotId += 1
	local brainrot = {
		id = id,
		characterId = character.id,
		mutation = mutation,
		ownerUserId = player.UserId,
		plotIndex = record.plotIndex,
		slotIndex = freeSlot,
		model = nil,
	}
	plot.slots[freeSlot] = id
	record.brainrots[id] = brainrot
	GameState.brainrots[id] = brainrot
	return brainrot
end

function GameState.removeBrainrotFromPlot(brainrot)
	local plot = GameState.plots[brainrot.plotIndex]
	if plot then
		plot.slots[brainrot.slotIndex] = nil
	end
	local owner = GameState.players[brainrot.ownerUserId]
	if owner then
		owner.brainrots[brainrot.id] = nil
	end
	GameState.brainrots[brainrot.id] = nil
	if brainrot.model then
		brainrot.model:Destroy()
		brainrot.model = nil
	end
end

-- Moves a brainrot to a new owner's first free slot. Returns false when full.
function GameState.transferBrainrot(brainrot, newOwner)
	local record = GameState.players[newOwner.UserId]
	if not record or not record.plotIndex then
		return false
	end
	local newPlot = GameState.plots[record.plotIndex]
	local freeSlot = nil
	for slot = 1, BrainrotData.BaseSlotsPerPlot do
		if newPlot.slots[slot] == nil then
			freeSlot = slot
			break
		end
	end
	if not freeSlot then
		return false
	end
	local oldPlot = GameState.plots[brainrot.plotIndex]
	if oldPlot then
		oldPlot.slots[brainrot.slotIndex] = nil
	end
	local oldOwner = GameState.players[brainrot.ownerUserId]
	if oldOwner then
		oldOwner.brainrots[brainrot.id] = nil
	end
	brainrot.ownerUserId = newOwner.UserId
	brainrot.plotIndex = record.plotIndex
	brainrot.slotIndex = freeSlot
	newPlot.slots[freeSlot] = brainrot.id
	record.brainrots[brainrot.id] = brainrot
	return true
end

function GameState.resetForRebirth(player)
	local record = GameState.players[player.UserId]
	if not record then
		return false
	end
	local ids = {}
	for id, _ in pairs(record.brainrots) do
		table.insert(ids, id)
	end
	for _, id in ipairs(ids) do
		GameState.removeBrainrotFromPlot(GameState.brainrots[id])
	end
	record.coins = BrainrotData.StartingCoins
	record.rebirths += 1
	return true
end

-- A small snapshot the client renders: money, income, rebirths, lock state.
function GameState.snapshotFor(player)
	local record = GameState.players[player.UserId]
	if not record then
		return nil
	end
	local count = 0
	for _, _ in pairs(record.brainrots) do
		count += 1
	end
	return {
		coins = math.floor(record.coins),
		earnPerSecond = math.floor(GameState.earnPerSecond(player)),
		rebirths = record.rebirths,
		multiplier = GameState.incomeMultiplier(player),
		brainrotCount = count,
		plotIndex = record.plotIndex or 0,
		locked = record.plotIndex ~= nil and GameState.isPlotLocked(record.plotIndex),
		lockSecondsLeft = math.max(0, math.ceil(record.lockedUntil - os.clock())),
		lockCooldownLeft = math.max(0, math.ceil(record.lockReadyAt - os.clock())),
		eggRushActive = GameState.eggRushActive,
		eggRushSecondsLeft = math.max(0, math.ceil(GameState.eggRushEndsAt - os.clock())),
		nextEggRushIn = math.max(0, math.ceil(GameState.nextEggRushAt - os.clock())),
		goldenEggAvailable = GameState.goldenEggAvailable,
	}
end

return GameState
