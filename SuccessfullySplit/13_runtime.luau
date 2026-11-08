-- // 13_runtime.luau
-- // Background refresh loops, render loop, and configurable hotkeys.

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

-- // Render loop: FOV circle + ESP
local renderConn = runService.Heartbeat:Connect(function()
    local fovCircle = PD.fovCircle

    if fovCircle then
        fovCircle.Radius = silentAim.FovRadius
        fovCircle.Color = silentAim.FovColor
        fovCircle.Thickness = silentAim.FovThickness
        fovCircle.Filled = silentAim.FovFilled
        fovCircle.Visible = silentAim.Enabled and silentAim.FovCircle

        if fovCircle.Visible then
            fovCircle.Position = camera.ViewportSize / 2
        end
    end

    PD.updateVisuals()
end)
PD.renderConn = renderConn

-- // Configurable hotkeys
local inputConn = userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not PD.UI or not PD.UI.GetInputName then return end

    local inputName = PD.UI:GetInputName(input)
    if not inputName then return end

    local binds = silentAim.Keybinds

    if inputName == binds.Aim then
        silentAim.Enabled = not silentAim.Enabled
        if PD.fovCircle then
            PD.fovCircle.Visible = silentAim.Enabled and silentAim.FovCircle
        end
        if PD.UI and PD.UI.Sync then
            PD.UI.Sync()
        end
    elseif inputName == binds.Menu then
        if silentAim.HideVisibles then
            silentAim.HideVisibles = false
            PD.saveConfig()
        end
        if PD.UI and PD.UI.Window then
            PD.UI.Window:Toggle()
            if PD.UI.Window:IsOpen() and PD.updateUILists then
                PD.updateUILists()
            end
            if PD.UI.Sync then
                PD.UI.Sync()
            end
        end
    elseif inputName == binds.Esp then
        silentAim.EspEnabled = not silentAim.EspEnabled
        if not silentAim.EspEnabled and PD.clearEsp then
            PD.clearEsp()
        end
        if PD.UI and PD.UI.Sync then
            PD.UI.Sync()
        end
    elseif inputName == binds.Unload then
        if PD.globalCleanup then
            PD.globalCleanup()
        end
    end
end)
PD.inputConn = inputConn
