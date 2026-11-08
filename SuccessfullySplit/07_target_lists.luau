-- // 07_target_lists.luau
-- // Hitpart selector list + player exclusion/target list UI.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local mainFrame = PD.mainFrame
local players = PD.players
local localPlayer = PD.localPlayer
local cachedAI = PD.cachedAI
local silentAim = PD.silentAim
local saveConfig = PD.saveConfig

-- // Left Container (HitParts)
local leftContainer = Instance.new("Frame")
leftContainer.Size = UDim2.new(0.5, -18, 1, -110)
leftContainer.Position = UDim2.new(0, 15, 0, 105)
leftContainer.BackgroundTransparency = 1
leftContainer.Parent = mainFrame

local leftTitle = Instance.new("TextLabel")
leftTitle.Size = UDim2.new(1, 0, 0, 20)
leftTitle.BackgroundTransparency = 1
leftTitle.Text = "TARGET HITPART SELECTION"
leftTitle.TextColor3 = Color3.fromRGB(140, 150, 175)
leftTitle.TextSize = 11
leftTitle.Font = Enum.Font.GothamBold
leftTitle.Parent = leftContainer

local partsScrolling = Instance.new("ScrollingFrame")
partsScrolling.Size = UDim2.new(1, 0, 1, -25)
partsScrolling.Position = UDim2.new(0, 0, 0, 25)
partsScrolling.BackgroundTransparency = 1
partsScrolling.BorderSizePixel = 0
partsScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
partsScrolling.ScrollBarThickness = 3
partsScrolling.Parent = leftContainer

local partsLayout = Instance.new("UIListLayout")
partsLayout.SortOrder = Enum.SortOrder.LayoutOrder
partsLayout.Padding = UDim.new(0, 6)
partsLayout.Parent = partsScrolling

-- // Right Container (Player Exclusions)
local rightContainer = Instance.new("Frame")
rightContainer.Size = UDim2.new(0.5, -18, 1, -110)
rightContainer.Position = UDim2.new(0.5, 3, 0, 105)
rightContainer.BackgroundTransparency = 1
rightContainer.Parent = mainFrame

local rightTitle = Instance.new("TextLabel")
rightTitle.Size = UDim2.new(1, 0, 0, 20)
rightTitle.BackgroundTransparency = 1
rightTitle.Text = "PLAYER TARGET / EXCLUSIONS"
rightTitle.TextColor3 = Color3.fromRGB(140, 150, 175)
rightTitle.TextSize = 11
rightTitle.Font = Enum.Font.GothamBold
rightTitle.Parent = rightContainer

local playersScrolling = Instance.new("ScrollingFrame")
playersScrolling.Size = UDim2.new(1, 0, 1, -25)
playersScrolling.Position = UDim2.new(0, 0, 0, 25)
playersScrolling.BackgroundTransparency = 1
playersScrolling.BorderSizePixel = 0
playersScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersScrolling.ScrollBarThickness = 3
playersScrolling.Parent = rightContainer

local playersLayout = Instance.new("UIListLayout")
playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersLayout.Padding = UDim.new(0, 6)
playersLayout.Parent = playersScrolling

local allowedHitParts = {
    ["FaceHitBox"] = true,
    ["HeadTopHitBox"] = true,
    ["Head"] = true,
    ["UpperTorso"] = true,
    ["LowerTorso"] = true,
    ["Torso"] = true,
    ["LeftUpperLeg"] = true,
    ["RightUpperLeg"] = true,
    ["LeftLowerLeg"] = true,
    ["RightLowerLeg"] = true,
    ["LeftLeg"] = true,
    ["RightLeg"] = true,
    ["LeftFoot"] = true,
    ["RightFoot"] = true
}
PD.allowedHitParts = allowedHitParts

-- // UI Population
local createdPartButtons = {}
local createdPlayerButtons = {}

local function updateUILists()
    if not mainFrame.Visible then return end

    local foundParts = {"Random"}
    local seenParts = {["Random"] = true}

    local function processCharacter(char)
        if not char or players:GetPlayerFromCharacter(char) == localPlayer then return end
        for _, desc in ipairs(char:GetChildren()) do
            if desc:IsA("BasePart") and allowedHitParts[desc.Name] and not seenParts[desc.Name] then
                seenParts[desc.Name] = true
                table.insert(foundParts, desc.Name)
            end
        end
    end

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= localPlayer then
            processCharacter(p.Character)
        end
    end
    for model, _ in pairs(cachedAI) do
        processCharacter(model)
    end

    for _, btn in pairs(createdPartButtons) do btn:Destroy() end
    createdPartButtons = {}

    for _, partName in ipairs(foundParts) do
        local isSelected = (silentAim.SelectedHitPart == partName)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 32)
        btn.BackgroundColor3 = isSelected and Color3.fromRGB(24, 43, 76) or Color3.fromRGB(20, 20, 28)
        btn.BorderColor3 = isSelected and Color3.fromRGB(50, 130, 246) or Color3.fromRGB(35, 35, 48)
        btn.BorderSizePixel = 1
        btn.Text = "  " .. partName
        btn.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 195, 210)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = partsScrolling

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            silentAim.SelectedHitPart = partName
            saveConfig()
            for _, b in pairs(createdPartButtons) do
                local matches = (b.Text == "  " .. silentAim.SelectedHitPart)
                b.BackgroundColor3 = matches and Color3.fromRGB(24, 43, 76) or Color3.fromRGB(20, 20, 28)
                b.BorderColor3 = matches and Color3.fromRGB(50, 130, 246) or Color3.fromRGB(35, 35, 48)
                b.TextColor3 = matches and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 195, 210)
            end
        end)

        table.insert(createdPartButtons, btn)
    end

    for _, btn in pairs(createdPlayerButtons) do btn:Destroy() end
    createdPlayerButtons = {}

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= localPlayer then
            local isExcluded = silentAim.ExcludedPlayers[p.Name] == true

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 32)
            btn.BackgroundColor3 = isExcluded and Color3.fromRGB(48, 22, 22) or Color3.fromRGB(20, 38, 28)
            btn.BorderColor3 = isExcluded and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113)
            btn.BorderSizePixel = 1
            btn.Text = "  " .. p.Name .. (isExcluded and " [EXCLUDED]" or " [TARGET]")
            btn.TextColor3 = isExcluded and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113)
            btn.TextSize = 11
            btn.Font = Enum.Font.GothamMedium
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = playersScrolling

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                if silentAim.ExcludedPlayers[p.Name] then
                    silentAim.ExcludedPlayers[p.Name] = nil
                else
                    silentAim.ExcludedPlayers[p.Name] = true
                end
                saveConfig()
                updateUILists()
            end)

            table.insert(createdPlayerButtons, btn)
        end
    end
end
PD.updateUILists = updateUILists
