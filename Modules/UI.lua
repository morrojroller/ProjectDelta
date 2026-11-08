-- // Modules/UI.lua
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

    -- FOV Circle
    local fovCircle = Drawing.new("Circle")
    fovCircle.Visible = silentAimData.Enabled
    fovCircle.Filled = false
    fovCircle.NumSides = 60
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1
    fovCircle.Radius = silentAimData.FovRadius

    -- Main Config Frame
    local mainFrame = Instance.new("Frame")
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

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "  PROJECT DELTA // CONFIGURATOR"
    titleLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Inventory HUD Frame
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

    local hudContainer = Instance.new("Frame")
    hudContainer.Size = UDim2.new(1, -10, 1, -44)
    hudContainer.Position = UDim2.new(0, 5, 0, 40)
    hudContainer.BackgroundTransparency = 1
    hudContainer.Parent = hudFrame

    local hudLayout = Instance.new("UIListLayout")
    hudLayout.SortOrder = Enum.SortOrder.LayoutOrder
    hudLayout.Padding = UDim.new(0, 6)
    hudLayout.Parent = hudContainer

    return {
        ScreenGui = screenGui,
        FovCircle = fovCircle,
        MainFrame = mainFrame,
        HudFrame = hudFrame,
        TargetNameLabel = targetNameLabel,
        HudContainer = hudContainer
    }
end

return UIModule