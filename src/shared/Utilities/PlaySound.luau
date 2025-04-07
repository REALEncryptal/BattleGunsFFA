local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function (Sound: Sound | Folder, Position: Vector3)
    if Sound:IsA("Folder") then
        local Sounds = Sound:GetChildren()
        Sound = Sounds[math.random(1, #Sounds)]
    end

    Sound = Sound:Clone()
    Debris:AddItem(Sound, Sound.TimeLength + 2)

    Sound.Parent = workspace.Ignore

    if Position then
        local SoundPart = Instance.new("Part")
        SoundPart.Size = Vector3.new()
        SoundPart.Position = Position
        SoundPart.Anchored = true
        SoundPart.CanCollide = false
        SoundPart.Transparency = 1
        SoundPart.Parent = workspace.Ignore

        if shared.Import("Constants").DEBUG and shared.Import("Constants").SHOW_SOUNDS then
            local DebugGui = ReplicatedStorage.Assets.AudioDebug:Clone()
            DebugGui.Parent = SoundPart

            DebugGui.SoundName.Text = Sound.Name

            Debris:AddItem(DebugGui, Sound.TimeLength)
        end

        Sound.Parent = SoundPart

        Debris:AddItem(SoundPart, Sound.TimeLength)
    end

    local StartTime = Sound:GetAttribute("StartTime") or 0
    Sound.TimePosition = StartTime

    Sound:Play()

    return Sound
end