local Controller = {}

local CharacterController
function Controller:Init()
    CharacterController = shared.Import "CharacterController"

    CharacterController:OnCharacterAdded(game.Players.LocalPlayer):Connect(Controller._CharacterAdded)
end

function Controller._CharacterAdded(Character)
    local LocalPlayer = game.Players.LocalPlayer
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

    CharacterController:GetSignals(Character).Died:Connect(function()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 15
        LocalPlayer.CameraMinZoomDistance = 15

        local Root:BasePart = Character:FindFirstChild("HumanoidRootPart")

        local Vel = (Root.AssemblyLinearVelocity * Vector3.new(1,0,1)).Unit

        Root:ApplyImpulse(Vector3.new(0, 200, 0) + Vel * 200)
        Root:ApplyAngularImpulse(Vector3.new(0, 500, 0))
    end)
end

return Controller