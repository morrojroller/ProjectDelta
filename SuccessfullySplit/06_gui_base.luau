-- // 06_gui_base.luau
-- // ScreenGui, main window shell, title bar dragging and top toggle buttons.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local userInputService = PD.userInputService
local coreGui = PD.coreGui
local silentAim = PD.silentAim
local saveConfig = PD.saveConfig
local applyFullbright = PD.applyFullbright

-- // GUI Parent Setup (Stealthy CoreGui Protection)
local guiParent = (gethui and gethui()) or (syn and syn.protect_gui and coreGui) or coreGui
PD.guiParent = guiParent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SilentAimConfig"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent
PD.screenGui = screenGui

-- // Ultra-Modern Redesigned Right-Alt Menu (Sleek Dark Theme, Neon Accents, Glassmorphism)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 560, 0, 440)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
mainFrame.BorderColor3 = Color3.fromRGB(45, 45, 60)
mainFrame.BorderSizePixel = 1
mainFrame.Visible = not silentAim.HideVisibles
mainFrame.Parent = screenGui
PD.mainFrame = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 130, 246)
mainStroke.Transparency = 0.4
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
PD.titleBar = titleBar

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 10)
titleBarCorner.Parent = titleBar

local titleFixCover = Instance.new("Frame")
titleFixCover.Size = UDim2.new(1, 0, 0, 12)
titleFixCover.Position = UDim2.new(0, 0, 1, -12)
titleFixCover.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
titleFixCover.BorderSizePixel = 0
titleFixCover.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "PROJECT DELTA // CONTROL HUB"
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.TextSize = 14
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

userInputService.InputChanged:Connect(function(input)
    if input == dragInputMain and draggingMain then
        local delta = input.Position - dragStartMain
        mainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
    end
end)

-- // Top Control Buttons Container
local topControlsFrame = Instance.new("Frame")
topControlsFrame.Size = UDim2.new(1, -30, 0, 36)
topControlsFrame.Position = UDim2.new(0, 15, 0, 55)
topControlsFrame.BackgroundTransparency = 1
topControlsFrame.Parent = mainFrame
PD.topControlsFrame = topControlsFrame

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.SortOrder = Enum.SortOrder.LayoutOrder
topLayout.Padding = UDim.new(0, 12)
topLayout.Parent = topControlsFrame

-- // Helper to style ultra-modern chic toggle buttons with subtle glows & indicators
local function styleToggleButton(btn, text, state)
    btn.Size = UDim2.new(0, 164, 1, 0)
    btn.BackgroundColor3 = state and Color3.fromRGB(20, 38, 28) or Color3.fromRGB(38, 20, 20)
    btn.BorderColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    btn.BorderSizePixel = 1
    btn.Text = "  " .. text .. ": " .. (state and "ACTIVE" or "DISABLED")
    btn.TextColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
end
PD.styleToggleButton = styleToggleButton

-- // Visible Only Toggle Button
local visibleToggleBtn = Instance.new("TextButton")
visibleToggleBtn.Parent = topControlsFrame
styleToggleButton(visibleToggleBtn, "Visible Only", silentAim.VisibleOnly)
PD.visibleToggleBtn = visibleToggleBtn

visibleToggleBtn.MouseButton1Click:Connect(function()
    silentAim.VisibleOnly = not silentAim.VisibleOnly
    styleToggleButton(visibleToggleBtn, "Visible Only", silentAim.VisibleOnly)
    saveConfig()
end)

-- // Fullbright Toggle Button
local fullbrightToggleBtn = Instance.new("TextButton")
fullbrightToggleBtn.Parent = topControlsFrame
styleToggleButton(fullbrightToggleBtn, "Fullbright", silentAim.Fullbright)
PD.fullbrightToggleBtn = fullbrightToggleBtn

fullbrightToggleBtn.MouseButton1Click:Connect(function()
    silentAim.Fullbright = not silentAim.Fullbright
    styleToggleButton(fullbrightToggleBtn, "Fullbright", silentAim.Fullbright)
    applyFullbright(silentAim.Fullbright)
    saveConfig()
end)

-- // Hide Visibles Toggle Button
local hideVisiblesToggleBtn = Instance.new("TextButton")
hideVisiblesToggleBtn.Parent = topControlsFrame
styleToggleButton(hideVisiblesToggleBtn, "Hide Visibles", silentAim.HideVisibles)
PD.hideVisiblesToggleBtn = hideVisiblesToggleBtn

hideVisiblesToggleBtn.MouseButton1Click:Connect(function()
    silentAim.HideVisibles = not silentAim.HideVisibles
    styleToggleButton(hideVisiblesToggleBtn, "Hide Visibles", silentAim.HideVisibles)
    mainFrame.Visible = not silentAim.HideVisibles
    saveConfig()
end)
