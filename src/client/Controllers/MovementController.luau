local Workspace = game:GetService("Workspace")
local Controller = {}

local Constants
function Controller:Init()
    Constants = shared.Import "Constants"

    Workspace.Gravity = Constants.GRAVITY

    Controller.Enabled = true

    Controller.Humanoid = nil
    Controller.Ground = nil
    Controller.JumpCount = 0
    Controller.WishJump = false
    Controller.LastJump = tick()
end

function Controller.CharacterAdded(Character)
    Controller.Character = Character
    Controller.Humanoid = Character:WaitForChild("Humanoid")
    Controller.Manager = Character:WaitForChild("ControllerManager")

    Controller.Manager.ActiveController = Controller.Manager.GroundController
    Controller.GroundSensor = Character.HumanoidRootPart.GroundSensor

    Controller.JumpCount = 0
end

function Controller:SetGroundController()
    Controller.Manager.ActiveController = Controller.Manager.GroundController
end

function Controller:SetAirController()
    Controller.Manager.ActiveController = Controller.Manager.AirController
end

function Controller:Jump()
    if Controller.JumpCount >= Constants.JUMPS then return end
    if tick() - Controller.LastJump < Constants.JUMP_DELAY then return end
    if Constants.AUTO_JUMP and Controller.JumpCount > 0 then return end

    Controller.JumpCount += 1
    Controller.LastJump = tick()

    Controller.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    Controller.Character.HumanoidRootPart:ApplyImpulse(Vector3.new(0, Constants.JUMP, 0))
end

function Controller.Update()
    if not Controller.Character then return end
    if not Controller.Character:FindFirstChild("ControllerManager") then return end
    if not Controller.Humanoid then return end

    -- Get Data
    local WasJump = Controller.WishJump

    local MoveDirection = Controller.Humanoid.MoveDirection
    Controller.Ground = Controller.GroundSensor.SensedPart
    Controller.WishJump = Controller.Humanoid.Jump

    -- Set Controller
    if Controller.Ground then
        Controller.JumpCount = 0
        Controller.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        Controller:SetGroundController()
    else
        Controller:SetAirController()
    end

    -- Apply movement
    if not Controller.Enabled then return end

    Controller.Manager.MovingDirection = MoveDirection
    Controller.Manager.FacingDirection = MoveDirection

    if Controller.WishJump and Constants.AUTO_JUMP then
        Controller:Jump()
    elseif Controller.WishJump and not WasJump then
        Controller:Jump() 
    end
end

return Controller