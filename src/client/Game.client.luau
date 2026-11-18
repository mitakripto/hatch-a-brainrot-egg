-- Hatch a Brainrot Egg: client bootstrap.
-- Builds the HUD and wires its buttons and the server's updates. The client
-- holds no game state: money, hatching, stealing and events all live on the
-- server, and this script only renders what the server sends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudController = require(script.Parent:WaitForChild("HudController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

HudController.buildHud(playerGui)

local stateUpdateEvent = ReplicatedStorage:WaitForChild("StateUpdate")
local hatchResultEvent = ReplicatedStorage:WaitForChild("HatchResult")
local stealResultEvent = ReplicatedStorage:WaitForChild("StealResult")
local noticeEvent = ReplicatedStorage:WaitForChild("Notice")
local lockBaseEvent = ReplicatedStorage:WaitForChild("LockBaseRequest")
local rebirthEvent = ReplicatedStorage:WaitForChild("RebirthRequest")

stateUpdateEvent.OnClientEvent:Connect(function(snapshot)
	HudController.updateFromSnapshot(snapshot)
end)

hatchResultEvent.OnClientEvent:Connect(function(result)
	HudController.showHatchResult(result)
end)

stealResultEvent.OnClientEvent:Connect(function(result)
	if result.error then
		HudController.showNotice(result.error, false)
	elseif result.stolen then
		HudController.showNotice("You stole a brainrot!", true)
	end
end)

noticeEvent.OnClientEvent:Connect(function(notice)
	HudController.showNotice(notice.text, notice.good)
end)

local lockButton = HudController.getLockButton()
if lockButton then
	lockButton.MouseButton1Click:Connect(function()
		lockBaseEvent:FireServer()
	end)
end

local rebirthButton = HudController.getRebirthButton()
if rebirthButton then
	rebirthButton.MouseButton1Click:Connect(function()
		rebirthEvent:FireServer()
	end)
end
