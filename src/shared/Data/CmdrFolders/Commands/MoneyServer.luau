return function (context, Money, Player, Add:boolean)
    Player = Player or context.Executor

    if not Add then
        Player.Data:SetAttribute("Money", Money)
    else
        -- take 3 seconds to give them the money
        local length = 2
        local periods = 20
        for i = 1, periods do
            task.wait(length/periods)
            Player.Data:SetAttribute("Money", Player.Data:GetAttribute("Money") + math.round(Money/periods))
        end
    end
    
    return "Set " .. Player.Name .. "'s money to " .. Money
end