-- // Project Delta Loadstring Core Manager
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Safety Checks
if not hookfunction then return LocalPlayer:Kick("Executor Doesn't Have hookfunction.") end
if not Drawing then return LocalPlayer:Kick("Executor Doesn't Have Drawing.") end

local success, bullet = pcall(require, ReplicatedStorage.Modules.FPS.Bullet)
if not success or not bullet or not bullet.CreateBullet then
    return LocalPlayer:Kick("Couldn't Require Bullet Module.")
end

-- // Update with your actual GitHub username and repository name!
local baseUrl = "https://raw.githubusercontent.com/morrojroller/ProjectDelta/main/Modules/"

local function fetchModule(moduleName)
    local url = baseUrl .. moduleName .. ".lua"
    local fetchSuccess, res = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not fetchSuccess or not res or res == "404: Not Found" then
        return LocalPlayer:Kick("Failed to fetch module from GitHub: " .. moduleName)
    end
    
    local func, err = loadstring(res)
    if not func then
        return LocalPlayer:Kick("Failed to compile module " .. moduleName .. ": " .. tostring(err))
    end
    
    return func()
end

-- Load Modules
local Icons = fetchModule("Icons")
local Config = fetchModule("Config")
local Fullbright = fetchModule("Fullbright")
local AI = fetchModule("AI")
local Combat = fetchModule("Combat")
local HUD = fetchModule("HUD")
local ESP = fetchModule("ESP")
local UI = fetchModule("UI")

Config:Load()
AI.Init()
Combat.ApplyAmmoMods(Config.Data)
Combat.InitBulletHook(bullet, Config.Data, AI)

if Config.Data.Fullbright then Fullbright.Apply(true) end

local uiElements = UI.CreateUI(Config.Data, Config, Fullbright, Combat, Icons.Flat, HUD, AI)

-- // Global Cleanup System (Guaranteed 100% Memory & State Restoration)
local activeConnections = {}
local isCleanedUp = false

local function globalCleanup()
    if isCleanedUp then return end
    isCleanedUp = true

    pcall(function()
        for _, conn in ipairs(activeConnections) do
            if conn then conn:Disconnect() end
        end
        activeConnections = {}

        AI.Cleanup()
        Fullbright.Apply(false)
        Combat.RestoreAmmoMods()
        Combat.RestoreBulletHook(bullet)

        if uiElements.FovCircle then pcall(function() uiElements.FovCircle:Remove() end) end
        if uiElements.ScreenGui then pcall(function() uiElements.ScreenGui:Destroy() end) end

        for char, _ in pairs(ESP.CharacterDrawings) do
            pcall(function() ESP.RemoveDrawings(char) end)
        end
    end)
end

-- Run Loops & Connections
table.insert(activeConnections, RunService.Heartbeat:Connect(function()
    uiElements.FovCircle.Radius = Config.Data.FovRadius
    uiElements.FovCircle.Visible = Config.Data.Enabled
    if uiElements.FovCircle.Visible then
        uiElements.FovCircle.Position = game:GetService("Workspace").CurrentCamera.ViewportSize / 2
    end
    ESP.Update(true, Config.Data, AI, HUD, Icons.Flat)
end))

table.insert(activeConnections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.CapsLock then
        Config.Data.Enabled = not Config.Data.Enabled
        uiElements.FovCircle.Visible = Config.Data.Enabled
        Combat.ApplyAmmoMods(Config.Data)
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        uiElements.MainFrame.Visible = not uiElements.MainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.Delete then
        globalCleanup()
    end
end))

table.insert(activeConnections, LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then globalCleanup() end
end))

print("Project Delta SilentAim & ESP Initialized Successfully via Loadstring!")
