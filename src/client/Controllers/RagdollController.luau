local UserInputService = game:GetService("UserInputService")
local Controller = {}

local CharacterController, CameraUtil
function Controller:Init()
    CharacterController = shared.Import "CharacterController"
    CameraUtil = shared.Import "Camera"
    CharacterController:OnCharacterAdded(game.Players.LocalPlayer):Connect(Controller._CharacterAdded)
end

function Controller._CharacterAdded(Character)
    Controller.Loaded = true
    local LocalPlayer = game.Players.LocalPlayer
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

    UserInputService.MouseIconEnabled = false
    CharacterController:GetSignals(Character).Died:Connect(function()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 15
        LocalPlayer.CameraMinZoomDistance = 15
        
        UserInputService.MouseIconEnabled = true

        local Root:BasePart = Character:FindFirstChild("HumanoidRootPart")

        local Vel = (Root.AssemblyLinearVelocity * Vector3.new(1,0,1)).Unit

        Root:ApplyImpulse(Vector3.new(5, 100, 0) + Vel * 400)
        Root:ApplyAngularImpulse(Vector3.new(10, 400, 0))
    end)
end

return Controller