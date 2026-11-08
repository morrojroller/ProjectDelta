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

-- // GitHub Raw Base URL
local baseUrl = "https://raw.githubusercontent.com/morrojroller/ProjectDelta/refs/heads/main/Modules/"

-- Enhanced fetchModule with full traceback & stack printing
local function fetchModule(moduleName)
    local success, res = pcall(function()
        return game:HttpGet(baseUrl .. moduleName .. ".lua")
    end)
    if not success then 
        warn("[Project Delta] HTTP GET Failed for: " .. moduleName)
        error("Failed to fetch module: " .. moduleName) 
    end
    
    -- Passing the second argument to loadstring tags the chunk name for accurate traceback lines
    local func, err = loadstring(res, "@" .. moduleName .. ".lua")
    if not func then 
        warn("[Project Delta] Compile Error in [" .. moduleName .. "]: " .. tostring(err))
        error("Failed to compile module " .. moduleName .. ": " .. tostring(err)) 
    end
    
    -- Execute with xpcall to catch and print runtime errors with traceback
    local execSuccess, execResult = xpcall(func, function(errMessage)
        return string.format("\n--- [Project Delta Error] ---\nModule Failed: %s.lua\nMessage: %s\n%s\n-----------------------------", moduleName, tostring(errMessage), debug.traceback())
    end)
    
    if not execSuccess then
        warn(execResult) -- Prints the full stack trace to the F9 developer console
        error("Execution crashed in module: " .. moduleName)
    end
    
    return execResult
end

-- Safe execution wrapper for initialization calls
local function safeCall(name, func, ...)
    local success, err = pcall(func, ...)
    if not success then
        warn(string.format("[Project Delta Error] Failed during initialization of [%s]: %s", name, tostring(err)))
    end
end

print("[Project Delta] Loading modules...")

-- Load Modules with error reporting
local Icons = fetchModule("Icons")
local Config = fetchModule("Config")
local Fullbright = fetchModule("Fullbright")
local AI = fetchModule("AI")
local Combat = fetchModule("Combat")
local HUD = fetchModule("HUD")
local ESP = fetchModule("ESP")
local UI = fetchModule("UI")

safeCall("Config:Load", function() Config:Load() end)
safeCall("AI.Init", function() AI.Init() end)
safeCall("Combat.ApplyAmmoMods", function() Combat.ApplyAmmoMods(Config.Data) end)
safeCall("Combat.InitBulletHook", function() Combat.InitBulletHook(bullet, Config.Data, AI) end)

if Config.Data.Fullbright then 
    safeCall("Fullbright.Apply", function() Fullbright.Apply(true) end) 
end

local uiElements
safeCall("UI.CreateUI", function()
    uiElements = UI.CreateUI(Config.Data, Config, Fullbright, Combat, Icons.Flat, HUD, AI)
end)

if not uiElements then
    return warn("[Project Delta Critical] UI failed to initialize. Aborting script execution.")
end

-- // Global Cleanup System
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
    if uiElements and uiElements.FovCircle then
        uiElements.FovCircle.Radius = Config.Data.FovRadius
        uiElements.FovCircle.Visible = Config.Data.Enabled
        if uiElements.FovCircle.Visible then
            uiElements.FovCircle.Position = game:GetService("Workspace").CurrentCamera.ViewportSize / 2
        end
    end
    ESP.Update(true, Config.Data, AI, HUD, Icons.Flat)
end))

table.insert(activeConnections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.CapsLock then
        Config.Data.Enabled = not Config.Data.Enabled
        if uiElements and uiElements.FovCircle then
            uiElements.FovCircle.Visible = Config.Data.Enabled
        end
        Combat.ApplyAmmoMods(Config.Data)
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        if uiElements and uiElements.MainFrame then
            uiElements.MainFrame.Visible = not uiElements.MainFrame.Visible
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        globalCleanup()
    end
end))

table.insert(activeConnections, LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then globalCleanup() end
end))

print("[Project Delta] SilentAim & ESP Initialized Successfully via Loadstring!")
