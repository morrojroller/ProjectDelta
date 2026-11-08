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
    InventoryVisible = true,
    InventoryPositionX = 30,
    InventoryPositionY = 220,
    InventoryScale = 1.0
}
PD.silentAim = silentAim

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
        if silentAim.Enabled then
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
            local data = {
                SelectedHitPart = silentAim.SelectedHitPart,
                FovRadius = silentAim.FovRadius,
                VisibleOnly = silentAim.VisibleOnly,
                ExcludedPlayers = silentAim.ExcludedPlayers,
                Fullbright = silentAim.Fullbright,
                HideVisibles = silentAim.HideVisibles,
                InventoryVisible = silentAim.InventoryVisible,
                InventoryPositionX = silentAim.InventoryPositionX,
                InventoryPositionY = silentAim.InventoryPositionY,
                InventoryScale = silentAim.InventoryScale
            }
            writefile(configFileName, httpService:JSONEncode(data))
        end
    end)
end
PD.saveConfig = saveConfig

local function loadConfig()
    pcall(function()
        if isfile and isfile(configFileName) then
            local data = httpService:JSONDecode(readfile(configFileName))
            if type(data) == "table" then
                if data.SelectedHitPart then silentAim.SelectedHitPart = data.SelectedHitPart end
                if data.FovRadius then silentAim.FovRadius = data.FovRadius end
                if data.VisibleOnly ~= nil then silentAim.VisibleOnly = data.VisibleOnly end
                if data.ExcludedPlayers then silentAim.ExcludedPlayers = data.ExcludedPlayers end
                if data.Fullbright ~= nil then silentAim.Fullbright = data.Fullbright end
                if data.HideVisibles ~= nil then silentAim.HideVisibles = data.HideVisibles end
                if data.InventoryVisible ~= nil then silentAim.InventoryVisible = data.InventoryVisible end
                if data.InventoryPositionX then silentAim.InventoryPositionX = data.InventoryPositionX end
                if data.InventoryPositionY then silentAim.InventoryPositionY = data.InventoryPositionY end
                if data.InventoryScale then silentAim.InventoryScale = data.InventoryScale end
            end
        end
    end)
end
PD.loadConfig = loadConfig

loadConfig()
applyAmmoMods()
