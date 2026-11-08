-- // Modules/UI.lua (Patched for Modular Loadstring Support)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local UIModule = {}

function UIModule.CreateUI(silentAimData, configModule, fullbrightModule, combatModule, icons, hudModule, aiModule)
    local guiParent = (gethui and gethui()) or (syn and syn.protect_gui and CoreGui) or CoreGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SilentAimConfig"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = guiParent

    -- // FOV Circle
    local fovCircle = Drawing.new("Circle")
    fovCircle.Visible = silentAimData.Enabled
    fovCircle.Filled = false
    fovCircle.NumSides = 60
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1
    fovCircle.Transparency = 1
    fovCircle.Radius = silentAimData.FovRadius

    -- // Main Config Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 540, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -270, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    mainFrame.BorderColor3 = Color3.fromRGB(50, 120, 220)
    mainFrame.BorderSizePixel = 2
    mainFrame.Visible = not silentAimData.HideVisibles
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 8)
    titleBarCorner.Parent = titleBar

    local titleFixCover = Instance.new("Frame")
    titleFixCover.Size = UDim2.new(1, 0, 0, 10)
    titleFixCover.Position = UDim2.new(0, 0, 1, -10)
    titleFixCover.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    titleFixCover.BorderSizePixel = 0
    titleFixCover.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "  PROJECT DELTA // CONFIGURATOR"
    titleLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- // Draggable Implementation for Main Menu
    local draggingMain, dragInputMain, dragStartMain, startPosMain
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = true
            dragStartMain = input.Position
            startPosMain = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingMain = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInputMain = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInputMain and draggingMain then
            local delta = input.Position - dragStartMain
            mainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
        end
    end)

    -- // Top Control Buttons Container
    local topControlsFrame = Instance.new("Frame")
    topControlsFrame.Size = UDim2.new(1, -20, 0, 32)
    topControlsFrame.Position = UDim2.new(0, 10, 0, 50)
    topControlsFrame.BackgroundTransparency = 1
    topControlsFrame.Parent = mainFrame

    local topLayout = Instance.new("UIListLayout")
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.Padding = UDim.new(0, 10)
    topLayout.Parent = topControlsFrame

    local function styleToggleButton(btn, text, state)
        btn.Size = UDim2.new(0, 160, 1, 0)
        btn.BackgroundColor3 = state and Color3.fromRGB(30, 140, 70) or Color3.fromRGB(140, 35, 35)
        btn.Text = text .. ": " .. tostring(state)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
    end

    -- Visible Only Toggle
    local visibleToggleBtn = Instance.new("TextButton")
    visibleToggleBtn.Parent = topControlsFrame
    styleToggleButton(visibleToggleBtn, "Visible Only", silentAimData.VisibleOnly)
    visibleToggleBtn.MouseButton1Click:Connect(function()
        silentAimData.VisibleOnly = not silentAimData.VisibleOnly
        styleToggleButton(visibleToggleBtn, "Visible Only", silentAimData.VisibleOnly)
        if configModule.Save then configModule:Save() end
    end)

    -- Fullbright Toggle
    local fullbrightToggleBtn = Instance.new("TextButton")
    fullbrightToggleBtn.Parent = topControlsFrame
    styleToggleButton(fullbrightToggleBtn, "Fullbright", silentAimData.Fullbright)
    fullbrightToggleBtn.MouseButton1Click:Connect(function()
        silentAimData.Fullbright = not silentAimData.Fullbright
        styleToggleButton(fullbrightToggleBtn, "Fullbright", silentAimData.Fullbright)
        fullbrightModule.Apply(silentAimData.Fullbright)
        if configModule.Save then configModule:Save() end
    end)

    -- Hide Visibles Toggle
    local hideVisiblesToggleBtn = Instance.new("TextButton")
    hideVisiblesToggleBtn.Parent = topControlsFrame
    styleToggleButton(hideVisiblesToggleBtn, "Hide Visibles", silentAimData.HideVisibles)
    hideVisiblesToggleBtn.MouseButton1Click:Connect(function()
        silentAimData.HideVisibles = not silentAimData.HideVisibles
        styleToggleButton(hideVisiblesToggleBtn, "Hide Visibles", silentAimData.HideVisibles)
        mainFrame.Visible = not silentAimData.HideVisibles
        if configModule.Save then configModule:Save() end
    end)

    -- // Left Container (HitParts)
    local leftContainer = Instance.new("Frame")
    leftContainer.Size = UDim2.new(0.5, -15, 1, -100)
    leftContainer.Position = UDim2.new(0, 10, 0, 90)
    leftContainer.BackgroundTransparency = 1
    leftContainer.Parent = mainFrame

    local leftTitle = Instance.new("TextLabel")
    leftTitle.Size = UDim2.new(1, 0, 0, 20)
    leftTitle.BackgroundTransparency = 1
    leftTitle.Text = "Target HitPart"
    leftTitle.TextColor3 = Color3.fromRGB(160, 170, 190)
    leftTitle.TextSize = 13
    leftTitle.Font = Enum.Font.GothamBold
    leftTitle.Parent = leftContainer

    local partsScrolling = Instance.new("ScrollingFrame")
    partsScrolling.Size = UDim2.new(1, 0, 1, -25)
    partsScrolling.Position = UDim2.new(0, 0, 0, 25)
    partsScrolling.BackgroundTransparency = 1
    partsScrolling.BorderSizePixel = 0
    partsScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    partsScrolling.ScrollBarThickness = 4
    partsScrolling.Parent = leftContainer

    local partsLayout = Instance.new("UIListLayout")
    partsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    partsLayout.Padding = UDim.new(0, 5)
    partsLayout.Parent = partsScrolling

    -- // Right Container (Player Exclusions)
    local rightContainer = Instance.new("Frame")
    rightContainer.Size = UDim2.new(0.5, -15, 1, -100)
    rightContainer.Position = UDim2.new(0.5, 5, 0, 90)
    rightContainer.BackgroundTransparency = 1
    rightContainer.Parent = mainFrame

    local rightTitle = Instance.new("TextLabel")
    rightTitle.Size = UDim2.new(1, 0, 0, 20)
    rightTitle.BackgroundTransparency = 1
    rightTitle.Text = "Player Target / Exclusions"
    rightTitle.TextColor3 = Color3.fromRGB(160, 170, 190)
    rightTitle.TextSize = 13
    rightTitle.Font = Enum.Font.GothamBold
    rightTitle.Parent = rightContainer

    local playersScrolling = Instance.new("ScrollingFrame")
    playersScrolling.Size = UDim2.new(1, 0, 1, -25)
    playersScrolling.Position = UDim2.new(0, 0, 0, 25)
    playersScrolling.BackgroundTransparency = 1
    playersScrolling.BorderSizePixel = 0
    playersScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playersScrolling.ScrollBarThickness = 4
    playersScrolling.Parent = rightContainer

    local playersLayout = Instance.new("UIListLayout")
    playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playersLayout.Padding = UDim.new(0, 5)
    playersLayout.Parent = playersScrolling

    local allowedHitParts = {
        ["FaceHitBox"] = true, ["HeadTopHitBox"] = true, ["Head"] = true,
        ["UpperTorso"] = true, ["LowerTorso"] = true, ["Torso"] = true,
        ["LeftUpperLeg"] = true, ["RightUpperLeg"] = true, ["LeftLowerLeg"] = true,
        ["RightLowerLeg"] = true, ["LeftLeg"] = true, ["RightLeg"] = true,
        ["LeftFoot"] = true, ["RightFoot"] = true
    }

    local createdPartButtons = {}
    local createdPlayerButtons = {}

    local function updateUILists()
        if not mainFrame.Visible then return end
        
        local foundParts = {"Random"}
        local seenParts = {["Random"] = true}
        
        local function processCharacter(char)
            if not char or Players:GetPlayerFromCharacter(char) == LocalPlayer then return end
            for _, desc in ipairs(char:GetChildren()) do
                if desc:IsA("BasePart") and allowedHitParts[desc.Name] and not seenParts[desc.Name] then
                    seenParts[desc.Name] = true
                    table.insert(foundParts, desc.Name)
                end
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then processCharacter(p.Character) end
        end
        for model, _ in pairs(aiModule.CachedAI) do
            processCharacter(model)
        end

        for _, btn in pairs(createdPartButtons) do btn:Destroy() end
        createdPartButtons = {}

        for _, partName in ipairs(foundParts) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 30)
            btn.BackgroundColor3 = (silentAimData.SelectedHitPart == partName) and Color3.fromRGB(40, 110, 200) or Color3.fromRGB(30, 30, 38)
            btn.BorderSizePixel = 0
            btn.Text = "  " .. partName
            btn.TextColor3 = Color3.fromRGB(240, 240, 240)
            btn.TextSize = 13
            btn.Font = Enum.Font.Gotham
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = partsScrolling

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 5)
            corner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                silentAimData.SelectedHitPart = partName
                if configModule.Save then configModule:Save() end
                for _, b in pairs(createdPartButtons) do
                    b.BackgroundColor3 = (b.Text == "  " .. silentAimData.SelectedHitPart) and Color3.fromRGB(40, 110, 200) or Color3.fromRGB(30, 30, 38)
                end
            end)

            table.insert(createdPartButtons, btn)
        end

        for _, btn in pairs(createdPlayerButtons) do btn:Destroy() end
        createdPlayerButtons = {}

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local isExcluded = silentAimData.ExcludedPlayers[p.Name] == true
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -5, 0, 30)
                btn.BackgroundColor3 = isExcluded and Color3.fromRGB(150, 45, 45) or Color3.fromRGB(40, 130, 70)
                btn.BorderSizePixel = 0
                btn.Text = "  " .. p.Name .. (isExcluded and " [EXCLUDED]" or " [TARGET]")
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextSize = 12
                btn.Font = Enum.Font.Gotham
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = playersScrolling

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 5)
                corner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    if silentAimData.ExcludedPlayers[p.Name] then
                        silentAimData.ExcludedPlayers[p.Name] = nil
                    else
                        silentAimData.ExcludedPlayers[p.Name] = true
                    end
                    if configModule.Save then configModule:Save() end
                    updateUILists()
                end)

                table.insert(createdPlayerButtons, btn)
            end
        end
    end

    task.spawn(function()
        while screenGui.Parent do
            pcall(updateUILists)
            task.wait(3)
        end
    end)

    -- // Inventory HUD Frame
    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "InventoryHUD"
    hudFrame.Size = UDim2.new(0, 115, 0, 520)
    hudFrame.Position = UDim2.new(0, silentAimData.InventoryPositionX, 0, silentAimData.InventoryPositionY)
    hudFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    hudFrame.BorderColor3 = Color3.fromRGB(60, 150, 255)
    hudFrame.BorderSizePixel = 2
    hudFrame.Visible = silentAimData.InventoryVisible
    hudFrame.Parent = screenGui

    local hudCorner = Instance.new("UICorner")
    hudCorner.CornerRadius = UDim.new(0, 8)
    hudCorner.Parent = hudFrame

    local hudTitleBar = Instance.new("Frame")
    hudTitleBar.Size = UDim2.new(1, 0, 0, 36)
    hudTitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    hudTitleBar.BorderSizePixel = 0
    hudTitleBar.Parent = hudFrame

    local targetNameLabel = Instance.new("TextLabel")
    targetNameLabel.Size = UDim2.new(1, 0, 1, 0)
    targetNameLabel.BackgroundTransparency = 1
    targetNameLabel.Text = "NO TARGET"
    targetNameLabel.TextColor3 = Color3.fromRGB(120, 210, 255)
    targetNameLabel.TextSize = 12
    targetNameLabel.Font = Enum.Font.GothamBold
    targetNameLabel.Parent = hudTitleBar

    return {
        ScreenGui = screenGui,
        FovCircle = fovCircle,
        MainFrame = mainFrame,
        HudFrame = hudFrame,
        TargetNameLabel = targetNameLabel,
        UpdateUILists = updateUILists
    }
end

return UIModule
