-- // 05_fov_visibility.luau
-- // FOV circle drawing + line-of-sight raycast helper.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local silentAim = PD.silentAim
local camera = PD.camera
local localPlayer = PD.localPlayer
local workspace = PD.workspace

-- // FOV Circle Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = silentAim.Enabled
fovCircle.Filled = false
fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Transparency = 1
fovCircle.Radius = silentAim.FovRadius
PD.fovCircle = fovCircle

-- // Line-of-sight Check Function
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
PD.raycastParams = raycastParams

local function isPartVisible(part)
    if not part then return false end
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (part.Position - rayOrigin)

    local filterList = {}
    if localPlayer.Character then
        table.insert(filterList, localPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = filterList

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        if result.Instance == part or result.Instance:IsDescendantOf(part.Parent) then
            return true
        end
        return false
    end
    return true
end
PD.isPartVisible = isPartVisible
