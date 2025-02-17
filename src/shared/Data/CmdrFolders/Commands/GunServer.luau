local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function (context, Name, Player)
    local WeaponController = shared.Import "WeaponController"

    local Weapon = ReplicatedStorage.Assets.AdminWeapons:FindFirstChild(Name)
    if not Weapon then
        return "Failed to find weapon " .. Name
    end

    Player = Player or context.Executor
    WeaponController:EquipWeapon(Player, Weapon)
    
    return "Gave " .. Player.Name .. " " .. Name
end