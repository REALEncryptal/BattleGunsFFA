local Controller = {}

local Constants, Event
function Controller:Init()
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"

    Event:Listen("Reset", function(Player)
        Player.Character:SetAttribute("Health", 0)
    end)

    Event:Listen("Loaded", function(Player)
        if Player:GetAttribute("Loaded") then return end
        task.wait(1)
        Player:LoadCharacter()
        Player:SetAttribute("Loaded", true)
    end)
end

function Controller.PlayerAdded(Player:Player)
    Player.CharacterAdded:Connect(Controller.CharacterAdded)
end

function Controller:SetupPhysics(Character)
    if Character:FindFirstChild("ControllerManager") then return end
    local Manager = Instance.new("ControllerManager")
    local GroundController = Instance.new("GroundController", Manager)
    local AirController = Instance.new("AirController", Manager)
    local ClimbController = Instance.new("ClimbController", Manager)

    local Humanoid = Character:WaitForChild("Humanoid")
    Manager.RootPart = Character:WaitForChild("HumanoidRootPart")
    GroundController.GroundOffset = 2
    Manager.FacingDirection = Manager.RootPart.CFrame.LookVector

    local FloorSensor = Instance.new("ControllerPartSensor")
    FloorSensor.SensorMode = Enum.SensorMode.Floor
    FloorSensor.SearchDistance = GroundController.GroundOffset + 0.35
    FloorSensor.Name = "GroundSensor"

    local LadderSensor = Instance.new("ControllerPartSensor")
    LadderSensor.SensorMode = Enum.SensorMode.Ladder
    LadderSensor.SearchDistance = 1.5
    LadderSensor.Name = "ClimbSensor"

    Manager.GroundSensor = FloorSensor
    Manager.ClimbSensor = LadderSensor

    FloorSensor.Parent = Manager.RootPart
    LadderSensor.Parent = Manager.RootPart
    Manager.Parent = Character

    -- Apply configs
    Manager.BaseMoveSpeed = Constants.SPEED
    Manager.BaseTurnSpeed = 10

    AirController.MaintainLinearMomentum = true
    AirController.MaintainAngularMomentum = false
    AirController.MoveMaxForce = Constants.AIR_FORCE
    AirController.MoveSpeedFactor = Constants.AIR_SPEED

    GroundController.AccelerationTime = Constants.ACCEL_TIME
    GroundController.DecelerationTime = Constants.DECEL_TIME
    GroundController.FrictionWeight = Constants.FRICTION_WEIGHT
    GroundController.TurnSpeedFactor = Constants.TURN_SPEED
    GroundController.BalanceRigidityEnabled = true

    Manager.BaseTurnSpeed = 10

    -- Disable Humanoid state machine and physics
    Humanoid.EvaluateStateMachine = false

    -- fix density : number,friction : number,elasticity : number,frictionWeight : number,elasticityWeight : number)
    local ColliderMaterial = PhysicalProperties.new(.7, 0, 0, 100, 100)
    Character.Head.CustomPhysicalProperties = ColliderMaterial
    Character.Torso.CustomPhysicalProperties = ColliderMaterial
end

function Controller.CharacterAdded(Character)
    local Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = Constants.SPEED
    Humanoid.JumpPower = Constants.JUMP
    Humanoid.JumpHeight = Constants.JUMP_HEIGHT
end

return Controller