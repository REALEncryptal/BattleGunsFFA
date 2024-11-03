local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local Constants, Event
function Controller:Init()
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"
end

function Controller.PlayerAdded(Player: Player)
    Player.CharacterAdded:Connect(function(character)
        Controller.CharacterAdded(character, Player)
    end)
end

function Controller.CharacterAdded(Character, Player)
    local Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild("M4A1")

    Event:FireClient(Player, "SetWeapon", Weapon)
end

return Controller