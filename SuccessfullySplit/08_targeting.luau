-- // 08_targeting.luau
-- // Target selection, movement prediction, and HUD target finder.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local silentAim = PD.silentAim
local allowedHitParts = PD.allowedHitParts
local players = PD.players
local localPlayer = PD.localPlayer
local camera = PD.camera
local cachedAI = PD.cachedAI
local isPartVisible = PD.isPartVisible
local workspace = PD.workspace

-- // Target Selector
local function getTarget()
    local closestTarget = nil
    local closestDistance = silentAim.FovRadius
    local screenCenter = camera.ViewportSize / 2

    local function evaluateCharacter(character, isPlayer, playerName)
        if not character then return end
        local player = players:GetPlayerFromCharacter(character)
        if player == localPlayer then return end
        if isPlayer and (player == localPlayer or silentAim.ExcludedPlayers[playerName]) then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local targetPart = nil

            if silentAim.SelectedHitPart == "Random" then
                local validParts = {}
                for _, desc in ipairs(character:GetChildren()) do
                    if desc:IsA("BasePart") and allowedHitParts[desc.Name] then
                        table.insert(validParts, desc)
                    end
                end
                if #validParts > 0 then
                    targetPart = validParts[math.random(1, #validParts)]
                end
            else
                targetPart = character:FindFirstChild(silentAim.SelectedHitPart, true)
            end

            if targetPart then
                local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude
                    if distance < closestDistance then
                        if not silentAim.VisibleOnly or isPartVisible(targetPart) then
                            closestDistance = distance
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            evaluateCharacter(player.Character, true, player.Name)
        end
    end

    for aiModel, _ in pairs(cachedAI) do
        if aiModel and aiModel.Parent then
            evaluateCharacter(aiModel, false, nil)
        else
            cachedAI[aiModel] = nil
        end
    end

    return closestTarget
end
PD.getTarget = getTarget

-- // Prediction Function
local function getPredictedPosition(targetPart)
    if not targetPart then return nil end
    if not silentAim.Prediction then return targetPart.Position end

    local pos = targetPart.Position
    local rootPart = targetPart.Parent and (targetPart.Parent:FindFirstChild("HumanoidRootPart") or targetPart.Parent:FindFirstChild("Torso")) or targetPart
    local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)

    local origin = camera.CFrame.Position
    local distance = (origin - pos).Magnitude

    local estimatedBulletSpeed = 3500
    local timeToTarget = distance / estimatedBulletSpeed

    local predictedPos = pos + (velocity * timeToTarget)

    local gravity = workspace.Gravity
    local dropCompensation = 0.5 * gravity * (timeToTarget ^ 2)
    predictedPos = predictedPos + Vector3.new(0, dropCompensation, 0)

    if distance > 100 then
        predictedPos = predictedPos + Vector3.new(0, distance * 0.0015, 0)
    end

    local tinyOffset = Vector3.new(
        (math.random() * 0.2) - 0.1,
        (math.random() * 0.2) - 0.1,
        (math.random() * 0.2) - 0.1
    )
    predictedPos = predictedPos + tinyOffset

    return predictedPos
end
PD.getPredictedPosition = getPredictedPosition

-- // Target Character Finder for Inventory HUD
local function getTargetedPlayerCharacter()
    local closestChar = nil
    local closestDistance = silentAim.FovRadius
    local screenCenter = camera.ViewportSize / 2

    local function checkChar(char, isPlayer, playerName)
        if not char then return end
        local player = players:GetPlayerFromCharacter(char)
        if player == localPlayer then return end
        if isPlayer and silentAim.ExcludedPlayers[playerName] then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")

        if humanoid and humanoid.Health > 0 and rootPart then
            local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if dist <= closestDistance then
                    closestDistance = dist
                    closestChar = char
                end
            end
        end
    end

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= localPlayer then
            checkChar(p.Character, true, p.Name)
        end
    end
    for model, _ in pairs(cachedAI) do
        checkChar(model, false, nil)
    end

    return closestChar
end
PD.getTargetedPlayerCharacter = getTargetedPlayerCharacter
