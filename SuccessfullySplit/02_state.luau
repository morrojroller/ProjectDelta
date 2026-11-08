-- // 02_state.luau
-- // Feature state, config persistence, and ammo attribute modifications.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local replicatedStorage = PD.replicatedStorage
local httpService = PD.httpService

-- // Configuration & State
local silentAim = {
    Enabled = true,
    SelectedHitPart = "Head",
    FovRadius = 250,
    VisibleOnly = false,
    ExcludedPlayers = {},
    Fullbright = false,
    HideVisibles = false,

    -- // Inventory HUD
    InventoryVisible = true,
    InventoryPositionX = 30,
    InventoryPositionY = 220,
    InventoryScale = 1.0,
    InventoryShowWeapon = true,
    InventoryShowGear = true,
    InventoryAccent = Color3.fromRGB(0, 255, 120),

    -- // Combat
    Prediction = true,
    AmmoMods = true,

    -- // ESP
    EspEnabled = true,
    EspSkeleton = true,
    EspNames = true,
    EspDistance = true,
    EspHealth = true,
    EspWeapon = true,
    EspTeam = true,
    EspTracers = false,
    EspBox = false,
    EspMaxDistance = 2250,
    EspColorVisible = Color3.fromRGB(0, 255, 120),
    EspColorOccluded = Color3.fromRGB(255, 60, 60),
    EspColorName = Color3.fromRGB(255, 255, 255),
    EspColorInfo = Color3.fromRGB(210, 220, 214),
    EspColorWeapon = Color3.fromRGB(140, 255, 180),
    EspColorTracer = Color3.fromRGB(0, 255, 120),
    EspColorBox = Color3.fromRGB(0, 255, 120),

    -- // FOV circle
    FovCircle = true,
    FovColor = Color3.fromRGB(0, 255, 120),
    FovThickness = 1,
    FovFilled = false,

    -- // Menu
    MenuScale = 1.0,
    Keybinds = {
        Aim = "CapsLock",
        Menu = "RightAlt",
        Esp = "LeftAlt",
        Unload = "Delete",
    },
}
PD.silentAim = silentAim

-- // Deep copy / serialization helpers
local function deepCopy(value)
    if type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[k] = deepCopy(v)
        end
        return out
    end
    return value
end

local function encodeValue(value)
    if typeof(value) == "Color3" then
        return {__color = true, r = value.R, g = value.G, b = value.B}
    elseif type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[k] = encodeValue(v)
        end
        return out
    end
    return value
end

local function decodeValue(value)
    if type(value) == "table" then
        if value.__color then
            return Color3.new(value.r or 0, value.g or 0, value.b or 0)
        end
        local out = {}
        for k, v in pairs(value) do
            out[k] = decodeValue(v)
        end
        return out
    end
    return value
end

local function mergeState(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" and k ~= "ExcludedPlayers" then
            mergeState(target[k], v)
        else
            target[k] = v
        end
    end
end

-- // Ammo Modifications
local cachedAmmoAttributes = {}
PD.cachedAmmoAttributes = cachedAmmoAttributes

local function applyAmmoMods()
    local ammoTypes = replicatedStorage:FindFirstChild("AmmoTypes")
    if not ammoTypes then return end

    for _, ammo in ipairs(ammoTypes:GetChildren()) do
        if not cachedAmmoAttributes[ammo] then
            cachedAmmoAttributes[ammo] = {
                Recoil = ammo:GetAttribute("RecoilStrength"),
                Drop = ammo:GetAttribute("ProjectileDrop"),
                Drag = ammo:GetAttribute("Drag")
            }
        end

        local original = cachedAmmoAttributes[ammo]
        if silentAim.AmmoMods then
            ammo:SetAttribute("RecoilStrength", 0)
            ammo:SetAttribute("ProjectileDrop", 0)
            ammo:SetAttribute("Drag", 0)
        else
            if original.Recoil ~= nil then ammo:SetAttribute("RecoilStrength", original.Recoil) end
            if original.Drop ~= nil then ammo:SetAttribute("ProjectileDrop", original.Drop) end
            if original.Drag ~= nil then ammo:SetAttribute("Drag", original.Drag) end
        end
    end
end
PD.applyAmmoMods = applyAmmoMods

local ammoTypesFolder = replicatedStorage:FindFirstChild("AmmoTypes")
if ammoTypesFolder then
    ammoTypesFolder.ChildAdded:Connect(function()
        task.defer(applyAmmoMods)
    end)
end

local function restoreAmmoMods()
    for ammo, original in pairs(cachedAmmoAttributes) do
        if ammo and ammo.Parent then
            if original.Recoil ~= nil then ammo:SetAttribute("RecoilStrength", original.Recoil) end
            if original.Drop ~= nil then ammo:SetAttribute("ProjectileDrop", original.Drop) end
            if original.Drag ~= nil then ammo:SetAttribute("Drag", original.Drag) end
        end
    end
end
PD.restoreAmmoMods = restoreAmmoMods

-- // Config Persistence Functions
local configFileName = "SilentAim_Config.json"

local function saveConfig()
    pcall(function()
        if writefile then
            writefile(configFileName, httpService:JSONEncode(encodeValue(silentAim)))
        end
    end)
end
PD.saveConfig = saveConfig

local defaults = deepCopy(silentAim)

local function applyStateSideEffects()
    if PD.applyAmmoMods then PD.applyAmmoMods() end
    if PD.applyFullbright then PD.applyFullbright(silentAim.Fullbright) end
    if PD.hudFrame then PD.hudFrame.Visible = silentAim.InventoryVisible end
    if PD.setInventoryScale then PD.setInventoryScale(silentAim.InventoryScale) end
    if PD.UI and PD.UI.Sync then PD.UI.Sync() end
    if PD.UI and PD.UI.Window and PD.UI.Window.SetScale then PD.UI.Window:SetScale(silentAim.MenuScale) end
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(configFileName) then
            local data = decodeValue(httpService:JSONDecode(readfile(configFileName)))
            if type(data) == "table" then
                mergeState(silentAim, data)
                applyStateSideEffects()
            end
        end
    end)
end
PD.loadConfig = loadConfig

local function resetState()
    for k in pairs(silentAim) do
        silentAim[k] = nil
    end
    for k, v in pairs(defaults) do
        silentAim[k] = deepCopy(v)
    end
    applyStateSideEffects()
    saveConfig()
end
PD.resetState = resetState

loadConfig()
applyAmmoMods()
