-- // 11_inventory_hud.luau
-- // Fabled inventory HUD: category accents, icon glow, scale + accent support.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local screenGui = PD.screenGui
local userInputService = PD.userInputService
local silentAim = PD.silentAim
local saveConfig = PD.saveConfig
local itemIcons = PD.itemIcons
local Theme = PD.UI and PD.UI.Theme or {}
local TweenService = game:GetService("TweenService")

local accent = silentAim.InventoryAccent or Color3.fromRGB(0, 255, 120)

-- // Main HUD
local hudFrame = Instance.new("Frame")
hudFrame.Name = "FabledInventoryHUD"
hudFrame.Size = UDim2.new(0, 178, 0, 0)
hudFrame.Position = UDim2.new(0, silentAim.InventoryPositionX, 0, silentAim.InventoryPositionY)
hudFrame.BackgroundColor3 = Color3.fromRGB(8, 13, 10)
hudFrame.BorderSizePixel = 0
hudFrame.AutomaticSize = Enum.AutomaticSize.Y
hudFrame.Visible = silentAim.InventoryVisible
hudFrame.Parent = screenGui
PD.hudFrame = hudFrame

local uiScale = Instance.new("UIScale")
uiScale.Scale = silentAim.InventoryScale or 1
uiScale.Parent = hudFrame

PD.setInventoryScale = function(value)
    uiScale.Scale = value
end

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hudFrame

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = accent
hudStroke.Transparency = 0.45
hudStroke.Thickness = 1.2
hudStroke.Parent = hudFrame

-- // Header
local hudTitleBar = Instance.new("Frame")
hudTitleBar.Size = UDim2.new(1, 0, 0, 54)
hudTitleBar.BackgroundColor3 = Color3.fromRGB(13, 20, 15)
hudTitleBar.BorderSizePixel = 0
hudTitleBar.Parent = hudFrame

local hudTitleCorner = Instance.new("UICorner")
hudTitleCorner.CornerRadius = UDim.new(0, 8)
hudTitleCorner.Parent = hudTitleBar

local hudTitleCover = Instance.new("Frame")
hudTitleCover.Size = UDim2.new(1, 0, 0, 10)
hudTitleCover.Position = UDim2.new(0, 0, 1, -10)
hudTitleCover.BackgroundColor3 = Color3.fromRGB(13, 20, 15)
hudTitleCover.BorderSizePixel = 0
hudTitleCover.Parent = hudTitleBar

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 3, 0, 30)
accentBar.Position = UDim2.new(0, 10, 0, 12)
accentBar.BackgroundColor3 = accent
accentBar.BorderSizePixel = 0
accentBar.Parent = hudTitleBar

local accentBarCorner = Instance.new("UICorner")
accentBarCorner.CornerRadius = UDim.new(0, 2)
accentBarCorner.Parent = accentBar

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -50, 0, 14)
headerLabel.Position = UDim2.new(0, 20, 0, 8)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "INVENTORY"
headerLabel.TextColor3 = accent
headerLabel.TextSize = 10
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = hudTitleBar

local targetNameLabel = Instance.new("TextLabel")
targetNameLabel.Size = UDim2.new(1, -50, 0, 16)
targetNameLabel.Position = UDim2.new(0, 20, 0, 23)
targetNameLabel.BackgroundTransparency = 1
targetNameLabel.Text = "NO TARGET"
targetNameLabel.TextColor3 = Color3.fromRGB(235, 246, 239)
targetNameLabel.TextSize = 12
targetNameLabel.Font = Enum.Font.GothamBold
targetNameLabel.TextXAlignment = Enum.TextXAlignment.Left
targetNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
targetNameLabel.Parent = hudTitleBar
PD.targetNameLabel = targetNameLabel

local liveDot = Instance.new("Frame")
liveDot.Size = UDim2.new(0, 5, 0, 5)
liveDot.Position = UDim2.new(1, -16, 0, 11)
liveDot.BackgroundColor3 = accent
liveDot.BorderSizePixel = 0
liveDot.Parent = hudTitleBar

local liveDotCorner = Instance.new("UICorner")
liveDotCorner.CornerRadius = UDim.new(1, 0)
liveDotCorner.Parent = liveDot

local liveTween = TweenService:Create(liveDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.7,
})
liveTween:Play()

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, -1)
headerLine.BackgroundColor3 = accent
headerLine.BorderSizePixel = 0
headerLine.Parent = hudTitleBar

-- // Dragging
local draggingHUD, dragStartHUD, startPosHUD
hudTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingHUD = true
        dragStartHUD = input.Position
        startPosHUD = hudFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingHUD = false
                silentAim.InventoryPositionX = hudFrame.Position.X.Offset
                silentAim.InventoryPositionY = hudFrame.Position.Y.Offset
                saveConfig()
                if PD.UI and PD.UI.Sync then
                    PD.UI.Sync()
                end
            end
        end)
    end
end)

userInputService.InputChanged:Connect(function(input)
    if draggingHUD and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartHUD
        hudFrame.Position = UDim2.new(
            startPosHUD.X.Scale,
            startPosHUD.X.Offset + delta.X,
            startPosHUD.Y.Scale,
            startPosHUD.Y.Offset + delta.Y
        )
    end
end)

-- // Body
local hudContainer = Instance.new("Frame")
hudContainer.Size = UDim2.new(1, -12, 0, 0)
hudContainer.Position = UDim2.new(0, 6, 0, 60)
hudContainer.BackgroundTransparency = 1
hudContainer.AutomaticSize = Enum.AutomaticSize.Y
hudContainer.Parent = hudFrame
PD.hudContainer = hudContainer

local hudLayout = Instance.new("UIListLayout")
hudLayout.SortOrder = Enum.SortOrder.LayoutOrder
hudLayout.Padding = UDim.new(0, 5)
hudLayout.Parent = hudContainer

local hudSlotPool = {}
PD.hudSlotPool = hudSlotPool

local function createSlot()
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(1, 0, 0, 52)
    slot.BackgroundColor3 = Color3.fromRGB(11, 17, 13)
    slot.BorderSizePixel = 0

    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 5)
    slotCorner.Parent = slot

    local slotStroke = Instance.new("UIStroke")
    slotStroke.Name = "Stroke"
    slotStroke.Color = Color3.fromRGB(31, 50, 35)
    slotStroke.Transparency = 0.35
    slotStroke.Thickness = 1
    slotStroke.Parent = slot

    local categoryBar = Instance.new("Frame")
    categoryBar.Name = "CategoryBar"
    categoryBar.Size = UDim2.new(0, 3, 0, 34)
    categoryBar.Position = UDim2.new(0, 0, 0, 9)
    categoryBar.BackgroundColor3 = accent
    categoryBar.BorderSizePixel = 0
    categoryBar.Parent = slot

    local categoryCorner = Instance.new("UICorner")
    categoryCorner.CornerRadius = UDim.new(0, 2)
    categoryCorner.Parent = categoryBar

    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 40, 0, 40)
    iconFrame.Position = UDim2.new(0, 9, 0, 6)
    iconFrame.BackgroundColor3 = Color3.fromRGB(6, 10, 8)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = slot

    local iconFrameCorner = Instance.new("UICorner")
    iconFrameCorner.CornerRadius = UDim.new(0, 5)
    iconFrameCorner.Parent = iconFrame

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Name = "Stroke"
    iconStroke.Color = accent
    iconStroke.Transparency = 0.55
    iconStroke.Thickness = 1
    iconStroke.Parent = iconFrame

    local iconImg = Instance.new("ImageLabel")
    iconImg.Name = "Icon"
    iconImg.Size = UDim2.new(1, -6, 1, -6)
    iconImg.Position = UDim2.new(0, 3, 0, 3)
    iconImg.BackgroundTransparency = 1
    iconImg.ScaleType = Enum.ScaleType.Fit
    iconImg.Parent = iconFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -64, 0, 16)
    nameLabel.Position = UDim2.new(0, 54, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(238, 247, 241)
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = slot

    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Name = "Category"
    categoryLabel.Size = UDim2.new(1, -64, 0, 13)
    categoryLabel.Position = UDim2.new(0, 54, 0, 25)
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.TextColor3 = accent
    categoryLabel.TextSize = 8
    categoryLabel.Font = Enum.Font.GothamBold
    categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    categoryLabel.Parent = slot

    return slot
end

local function getOrCreateSlot()
    local slot = table.remove(hudSlotPool)
    if not slot then
        slot = createSlot()
    end
    slot.Parent = hudContainer
    slot.Visible = true
    return slot
end

local activeHudSlots = {}
PD.activeHudSlots = activeHudSlots

local function setSlot(slot, itemName, category, categoryColor, iconId)
    local iconImg = slot:FindFirstChild("IconFrame") and slot.IconFrame:FindFirstChild("Icon")
    local nameLabel = slot:FindFirstChild("Name")
    local categoryLabel = slot:FindFirstChild("Category")
    local categoryBar = slot:FindFirstChild("CategoryBar")
    local iconFrame = slot:FindFirstChild("IconFrame")
    local slotStroke = slot:FindFirstChild("Stroke")

    if iconImg then iconImg.Image = iconId or "rbxassetid://0" end
    if nameLabel then nameLabel.Text = itemName or "" end
    if categoryLabel then
        categoryLabel.Text = category or "ITEM"
        categoryLabel.TextColor3 = categoryColor or Color3.fromRGB(150, 170, 158)
    end
    if categoryBar then categoryBar.BackgroundColor3 = categoryColor or accent end
    if iconFrame then
        local iconStroke = iconFrame:FindFirstChild("Stroke")
        if iconStroke then iconStroke.Color = categoryColor or accent end
    end
    if slotStroke then
        slotStroke.Color = categoryColor and categoryColor:Lerp(Color3.fromRGB(31, 50, 35), 0.65) or Color3.fromRGB(31, 50, 35)
    end
end

local function updateInventoryHUD()
    if not hudFrame.Visible then return end

    local currentAccent = silentAim.InventoryAccent or accent
    hudStroke.Color = currentAccent
    headerLabel.TextColor3 = currentAccent
    accentBar.BackgroundColor3 = currentAccent
    headerLine.BackgroundColor3 = currentAccent
    liveDot.BackgroundColor3 = currentAccent

    local targetChar = PD.getTargetedPlayerCharacter()

    for _, slot in ipairs(activeHudSlots) do
        slot.Parent = nil
        slot.Visible = false
        table.insert(hudSlotPool, slot)
    end
    table.clear(activeHudSlots)

    if not targetChar then
        targetNameLabel.Text = "NO TARGET"
        local slot = getOrCreateSlot()
        setSlot(slot, "Searching...", "STANDBY", Color3.fromRGB(120, 145, 130), "rbxassetid://0")
        slot.LayoutOrder = #activeHudSlots + 1
        table.insert(activeHudSlots, slot)
        return
    end

    local targetPlayer = PD.players:GetPlayerFromCharacter(targetChar)
    targetNameLabel.Text = targetPlayer and targetPlayer.Name or "AI TARGET"

    local equipped = PD.getEquippedCharacterItems(targetChar)
    local orderedItems = {}

    if silentAim.InventoryShowWeapon and equipped.weapon then
        table.insert(orderedItems, equipped.weapon)
    end

    if silentAim.InventoryShowGear then
        for _, armorName in ipairs(equipped.armor) do
            table.insert(orderedItems, armorName)
        end
    end

    if #orderedItems == 0 then
        local slot = getOrCreateSlot()
        setSlot(slot, "None Equipped", "EMPTY", Color3.fromRGB(120, 145, 130), "rbxassetid://0")
        slot.LayoutOrder = #activeHudSlots + 1
        table.insert(activeHudSlots, slot)
        return
    end

    for _, itemName in ipairs(orderedItems) do
        local category, categoryColor = PD.getItemCategory(itemName)
        local slot = getOrCreateSlot()
        setSlot(slot, itemName, category, categoryColor, itemIcons[itemName])
        slot.LayoutOrder = #activeHudSlots + 1
        table.insert(activeHudSlots, slot)
    end
end
PD.updateInventoryHUD = updateInventoryHUD
