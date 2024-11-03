local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local WeaponObject = {}
WeaponObject.__index = WeaponObject

function WeaponObject.new(Weapon)
    local self = setmetatable({}, WeaponObject)

    local Spring3 = shared.Import "Spring3"

    self.Enabled = true

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
        Move = Spring3.new(), -- walk bob
        Recoil = Spring3.new(),
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

    return self
end

function WeaponObject:Destroy()
    self.Trove:Destroy()
    self.Enabled = false
end

function WeaponObject:Update(DeltaTime): boolean
    if not self.Enabled then return false end
    local Character = game.Players.LocalPlayer.Character
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
            math.sin(tick()*10)*.1,
            math.cos(tick()*20)*.1,
            0
        ))
    elseif Moving and not self.Grounded then
        self.Springs.Move:Shove(Vector3.new(
            math.sin(tick()*2.5)*.05,
            math.cos(tick()*5)*.05 + 0.1,
            0
        ))
    elseif not self.Grounded then
        self.Springs.Move:Shove(Vector3.new(0,.1,0))
    end

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
    SpringFinal += UpdatedSprings.Sway + UpdatedSprings.Move + UpdatedSprings.Impact

    SpringFinal = CFrame.new(SpringFinal) 
        * CFrame.Angles(math.rad(UpdatedSprings.Sway.Y*-20), math.rad(UpdatedSprings.Sway.X*10), 0)
        * CFrame.Angles(math.rad(UpdatedSprings.Impact.Y*25), 0, 0)

    -- set viewmodel pos
    self.Viewmodel.PrimaryPart.CFrame = CameraCFrame * SpringFinal * OffsetFinal

    return true
end

return WeaponObject