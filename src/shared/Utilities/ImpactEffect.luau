local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function (RaycastResult:RaycastResult)
    if not RaycastResult then return end
    if RaycastResult.Instance.Parent:FindFirstChild("Humanoid") then return end

    local Material = RaycastResult.Material
    local Position = RaycastResult.Position
    local Normal = RaycastResult.Normal

    local ImpactEffect = ReplicatedStorage.Assets.Particles:FindFirstChild(Material.Name) or ReplicatedStorage.Assets.Particles:FindFirstChild("Any")
    ImpactEffect = ImpactEffect:Clone()

    local ImpactSound = ReplicatedStorage.Assets.SFX.BulletImpact:FindFirstChild(Material.Name) or ReplicatedStorage.Assets.SFX.BulletImpact:FindFirstChild("Any")
    shared.Import("PlaySound")(ImpactSound, Position)

    if ImpactEffect.Name == "Any" then
        local Color = RaycastResult.Instance.Color
        local H, S, V = Color:ToHSV()

        V = V * .7
        S = S * .5

        Color = Color3.fromHSV(H, S, V)

        ImpactEffect.ParticleEmitter.Color = ColorSequence.new(Color)
    end

    ImpactEffect.Parent = workspace.Ignore

    ImpactEffect.CFrame = CFrame.new(Position, Position + Normal) * CFrame.Angles(math.rad(-90), 0, 0)

    -- emit
    local Lifetime = 0

    for _, Emitter:ParticleEmitter in ipairs(ImpactEffect:GetChildren()) do
        if not Emitter:IsA("ParticleEmitter") then return end

        local Amount = Emitter:GetAttribute("Amount") or 10
        local MaxLifetime = Emitter.Lifetime.Max

        Emitter:Emit(Amount)

        if MaxLifetime > Lifetime then
            Lifetime = MaxLifetime
        end
    end

    Debris:AddItem(ImpactEffect, Lifetime)
end