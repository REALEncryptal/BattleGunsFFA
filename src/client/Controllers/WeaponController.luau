local Controller = {}

local Event, WeaponObject, CharacterController
function Controller:Init()
    Event = shared.Import "Event"
    WeaponObject = shared.Import "WeaponObject"
    CharacterController = shared.Import "CharacterController"

    Controller.Weapon = nil

    Event:Listen("SetWeapon", Controller.SetWeapon)

    CharacterController:OnCharacterAdded(game.Players.LocalPlayer):Connect(Controller._CharacterAdded)
end

function Controller._CharacterAdded(Character)
    CharacterController:GetSignals(Character).Died:Connect(function()
        if Controller.Weapon then
            Controller.Weapon:Destroy()
        end
    end)
end

function Controller.SetWeapon(Weapon:Model)
    if Controller.Weapon then
        Controller.Weapon:Destroy()
    end

    Controller.Weapon = WeaponObject.new(Weapon)
end

function Controller.Update(DeltaTime)
    if not Controller.Weapon then return end

    Controller.Weapon:Update(DeltaTime)
end

return Controller