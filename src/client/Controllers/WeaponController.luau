local Debris = game:GetService("Debris")
local Controller = {}

local Event, RaycastWeapon, CharacterController
function Controller:Init()
    Event = shared.Import "Event"
    RaycastWeapon = shared.Import "RaycastWeapon"
    CharacterController = shared.Import "CharacterController"

    Controller.Weapon = nil

    Event:Listen("SetWeapon", Controller.SetWeapon)
    Event:Listen("PlaySound", Controller.PlaySound)

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

    Controller.Weapon = RaycastWeapon.new(Weapon)
end

function Controller.PlaySound(Position: Vector3, Sound: Sound)
    local SoundOrigin = Instance.new("Part")
    SoundOrigin.Position = Position
    SoundOrigin.Anchored = true
    SoundOrigin.CanCollide = false
    SoundOrigin.Size = Vector3.new(0.1, 0.1, 0.1)
    SoundOrigin.Transparency = 1
    SoundOrigin.Parent = workspace
    SoundOrigin.CanQuery = false

    local SoundInstance = Sound:Clone()
    SoundInstance.Parent = SoundOrigin
    SoundInstance:Play()

    Debris:AddItem(SoundOrigin, SoundInstance.TimeLength)
end

function Controller.Update(DeltaTime)
    if not Controller.Weapon then return end

    Controller.Weapon:Update(DeltaTime)
end

return Controller