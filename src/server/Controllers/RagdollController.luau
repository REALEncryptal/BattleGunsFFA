local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

--[[
    SOURCE: https://devforum.roblox.com/t/updated-perfect-r6-ragdoll-easiest-ragdoll-system-for-r6-avatars/2413582
]]

local attachmentCFrames = {
	["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
	["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
	["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
	["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
}

local ragdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

local CharacterController
function Controller:Init()
    CharacterController = shared.Import "CharacterController"
end

function Controller.PlayerAdded(Player: Player)
    CharacterController:OnCharacterAdded(Player):Connect(Controller.CharacterAdded)
end

function Controller.CharacterAdded(Character)
    CharacterController:GetSignals(Character).Died:Connect(function()
        if not Character:FindFirstChild("ControllerManager") then return end
        Character:FindFirstChild("ControllerManager"):Destroy()
        Controller:Ragdoll(Character)
    end)
end

function Controller:CreateColliderPart(Part)
    if not Part:IsA("BasePart") then return end

    local Collider = Instance.new("Part")
    Collider.Size = Part.Size/1.7
    Collider.Massless = true
    Collider.Transparency = 1
    Collider.CFrame = Part.CFrame
    Collider.CollisionGroup = "RagdollCollider"
    Collider.Name = "ColliderPart"

    local Weld = Instance.new("WeldConstraint")
    Weld.Part0 = Part
    Weld.Part1 = Collider

    Collider.Parent = Part
    Weld.Parent = Collider
end

function Controller:Ragdoll(Character)
    for _, Motor6D:Motor6D in pairs(Character:GetDescendants()) do
        if not Motor6D:IsA("Motor6D") then continue end
        if not attachmentCFrames[Motor6D.Name] then continue end

        Motor6D.Enabled = false

        local Attachment0, Attachment1 = Instance.new("Attachment"), Instance.new("Attachment")
        Attachment0.CFrame = attachmentCFrames[Motor6D.Name][1]
        Attachment1.CFrame = attachmentCFrames[Motor6D.Name][2]

        Attachment0.Name = "RagdollAttachment"
        Attachment1.Name = "RagdollAttachment"

        Controller:CreateColliderPart(Motor6D.Part1)

        local Constraint = Instance.new("BallSocketConstraint")
        Constraint.Attachment0 = Attachment0
        Constraint.Attachment1 = Attachment1
        Constraint.Name = "RagdollConstraint"

        Constraint.Radius = 0.15
        Constraint.LimitsEnabled = true
        Constraint.TwistLimitsEnabled = false
        Constraint.MaxFrictionTorque = 0
        Constraint.Restitution = 0
        Constraint.UpperAngle = 90
        Constraint.TwistLowerAngle = -45
        Constraint.TwistUpperAngle = 45

        if Motor6D.Name == "Neck" then
            Constraint.TwistLimitsEnabled = true
            Constraint.UpperAngle = 45
            Constraint.TwistLowerAngle = -70
            Constraint.TwistUpperAngle = 70
        end

        Attachment0.Parent = Motor6D.Part0
        Attachment1.Parent = Motor6D.Part1
        Constraint.Parent = Motor6D.Parent
    end
    
    Character.Humanoid.AutoRotate = false

    local Root: BasePart = Character:FindFirstChild("HumanoidRootPart")

    ReplicatedStorage.Assets.VFX.Trail:Clone().Parent = Root
end

return Controller