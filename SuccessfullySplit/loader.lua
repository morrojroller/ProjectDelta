--[[
    PROJECT DELTA // LOADER
    -----------------------
    1. Upload every file in this folder to your GitHub repository.
    2. Put the raw base URL of this folder in BASE_URL below.
    3. Run this file with a single loadstring:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/morrojroller/ProjectDelta/main/SuccessfullySplit/loader.lua"))()

    Every run adds a cache-buster, so editing one module on GitHub and
    re-running the same loadstring instantly picks up the change.
]]

-- // >>> EDIT THIS ONE LINE <<<
local BASE_URL = "https://raw.githubusercontent.com/morrojroller/ProjectDelta/main/SuccessfullySplit/"

-- // Load order matters. Do not reorder unless you know why.
local FILES = {
    "00_core.luau",
    "01_icons.luau",
    "02_state.luau",
    "03_fullbright.luau",
    "04_ai_cache.luau",
    "05_fov_visibility.luau",
    "06_gui_base.luau",
    "07_target_lists.luau",
    "08_targeting.luau",
    "09_bullet_hook.luau",
    "10_item_parser.luau",
    "11_inventory_hud.luau",
    "12_esp.luau",
    "13_runtime.luau",
    "14_cleanup.luau",
}

if not loadstring then
    return warn("[ProjectDelta] This executor does not support loadstring.")
end

local env = (getgenv and getgenv()) or _G

-- // Clean up a previous instance before loading a fresh one
local previous = env.ProjectDelta
if previous and type(previous) == "table" and previous.globalCleanup then
    pcall(previous.globalCleanup)
end

local PD = {}
env.ProjectDelta = PD
PD.__baseUrl = BASE_URL

local function fail(message)
    warn(message)
    if PD.globalCleanup then
        pcall(PD.globalCleanup)
    elseif PD.screenGui then
        pcall(function() PD.screenGui:Destroy() end)
    end
end

local function httpGet(url)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        error(body, 0)
    end
    return body
end

local stamp = tostring(DateTime.now().UnixTimestamp)
local loaded = 0

for _, file in ipairs(FILES) do
    local url = BASE_URL .. file .. "?v=" .. stamp

    local ok, source = pcall(httpGet, url)
    if not ok then
        fail(("[ProjectDelta] Download failed for %s: %s"):format(file, tostring(source)))
        return
    end

    local chunk, compileError = loadstring(source, "@ProjectDelta/" .. file)
    if not chunk then
        fail(("[ProjectDelta] Compile failed for %s: %s"):format(file, tostring(compileError)))
        return
    end

    local ran, runtimeError = pcall(chunk)
    if not ran then
        fail(("[ProjectDelta] Runtime error in %s: %s"):format(file, tostring(runtimeError)))
        return
    end

    loaded = loaded + 1

    if PD.aborted then
        fail("[ProjectDelta] Aborted: " .. tostring(PD.aborted))
        return
    end
end

print(("[ProjectDelta] Loaded %d/%d modules successfully."):format(loaded, #FILES))
