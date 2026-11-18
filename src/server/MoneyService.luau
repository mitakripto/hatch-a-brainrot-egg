-- MoneyService: pays every player their brainrots' income once a second and
-- pushes a fresh snapshot to each client so the HUD money counter ticks up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(script.Parent:WaitForChild("GameState"))

local MoneyService = {}
local stateUpdateEvent = nil

function MoneyService.setStateUpdateEvent(remoteEvent)
	stateUpdateEvent = remoteEvent
end

function MoneyService.payIncomeTick()
	for _, player in ipairs(Players:GetPlayers()) do
		local record = GameState.getPlayerRecord(player)
		if record then
			local earned = GameState.earnPerSecond(player)
			if earned > 0 then
				GameState.addCoins(player, earned)
			end
		end
	end
end

function MoneyService.broadcastSnapshots()
	if not stateUpdateEvent then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local snapshot = GameState.snapshotFor(player)
		if snapshot then
			stateUpdateEvent:FireClient(player, snapshot)
		end
	end
end

function MoneyService.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			MoneyService.payIncomeTick()
			MoneyService.broadcastSnapshots()
		end
	end)
end

return MoneyService
