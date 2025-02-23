local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Controller = {}

local Event
function Controller:Init()
    Event = shared.Import "Event"

    Event:Listen("KillEffect", Controller.KillEffect)
end

function Controller.KillEffect(KillEffect:ModuleScript, Character:Model, Killer:Player, CFrameBeforeDeath: CFrame)
    local RunFunction = require(KillEffect)

    if Killer == game.Players.LocalPlayer then
        SoundService:PlayLocalSound(ReplicatedStorage.Assets.SFX.Kill)
    end

    RunFunction(Character, Killer, CFrameBeforeDeath)
end

return Controller
