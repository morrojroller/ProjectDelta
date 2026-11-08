-- // 12_esp.luau
-- // Skeleton / name / distance / weapon ESP rendering.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local players = PD.players
local localPlayer = PD.localPlayer
local camera = PD.camera
local silentAim = PD.silentAim
local cachedAI = PD.cachedAI

-- // Skeleton & ESP Rendering System
PD.visualsEnabled = true
PD.characterDrawings = PD.characterDrawings or {}
local characterDrawings = PD.characterDrawings

local function removeCharacterDrawings(char)
    if characterDrawings[char] then
        for _, drawing in pairs(characterDrawings[char].Lines) do
            pcall(function() drawing:Remove() end)
        end
        if characterDrawings[char].TeamText then
            pcall(function() characterDrawings[char].TeamText:Remove() end)
        end
        if characterDrawings[char].NameText then
            pcall(function() characterDrawings[char].NameText:Remove() end)
        end
        if characterDrawings[char].InfoText then
            pcall(function() characterDrawings[char].InfoText:Remove() end)
        end
        if characterDrawings[char].WeaponText then
            pcall(function() characterDrawings[char].WeaponText:Remove() end)
        end
        characterDrawings[char] = nil
    end
end
PD.removeCharacterDrawings = removeCharacterDrawings

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

local function updateVisuals()
    local drawings = PD.characterDrawings

    for char, _ in pairs(drawings) do
        if not char or not char.Parent or players:GetPlayerFromCharacter(char) == localPlayer or not char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
            removeCharacterDrawings(char)
        end
    end

    if not PD.visualsEnabled or silentAim.HideVisibles then
        for char, _ in pairs(drawings) do
            removeCharacterDrawings(char)
        end
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

        if distance > 2250 then
            removeCharacterDrawings(char)
            return
        end

        local isExcluded = isPlayer and silentAim.ExcludedPlayers[playerName] == true

        if not drawings[char] then
            drawings[char] = {
                Lines = {},
                TeamText = Drawing.new("Text"),
                NameText = Drawing.new("Text"),
                InfoText = Drawing.new("Text"),
                WeaponText = Drawing.new("Text")
            }

            for _, tObj in ipairs({drawings[char].TeamText, drawings[char].NameText, drawings[char].InfoText, drawings[char].WeaponText}) do
                tObj.Size = 13
                tObj.Center = true
                tObj.Outline = true
                tObj.Color = Color3.fromRGB(255, 255, 255)
            end
        end

        local charData = drawings[char]
        local head = char:FindFirstChild("Head")

        if head then
            if (head.Position - camera.CFrame.Position).Magnitude <= 2.0 then
                charData.TeamText.Visible = false
                charData.NameText.Visible = false
                charData.InfoText.Visible = false
                charData.WeaponText.Visible = false
                for _, line in ipairs(charData.Lines) do line.Visible = false end
                return
            end

            local headPos, onScreenHead = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
            if onScreenHead then
                if isExcluded then
                    charData.TeamText.Text = "Team"
                    charData.TeamText.Position = Vector2.new(headPos.X, headPos.Y - 14)
                    charData.TeamText.Visible = true
                else
                    charData.TeamText.Visible = false
                end

                charData.NameText.Text = displayName or playerName or "AI"
                local nameOffset = isExcluded and 28 or 14
                charData.NameText.Position = Vector2.new(headPos.X, headPos.Y - nameOffset)
                charData.NameText.Visible = true
            else
                charData.TeamText.Visible = false
                charData.NameText.Visible = false
            end
        else
            charData.TeamText.Visible = false
            charData.NameText.Visible = false
        end

        local footPart = char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightLeg") or char:FindFirstChild("LeftLeg") or rootPart
        if footPart then
            if (footPart.Position - camera.CFrame.Position).Magnitude <= 2.0 then
                charData.InfoText.Visible = false
                charData.WeaponText.Visible = false
            else
                local footPos, onScreenFoot = camera:WorldToViewportPoint(footPart.Position - Vector3.new(0, 2.5, 0))
                if onScreenFoot then
                    local distRounded = math.floor(distance)
                    local hp = math.floor(humanoid.Health)

                    charData.InfoText.Text = distRounded .. " studs | HP: " .. hp
                    charData.InfoText.Position = Vector2.new(footPos.X, footPos.Y)
                    charData.InfoText.Visible = true

                    local equipped = PD.getEquippedCharacterItems(char)
                    charData.WeaponText.Text = equipped.weapon or "None"
                    charData.WeaponText.Position = Vector2.new(footPos.X, footPos.Y + 14)
                    charData.WeaponText.Visible = true
                else
                    charData.InfoText.Visible = false
                    charData.WeaponText.Visible = false
                end
            end
        else
            charData.InfoText.Visible = false
            charData.WeaponText.Visible = false
        end

        local activeLineIndex = 0
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
                    local line = charData.Lines[activeLineIndex]
                    if not line then
                        line = Drawing.new("Line")
                        line.Thickness = 1.5
                        charData.Lines[activeLineIndex] = line
                    end

                    line.From = Vector2.new(posA.X, posA.Y)
                    line.To = Vector2.new(posB.X, posB.Y)

                    local boneVisible = PD.isPartVisible(partA) or PD.isPartVisible(partB)
                    line.Color = boneVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    line.Visible = true
                end
            end
        end

        for i = activeLineIndex + 1, #charData.Lines do
            charData.Lines[i].Visible = false
        end
    end

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= localPlayer then
            processChar(p.Character, true, p.Name, p.DisplayName)
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
