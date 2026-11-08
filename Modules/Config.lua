-- // Modules/Config.lua
local HttpService = game:GetService("HttpService")

local Config = {
    Data = {
        Enabled = true,
        SelectedHitPart = "Head",
        FovRadius = 250,
        VisibleOnly = false,
        ExcludedPlayers = {},
        Fullbright = false,
        HideVisibles = false,
        InventoryVisible = true,
        InventoryPositionX = 30,
        InventoryPositionY = 220,
        InventoryScale = 1.0
    },
    FileName = "SilentAim_Config.json"
}

function Config:Save()
    pcall(function()
        if writefile then
            writefile(self.FileName, HttpService:JSONEncode(self.Data))
        end
    end)
end

function Config:Load()
    pcall(function()
        if isfile and isfile(self.FileName) then
            local decoded = HttpService:JSONDecode(readfile(self.FileName))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    self.Data[k] = v
                end
            end
        end
    end)
end

return Config
