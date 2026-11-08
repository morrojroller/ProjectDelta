-- // Modules/HUD.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HUDModule = {}

function HUDModule.GetTargetedCharacter(silentAimData, aiModule)
    local closestChar = nil
    local closestDistance = silentAimData.FovRadius
    local screenCenter = Camera.ViewportSize / 2

    local function checkChar(char, isPlayer, playerName)
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if player == LocalPlayer then return end
        if isPlayer and silentAimData.ExcludedPlayers[playerName] then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
        
        if humanoid and humanoid.Health > 0 and rootPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if dist <= closestDistance then
                    closestDistance = dist
                    closestChar = char
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then checkChar(p.Character, true, p.Name) end
    end
    for model, _ in pairs(aiModule.CachedAI) do
        checkChar(model, false, nil)
    end
    return closestChar
end

local blacklistedItems = {
    ["Attachments"] = true, ["Hair"] = true, ["Clothing"] = true,
    ["Radio"] = true, ["WaterBottle"] = true, ["ChocolateBar"] = true,
    ["Shirt"] = true, ["Pants"] = true
}

local function descIsArmorLike(name, icons)
    local lower = string.lower(name)
    if string.find(lower, "armor") or string.find(lower, "vest") or string.find(lower, "helmet") or string.find(lower, "mask") or string.find(lower, "plate") or string.find(lower, "visor") or string.find(lower, "backpack") or string.find(lower, "gloves") or icons[name] then
        return true
    end
    return false
end

function HUDModule.GetEquippedItems(char, icons)
    local items = { weapon = nil, armor = {} }
    if not char then return items end

    for _, child in ipairs(char:GetChildren()) do
        local name = child.Name
        local className = child.ClassName
        if not blacklistedItems[name] and name ~= "HumanoidRootPart" and name ~= "Head" and name ~= "Torso" then
            local lowerName = string.lower(name)
            local isWeapon = (className == "Tool" or className == "HopperBin" or string.find(lowerName, "rifle") or string.find(lowerName, "gun") or string.find(lowerName, "pistol") or string.find(lowerName, "shotgun") or string.find(lowerName, "smg") or string.find(lowerName, "sniper"))
            
            if isWeapon and not items.weapon then
                items.weapon = name
            elseif (className == "Accessory" or className == "Model" or descIsArmorLike(name, icons)) then
                local exists = false
                for _, existing in ipairs(items.armor) do
                    if existing == name then exists = true break end
                end
                if not exists and name ~= items.weapon then
                    table.insert(items.armor, name)
                end
            end
        end
    end
    return items
end

return HUDModule