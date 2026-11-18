-- BaseService: owns the player base plots. It places hatched brainrots on
-- their slot pads, moves models when a brainrot changes owner, and runs the
-- base Lock button (60 seconds locked, then a cooldown).

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GameState = require(script.Parent:WaitForChild("GameState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BaseService = {}

function BaseService.placeBrainrotModel(brainrot)
	local character = BrainrotData.getCharacterById(brainrot.characterId)
	if not character then
		return
	end
	local slotPosition = WorldBuilder.plotSlots[brainrot.plotIndex][brainrot.slotIndex]
	if not slotPosition then
		return
	end
	if brainrot.model then
		brainrot.model:Destroy()
	end
	local model = BrainrotFactory.buildBrainrotModel(character, brainrot.mutation, slotPosition)
	model.Parent = game:GetService("Workspace"):WaitForChild("HatchWorld")
	brainrot.model = model
	BaseService.attachStealPrompt(brainrot)
end

-- Every brainrot carries a Steal prompt; StealService decides who may use it.
function BaseService.attachStealPrompt(brainrot)
	if not brainrot.model then
		return
	end
	local body = brainrot.model.PrimaryPart
	if not body then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = brainrot.characterId
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1.0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt:SetAttribute("BrainrotId", brainrot.id)
end

function BaseService.assignPlotToPlayer(player)
	local plotIndex = GameState.claimFreePlot(player)
	if plotIndex then
		WorldBuilder.setPlotOwnerName(plotIndex, player.DisplayName)
	end
	return plotIndex
end

function BaseService.releasePlotOfPlayer(player)
	local record = GameState.getPlayerRecord(player)
	if record and record.plotIndex then
		WorldBuilder.clearPlotOwnerName(record.plotIndex)
	end
end

function BaseService.lockBase(player)
	local record = GameState.getPlayerRecord(player)
	if not record or not record.plotIndex then
		return false, "You have no base to lock."
	end
	local now = os.clock()
	if now < record.lockReadyAt then
		return false, "Lock is recharging (" .. math.ceil(record.lockReadyAt - now) .. "s)."
	end
	if now < record.lockedUntil then
		return false, "Your base is already locked."
	end
	record.lockedUntil = now + BrainrotData.LockDurationSeconds
	record.lockReadyAt = now + BrainrotData.LockDurationSeconds + BrainrotData.LockCooldownSeconds
	return true, "Base locked for 60 seconds!"
end

function BaseService.rebirth(player)
	local record = GameState.getPlayerRecord(player)
	if not record then
		return false, "You are not in the game yet."
	end
	if record.coins < BrainrotData.RebirthCost then
		return false, "Rebirth costs " .. BrainrotData.RebirthCost .. " coins."
	end
	GameState.resetForRebirth(player)
	return true, "Reborn! Income x" .. string.format("%.1f", GameState.incomeMultiplier(player)) .. " forever."
end

return BaseService
