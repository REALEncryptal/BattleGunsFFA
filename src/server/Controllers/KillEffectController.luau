local Controller = {}

local Event
function Controller:Init()
    Event = shared.Import "Event"
end

function Controller:KillEffect(KillEffect:ModuleScript, Character:Model, Killer:Player, CFrameBeforeDeath: CFrame)
    Event:FireAllClients("KillEffect", KillEffect, Character, Killer, CFrameBeforeDeath)
end

return Controller