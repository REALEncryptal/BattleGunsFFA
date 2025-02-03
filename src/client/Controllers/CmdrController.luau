local Controller = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cmdr
function Controller:Init()
    Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
    Cmdr:SetActivationKeys({ Enum.KeyCode.F2, Enum.KeyCode.Backquote })
end

return Controller