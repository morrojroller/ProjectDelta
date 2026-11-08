-- // 10_item_parser.luau
-- // Equipped item parsing (weapon / armor detection) for the HUD + ESP.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local players = PD.players
local itemIcons = PD.itemIcons

-- // Strictly Equipped Item Parser with Blacklist & Icon Mapping
local blacklistedItems = {
    ["Attachments"] = true,
    ["Hair"] = true,
    ["Clothing"] = true,
    ["Radio"] = true,
    ["WaterBottle"] = true,
    ["ChocolateBar"] = true,
    ["Shirt"] = true,
    ["Pants"] = true
}
PD.blacklistedItems = blacklistedItems

local function descIsArmorLike(name)
    local lower = string.lower(name)
    if string.find(lower, "armor") or string.find(lower, "vest") or string.find(lower, "helmet") or string.find(lower, "mask") or string.find(lower, "plate") or string.find(lower, "visor") or string.find(lower, "backpack") or string.find(lower, "gloves") or itemIcons[name] then
        return true
    end
    return false
end
PD.descIsArmorLike = descIsArmorLike

local function getEquippedCharacterItems(char)
    local items = {
        weapon = nil,
        armor = {}
    }
    if not char then return items end

    for _, child in ipairs(char:GetChildren()) do
        local name = child.Name
        local className = child.ClassName

        if not blacklistedItems[name] and name ~= "HumanoidRootPart" and name ~= "Head" and name ~= "Torso" then
            local lowerName = string.lower(name)
            local isWeapon = (className == "Tool" or className == "HopperBin" or string.find(lowerName, "rifle") or string.find(lowerName, "gun") or string.find(lowerName, "pistol") or string.find(lowerName, "shotgun") or string.find(lowerName, "smg") or string.find(lowerName, "sniper") or string.find(lowerName, "ak") or string.find(lowerName, "m4"))

            if isWeapon and not items.weapon then
                items.weapon = name
            elseif (className == "Accessory" == true or className == "Model" or descIsArmorLike(name)) then
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

    local player = players:GetPlayerFromCharacter(char)
    if player and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            for _, tool in ipairs(player.Character:GetChildren()) do
                if tool:IsA("Tool") and not blacklistedItems[tool.Name] then
                    items.weapon = tool.Name
                    break
                end
            end
        end
    end

    return items
end
PD.getEquippedCharacterItems = getEquippedCharacterItems

-- // HUD category tagging (used by the inventory HUD accent system)
local weaponNames = {
    ["ADAR15"] = true,
    ["AKM"] = true,
    ["AKMN"] = true,
    ["AsVal"] = true,
    ["FAL"] = true,
    ["FlareGun"] = true,
    ["Groza"] = true,
    ["IZh12"] = true,
    ["IZh81"] = true,
    ["M4"] = true,
    ["MK23"] = true,
    ["MP443"] = true,
    ["MP5SD"] = true,
    ["Makarov"] = true,
    ["Mosin"] = true,
    ["NagantRevolver"] = true,
    ["PKM"] = true,
    ["PPSH41"] = true,
    ["R700"] = true,
    ["RPG7"] = true,
    ["Saiga12"] = true,
    ["SKS"] = true,
    ["SPSh44"] = true,
    ["SVD"] = true,
    ["TFZ0"] = true,
    ["TFZ98S"] = true,
    ["TOZ106"] = true,
    ["TOZ87"] = true,
    ["TT33"] = true,
    ["VZ61"] = true,
    ["AK47"] = true,
    ["M4A1"] = true,
    ["HK416"] = true,
    ["M16A4"] = true,
    ["MP5"] = true,
    ["MP7"] = true,
    ["Vector"] = true,
    ["P90"] = true,
    ["G17"] = true,
    ["M9"] = true,
    ["DesertEagle"] = true,
    ["Remington870"] = true,
    ["VSS"] = true,
    ["MosintNagant"] = true,
}

local function getItemCategory(name)
    local lower = string.lower(name or "")
    if weaponNames[name] then
        return "WEAPON", Color3.fromRGB(255, 92, 92)
    end
    if string.find(lower, "mag") or string.find(lower, "ammo") or string.find(lower, "rnd") or string.find(lower, "tracer") or string.find(lower, "buckshot") or string.find(lower, "slug") then
        return "AMMO", Color3.fromRGB(255, 200, 87)
    end
    if string.find(lower, "scope") or string.find(lower, "sight") or string.find(lower, "suppressor") or string.find(lower, "grip") or string.find(lower, "flashhider") or string.find(lower, "muzzle") or string.find(lower, "laser") then
        return "ATTACH", Color3.fromRGB(180, 120, 255)
    end
    if string.find(lower, "armor") or string.find(lower, "vest") or string.find(lower, "helmet") or string.find(lower, "mask") or string.find(lower, "plate") or string.find(lower, "visor") or string.find(lower, "backpack") or string.find(lower, "gloves") then
        return "GEAR", Color3.fromRGB(77, 163, 255)
    end
    return "ITEM", Color3.fromRGB(150, 170, 158)
end
PD.getItemCategory = getItemCategory
