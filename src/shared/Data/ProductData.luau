return {
    UnlockWeapons = {
        Type = Enum.InfoType.GamePass,
        AssetID = 970873915,
        Name = "Unlock Weapons",
        Description = "Unlock all weapons",

        PlayerJoined = function(Player)
            Player:SetAttribute("UnlockWeapons", true)
        end
    }
}