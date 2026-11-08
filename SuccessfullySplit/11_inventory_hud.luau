-- // 11_inventory_hud.luau
-- // Right-side inventory HUD: UI construction, slot pool, and refresh logic.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local screenGui = PD.screenGui
local userInputService = PD.userInputService
local silentAim = PD.silentAim
local saveConfig = PD.saveConfig
local itemIcons = PD.itemIcons

-- // Modern Public HVH Style Tall Vertical Inventory HUD with Dynamic Expansion
local hudFrame = Instance.new("Frame")
hudFrame.Name = "InventoryHUD"
hudFrame.Size = UDim2.new(0, 115, 0, 120) -- Initial base height, dynamically expanded automatically by UIListLayout + AutomaticSize
hudFrame.Position = UDim2.new(0, silentAim.InventoryPositionX, 0, silentAim.InventoryPositionY)
hudFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
hudFrame.BorderColor3 = Color3.fromRGB(50, 130, 246)
hudFrame.BorderSizePixel = 1
hudFrame.AutomaticSize = Enum.AutomaticSize.Y
hudFrame.Visible = silentAim.InventoryVisible
hudFrame.Parent = screenGui
PD.hudFrame = hudFrame

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hudFrame

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(50, 130, 246)
hudStroke.Transparency = 0.5
hudStroke.Thickness = 1.2
hudStroke.Parent = hudFrame

local hudTitleBar = Instance.new("Frame")
hudTitleBar.Size = UDim2.new(1, 0, 0, 36)
hudTitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
hudTitleBar.BorderSizePixel = 0
hudTitleBar.Parent = hudFrame

local hudTitleCorner = Instance.new("UICorner")
hudTitleCorner.CornerRadius = UDim.new(0, 8)
hudTitleCorner.Parent = hudTitleBar

local hudTitleCover = Instance.new("Frame")
hudTitleCover.Size = UDim2.new(1, 0, 0, 8)
hudTitleCover.Position = UDim2.new(0, 0, 1, -8)
hudTitleCover.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
hudTitleCover.BorderSizePixel = 0
hudTitleCover.Parent = hudTitleBar

local targetNameLabel = Instance.new("TextLabel")
targetNameLabel.Size = UDim2.new(1, 0, 1, 0)
targetNameLabel.BackgroundTransparency = 1
targetNameLabel.Text = "NO TARGET"
targetNameLabel.TextColor3 = Color3.fromRGB(120, 210, 255)
targetNameLabel.TextSize = 11
targetNameLabel.Font = Enum.Font.GothamBold
targetNameLabel.Parent = hudTitleBar
PD.targetNameLabel = targetNameLabel

-- // Draggable implementation for Inventory HUD
local draggingHUD, dragInputHUD, dragStartHUD, startPosHUD
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
            end
        end)
    end
end)

hudTitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputHUD = input
    end
end)

userInputService.InputChanged:Connect(function(input)
    if input == dragInputHUD and draggingHUD then
        local delta = input.Position - dragStartHUD
        hudFrame.Position = UDim2.new(startPosHUD.X.Scale, startPosHUD.X.Offset + delta.X, startPosHUD.Y.Scale, startPosHUD.Y.Offset + delta.Y)
    end
end)

local hudContainer = Instance.new("Frame")
hudContainer.Size = UDim2.new(1, -10, 0, 0)
hudContainer.Position = UDim2.new(0, 5, 0, 42)
hudContainer.BackgroundTransparency = 1
hudContainer.AutomaticSize = Enum.AutomaticSize.Y
hudContainer.Parent = hudFrame

local hudLayout = Instance.new("UIListLayout")
hudLayout.SortOrder = Enum.SortOrder.LayoutOrder
hudLayout.Padding = UDim.new(0, 6)
hudLayout.Parent = hudContainer
PD.hudContainer = hudContainer

-- // Icon Caching & Re-use Pool System (Instant Load / Zero Lag)
local hudSlotPool = {}
PD.hudSlotPool = hudSlotPool

local function getOrCreateSlot()
    local slot = table.remove(hudSlotPool)
    if not slot then
        slot = Instance.new("Frame")
        slot.Size = UDim2.new(1, 0, 0, 95)
        slot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        slot.BorderSizePixel = 0

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 6)
        slotCorner.Parent = slot

        local iconImg = Instance.new("ImageLabel")
        iconImg.Name = "Icon"
        iconImg.Size = UDim2.new(0, 64, 0, 64)
        iconImg.Position = UDim2.new(0.5, -32, 0, 4)
        iconImg.BackgroundTransparency = 1
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.Parent = slot

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, -4, 0, 20)
        nameLabel.Position = UDim2.new(0, 2, 0, 71)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameLabel.TextSize = 10
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextTruncate = Enum.TextTruncate.SplitWord
        nameLabel.Parent = slot
    end
    slot.Parent = hudContainer
    slot.Visible = true
    return slot
end
PD.getOrCreateSlot = getOrCreateSlot

local activeHudSlots = {}
PD.activeHudSlots = activeHudSlots

local function updateInventoryHUD()
    if not hudFrame.Visible then return end

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
        slot.FindFirstChild(slot, "Icon").Image = "rbxassetid://0"
        slot.FindFirstChild(slot, "Name").Text = "Searching..."
        table.insert(activeHudSlots, slot)
        return
    end

    local targetPlayer = PD.players:GetPlayerFromCharacter(targetChar)
    targetNameLabel.Text = targetPlayer and targetPlayer.Name or "AI TARGET"

    local equipped = PD.getEquippedCharacterItems(targetChar)
    local orderedItems = {}

    if equipped.weapon then
        table.insert(orderedItems, {name = equipped.weapon, type = "WEAR"})
    end

    for _, armorName in ipairs(equipped.armor) do
        table.insert(orderedItems, {name = armorName, type = "GEAR"})
    end

    if #orderedItems == 0 then
        local slot = getOrCreateSlot()
        slot.FindFirstChild(slot, "Icon").Image = "rbxassetid://0"
        slot.FindFirstChild(slot, "Name").Text = "None Equipped"
        table.insert(activeHudSlots, slot)
        return
    end

    for _, itemData in ipairs(orderedItems) do
        local slot = getOrCreateSlot()
        local iconImg = slot:FindFirstChild("Icon")
        local nameLabel = slot:FindFirstChild("Name")

        iconImg.Image = itemIcons[itemData.name] or "rbxassetid://0"
        nameLabel.Text = itemData.name

        table.insert(activeHudSlots, slot)
    end
end
PD.updateInventoryHUD = updateInventoryHUD
