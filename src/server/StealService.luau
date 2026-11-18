-- StealService: lets a player take a brainrot from another player's base
-- while that base is unlocked. The thief must have a free slot, and stealing
-- has a short cooldown so one player cannot strip a base in seconds.
-- Stealing your own brainrot is refused, and locked bases are safe.

local GameState = require(script.Parent:WaitForChild("GameState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local StealService = {}

local STEAL_COOLDOWN_SECONDS = 15
StealService.stealResultEvent = nil

function StealService.setStealResultEvent(remoteEvent)
	StealService.stealResultEvent = remoteEvent
end

function StealService.trySteal(thief, brainrotId)
	local brainrot = GameState.brainrots[brainrotId]
	if not brainrot then
		return false, "That brainrot is gone."
	end
	if brainrot.ownerUserId == thief.UserId then
		return false, "That brainrot is already yours."
	end
	if GameState.isPlotLocked(brainrot.plotIndex) then
		return false, "That base is locked."
	end
	local record = GameState.getPlayerRecord(thief)
	if not record or not record.plotIndex then
		return false, "You need a base first."
	end
	if os.clock() < record.stealReadyAt then
		return false, "Stealing recharges in " .. math.ceil(record.stealReadyAt - os.clock()) .. "s."
	end
	if not GameState.transferBrainrot(brainrot, thief) then
		return false, "Your base is full."
	end
	record.stealReadyAt = os.clock() + STEAL_COOLDOWN_SECONDS
	BaseService.placeBrainrotModel(brainrot)
	if StealService.stealResultEvent then
		StealService.stealResultEvent:FireClient(thief, { stolen = true, characterId = brainrot.characterId })
	end
	return true, "Stolen!"
end

-- Watches every Steal prompt in the world, including prompts on models
-- built after this service starts.
function StealService.watchStealPrompts()
	local world = game:GetService("Workspace"):WaitForChild("HatchWorld")
	local function watchPrompt(prompt)
		if prompt.Name ~= "StealPrompt" then
			return
		end
		prompt.Triggered:Connect(function(player)
			local brainrotId = prompt:GetAttribute("BrainrotId")
			local ok, message = StealService.trySteal(player, brainrotId)
			if not ok and StealService.stealResultEvent then
				StealService.stealResultEvent:FireClient(player, { error = message })
			end
		end)
	end
	world.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			watchPrompt(descendant)
		end
	end)
	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			watchPrompt(descendant)
		end
	end
end

return StealService
