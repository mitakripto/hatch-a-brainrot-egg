-- SnatcherService: runs the Snatcher, a roaming shadowy NPC that stalks the
-- bases. Every so often it picks an unlocked base that has brainrots, walks
-- over, grabs one and carries it toward the edge of the map. Any player can
-- scare it off by touching it or clicking it: it drops what it carries (the
-- brainrot goes straight back to its owner's base) and flees. Locked bases
-- are never targeted, so the Lock button is the defence.

local GameState = require(script.Parent:WaitForChild("GameState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local SnatcherService = {}

local SNATCHER_CHECK_SECONDS = 20
local SNATCHER_WALK_SPEED = 14
local SNATCHER_FLEE_SPEED = 22

local snatcherModel = nil
local carriedBrainrot = nil
local snatcherBusy = false
local snatchRunId = 0 -- guards the escape walk: a scare bumps it, stale walks stop

local function makeSnatcherModel(spawnPosition)
	local model = Instance.new("Model")
	model.Name = "Snatcher"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 3, 1.6)
	body.Color = Color3.fromRGB(40, 40, 50)
	body.Position = spawnPosition + Vector3.new(0, 2.5, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.8, 1.4, 1.8)
	head.Shape = Enum.PartType.Ball
	head.Color = Color3.fromRGB(60, 60, 80)
	head.Position = spawnPosition + Vector3.new(0, 4.7, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	for _, side in ipairs({ -0.5, 0.5 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.3, 0.5, 0.2)
		eye.Color = Color3.fromRGB(255, 60, 60)
		eye.Material = Enum.Material.Neon
		eye.Position = spawnPosition + Vector3.new(side, 4.8, 0.9)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
	end

	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Size = Vector3.new(1.4, 1.8, 1.4)
	sack.Color = Color3.fromRGB(120, 90, 50)
	sack.Position = spawnPosition + Vector3.new(1.6, 2.2, 0)
	sack.Anchored = true
	sack.CanCollide = false
	sack.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 220, 0, 50)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0)
	billboard.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "THE SNATCHER"
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = billboard
	billboard.Parent = model

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 24
	clickDetector.Parent = body

	model.PrimaryPart = body
	return model
end

local function moveSnatcherTo(targetPosition, speed, runId)
	if not snatcherModel or not snatcherModel.PrimaryPart then
		return false
	end
	local start = snatcherModel.PrimaryPart.Position
	local pivotY = snatcherModel:GetPivot().Position.Y
	local goal = Vector3.new(targetPosition.X, start.Y, targetPosition.Z)
	local distance = (goal - start).Magnitude
	if distance < 0.5 then
		return true
	end
	local duration = distance / speed
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		if runId and runId ~= snatchRunId then
			return false
		end
		if not snatcherModel or not snatcherModel.PrimaryPart then
			return false
		end
		local alpha = (os.clock() - startTime) / duration
		local current = start:Lerp(goal, alpha)
		snatcherModel:PivotTo(CFrame.new(current.X, pivotY, current.Z))
		task.wait(0.05)
	end
	if snatcherModel then
		snatcherModel:PivotTo(CFrame.new(goal.X, pivotY, goal.Z))
	end
	return true
end

function SnatcherService.scareSnatcherAway()
	if not snatcherModel then
		return
	end
	snatchRunId += 1
	if carriedBrainrot then
		-- The dropped brainrot goes straight back to its owner's base.
		BaseService.placeBrainrotModel(carriedBrainrot)
		carriedBrainrot = nil
	end
	snatcherBusy = false
	task.spawn(function()
		moveSnatcherTo(Vector3.new(0, 0, -60), SNATCHER_FLEE_SPEED, nil)
	end)
end

function SnatcherService.pickVictimPlot()
	local candidates = {}
	for index, plot in ipairs(GameState.plots) do
		if plot.ownerUserId and not GameState.isPlotLocked(index) then
			local hasBrainrot = false
			for slot = 1, 6 do
				if plot.slots[slot] ~= nil then
					hasBrainrot = true
					break
				end
			end
			if hasBrainrot then
				table.insert(candidates, index)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(#candidates)]
end

function SnatcherService.snatchFromPlot(plotIndex)
	local plot = GameState.plots[plotIndex]
	if not plot then
		return
	end
	local victimId = nil
	for slot = 1, 6 do
		if plot.slots[slot] ~= nil then
			victimId = plot.slots[slot]
			break
		end
	end
	if not victimId then
		return
	end
	local brainrot = GameState.brainrots[victimId]
	if not brainrot then
		return
	end
	snatchRunId += 1
	local runId = snatchRunId
	local center = WorldBuilder.plotCenters[plotIndex]
	if not moveSnatcherTo(center, SNATCHER_WALK_SPEED, runId) then
		return
	end
	-- Grab: hide the model and carry the brainrot off.
	if brainrot.model then
		brainrot.model:Destroy()
		brainrot.model = nil
	end
	carriedBrainrot = brainrot
	task.spawn(function()
		moveSnatcherTo(Vector3.new(0, 0, -60), SNATCHER_WALK_SPEED, runId)
		-- If it escapes with the brainrot, the brainrot is gone for good.
		if runId == snatchRunId and carriedBrainrot == brainrot then
			GameState.removeBrainrotFromPlot(brainrot)
			carriedBrainrot = nil
		end
		if runId == snatchRunId then
			snatcherBusy = false
		end
	end)
end

function SnatcherService.startSnatcherLoop()
	local world = game:GetService("Workspace"):WaitForChild("HatchWorld")
	snatcherModel = makeSnatcherModel(Vector3.new(0, 0, -60))
	snatcherModel.Parent = world
	local body = snatcherModel.PrimaryPart
	local clickDetector = body:FindFirstChildOfClass("ClickDetector")
	if clickDetector then
		clickDetector.MouseClick:Connect(function(_player)
			SnatcherService.scareSnatcherAway()
		end)
	end
	body.Touched:Connect(function(hit)
		-- Only a player's character scares the Snatcher, not a fence or tree.
		local character = hit.Parent
		if character and character:FindFirstChildOfClass("Humanoid") then
			SnatcherService.scareSnatcherAway()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(SNATCHER_CHECK_SECONDS)
			if not snatcherBusy then
				local victimPlot = SnatcherService.pickVictimPlot()
				if victimPlot then
					snatcherBusy = true
					SnatcherService.snatchFromPlot(victimPlot)
				end
			end
		end
	end)
end

return SnatcherService
