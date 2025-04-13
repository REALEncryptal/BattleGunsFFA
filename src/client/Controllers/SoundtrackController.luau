local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}


local PlaySound, Constants
function Controller:Init()
    PlaySound = shared.Import "PlaySound"
    Constants = shared.Import "Constants"

    Controller.Volume = Constants.BACKGROUND_VOLUME
    Controller.Track = 1

    Controller.Soundtracks = ReplicatedStorage.Assets.SFX.Soundtracks:GetChildren()
    Controller:UpdateVolumes()

end

function Controller:UpdateVolumes()
    for _, Soundtrack in ipairs(Controller.Soundtracks) do
        Soundtrack.Volume = Controller.Volume
    end
end

function Controller:Play()
    Controller.Volume = Constants.BACKGROUND_VOLUME
    Controller.Track += 1
    if Controller.Track > #Controller.Soundtracks then
        Controller.Track = 1
    end

    Controller.Soundtracks[Controller.Track]:Play()

    -- play next track after current track ends
    Controller.Soundtracks[Controller.Track].Ended:Connect(function()
        Controller:Play()
    end)
end

return Controller