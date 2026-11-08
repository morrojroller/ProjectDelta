-- // Modules/AI.lua
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local AIModule = {
    CachedAI = {},
    Connections = {}
}

local function isValidAI(model)
    if not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 and not Players:GetPlayerFromCharacter(model) then
        return true
    end
    return false
end

function AIModule.Init()
    local aiZones = Workspace:FindFirstChild("AiZones")
    local parentToScan = aiZones or Workspace

    for _, descendant in ipairs(parentToScan:GetDescendants()) do
        if isValidAI(descendant) then
            AIModule.CachedAI[descendant] = true
        end
    end

    table.insert(AIModule.Connections, Workspace.DescendantAdded:Connect(function(descendant)
        if isValidAI(descendant) then
            AIModule.CachedAI[descendant] = true
        end
    end))

    table.insert(AIModule.Connections, Workspace.DescendantRemoving:Connect(function(descendant)
        if AIModule.CachedAI[descendant] then
            AIModule.CachedAI[descendant] = nil
        end
    end))
end

function AIModule.Cleanup()
    for _, conn in ipairs(AIModule.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    AIModule.Connections = {}
    AIModule.CachedAI = {}
end

return AIModule