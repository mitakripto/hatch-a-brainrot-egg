-- HudController: builds and updates the player's HUD. The client never owns
-- game state: it renders snapshots the server sends every second, and sends
-- Lock and Rebirth requests back. All text stays clear of the top-left
-- corner, where Roblox's own menu buttons sit, and is kept large so it
-- stays readable when screenshots are scaled down for judging.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local HudController = {}

local moneyLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local eventBanner = nil
local lockButton = nil
local rebirthButton = nil
local guideFrame = nil
local hatchPopup = nil
local hatchPopupTitle = nil
local hatchPopupDetail = nil
local noticeLabel = nil

local function makeLabel(name, parent, size, position, text, textSize, textColor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.SourceSansBold
	label.Parent = parent
	return label
end

local function makeButton(name, parent, size, position, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 2
	button.BorderColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.TextSize = 22
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.3
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	return button
end

function HudController.buildHud(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HatchHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Money bar: top center, big and readable.
	local moneyBar = Instance.new("Frame")
	moneyBar.Name = "MoneyBar"
	moneyBar.AnchorPoint = Vector2.new(0.5, 0)
	moneyBar.Position = UDim2.new(0.5, 0, 0, 12)
	moneyBar.Size = UDim2.new(0, 460, 0, 64)
	moneyBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	moneyBar.BackgroundTransparency = 0.25
	moneyBar.BorderSizePixel = 0
	moneyBar.Parent = gui
	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 12)
	moneyCorner.Parent = moneyBar

	moneyLabel = makeLabel("Coins", moneyBar, UDim2.new(1, 0, 0.6, 0), UDim2.new(0, 0, 0, 2), "100 coins", 32)
	incomeLabel = makeLabel(
		"Income",
		moneyBar,
		UDim2.new(1, 0, 0.4, 0),
		UDim2.new(0, 0, 0.55, 0),
		"0 coins / second",
		20,
		Color3.fromRGB(150, 255, 150)
	)

	rebirthLabel = makeLabel(
		"Rebirths",
		gui,
		UDim2.new(0, 300, 0, 30),
		UDim2.new(0.5, -150, 0, 80),
		"Rebirths: 0  |  Income x1.0",
		20,
		Color3.fromRGB(255, 220, 120)
	)

	-- Event banner: top right.
	eventBanner = makeLabel(
		"EventBanner",
		gui,
		UDim2.new(0, 320, 0, 44),
		UDim2.new(1, -336, 0, 12),
		"Next Egg Rush in 4:00",
		22,
		Color3.fromRGB(255, 200, 80)
	)

	-- Notice toast: under the money bar.
	noticeLabel = makeLabel(
		"Notice",
		gui,
		UDim2.new(0, 600, 0, 36),
		UDim2.new(0.5, -300, 0, 116),
		"",
		22,
		Color3.fromRGB(255, 255, 255)
	)

	-- Egg prices: bottom left.
	local priceFrame = Instance.new("Frame")
	priceFrame.Name = "EggPrices"
	priceFrame.Position = UDim2.new(0, 16, 1, -190)
	priceFrame.Size = UDim2.new(0, 280, 0, 174)
	priceFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	priceFrame.BackgroundTransparency = 0.25
	priceFrame.BorderSizePixel = 0
	priceFrame.Parent = gui
	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 12)
	priceCorner.Parent = priceFrame
	makeLabel("PriceTitle", priceFrame, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 6), "EGGS AT THE HATCHERY", 20, Color3.fromRGB(255, 220, 120))
	local priceLines = {}
	for _, tier in ipairs(BrainrotData.EggTiers) do
		local note = ""
		if tier.eventOnly then
			note = " (Egg Rush only)"
		elseif tier.minRebirths > 0 then
			note = " (needs " .. tier.minRebirths .. " rebirth)"
		end
		table.insert(priceLines, tier.name .. " - " .. tier.price .. " coins" .. note)
	end
	makeLabel(
		"PriceList",
		priceFrame,
		UDim2.new(1, -16, 1, -40),
		UDim2.new(0, 8, 0, 36),
		table.concat(priceLines, "\n"),
		18
	).TextXAlignment = Enum.TextXAlignment.Left

	-- Buttons: bottom center.
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"
	buttonRow.AnchorPoint = Vector2.new(0.5, 1)
	buttonRow.Position = UDim2.new(0.5, 0, 1, -16)
	buttonRow.Size = UDim2.new(0, 560, 0, 56)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = gui
	lockButton = makeButton("LockBase", buttonRow, UDim2.new(0, 170, 1, 0), UDim2.new(0, 0, 0, 0), "LOCK BASE (60s)", Color3.fromRGB(60, 90, 200))
	rebirthButton = makeButton(
		"Rebirth",
		buttonRow,
		UDim2.new(0, 200, 1, 0),
		UDim2.new(0, 180, 0, 0),
		"REBIRTH (" .. BrainrotData.RebirthCost .. ")",
		Color3.fromRGB(180, 60, 180)
	)
	local guideButton = makeButton("Guide", buttonRow, UDim2.new(0, 170, 1, 0), UDim2.new(0, 390, 0, 0), "BRAINROT GUIDE", Color3.fromRGB(60, 160, 90))
	guideButton.MouseButton1Click:Connect(function()
		guideFrame.Visible = not guideFrame.Visible
	end)

	-- Rarity guide: right side, toggleable.
	guideFrame = Instance.new("Frame")
	guideFrame.Name = "RarityGuide"
	guideFrame.Position = UDim2.new(1, -336, 0, 70)
	guideFrame.Size = UDim2.new(0, 320, 0, 420)
	guideFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	guideFrame.BackgroundTransparency = 0.15
	guideFrame.BorderSizePixel = 0
	guideFrame.Visible = false
	guideFrame.Parent = gui
	local guideCorner = Instance.new("UICorner")
	guideCorner.CornerRadius = UDim.new(0, 12)
	guideCorner.Parent = guideFrame
	makeLabel("GuideTitle", guideFrame, UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 6), "BRAINROT GUIDE", 22, Color3.fromRGB(255, 220, 120))
	local guideLines = {}
	for _, character in ipairs(BrainrotData.Characters) do
		table.insert(
			guideLines,
			character.name .. " (" .. character.rarity .. ") - " .. character.coinsPerSecond .. "/s"
		)
	end
	table.insert(guideLines, "")
	table.insert(guideLines, "Golden mutation: x3 income")
	table.insert(guideLines, "Rainbow mutation: x8 income")
	local guideList = makeLabel(
		"GuideList",
		guideFrame,
		UDim2.new(1, -16, 1, -44),
		UDim2.new(0, 8, 0, 40),
		table.concat(guideLines, "\n"),
		17
	)
	guideList.TextXAlignment = Enum.TextXAlignment.Left
	guideList.TextYAlignment = Enum.TextYAlignment.Top

	-- Hatch popup: center screen, shown briefly on every hatch.
	hatchPopup = Instance.new("Frame")
	hatchPopup.Name = "HatchPopup"
	hatchPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	hatchPopup.Position = UDim2.new(0.5, 0, 0.38, 0)
	hatchPopup.Size = UDim2.new(0, 480, 0, 130)
	hatchPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	hatchPopup.BackgroundTransparency = 0.15
	hatchPopup.BorderSizePixel = 0
	hatchPopup.Visible = false
	hatchPopup.Parent = gui
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 16)
	popupCorner.Parent = hatchPopup
	hatchPopupTitle = makeLabel("HatchTitle", hatchPopup, UDim2.new(1, 0, 0.45, 0), UDim2.new(0, 0, 0.08, 0), "", 34, Color3.fromRGB(255, 220, 120))
	hatchPopupDetail = makeLabel("HatchDetail", hatchPopup, UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.52, 0), "", 24)

	return gui
end

function HudController.getLockButton()
	return lockButton
end

function HudController.getRebirthButton()
	return rebirthButton
end

local function formatClock(totalSeconds)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

function HudController.updateFromSnapshot(snapshot)
	if moneyLabel then
		moneyLabel.Text = snapshot.coins .. " coins"
	end
	if incomeLabel then
		incomeLabel.Text = snapshot.earnPerSecond .. " coins / second  |  " .. snapshot.brainrotCount .. " brainrots"
	end
	if rebirthLabel then
		rebirthLabel.Text = "Rebirths: "
			.. snapshot.rebirths
			.. "  |  Income x"
			.. string.format("%.1f", snapshot.multiplier)
			.. "  |  Base plot "
			.. snapshot.plotIndex
	end
	if eventBanner then
		if snapshot.eggRushActive then
			eventBanner.Text = "EGG RUSH! Double luck - " .. formatClock(snapshot.eggRushSecondsLeft) .. " left"
			eventBanner.TextColor3 = Color3.fromRGB(255, 220, 60)
		else
			eventBanner.Text = "Next Egg Rush in " .. formatClock(snapshot.nextEggRushIn)
			eventBanner.TextColor3 = Color3.fromRGB(255, 200, 80)
		end
	end
	if lockButton then
		if snapshot.locked then
			lockButton.Text = "LOCKED (" .. snapshot.lockSecondsLeft .. "s)"
		elseif snapshot.lockCooldownLeft > 0 then
			lockButton.Text = "LOCK (" .. snapshot.lockCooldownLeft .. "s)"
		else
			lockButton.Text = "LOCK BASE (60s)"
		end
	end
end

function HudController.showHatchResult(result)
	if result.error then
		HudController.showNotice(result.error, false)
		return
	end
	if not hatchPopup then
		return
	end
	local mutationText = ""
	if result.mutation ~= "None" then
		mutationText = " " .. result.mutation:upper() .. "!"
	end
	hatchPopupTitle.Text = "Hatched " .. result.characterName .. "!"
	hatchPopupDetail.Text = result.rarity .. mutationText .. "  |  " .. result.coinsPerSecond .. " coins / second"
	hatchPopupDetail.TextColor3 = BrainrotData.Rarities[result.rarity].color
	hatchPopup.Visible = true
	task.delay(4, function()
		hatchPopup.Visible = false
	end)
end

function HudController.showNotice(text, good)
	if not noticeLabel then
		return
	end
	noticeLabel.Text = text
	noticeLabel.TextColor3 = good and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)
	task.delay(4, function()
		if noticeLabel and noticeLabel.Text == text then
			noticeLabel.Text = ""
		end
	end)
end

return HudController
