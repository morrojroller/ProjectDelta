-- // 06_gui_base.luau
-- // Fabled main window: Combat / Visuals / Misc / Settings.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local silentAim = PD.silentAim
local UI = PD.UI

local window = UI:CreateWindow({
    Title = "FABLED",
    Subtitle = "PROJECT DELTA",
    Version = "v2.0",
})
window:SetScale(silentAim.MenuScale)

local combat = window:Tab("Combat")
local visuals = window:Tab("Visuals")
local misc = window:Tab("Misc")
local settings = window:Tab("Settings")

UI.Tabs = {
    Combat = combat,
    Visuals = visuals,
    Misc = misc,
    Settings = settings,
}

local function toggleSetter(field, extra)
    return function(value)
        silentAim[field] = value
        if extra then extra(value) end
        PD.saveConfig()
    end
end

local function sliderSetter(field, extra)
    return function(value, finished)
        silentAim[field] = value
        if extra then extra(value) end
        if finished then PD.saveConfig() end
    end
end

local function colorSetter(field)
    return function(color, finished)
        silentAim[field] = color
        if finished then PD.saveConfig() end
    end
end

local function keybindSetter(field)
    return function(key)
        silentAim.Keybinds[field] = key
        PD.saveConfig()
    end
end

local function refreshHudPosition()
    if PD.hudFrame then
        PD.hudFrame.Position = UDim2.new(0, silentAim.InventoryPositionX, 0, silentAim.InventoryPositionY)
    end
end

-- // ---------------------------------------------------------------------------
-- // Combat
-- // ---------------------------------------------------------------------------

local aimSection = combat:Section("Aimbot")

local aimToggle = aimSection:Toggle("Silent Aim", silentAim.Enabled, toggleSetter("Enabled", function(value)
    if PD.fovCircle then
        PD.fovCircle.Visible = value and silentAim.FovCircle
    end
end))
UI:Bind(aimToggle, function() return silentAim.Enabled end)

local aimKey = aimSection:Keybind("Aim Keybind", silentAim.Keybinds.Aim, keybindSetter("Aim"))
UI:Bind(aimKey, function() return silentAim.Keybinds.Aim end)

local visibleToggle = aimSection:Toggle("Visible Only", silentAim.VisibleOnly, toggleSetter("VisibleOnly"))
UI:Bind(visibleToggle, function() return silentAim.VisibleOnly end)

local predictionToggle = aimSection:Toggle("Movement Prediction", silentAim.Prediction, toggleSetter("Prediction"))
UI:Bind(predictionToggle, function() return silentAim.Prediction end)

local fovSlider = aimSection:Slider("FOV Radius", 20, 800, silentAim.FovRadius, sliderSetter("FovRadius"), {
    suffix = " px",
    decimals = 0,
})
UI:Bind(fovSlider, function() return silentAim.FovRadius end)

local ammoToggle = aimSection:Toggle("No Recoil / No Drop", silentAim.AmmoMods, toggleSetter("AmmoMods", function()
    PD.applyAmmoMods()
end))
UI:Bind(ammoToggle, function() return silentAim.AmmoMods end)

-- // ---------------------------------------------------------------------------
-- // Visuals
-- // ---------------------------------------------------------------------------

local espSection = visuals:Section("Player ESP")

local espMaster = espSection:Toggle("ESP Enabled", silentAim.EspEnabled, toggleSetter("EspEnabled", function(value)
    if not value and PD.clearEsp then
        PD.clearEsp()
    end
end))
UI:Bind(espMaster, function() return silentAim.EspEnabled end)

local espSkeleton = espSection:Toggle("Skeleton", silentAim.EspSkeleton, toggleSetter("EspSkeleton"))
UI:Bind(espSkeleton, function() return silentAim.EspSkeleton end)

local espNames = espSection:Toggle("Names", silentAim.EspNames, toggleSetter("EspNames"))
UI:Bind(espNames, function() return silentAim.EspNames end)

local espDistance = espSection:Toggle("Distance", silentAim.EspDistance, toggleSetter("EspDistance"))
UI:Bind(espDistance, function() return silentAim.EspDistance end)

local espHealth = espSection:Toggle("Health", silentAim.EspHealth, toggleSetter("EspHealth"))
UI:Bind(espHealth, function() return silentAim.EspHealth end)

local espWeapon = espSection:Toggle("Weapon", silentAim.EspWeapon, toggleSetter("EspWeapon"))
UI:Bind(espWeapon, function() return silentAim.EspWeapon end)

local espTeam = espSection:Toggle("Team Tag", silentAim.EspTeam, toggleSetter("EspTeam"))
UI:Bind(espTeam, function() return silentAim.EspTeam end)

local espTracers = espSection:Toggle("Tracers", silentAim.EspTracers, toggleSetter("EspTracers"))
UI:Bind(espTracers, function() return silentAim.EspTracers end)

local espBox = espSection:Toggle("Boxes", silentAim.EspBox, toggleSetter("EspBox"))
UI:Bind(espBox, function() return silentAim.EspBox end)

local espDistanceSlider = espSection:Slider("Max Distance", 100, 5000, silentAim.EspMaxDistance, sliderSetter("EspMaxDistance"), {
    suffix = " studs",
    decimals = 0,
})
UI:Bind(espDistanceSlider, function() return silentAim.EspMaxDistance end)

local colorSection = visuals:Section("ESP Colors")

local colorVisible = colorSection:ColorPicker("Skeleton Visible", silentAim.EspColorVisible, colorSetter("EspColorVisible"))
UI:Bind(colorVisible, function() return silentAim.EspColorVisible end)

local colorOccluded = colorSection:ColorPicker("Skeleton Occluded", silentAim.EspColorOccluded, colorSetter("EspColorOccluded"))
UI:Bind(colorOccluded, function() return silentAim.EspColorOccluded end)

local colorName = colorSection:ColorPicker("Name Color", silentAim.EspColorName, colorSetter("EspColorName"))
UI:Bind(colorName, function() return silentAim.EspColorName end)

local colorInfo = colorSection:ColorPicker("Info Color", silentAim.EspColorInfo, colorSetter("EspColorInfo"))
UI:Bind(colorInfo, function() return silentAim.EspColorInfo end)

local colorWeapon = colorSection:ColorPicker("Weapon Color", silentAim.EspColorWeapon, colorSetter("EspColorWeapon"))
UI:Bind(colorWeapon, function() return silentAim.EspColorWeapon end)

local colorTracer = colorSection:ColorPicker("Tracer Color", silentAim.EspColorTracer, colorSetter("EspColorTracer"))
UI:Bind(colorTracer, function() return silentAim.EspColorTracer end)

local colorBox = colorSection:ColorPicker("Box Color", silentAim.EspColorBox, colorSetter("EspColorBox"))
UI:Bind(colorBox, function() return silentAim.EspColorBox end)

local worldSection = visuals:Section("World")

local fullbrightToggle = worldSection:Toggle("Fullbright", silentAim.Fullbright, toggleSetter("Fullbright", function(value)
    PD.applyFullbright(value)
end))
UI:Bind(fullbrightToggle, function() return silentAim.Fullbright end)

local hideMenuToggle = worldSection:Toggle("Hide Menu (Menu Key)", silentAim.HideVisibles, toggleSetter("HideVisibles", function(value)
    if value then
        window:SetVisible(false)
    end
end))
UI:Bind(hideMenuToggle, function() return silentAim.HideVisibles end)

local fovSection = visuals:Section("FOV Circle")

local fovCircleToggle = fovSection:Toggle("Show FOV Circle", silentAim.FovCircle, toggleSetter("FovCircle", function(value)
    if PD.fovCircle then
        PD.fovCircle.Visible = value and silentAim.Enabled
    end
end))
UI:Bind(fovCircleToggle, function() return silentAim.FovCircle end)

local fovThickness = fovSection:Slider("Thickness", 1, 5, silentAim.FovThickness, sliderSetter("FovThickness"), {
    decimals = 1,
})
UI:Bind(fovThickness, function() return silentAim.FovThickness end)

local fovColor = fovSection:ColorPicker("FOV Color", silentAim.FovColor, colorSetter("FovColor"))
UI:Bind(fovColor, function() return silentAim.FovColor end)

local fovFilled = fovSection:Toggle("Filled", silentAim.FovFilled, toggleSetter("FovFilled"))
UI:Bind(fovFilled, function() return silentAim.FovFilled end)

-- // ---------------------------------------------------------------------------
-- // Misc
-- // ---------------------------------------------------------------------------

local inventorySection = misc:Section("Inventory HUD")

local inventoryToggle = inventorySection:Toggle("Inventory HUD", silentAim.InventoryVisible, toggleSetter("InventoryVisible", function(value)
    if PD.hudFrame then
        PD.hudFrame.Visible = value
    end
end))
UI:Bind(inventoryToggle, function() return silentAim.InventoryVisible end)

local inventoryScale = inventorySection:Slider("HUD Scale", 0.6, 1.6, silentAim.InventoryScale, sliderSetter("InventoryScale", function(value)
    if PD.setInventoryScale then
        PD.setInventoryScale(value)
    end
end), {
    decimals = 2,
})
UI:Bind(inventoryScale, function() return silentAim.InventoryScale end)

local inventoryX = inventorySection:Slider("Position X", 0, 1920, silentAim.InventoryPositionX, sliderSetter("InventoryPositionX", refreshHudPosition), {
    suffix = " px",
})
UI:Bind(inventoryX, function() return silentAim.InventoryPositionX end)

local inventoryY = inventorySection:Slider("Position Y", 0, 1080, silentAim.InventoryPositionY, sliderSetter("InventoryPositionY", refreshHudPosition), {
    suffix = " px",
})
UI:Bind(inventoryY, function() return silentAim.InventoryPositionY end)

local inventoryWeapon = inventorySection:Toggle("Show Weapon", silentAim.InventoryShowWeapon, toggleSetter("InventoryShowWeapon"))
UI:Bind(inventoryWeapon, function() return silentAim.InventoryShowWeapon end)

local inventoryGear = inventorySection:Toggle("Show Gear", silentAim.InventoryShowGear, toggleSetter("InventoryShowGear"))
UI:Bind(inventoryGear, function() return silentAim.InventoryShowGear end)

local inventoryAccent = inventorySection:ColorPicker("HUD Accent", silentAim.InventoryAccent, colorSetter("InventoryAccent"))
UI:Bind(inventoryAccent, function() return silentAim.InventoryAccent end)

local utilitySection = misc:Section("Utility")

utilitySection:Button("Restore Ammo Attributes", function()
    PD.restoreAmmoMods()
end)

utilitySection:Button("Reset HUD Position", function()
    silentAim.InventoryPositionX = 30
    silentAim.InventoryPositionY = 220
    refreshHudPosition()
    PD.saveConfig()
    UI:Sync()
end)

-- // ---------------------------------------------------------------------------
-- // Settings
-- // ---------------------------------------------------------------------------

local keybindSection = settings:Section("Keybinds")

local menuKey = keybindSection:Keybind("Menu Toggle", silentAim.Keybinds.Menu, keybindSetter("Menu"))
UI:Bind(menuKey, function() return silentAim.Keybinds.Menu end)

local espKey = keybindSection:Keybind("ESP Toggle", silentAim.Keybinds.Esp, keybindSetter("Esp"))
UI:Bind(espKey, function() return silentAim.Keybinds.Esp end)

local unloadKey = keybindSection:Keybind("Unload", silentAim.Keybinds.Unload, keybindSetter("Unload"))
UI:Bind(unloadKey, function() return silentAim.Keybinds.Unload end)

local menuSection = settings:Section("Menu")

local menuScale = menuSection:Slider("Menu Scale", 0.75, 1.35, silentAim.MenuScale, sliderSetter("MenuScale", function(value)
    window:SetScale(value)
end), {
    decimals = 2,
})
UI:Bind(menuScale, function() return silentAim.MenuScale end)

local configSection = settings:Section("Config")

configSection:Button("Save Config", function()
    PD.saveConfig()
    window:SetStatus("Config saved.")
end)

configSection:Button("Load Config", function()
    PD.loadConfig()
    UI:Sync()
    refreshHudPosition()
    if PD.setInventoryScale then
        PD.setInventoryScale(silentAim.InventoryScale)
    end
    if PD.hudFrame then
        PD.hudFrame.Visible = silentAim.InventoryVisible
    end
    window:SetStatus("Config loaded.")
end)

configSection:Button("Reset To Defaults", function()
    PD.resetState()
    UI:Sync()
    refreshHudPosition()
    if PD.setInventoryScale then
        PD.setInventoryScale(silentAim.InventoryScale)
    end
    window:SetStatus("Config reset to defaults.")
end)

configSection:Button("Unload", function()
    if PD.globalCleanup then
        PD.globalCleanup()
    end
end)

local infoSection = settings:Section("Info")
infoSection:Label("Fabled // Project Delta")
infoSection:Label("Rage-style control panel with persistent config.")
infoSection:Label("Menu keybind can be changed above. Delete unloads everything.")
infoSection:Divider()
infoSection:Label("Tabs: Combat • Visuals • Misc • Settings")

UI:Sync()
