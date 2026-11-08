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
