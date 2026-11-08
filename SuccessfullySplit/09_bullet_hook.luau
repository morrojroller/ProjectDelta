-- // 09_bullet_hook.luau
-- // Bullet.CreateBullet hook for silent-aim prediction.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local bullet = PD.bullet
local silentAim = PD.silentAim

-- // Hook Bullet Creation
local oldBullet
oldBullet = hookfunction(bullet.CreateBullet, function(idk, model, model2, model3, aimPart, ...)
    if silentAim.Enabled then
        local targetTestPart = PD.getTarget()
        if targetTestPart and aimPart and type(aimPart) == "userdata" and aimPart:IsA("BasePart") then
            local predictedPos = PD.getPredictedPosition(targetTestPart)
            local modifiedAimPart = {
                ["Position"] = predictedPos,
                ["CFrame"] = CFrame.new(aimPart.Position, predictedPos)
            }
            return oldBullet(idk, model, model2, model3, modifiedAimPart, ...)
        end
    end

    return oldBullet(idk, model, model2, model3, aimPart, ...)
end)
PD.oldBullet = oldBullet

-- // Bullet Hook Restoration Function for Unloading
local function restoreBulletHook()
    pcall(function()
        if PD.oldBullet then
            hookfunction(bullet.CreateBullet, PD.oldBullet)
        end
    end)
end
PD.restoreBulletHook = restoreBulletHook
