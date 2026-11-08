-- // Modules/Combat.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CombatModule = {
    OldBullet = nil,
    CachedAmmoAttributes = {}
}

function CombatModule.ApplyAmmoMods(silentAimData)
    local ammoTypes = ReplicatedStorage:FindFirstChild("AmmoTypes")
    if not ammoTypes then return end

    for _, ammo in ipairs(ammoTypes:GetChildren()) do
        if not CombatModule.CachedAmmoAttributes[ammo] then
            CombatModule.CachedAmmoAttributes[ammo] = {
                Recoil = ammo:GetAttribute("RecoilStrength"),
                Drop = ammo:GetAttribute("ProjectileDrop"),
                Drag = ammo:GetAttribute("Drag")
            }
        end

        local original = CombatModule.CachedAmmoAttributes[ammo]
        if silentAimData.Enabled then
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

function CombatModule.RestoreAmmoMods()
    for ammo, original in pairs(CombatModule.CachedAmmoAttributes) do
        if ammo and ammo.Parent then
            if original.Recoil ~= nil then ammo:SetAttribute("RecoilStrength", original.Recoil) end
            if original.Drop ~= nil then ammo:SetAttribute("ProjectileDrop", original.Drop) end
            if original.Drag ~= nil then ammo:SetAttribute("Drag", original.Drag) end
        end
    end
end

function CombatModule.InitBulletHook(bulletModule, silentAimData, aiModule)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local function isPartVisible(part)
        local Camera = Workspace.CurrentCamera
        if not Camera or not part then return false end
        local rayOrigin = Camera.CFrame.Position
        local rayDirection = (part.Position - rayOrigin)
        local filterList = {}
        if LocalPlayer.Character then table.insert(filterList, LocalPlayer.Character) end
        raycastParams.FilterDescendantsInstances = filterList
        local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if result then
            if result.Instance == part or result.Instance:IsDescendantOf(part.Parent) then return true end
            return false
        end
        return true
    end

    local allowedHitParts = {
        ["FaceHitBox"] = true, ["HeadTopHitBox"] = true, ["Head"] = true,
        ["UpperTorso"] = true, ["LowerTorso"] = true, ["Torso"] = true,
        ["LeftUpperLeg"] = true, ["RightUpperLeg"] = true, ["LeftLowerLeg"] = true,
        ["RightLowerLeg"] = true, ["LeftLeg"] = true, ["RightLeg"] = true,
        ["LeftFoot"] = true, ["RightFoot"] = true
    }

    local function getTarget()
        local Camera = Workspace.CurrentCamera
        if not Camera then return nil end

        local closestTarget = nil
        local closestDistance = silentAimData.FovRadius
        local screenCenter = Camera.ViewportSize / 2

        local function evaluateCharacter(character, isPlayer, playerName)
            if not character then return end
            local player = Players:GetPlayerFromCharacter(character)
            if player == LocalPlayer then return end
            if isPlayer and (player == LocalPlayer or silentAimData.ExcludedPlayers[playerName]) then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart = nil
                if silentAimData.SelectedHitPart == "Random" then
                    local validParts = {}
                    for _, desc in ipairs(character:GetChildren()) do
                        if desc:IsA("BasePart") and allowedHitParts[desc.Name] then
                            table.insert(validParts, desc)
                        end
                    end
                    if #validParts > 0 then targetPart = validParts[math.random(1, #validParts)] end
                else
                    targetPart = character:FindFirstChild(silentAimData.SelectedHitPart, true)
                end
                
                if targetPart then
                    local screenPosition, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude
                        if distance < closestDistance then
                            if not silentAimData.VisibleOnly or isPartVisible(targetPart) then
                                closestDistance = distance
                                closestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then evaluateCharacter(player.Character, true, player.Name) end
        end
        for aiModel, _ in pairs(aiModule.CachedAI) do
            if aiModel and aiModel.Parent then evaluateCharacter(aiModel, false, nil) end
        end
        return closestTarget
    end

    local function getPredictedPosition(targetPart)
        local Camera = Workspace.CurrentCamera
        if not targetPart or not Camera then return nil end
        local pos = targetPart.Position
        local rootPart = targetPart.Parent and (targetPart.Parent:FindFirstChild("HumanoidRootPart") or targetPart.Parent:FindFirstChild("Torso")) or targetPart
        local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
        local distance = (Camera.CFrame.Position - pos).Magnitude
        local timeToTarget = distance / 3500
        local predictedPos = pos + (velocity * timeToTarget) + Vector3.new(0, 0.5 * Workspace.Gravity * (timeToTarget ^ 2), 0)
        if distance > 100 then predictedPos = predictedPos + Vector3.new(0, distance * 0.0015, 0) end
        return predictedPos + Vector3.new(math.random() * 0.2 - 0.1, math.random() * 0.2 - 0.1, math.random() * 0.2 - 0.1)
    end

    CombatModule.OldBullet = hookfunction(bulletModule.CreateBullet, function(idk, model, model2, model3, aimPart, ...)
        if silentAimData.Enabled then
            local targetTestPart = getTarget()
            if targetTestPart and aimPart and type(aimPart) == "userdata" and aimPart:IsA("BasePart") then
                local predictedPos = getPredictedPosition(targetTestPart)
                local modifiedAimPart = {
                    ["Position"] = predictedPos,
                    ["CFrame"] = CFrame.new(aimPart.Position, predictedPos)
                }
                return CombatModule.OldBullet(idk, model, model2, model3, modifiedAimPart, ...)
            end
        end
        return CombatModule.OldBullet(idk, model, model2, model3, aimPart, ...)
    end)
end

function CombatModule.RestoreBulletHook(bulletModule)
    pcall(function()
        if CombatModule.OldBullet and bulletModule and bulletModule.CreateBullet then
            hookfunction(bulletModule.CreateBullet, CombatModule.OldBullet)
        end
    end)
end

return CombatModule
