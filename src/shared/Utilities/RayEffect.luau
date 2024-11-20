local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RayEffects = {}


function RayEffects.BaseRay(Origin, End): Part
    local RayInstance = Instance.new("Part")
    RayInstance.Anchored = true
    RayInstance.CanCollide = false
    RayInstance.Color = Color3.fromRGB(255, 252, 72)
    RayInstance.Material = Enum.Material.Neon
    RayInstance.Size = Vector3.new(0.1, 0.1, (Origin - End).Magnitude)
    RayInstance.CFrame = CFrame.new(Origin, End) * CFrame.new(0, 0, -RayInstance.Size.Z/2)
    RayInstance.CanQuery = false
    RayInstance.Parent = workspace.Ignore

    return RayInstance
end

function RayEffects.BaseVisual(RayInstance:Part)
    local Visual = RayInstance:Clone()
    Visual.Parent = workspace.Ignore
    Visual.Transparency = 1

    Debris:AddItem(Visual, 5)

    return Visual
end

function RayEffects.Raygun(Origin, End)
    local RayInstance = RayEffects.BaseRay(Origin, End)

    RayInstance.Color = Color3.fromRGB(115, 255, 120)

    local VFX = ReplicatedStorage.Assets.VFX.Raygun:Clone()
    VFX.Parent = RayEffects.BaseVisual(RayInstance)
    VFX:Emit(VFX.Parent.Size.Z*2)

    TweenService:Create(RayInstance, TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size=Vector3.new(0,0,(Origin - End).Magnitude)}):Play()
    Debris:AddItem(RayInstance, .025)
end

function RayEffects.Default(Origin, End)
    local RayInstance = RayEffects.BaseRay(Origin, End)

    TweenService:Create(RayInstance, TweenInfo.new(.025, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size=Vector3.new(0,0,(Origin - End).Magnitude)}):Play()
    Debris:AddItem(RayInstance, .025)
end

return RayEffects