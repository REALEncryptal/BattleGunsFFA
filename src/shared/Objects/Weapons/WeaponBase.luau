local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local WeaponObject = {}
WeaponObject.__index = WeaponObject

function WeaponObject.new(Weapon)
    local self = setmetatable({}, WeaponObject)

    local Spring3 = shared.Import "Spring3"

    self.DeltaTime = 0
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
        Offset = Spring3.new(), -- viewmodel offset
        Recoil = Spring3.new(6,50,2,7), -- golden values
        WeaponRecoil = Spring3.new(6,50,2,7), -- golden values
        Impact = Spring3.new(), -- when hitting the ground
        Camera = Spring3.new() -- camera offset
    }

    self.Offsets = {
        Base = self.Config.Offsets.Base
    }

    -- apply humanoid description
    pcall(function()
        local Description = game.Players:GetHumanoidDescriptionFromUserId(game.Players.LocalPlayer.UserId)
        if Description then
            self.Viewmodel.Humanoid:ApplyDescription(Description)
        end
    end)

    -- rig weapon
    self:Rig()

    -- load animations
    self:LoadAnimations()

    -- events
    local MovementController = shared.Import("MovementController")
    self.Trove:Add(MovementController.WallSlide:Connect(function(Start) 
        self.Springs.Impact:Shove(Vector3.new(0,-.5,0) * self.DeltaTime)

        if Start then
            ReplicatedStorage.Assets.SFX.Slide.Playing = true
        else
            ReplicatedStorage.Assets.SFX.Slide.Playing = false
        end
    end))

    self.Trove:Add(MovementController.WallJump:Connect(function()
        shared.Import("PlaySound")(ReplicatedStorage.Assets.SFX.Jump)
    end))

    self.Trove:Add(MovementController.WallDismount:Connect(function()
        shared.Import("PlaySound")(ReplicatedStorage.Assets.SFX.Dismount)
    end))

    self.Trove:Add(MovementController.Slide:Connect(function(sliding)
        shared.Import("Event"):FireServer("AnimationState", sliding and "Slide" or "Idle")
        
        self.Sliding = sliding

        if self.Sliding then
            shared.Import("PlaySound")(ReplicatedStorage.Assets.SFX.WoodSlide)
            self.Animations.ArmOff:Play()
        else
            shared.Import("PlaySound")(ReplicatedStorage.Assets.SFX.Jump)
            self.Animations.ArmOff:Stop()
        end
    end))

    self.Trove:Add(MovementController.Vault:Connect(function()
        self.Animations.ArmOff:Play()
        shared.Import("PlaySound")(ReplicatedStorage.Assets.SFX.Vault)
        self.Springs.Impact:Shove(Vector3.new(0,-2,0) * self.DeltaTime)
        task.wait(.35)
        self.Animations.ArmOff:Stop()
    end))

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

    local AnimationsToLoad = {}

    for Name, AnimationId in pairs(self.Config.Animations) do
        AnimationsToLoad[Name] = AnimationId
    end

    for Name, AnimationId in pairs(shared.Import("DefaultAnimations")) do
        AnimationsToLoad[Name] = AnimationId
    end

    for Name, AnimationId in pairs(AnimationsToLoad) do
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
    self.DeltaTime = DeltaTime
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
    self.Springs.Sway:Shove(Vector3.new(-MouseDelta.X/90, MouseDelta.Y/90, 0) * self.DeltaTime)

    -- calculate move
    local Moving = shared.Import("CharacterController"):IsCharacterMoving(Character)
    local WasGrounded = self.Grounded
    self.Grounded =Character.Humanoid.FloorMaterial ~= Enum.Material.Air

    if Moving and self.Grounded and not self.Sliding then
        self.Springs.Move:Shove(Vector3.new(
            math.cos(tick()*12)*.15,
            math.sin(tick()*12*2)*.15-.2,
            0
        )*DeltaTime)
    elseif Moving and not self.Grounded then
        self.Springs.Move:Shove(Vector3.new())
    elseif not self.Grounded then
        self.Springs.Move:Shove(Vector3.new(0,.1,0) * self.DeltaTime)
    end
    
    local TiltAmount = CameraCFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection).Unit.X

    if self.Sliding then
        TiltAmount = -2
    end

    -- fix nan
    if TiltAmount ~= TiltAmount then
        TiltAmount = 0
    end

    self.Springs.Tilt:Shove(Vector3.new(TiltAmount,TiltAmount*2,0) * self.DeltaTime)

    if self.Grounded and not WasGrounded and Character.HumanoidRootPart.AssemblyLinearVelocity.Y < -10 then
        self.Springs.Impact:Shove(Vector3.new(0,-1,0) * self.DeltaTime)
    end

    -- sliding effects
    if self.Sliding then
        self.Springs.Camera:Shove(Vector3.new(0,-.75,0) * self.DeltaTime)
        self.Springs.Offset:Shove(Vector3.new(-.3,-.2,0)*self.DeltaTime)
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
        + UpdatedSprings.Offset

    SpringFinal = CFrame.new(SpringFinal) 
        * CFrame.Angles(math.rad(UpdatedSprings.Sway.Y*-20), math.rad(UpdatedSprings.Sway.X*10), 0)
        * CFrame.Angles(math.rad(UpdatedSprings.Impact.Y*25), 0, 0)
        * CFrame.Angles(0, 0, math.rad(UpdatedSprings.Tilt.X*-5))
        * self:FunctionalUpdateViewmodel(UpdatedSprings, DeltaTime)

    -- camera
    CameraCFrame *= 
    CFrame.new(UpdatedSprings.Camera)
    * self:FunctionalUpdateCamera(UpdatedSprings, DeltaTime) 
    --* CFrame.Angles(math.rad(UpdatedSprings.Move.Y*10),math.rad(UpdatedSprings.Move.X*10),0)

    -- set viewmodel pos
    self.Viewmodel.PrimaryPart.CFrame = CameraCFrame * SpringFinal * OffsetFinal

    -- set camera pos
    workspace.CurrentCamera.CFrame = CameraCFrame

    return true
end

return WeaponObject