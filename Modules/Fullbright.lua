-- // Modules/Fullbright.lua
local Lighting = game:GetService("Lighting")

local FullbrightModule = {}
local lightingBackup = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    AtmosphereDensity = Lighting:FindFirstChildOfClass("Atmosphere") and Lighting:FindFirstChildOfClass("Atmosphere").Density or nil
}

function FullbrightModule.Apply(state)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogStart = 0
        Lighting.FogEnd = 999999
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(170, 170, 170)
        Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
        if atmosphere then atmosphere.Density = 0 end
    else
        Lighting.Brightness = lightingBackup.Brightness
        Lighting.ClockTime = lightingBackup.ClockTime
        Lighting.FogStart = lightingBackup.FogStart
        Lighting.FogEnd = lightingBackup.FogEnd
        Lighting.GlobalShadows = lightingBackup.GlobalShadows
        Lighting.Ambient = lightingBackup.Ambient
        Lighting.OutdoorAmbient = lightingBackup.OutdoorAmbient
        if atmosphere and lightingBackup.AtmosphereDensity then
            atmosphere.Density = lightingBackup.AtmosphereDensity
        end
    end
end

return FullbrightModule