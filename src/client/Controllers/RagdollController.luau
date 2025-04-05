local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Controller = {}

local CharacterController, CameraUtil, WeaponController, PlaySound
function Controller:Init()
    CharacterController = shared.Import "CharacterController"
    CameraUtil = shared.Import "Camera"
    WeaponController = shared.Import "WeaponController"
    PlaySound = shared.Import "PlaySound"

    CharacterController:OnCharacterAdded(game.Players.LocalPlayer):Connect(Controller._CharacterAdded)
end

function Controller._CharacterAdded(Character)
    Controller.Loaded = true
    local LocalPlayer = game.Players.LocalPlayer
   LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

    UserInputService.MouseIconEnabled = if WeaponController.Enabled then false else true
    CharacterController:GetSignals(Character).Died:Connect(function()
        Character:WaitForChild("ControllerManager")
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 15
        LocalPlayer.CameraMinZoomDistance = 15

        game.ReplicatedStorage.Assets.SFX.Death:Play()
        
        UserInputService.MouseIconEnabled = true

        local Root:BasePart = Character:FindFirstChild("HumanoidRootPart")

        local Vel = (Root.AssemblyLinearVelocity * Vector3.new(1,0,1)).Unit
        Root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        Root:ApplyImpulse(Vector3.new(5, 0, 0) + Vel * 400)
        Root:ApplyImpulse(Vector3.new(0, 600, 0))
        Root:ApplyAngularImpulse(Vector3.new(10, 400, 0))

        local db = false
        Character:WaitForChild("Left Leg").Touched:Connect(function(TouchedPart)
            if db then return end
            if TouchedPart:IsDescendantOf(Character) then return end
            if not Character then return end
            if not Character.PrimaryPart then return end
            if Character.PrimaryPart.AssemblyLinearVelocity.Magnitude >= 8 then
                db = true
                local Sounds = ReplicatedStorage.Assets.SFX.BodyImpact:GetChildren()
                PlaySound(Sounds[math.random(1, #Sounds)], Character.PrimaryPart.Position)

                task.wait(.1)
                db = false
            end
        end)
    end)
end

return Controller