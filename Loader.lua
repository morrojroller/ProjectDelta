-- // Project Delta Loadstring Core Manager (Debug Mode)
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

local baseUrl = "https://raw.githubusercontent.com/morrojroller/ProjectDelta/main/Modules/"

local function fetchModule(moduleName)
    local url = baseUrl .. moduleName .. ".lua"
    print("[DEBUG] Fetching module:", moduleName, "from URL:", url)
    
    local fetchSuccess, res = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not fetchSuccess or not res then
        warn("[DEBUG ERROR] HttpGet failed for module:", moduleName, "Result:", tostring(res))
        return nil
    end
    
    if string.find(res, "404: Not Found") or string.find(res, "<html") then
        warn("[DEBUG ERROR] GitHub returned 404 or HTML page instead of Lua code for:", moduleName)
        return nil
    end
    
    local func, err = loadstring(res)
    if not func then
        warn("[DEBUG ERROR] Failed to compile module", moduleName, "Error:", tostring(err))
        return nil
    end
    
    local runSuccess, moduleData = pcall(func)
    if not runSuccess then
        warn("[DEBUG ERROR] Runtime error executing module", moduleName, "Error:", tostring(moduleData))
        return nil
    end
    
    print("[DEBUG] Successfully loaded module:", moduleName)
    return moduleData
end

-- Load Modules with Safe Fallbacks
local Icons = fetchModule("Icons") or { Flat = {} }
local Config = fetchModule("Config")
local Fullbright = fetchModule("Fullbright") or { Apply = function() end }
local AI = fetchModule("AI") or { Init = function() end, Cleanup = function() end, CachedAI = {} }
local Combat = fetchModule("Combat") or { ApplyAmmoMods = function() end, InitBulletHook = function() end, RestoreAmmoMods = function() end, RestoreBulletHook = function() end }
local HUD = fetchModule("HUD") or { GetEquippedItems = function() return {} end }
local ESP = fetchModule("ESP") or { CharacterDrawings = {}, Update = function() end, RemoveDrawings = function() end }
local UI = fetchModule("UI") or { CreateUI = function() return {} end }

-- Guard against missing critical config module
if not Config then
    warn("[DEBUG FATAL] Config module returned nil! Check your GitHub repository files.")
    return
end

if Config.Load then
    Config:Load()
end

AI.Init()
Combat.ApplyAmmoMods(Config.Data)
Combat.InitBulletHook(bullet, Config.Data, AI)

if Config.Data.Fullbright then Fullbright.Apply(true) end

local uiElements = UI.CreateUI(Config.Data, Config, Fullbright, Combat, Icons.Flat, HUD, AI)

-- // Global Cleanup System
local activeConnections = {}
local isCleanedUp = false

local function globalCleanup()
    if isCleanedUp then return end
    isCleanedUp = true
    print("[DEBUG] Running Global Cleanup...")

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
    print("[DEBUG] Global Cleanup Finished.")
end

-- Run Loops & Connections
table.insert(activeConnections, RunService.Heartbeat:Connect(function()
    if uiElements.FovCircle then
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
        if uiElements.FovCircle then uiElements.FovCircle.Visible = Config.Data.Enabled end
        Combat.ApplyAmmoMods(Config.Data)
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        if uiElements.MainFrame then uiElements.MainFrame.Visible = not uiElements.MainFrame.Visible end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        globalCleanup()
    end
end))

table.insert(activeConnections, LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then globalCleanup() end
end))

print("Project Delta SilentAim & ESP Initialized Successfully with Debug Prints!")
