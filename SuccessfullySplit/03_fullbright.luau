-- // 03_fullbright.luau
-- // Lighting backup + fullbright toggle logic.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local lighting = PD.lighting
local silentAim = PD.silentAim

-- // Fullbright Logic & Backup State
local lightingBackup = {
    Brightness = lighting.Brightness,
    ClockTime = lighting.ClockTime,
    FogStart = lighting.FogStart,
    FogEnd = lighting.FogEnd,
    GlobalShadows = lighting.GlobalShadows,
    Ambient = lighting.Ambient,
    OutdoorAmbient = lighting.OutdoorAmbient,
    AtmosphereDensity = lighting:FindFirstChildOfClass("Atmosphere") and lighting:FindFirstChildOfClass("Atmosphere").Density or nil
}
PD.lightingBackup = lightingBackup

local function applyFullbright(state)
    local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
    if state then
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogStart = 0
        lighting.FogEnd = 999999
        lighting.GlobalShadows = false
        lighting.Ambient = Color3.fromRGB(170, 170, 170)
        lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
        if atmosphere then
            atmosphere.Density = 0
        end
    else
        lighting.Brightness = lightingBackup.Brightness
        lighting.ClockTime = lightingBackup.ClockTime
        lighting.FogStart = lightingBackup.FogStart
        lighting.FogEnd = lightingBackup.FogEnd
        lighting.GlobalShadows = lightingBackup.GlobalShadows
        lighting.Ambient = lightingBackup.Ambient
        lighting.OutdoorAmbient = lightingBackup.OutdoorAmbient
        if atmosphere and lightingBackup.AtmosphereDensity then
            atmosphere.Density = lightingBackup.AtmosphereDensity
        end
    end
end
PD.applyFullbright = applyFullbright

if silentAim.Fullbright then
    applyFullbright(true)
end
