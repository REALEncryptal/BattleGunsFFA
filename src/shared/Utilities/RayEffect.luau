local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local function CreateRay(Origin, End)
    local Ray = Instance.new("Part")
    Ray.Anchored = true
    Ray.CanCollide = false
    Ray.Color = Color3.fromRGB(255, 252, 72)
    Ray.Material = Enum.Material.Neon
    Ray.Size = Vector3.new(0.1, 0.1, (Origin - End).Magnitude)
    Ray.CFrame = CFrame.new(Origin, End) * CFrame.new(0, 0, -Ray.Size.Z/2)
    Ray.CanQuery = false
    Ray.Parent = workspace

    TweenService:Create(Ray, TweenInfo.new(.025, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size=Vector3.new(0,0,(Origin - End).Magnitude)}):Play()
    Debris:AddItem(Ray, .025)
end

return CreateRay