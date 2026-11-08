-- // 14_cleanup.luau
-- // Unfail-safe global cleanup + unload hooks.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local localPlayer = PD.localPlayer

-- // Unfail-Safe Global Cleanup Function (Guaranteed Full Deallocation & Restoration)
local function globalCleanup()
    if PD.cleaned then return end
    PD.cleaned = true

    pcall(function()
        if PD.renderConn then PD.renderConn:Disconnect() end
        if PD.inputConn then PD.inputConn:Disconnect() end
        if PD.addedConn then PD.addedConn:Disconnect() end
        if PD.removingConn then PD.removingConn:Disconnect() end

        if PD.fovCircle then
            pcall(function() PD.fovCircle:Remove() end)
        end

        for char, _ in pairs(PD.characterDrawings) do
            pcall(function() PD.removeCharacterDrawings(char) end)
        end
        table.clear(PD.characterDrawings)

        PD.applyFullbright(false)
        PD.restoreAmmoMods()
        PD.restoreBulletHook()

        if PD.UI and PD.UI.Cleanup then
            pcall(function() PD.UI:Cleanup() end)
        end

        if PD.screenGui then
            pcall(function() PD.screenGui:Destroy() end)
        end
    end)
end
PD.globalCleanup = globalCleanup

-- // Auto-cleanup when the local player leaves / respawns out of the game
localPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        globalCleanup()
    end
end)
