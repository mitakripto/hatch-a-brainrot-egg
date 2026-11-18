-- EventService: runs the Egg Rush, a timed event every few minutes. While it
-- runs, hatch luck doubles for the rarer brainrots and a Golden Egg appears
-- on its pedestal. The HUD banner counts the event down.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GameState = require(script.Parent:WaitForChild("GameState"))
local HatcheryService = require(script.Parent:WaitForChild("HatcheryService"))

local EventService = {}

function EventService.startEggRush()
	GameState.eggRushActive = true
	GameState.eggRushEndsAt = os.clock() + BrainrotData.EggRushDurationSeconds
	GameState.goldenEggAvailable = true
	HatcheryService.stockGoldenEgg()
end

function EventService.endEggRush()
	GameState.eggRushActive = false
	GameState.goldenEggAvailable = false
	GameState.nextEggRushAt = os.clock() + BrainrotData.EggRushIntervalSeconds
	HatcheryService.clearGoldenEgg()
end

function EventService.startEventLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			if GameState.eggRushActive then
				if now >= GameState.eggRushEndsAt then
					EventService.endEggRush()
				end
			elseif now >= GameState.nextEggRushAt then
				EventService.startEggRush()
			end
		end
	end)
end

return EventService
