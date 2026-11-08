-- // Modules/ESP.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local ESPModule = {
    CharacterDrawings = {}
}

function ESPModule.RemoveDrawings(char)
    if ESPModule.CharacterDrawings[char] then
        for _, drawing in pairs(ESPModule.CharacterDrawings[char].Lines) do
            pcall(function() drawing:Remove() end)
        end
        for _, textObj in ipairs({"TeamText", "NameText", "InfoText", "WeaponText"}) do
            if ESPModule.CharacterDrawings[char][textObj] then
                pcall(function() ESPModule.CharacterDrawings[char][textObj]:Remove() end)
            end
        end
        ESPModule.CharacterDrawings[char] = nil
    end
end

local R6_Bones = {
    {"Head", "Torso"}, {"Torso", "LeftUpperArm"}, {"Torso", "RightUpperArm"},
    {"Torso", "LeftLeg"}, {"Torso", "RightLeg"}, {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

function ESPModule.Update(visualsEnabled, silentAimData, aiModule, hudModule, flatIcons)
    local Camera = Workspace.CurrentCamera
    if not Camera then return end

    for char, _ in pairs(ESPModule.CharacterDrawings) do
        if not char or not char.Parent or Players:GetPlayerFromCharacter(char) == LocalPlayer or not char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
            ESPModule.RemoveDrawings(char)
        end
    end

    if not visualsEnabled or silentAimData.HideVisibles then
        for char, _ in pairs(ESPModule.CharacterDrawings) do
            ESPModule.RemoveDrawings(char)
        end
        return
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local function isPartVisible(part)
        if not part then return false end
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

    local function processChar(char, isPlayer, playerName, displayName)
        if not char or Players:GetPlayerFromCharacter(char) == LocalPlayer then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            ESPModule.RemoveDrawings(char)
            return
        end

        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
        if not rootPart then return end

        local localRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso"))
        local distance = localRoot and (localRoot.Position - rootPart.Position).Magnitude or 0

        if distance > 2250 then
            ESPModule.RemoveDrawings(char)
            return
        end
        
        local isExcluded = isPlayer and silentAimData.ExcludedPlayers[playerName] == true

        if not ESPModule.CharacterDrawings[char] then
            ESPModule.CharacterDrawings[char] = {
                Lines = {},
                TeamText = Drawing.new("Text"),
                NameText = Drawing.new("Text"),
                InfoText = Drawing.new("Text"),
                WeaponText = Drawing.new("Text")
            }
            for _, tObj in ipairs({ESPModule.CharacterDrawings[char].TeamText, ESPModule.CharacterDrawings[char].NameText, ESPModule.CharacterDrawings[char].InfoText, ESPModule.CharacterDrawings[char].WeaponText}) do
                tObj.Size = 13
                tObj.Center = true
                tObj.Outline = true
                tObj.Color = Color3.fromRGB(255, 255, 255)
            end
        end

        local charData = ESPModule.CharacterDrawings[char]
        local head = char:FindFirstChild("Head")

        if head then
            if (head.Position - Camera.CFrame.Position).Magnitude <= 2.0 then
                charData.TeamText.Visible = false
                charData.NameText.Visible = false
                charData.InfoText.Visible = false
                charData.WeaponText.Visible = false
                for _, line in ipairs(charData.Lines) do line.Visible = false end
                return
            end

            local headPos, onScreenHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
            if onScreenHead then
                if isExcluded then
                    charData.TeamText.Text = "Team"
                    charData.TeamText.Position = Vector2.new(headPos.X, headPos.Y - 14)
                    charData.TeamText.Visible = true
                else
                    charData.TeamText.Visible = false
                end
                charData.NameText.Text = displayName or playerName or "AI"
                charData.NameText.Position = Vector2.new(headPos.X, headPos.Y - (isExcluded and 28 or 14))
                charData.NameText.Visible = true
            else
                charData.TeamText.Visible = false
                charData.NameText.Visible = false
            end
        end

        local footPart = char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot") or rootPart
        if footPart then
            if (footPart.Position - Camera.CFrame.Position).Magnitude > 2.0 then
                local footPos, onScreenFoot = Camera:WorldToViewportPoint(footPart.Position - Vector3.new(0, 2.5, 0))
                if onScreenFoot then
                    charData.InfoText.Text = math.floor(distance) .. " studs | HP: " .. math.floor(humanoid.Health)
                    charData.InfoText.Position = Vector2.new(footPos.X, footPos.Y)
                    charData.InfoText.Visible = true

                    local equipped = hudModule.GetEquippedItems(char, flatIcons)
                    charData.WeaponText.Text = equipped.weapon or "None"
                    charData.WeaponText.Position = Vector2.new(footPos.X, footPos.Y + 14)
                    charData.WeaponText.Visible = true
                else
                    charData.InfoText.Visible = false
                    charData.WeaponText.Visible = false
                end
            end
        end

        local activeLineIndex = 0
        for _, bone in ipairs(R6_Bones) do
            local partA, partB = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
            if partA and partB then
                if (partA.Position - Camera.CFrame.Position).Magnitude > 2.0 and (partB.Position - Camera.CFrame.Position).Magnitude > 2.0 then
                    local posA, onA = Camera:WorldToViewportPoint(partA.Position)
                    local posB, onB = Camera:WorldToViewportPoint(partB.Position)
                    if onA or onB then
                        activeLineIndex = activeLineIndex + 1
                        local line = charData.Lines[activeLineIndex]
                        if not line then
                            line = Drawing.new("Line")
                            line.Thickness = 1.5
                            charData.Lines[activeLineIndex] = line
                        end
                        line.From = Vector2.new(posA.X, posA.Y)
                        line.To = Vector2.new(posB.X, posB.Y)
                        
                        local boneVisible = isPartVisible(partA) or isPartVisible(partB)
                        line.Color = boneVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        line.Visible = true
                    end
                end
            end
        end
        for i = activeLineIndex + 1, #charData.Lines do
            charData.Lines[i].Visible = false
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then processChar(p.Character, true, p.Name, p.DisplayName) end
    end
    for aiModel, _ in pairs(aiModule.CachedAI) do
        if aiModel and aiModel.Parent then processChar(aiModel, false, nil, "AI Entity") end
    end
end

return ESPModule
