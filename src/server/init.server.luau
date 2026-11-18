-- Hatch a Brainrot Egg: server bootstrap.
-- Builds the world, creates the RemoteEvents, wires every service together,
-- and handles players joining and leaving. The server owns all state; the
-- client only renders the HUD and sends requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(script:WaitForChild("GameState"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local MoneyService = require(script:WaitForChild("MoneyService"))
local HatcheryService = require(script:WaitForChild("HatcheryService"))
local BaseService = require(script:WaitForChild("BaseService"))
local StealService = require(script:WaitForChild("StealService"))
local SnatcherService = require(script:WaitForChild("SnatcherService"))
local EventService = require(script:WaitForChild("EventService"))

local function createRemoteEvent(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

-- Server -> client updates.
local stateUpdateEvent = createRemoteEvent("StateUpdate")
local hatchResultEvent = createRemoteEvent("HatchResult")
local stealResultEvent = createRemoteEvent("StealResult")
local noticeEvent = createRemoteEvent("Notice")
-- Client -> server requests.
local lockBaseEvent = createRemoteEvent("LockBaseRequest")
local rebirthEvent = createRemoteEvent("RebirthRequest")

-- Build the world before any player can join.
GameState.createPlots()
WorldBuilder.buildWorld()
HatcheryService.buildPedestalPrompts()
HatcheryService.stockInitialEggs()

-- Wire the services together.
MoneyService.setStateUpdateEvent(stateUpdateEvent)
HatcheryService.setHatchResultEvent(hatchResultEvent)
StealService.setStealResultEvent(stealResultEvent)
StealService.watchStealPrompts()

lockBaseEvent.OnServerEvent:Connect(function(player)
	local ok, message = BaseService.lockBase(player)
	noticeEvent:FireClient(player, { text = message, good = ok })
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	local ok, message = BaseService.rebirth(player)
	noticeEvent:FireClient(player, { text = message, good = ok })
end)

local function onPlayerAdded(player)
	GameState.registerPlayer(player)
	local plotIndex = BaseService.assignPlotToPlayer(player)
	if plotIndex then
		noticeEvent:FireClient(player, {
			text = "Welcome! Your base is plot " .. plotIndex .. ". Hatch an egg to start earning!",
			good = true,
		})
	else
		noticeEvent:FireClient(player, {
			text = "Welcome! All 8 base plots are taken right now.",
			good = false,
		})
	end
end

local function onPlayerRemoving(player)
	BaseService.releasePlotOfPlayer(player)
	GameState.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
-- Players already in the game (Studio play-test solo) get the same welcome.
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Start the loops: income, Egg Rush, and the Snatcher.
MoneyService.startIncomeLoop()
EventService.startEventLoop()
SnatcherService.startSnatcherLoop()

print("Hatch a Brainrot Egg server is running.")
