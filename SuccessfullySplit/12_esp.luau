-- // 12_esp.luau
-- // Fabled ESP: skeleton, names, distance/health, weapon, team tag, boxes, tracers.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local players = PD.players
local localPlayer = PD.localPlayer
local camera = PD.camera
local silentAim = PD.silentAim
local cachedAI = PD.cachedAI

PD.characterDrawings = PD.characterDrawings or {}
local characterDrawings = PD.characterDrawings

local function removeCharacterDrawings(char)
    local data = characterDrawings[char]
    if not data then return end

    for _, drawing in pairs(data.Lines) do
        pcall(function() drawing:Remove() end)
    end
    for _, drawing in pairs(data.BoxLines) do
        pcall(function() drawing:Remove() end)
    end
    if data.Tracer then
        pcall(function() data.Tracer:Remove() end)
    end
    if data.TeamText then
        pcall(function() data.TeamText:Remove() end)
    end
    if data.NameText then
        pcall(function() data.NameText:Remove() end)
    end
    if data.InfoText then
        pcall(function() data.InfoText:Remove() end)
    end
    if data.WeaponText then
        pcall(function() data.WeaponText:Remove() end)
    end

    characterDrawings[char] = nil
end
PD.removeCharacterDrawings = removeCharacterDrawings

local function clearEsp()
    for char, _ in pairs(characterDrawings) do
        pcall(function() removeCharacterDrawings(char) end)
    end
end
PD.clearEsp = clearEsp

local R6_Bones = {
    {"Head", "Torso"},
    {"Torso", "LeftUpperArm"},
    {"Torso", "RightUpperArm"},
    {"Torso", "LeftLeg"},
    {"Torso", "RightLeg"},
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local function getOrCreateLine(list, index)
    local line = list[index]
    if not line then
        line = Drawing.new("Line")
        list[index] = line
    end
    return line
end

local function updateVisuals()
    local drawings = PD.characterDrawings

    for char, _ in pairs(drawings) do
        if not char or not char.Parent or players:GetPlayerFromCharacter(char) == localPlayer or not char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
            removeCharacterDrawings(char)
        end
    end

    if not silentAim.EspEnabled or silentAim.HideVisibles then
        clearEsp()
        return
    end

    local function processChar(char, isPlayer, playerName, displayName)
        if not char or players:GetPlayerFromCharacter(char) == localPlayer then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            removeCharacterDrawings(char)
            return
        end

        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
        if not rootPart then return end

        local localRoot = localPlayer.Character and (localPlayer.Character:FindFirstChild("HumanoidRootPart") or localPlayer.Character:FindFirstChild("Torso"))
        local distance = localRoot and (localRoot.Position - rootPart.Position).Magnitude or 0

        if distance > silentAim.EspMaxDistance then
            removeCharacterDrawings(char)
            return
        end

        local isExcluded = isPlayer and silentAim.ExcludedPlayers[playerName] == true
        local head = char:FindFirstChild("Head")

        local headScreen, headOnScreen = nil, false
        if head then
            headScreen, headOnScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
        end

        local footPart = char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightLeg") or char:FindFirstChild("LeftLeg") or rootPart
        local footScreen, footOnScreen = nil, false
        if footPart then
            footScreen, footOnScreen = camera:WorldToViewportPoint(footPart.Position - Vector3.new(0, 2.5, 0))
        end

        local nearCamera = false
        if head then
            nearCamera = (head.Position - camera.CFrame.Position).Magnitude <= 2.0
        end

        if not drawings[char] then
            drawings[char] = {
                Lines = {},
                BoxLines = {},
                Tracer = Drawing.new("Line"),
                TeamText = Drawing.new("Text"),
                NameText = Drawing.new("Text"),
                InfoText = Drawing.new("Text"),
                WeaponText = Drawing.new("Text"),
            }

            for _, textObject in ipairs({drawings[char].TeamText, drawings[char].NameText, drawings[char].InfoText, drawings[char].WeaponText}) do
                textObject.Size = 13
                textObject.Center = true
                textObject.Outline = true
                textObject.Color = Color3.fromRGB(255, 255, 255)
            end

            drawings[char].Tracer.Thickness = 1
            drawings[char].Tracer.Transparency = 1
        end

        local charData = drawings[char]

        -- // Team tag + name
        if headOnScreen and not nearCamera then
            charData.TeamText.Visible = silentAim.EspTeam and isExcluded
            if charData.TeamText.Visible then
                charData.TeamText.Text = "Team"
                charData.TeamText.Position = Vector2.new(headScreen.X, headScreen.Y - 14)
                charData.TeamText.Color = Color3.fromRGB(255, 120, 120)
            end

            charData.NameText.Visible = silentAim.EspNames
            if charData.NameText.Visible then
                charData.NameText.Text = displayName or playerName or "AI"
                local nameOffset = isExcluded and 28 or 14
                charData.NameText.Position = Vector2.new(headScreen.X, headScreen.Y - nameOffset)
                charData.NameText.Color = silentAim.EspColorName
            end
        else
            charData.TeamText.Visible = false
            charData.NameText.Visible = false
        end

        -- // Distance + health
        local infoParts = {}
        if silentAim.EspDistance then
            table.insert(infoParts, math.floor(distance) .. " studs")
        end
        if silentAim.EspHealth then
            table.insert(infoParts, "HP: " .. math.floor(humanoid.Health))
        end

        if footOnScreen and not nearCamera and #infoParts > 0 then
            charData.InfoText.Text = table.concat(infoParts, " | ")
            charData.InfoText.Position = Vector2.new(footScreen.X, footScreen.Y)
            charData.InfoText.Color = silentAim.EspColorInfo
            charData.InfoText.Visible = true
        else
            charData.InfoText.Visible = false
        end

        -- // Weapon
        if footOnScreen and not nearCamera and silentAim.EspWeapon then
            local equipped = PD.getEquippedCharacterItems(char)
            charData.WeaponText.Text = equipped.weapon or "None"
            charData.WeaponText.Position = Vector2.new(footScreen.X, footScreen.Y + 14)
            charData.WeaponText.Color = silentAim.EspColorWeapon
            charData.WeaponText.Visible = true
        else
            charData.WeaponText.Visible = false
        end

        -- // Tracer
        if silentAim.EspTracers and not nearCamera and (headOnScreen or footOnScreen) then
            local targetPoint = headOnScreen and headScreen or footScreen
            charData.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            charData.Tracer.To = Vector2.new(targetPoint.X, targetPoint.Y)
            charData.Tracer.Color = silentAim.EspColorTracer
            charData.Tracer.Visible = true
        else
            charData.Tracer.Visible = false
        end

        -- // 2D box
        local boxVisible = silentAim.EspBox and not nearCamera and headOnScreen and footOnScreen
        if boxVisible then
            local height = footScreen.Y - headScreen.Y
            if height > 8 then
                local width = math.clamp(height * 0.45, 8, 400)
                local centerX = (headScreen.X + footScreen.X) / 2
                local left = centerX - width / 2
                local right = centerX + width / 2
                local top = headScreen.Y
                local bottom = footScreen.Y

                local boxColor = silentAim.EspColorBox
                if not (PD.isPartVisible(rootPart) or (head and PD.isPartVisible(head))) then
                    boxColor = silentAim.EspColorOccluded
                end

                local points = {
                    {Vector2.new(left, top), Vector2.new(right, top)},
                    {Vector2.new(right, top), Vector2.new(right, bottom)},
                    {Vector2.new(right, bottom), Vector2.new(left, bottom)},
                    {Vector2.new(left, bottom), Vector2.new(left, top)},
                }

                for index, pair in ipairs(points) do
                    local line = getOrCreateLine(charData.BoxLines, index)
                    line.From = pair[1]
                    line.To = pair[2]
                    line.Color = boxColor
                    line.Thickness = 1
                    line.Transparency = 1
                    line.Visible = true
                end
            else
                for _, line in ipairs(charData.BoxLines) do
                    line.Visible = false
                end
            end
        else
            for _, line in ipairs(charData.BoxLines) do
                line.Visible = false
            end
        end

        -- // Skeleton
        local activeLineIndex = 0
        if silentAim.EspSkeleton then
            for _, bone in ipairs(R6_Bones) do
                local partA = char:FindFirstChild(bone[1])
                local partB = char:FindFirstChild(bone[2])

                if partA and partB then
                    if (partA.Position - camera.CFrame.Position).Magnitude <= 2.0 or (partB.Position - camera.CFrame.Position).Magnitude <= 2.0 then
                        continue
                    end

                    local posA, onScreenA = camera:WorldToViewportPoint(partA.Position)
                    local posB, onScreenB = camera:WorldToViewportPoint(partB.Position)

                    if onScreenA or onScreenB then
                        activeLineIndex = activeLineIndex + 1
                        local line = getOrCreateLine(charData.Lines, activeLineIndex)
                        line.From = Vector2.new(posA.X, posA.Y)
                        line.To = Vector2.new(posB.X, posB.Y)
                        line.Thickness = 1.5
                        line.Transparency = 1

                        local boneVisible = PD.isPartVisible(partA) or PD.isPartVisible(partB)
                        line.Color = boneVisible and silentAim.EspColorVisible or silentAim.EspColorOccluded
                        line.Visible = true
                    end
                end
            end
        end

        for i = activeLineIndex + 1, #charData.Lines do
            charData.Lines[i].Visible = false
        end
    end

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            processChar(player.Character, true, player.Name, player.DisplayName)
        end
    end

    for aiModel, _ in pairs(cachedAI) do
        if aiModel and aiModel.Parent then
            processChar(aiModel, false, nil, "AI Entity")
        else
            cachedAI[aiModel] = nil
        end
    end
end
PD.updateVisuals = updateVisuals
