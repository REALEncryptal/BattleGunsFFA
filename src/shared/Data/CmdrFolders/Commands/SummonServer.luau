return function (context, entity, amount)
    if amount <= 0 then
        local NumberOfBots = #workspace.Bots:GetChildren()
        workspace.Bots:ClearAllChildren()
        return "Cleared "..NumberOfBots.." bots"
    end

    local MousePosition:Vector3 = context:GetData()

    local BotController = shared.Import "BotController"
    
    BotController:NewBot(entity, amount, MousePosition)

    return "Spawned " .. amount .. " instances of " .. entity
end