-- // 00_core.luau
-- // Shared services, runtime references & executor safety checks.
-- // Every other file reads from the shared ProjectDelta namespace.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta or {}
env.ProjectDelta = PD

-- // Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local coreGui = game:GetService("CoreGui")
local workspace = game:GetService("Workspace")
local httpService = game:GetService("HttpService")
local lighting = game:GetService("Lighting")
local contentProvider = game:GetService("ContentProvider")

local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local aiZones = workspace:FindFirstChild("AiZones")

-- // Expose shared references
PD.runService = runService
PD.userInputService = userInputService
PD.replicatedStorage = replicatedStorage
PD.players = players
PD.coreGui = coreGui
PD.workspace = workspace
PD.httpService = httpService
PD.lighting = lighting
PD.contentProvider = contentProvider
PD.localPlayer = localPlayer
PD.camera = camera
PD.aiZones = aiZones

-- // Safety Checks
local function abort(message)
    PD.aborted = message
    pcall(function()
        localPlayer:Kick(message)
    end)
end

if not hookfunction then
    abort("Executor Doesn't Have hookfunction.")
    return
end

if not Drawing then
    abort("Executor Doesn't Have Drawing.")
    return
end

local success, bullet = pcall(function()
    return require(replicatedStorage.Modules.FPS.Bullet)
end)
if not success or not bullet or not bullet.CreateBullet then
    abort("Couldn't Require Bullet Module or Find CreateBullet.")
    return
end
PD.bullet = bullet
