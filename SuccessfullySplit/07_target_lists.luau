-- // 07_target_lists.luau
-- // Combat tab: hitpart selector + player exclusion/target list.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local UI = PD.UI
local Theme = UI.Theme
local silentAim = PD.silentAim
local players = PD.players
local localPlayer = PD.localPlayer
local cachedAI = PD.cachedAI
local saveConfig = PD.saveConfig

local combatTab = UI.Tabs.Combat
local allowedHitParts = PD.allowedHitParts
if not allowedHitParts then
    allowedHitParts = {
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
end

local function addScroll(section, height)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 0, height)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 2
    frame.ScrollBarImageColor3 = Theme.AccentDim
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.LayoutOrder = section._order
    section._order = section._order + 1
    frame.Parent = section.Frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame
    return frame
end

local partSection = combatTab:Section("Target Hitpart")
local partsScrolling = addScroll(partSection, 138)

local playerSection = combatTab:Section("Player Target / Exclusions")
local searchQuery = ""
local updateUILists

playerSection:Textbox("Search", "Filter players...", "", function(text)
    searchQuery = string.lower(text or "")
    if updateUILists then
        updateUILists()
    end
end)

local playersScrolling = addScroll(playerSection, 176)

local createdPartButtons = {}
local createdPlayerButtons = {}

local function stylePartButton(button, selected)
    button.BackgroundColor3 = selected and Color3.fromRGB(10, 45, 26) or Theme.Background
    button.TextColor3 = selected and Theme.Accent or Theme.TextDim
    local stroke = button:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = selected and Theme.Accent or Theme.Border
        stroke.Transparency = selected and 0.2 or 0.4
    end
end

updateUILists = function()
    if not UI.Window or not UI.Window:IsOpen() then return end

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

    for _, entry in ipairs(createdPartButtons) do
        entry.Button:Destroy()
    end
    createdPartButtons = {}

    for index, partName in ipairs(foundParts) do
        local selected = (silentAim.SelectedHitPart == partName)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -4, 0, 30)
        button.BackgroundColor3 = Theme.Background
        button.BorderSizePixel = 0
        button.Text = "  " .. partName
        button.TextColor3 = Theme.TextDim
        button.TextSize = 11
        button.Font = Theme.Font
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.AutoButtonColor = false
        button.LayoutOrder = index
        button.Parent = partsScrolling
        button.MouseEnter:Connect(function()
            if silentAim.SelectedHitPart ~= partName then
                button.BackgroundColor3 = Theme.PanelHover
            end
        end)
        button.MouseLeave:Connect(function()
            if silentAim.SelectedHitPart ~= partName then
                button.BackgroundColor3 = Theme.Background
            end
        end)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Border
        stroke.Transparency = 0.4
        stroke.Thickness = 1
        stroke.Parent = button

        stylePartButton(button, selected)

        button.MouseButton1Click:Connect(function()
            silentAim.SelectedHitPart = partName
            saveConfig()
            for _, entry in ipairs(createdPartButtons) do
                stylePartButton(entry.Button, entry.Part == partName)
            end
        end)

        table.insert(createdPartButtons, {Button = button, Part = partName})
    end

    for _, button in ipairs(createdPlayerButtons) do
        button:Destroy()
    end
    createdPlayerButtons = {}

    for index, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            local name = player.Name
            local matches = (searchQuery == "" or string.find(string.lower(name), searchQuery, 1, true) ~= nil)
            if matches then
                local isExcluded = silentAim.ExcludedPlayers[name] == true

                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, -4, 0, 30)
                button.BackgroundColor3 = isExcluded and Color3.fromRGB(38, 14, 14) or Color3.fromRGB(9, 34, 21)
                button.BorderSizePixel = 0
                button.Text = "  " .. name .. (isExcluded and "   [EXCLUDED]" or "   [TARGET]")
                button.TextColor3 = isExcluded and Theme.Danger or Theme.Accent
                button.TextSize = 10
                button.Font = Theme.FontBold
                button.TextXAlignment = Enum.TextXAlignment.Left
                button.AutoButtonColor = false
                button.LayoutOrder = index
                button.Parent = playersScrolling

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = button

                local stroke = Instance.new("UIStroke")
                stroke.Color = isExcluded and Theme.Danger or Theme.Accent
                stroke.Transparency = 0.55
                stroke.Thickness = 1
                stroke.Parent = button

                button.MouseButton1Click:Connect(function()
                    if silentAim.ExcludedPlayers[name] then
                        silentAim.ExcludedPlayers[name] = nil
                    else
                        silentAim.ExcludedPlayers[name] = true
                    end
                    saveConfig()
                    updateUILists()
                end)

                table.insert(createdPlayerButtons, button)
            end
        end
    end
end

PD.updateUILists = updateUILists
