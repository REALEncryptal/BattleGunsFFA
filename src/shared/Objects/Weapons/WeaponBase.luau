local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local WeaponObject = {}
WeaponObject.__index = WeaponObject

function WeaponObject.new(Weapon)
    local self = setmetatable({}, WeaponObject)

    local Spring3 = shared.Import "Spring3"

    self.Enabled = true
    self.Destroyed = false

    self.Trove = shared.Import("Trove").new()

    self.Weapon = self.Trove:Add(Weapon:Clone())
    self.Viewmodel = self.Trove:Add(ReplicatedStorage.Assets.Viewmodel:Clone())
    self.Config = require(self.Weapon:FindFirstChild("Configuration"))

    self.Viewmodel.Parent = workspace.CurrentCamera
    self.Grounded = false

    -- create springs
    self.Springs = {
        Sway = Spring3.new(),
        Tilt = Spring3.new(), -- tilt when moving left/right
        Move = Spring3.new(5,50,6,6), -- walk bob  mass force damping speed
        Recoil = Spring3.new(6,50,2,7), -- golden values
        Impact = Spring3.new() -- when hitting the ground
    }

    self.Offsets = {
        Base = self.Config.Offsets.Base
    }

    -- apply humanoid description
    local Description:HumanoidDescription = game.Players.LocalPlayer.Character:WaitForChild("Humanoid"):GetAppliedDescription()
    self.Viewmodel.Shirt.ShirtTemplate = Description.Shirt
    self.Viewmodel.BodyColors.LeftArmColor3 = Description.LeftArmColor
    self.Viewmodel.BodyColors.RightArmColor3 = Description.RightArmColor

    -- rig weapon
    self:Rig()

    -- load animations
    self:LoadAnimations()

    return self
end

function WeaponObject:Destroy()
    self.Trove:Destroy()
    self.Enabled = false
    self.Destroyed = true
end

function WeaponObject:Rig()
    self.Weapon.Parent = self.Viewmodel

    self.Weapon.PrimaryPart.CFrame = self.Viewmodel.PrimaryPart.CFrame

    local Motor6D = Instance.new("Motor6D")
    Motor6D.Name = "Weapon"
    Motor6D.Part0 = self.Viewmodel.PrimaryPart
    Motor6D.Part1 = self.Weapon.PrimaryPart
    Motor6D.Parent = self.Viewmodel.PrimaryPart
end

function WeaponObject:LoadAnimations()
    local Humanoid = self.Viewmodel:WaitForChild("Humanoid")
    local Animator = Humanoid:WaitForChild("Animator")

    self.Animations = {}

    for Name, AnimationId in pairs(self.Config.Animations) do
        local Animation = Instance.new("Animation")
        Animation.AnimationId = AnimationId

        local Track = Animator:LoadAnimation(Animation)

        self.Animations[Name] = Track
    end

    self.Animations.Idle:Play()
end

function WeaponObject:FunctionalUpdate(DeltaTime)
    -- implemented by children
end

function WeaponObject:FunctionalUpdateViewmodel(UpdatedSprings, DeltaTime): CFrame
    return CFrame.new()
end

function WeaponObject:FunctionalUpdateCamera(UpdatedSprings, DeltaTime): CFrame
    return CFrame.new()
end

function WeaponObject:Update(DeltaTime): boolean
    self:FunctionalUpdate(DeltaTime)
    if not self.Enabled or self.Destroyed then return false end

    local Character = game.Players.LocalPlayer.Character

    if not Character then return end
    if not Character:FindFirstChild("HumanoidRootPart") then return end
    -- brother is gone 🙏😭

    local CameraCFrame = workspace.CurrentCamera.CFrame
    local MouseDelta = UserInputService:GetMouseDelta()
    local SpringFinal = Vector3.new()
    local OffsetFinal = CFrame.new()

    -- calculate sway
    self.Springs.Sway:Shove(Vector3.new(-MouseDelta.X/90, MouseDelta.Y/90, 0))

    -- calculate move
    local Moving = shared.Import("CharacterController"):IsCharacterMoving(Character)
    local WasGrounded = self.Grounded
    self.Grounded =Character.HumanoidRootPart.GroundSensor.SensedPart

    if Moving and self.Grounded then
        self.Springs.Move:Shove(Vector3.new(
            math.cos(tick()*7)*.15,
            math.sin(tick()*7*2)*.12-.2,
            0
        ))
    elseif Moving and not self.Grounded then
        self.Springs.Move:Shove(Vector3.new())
    elseif not self.Grounded then
        self.Springs.Move:Shove(Vector3.new(0,.1,0))
    end
    
    local TiltAmount = CameraCFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection).Unit.X

    -- fix nan
    if TiltAmount ~= TiltAmount then
        TiltAmount = 0
    end

    self.Springs.Tilt:Shove(Vector3.new(TiltAmount,TiltAmount*2,0))

    if self.Grounded and not WasGrounded and Character.HumanoidRootPart.AssemblyLinearVelocity.Y < -10 then
        self.Springs.Impact:Shove(Vector3.new(0,-1,0))
    end

    -- add offsets
    for _, Offset in pairs(self.Offsets) do
        OffsetFinal *= Offset
    end

    -- update Springs
    local UpdatedSprings = {}

    for SpringName, Spring in pairs(self.Springs) do
        UpdatedSprings[SpringName] = Spring:Update(DeltaTime)
    end

    -- add springs
    SpringFinal += UpdatedSprings.Sway 
        + UpdatedSprings.Move 
        + UpdatedSprings.Impact
        + UpdatedSprings.Tilt/20

    SpringFinal = CFrame.new(SpringFinal) 
        * CFrame.Angles(math.rad(UpdatedSprings.Sway.Y*-20), math.rad(UpdatedSprings.Sway.X*10), 0)
        * CFrame.Angles(math.rad(UpdatedSprings.Impact.Y*25), 0, 0)
        * CFrame.Angles(0, 0, math.rad(UpdatedSprings.Tilt.X*-5))
        * self:FunctionalUpdateViewmodel(UpdatedSprings, DeltaTime)

    -- set viewmodel pos
    self.Viewmodel.PrimaryPart.CFrame = CameraCFrame * SpringFinal * OffsetFinal

    -- set camera pos
    workspace.CurrentCamera.CFrame = CameraCFrame * self:FunctionalUpdateCamera(UpdatedSprings, DeltaTime)

    return true
end

return WeaponObject