local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shell:Part = ReplicatedStorage.Assets.Shell

local Shells = {}

return function (Weapon, Power)
    if not Weapon.PrimaryPart:FindFirstChild("Eject") then return end

    if #Shells > 40 then
        Shells[1]:Destroy()
        table.remove(Shells, 1)
    end

    local ShellEffect = Shell:Clone()
    ShellEffect.Parent = workspace.Ignore
    ShellEffect.CFrame = Weapon.PrimaryPart.Eject.WorldCFrame
    ShellEffect.AssemblyLinearVelocity = ShellEffect.CFrame.LookVector * Power 
                                        + ShellEffect.CFrame.RightVector * math.random() * 10 
                                        + ShellEffect.CFrame.UpVector * math.random() * 2
    ShellEffect.AssemblyAngularVelocity = ShellEffect.CFrame.UpVector * Power



    table.insert(Shells, ShellEffect)

    local conn conn = ShellEffect.Touched:Connect(function(Hit)
        if not Hit:IsA("BasePart") then return end
        if Hit:IsDescendantOf(Weapon.Parent) then return end
        if Hit:IsDescendantOf(game.Players.LocalPlayer.Character) then return end

        ShellEffect.Sound:Play()

        if shared.Import("Constants").DEBUG then
            local DebugGui = ReplicatedStorage.Assets.AudioDebug:Clone()
            DebugGui.Parent = ShellEffect
    
            DebugGui.SoundName.Text = "Shell"
    
            Debris:AddItem(DebugGui, ShellEffect.Sound.TimeLength + 2)
        end

        conn:Disconnect()
    end)

    Debris:AddItem(ShellEffect, 5)
    task.spawn(function()
        task.wait(5)
        if ShellEffect then
            ShellEffect:Destroy()
            table.remove(Shells, table.find(Shells, ShellEffect))
            conn:Disconnect()
        end
    end)
end