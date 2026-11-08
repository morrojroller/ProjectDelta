-- // 13_runtime.luau
-- // Background refresh loops, render loop, and hotkey handling.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local runService = PD.runService
local userInputService = PD.userInputService
local silentAim = PD.silentAim
local camera = PD.camera
local localPlayer = PD.localPlayer
local players = PD.players

-- // Periodic UI list refresh
task.spawn(function()
    while PD.screenGui.Parent do
        pcall(PD.updateUILists)
        task.wait(3)
    end
end)

-- // Periodic inventory HUD refresh
task.spawn(function()
    while PD.screenGui.Parent do
        pcall(PD.updateInventoryHUD)
        task.wait(0.2)
    end
end)

-- // Keep local player ESP drawings removed
task.spawn(function()
    while PD.screenGui.Parent do
        pcall(function()
            if localPlayer.Character then
                PD.removeCharacterDrawings(localPlayer.Character)
            end
            for char, _ in pairs(PD.characterDrawings) do
                if char and players:GetPlayerFromCharacter(char) == localPlayer then
                    PD.removeCharacterDrawings(char)
                end
            end
        end)
        task.wait(0.3)
    end
end)

-- // RenderLoop for FOV Circle & Visuals
local renderConn = runService.Heartbeat:Connect(function()
    local fovCircle = PD.fovCircle
    fovCircle.Radius = silentAim.FovRadius
    fovCircle.Visible = silentAim.Enabled
    if fovCircle.Visible then
        fovCircle.Position = camera.ViewportSize / 2
    end

    PD.updateVisuals()
end)
PD.renderConn = renderConn

-- // Input / Toggles / Unloading
local inputConn
inputConn = userInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.CapsLock then
        silentAim.Enabled = not silentAim.Enabled
        PD.fovCircle.Visible = silentAim.Enabled
        PD.applyAmmoMods()
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        if silentAim.HideVisibles then
            silentAim.HideVisibles = false
            PD.hideVisiblesToggleBtn.BackgroundColor3 = Color3.fromRGB(38, 20, 20)
            PD.hideVisiblesToggleBtn.BorderColor3 = Color3.fromRGB(231, 76, 60)
            PD.hideVisiblesToggleBtn.TextColor3 = Color3.fromRGB(231, 76, 60)
            PD.hideVisiblesToggleBtn.Text = "  Hide Visibles: DISABLED"
            PD.saveConfig()
        end
        PD.mainFrame.Visible = not PD.mainFrame.Visible
        if PD.mainFrame.Visible then PD.updateUILists() end
    elseif input.KeyCode == Enum.KeyCode.LeftAlt then
        PD.visualsEnabled = not PD.visualsEnabled
        if not PD.visualsEnabled then
            for char, _ in pairs(PD.characterDrawings) do
                PD.removeCharacterDrawings(char)
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        if PD.globalCleanup then
            PD.globalCleanup()
        end
    end
end)
PD.inputConn = inputConn
