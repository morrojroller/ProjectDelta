-- // 04_ai_cache.luau
-- // AI / NPC model caching and workspace connections.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local workspace = PD.workspace
local players = PD.players
local aiZones = PD.aiZones

-- // AI Caching System
local cachedAI = {}
PD.cachedAI = cachedAI

local function isValidAI(model)
    if not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 and not players:GetPlayerFromCharacter(model) then
        return true
    end
    return false
end
PD.isValidAI = isValidAI

local function scanForAI(parent)
    for _, descendant in ipairs(parent:GetDescendants()) do
        if isValidAI(descendant) then
            cachedAI[descendant] = true
        end
    end
end
PD.scanForAI = scanForAI

if aiZones then
    scanForAI(aiZones)
else
    scanForAI(workspace)
end

local addedConn = workspace.DescendantAdded:Connect(function(descendant)
    if isValidAI(descendant) then
        cachedAI[descendant] = true
    end
end)
PD.addedConn = addedConn

local removingConn = workspace.DescendantRemoving:Connect(function(descendant)
    if cachedAI[descendant] then
        cachedAI[descendant] = nil
    end
end)
PD.removingConn = removingConn
