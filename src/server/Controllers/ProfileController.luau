local Controller = {}

local Players = game:GetService("Players")
local ProfileService, Constants

function Controller:PreInit()
    ProfileService = shared.Import "ProfileService"
    Constants = shared.Import "Constants"

    Controller.ProfileStore = ProfileService.GetProfileStore(
        "PlayerData",
        Constants.PROFILE_TEMPLATE
    )    
end


-- Profile Interface
function Controller:Init()
    Controller.Profiles = {}

    -- In case Players have joined the server earlier than this script ran:
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(Controller.PlayerAdded, player)
    end

    Players.PlayerAdded:Connect(Controller.PlayerAdded)

    Players.PlayerRemoving:Connect(function(player)
        local profile = Controller.Profiles[player]
        Controller.Profiles[player].Data = Controller:FolderToData(player:FindFirstChild("Data"))
        if profile ~= nil then
            profile:Release()
        end
    end)

end

function Controller.PlayerAdded(player)
    local profile = Controller.ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        profile:ListenToRelease(function()
            Controller.Profiles[player] = nil
            -- The profile could've been loaded on another Roblox server:

            Constants:Debug("[ProfileController] Player profile released: ", player)
            player:Kick()
        end)
        if player:IsDescendantOf(Players) == true then
            Controller.Profiles[player] = profile
        else
            -- Player left before the profile loaded:
            profile:Release()
        end

        -- create interface
        local DataFolder = Controller:DataToFolder(profile.Data)
        DataFolder.Parent = player
        DataFolder.Name = "Data"

        for _, Folder:Folder in ipairs(DataFolder:GetDescendants()) do
            Folder.AttributeChanged:Connect(function()
                profile.Data = Controller:FolderToData(player:FindFirstChild("Data"))
            end)
        end

        -- create leaderstats
        local Leaderstats = Instance.new("Folder")
        Leaderstats.Name = "leaderstats"
        Leaderstats.Parent = player

        local Kills = Instance.new("IntValue")
        Kills.Name = "Kills"
        Kills.Value = 0
        Kills.Parent = Leaderstats

        local TotalKills = Instance.new("IntValue")
        TotalKills.Name = "Total Kills"
        TotalKills.Value = DataFolder:GetAttribute("Kills")
        TotalKills.Parent = Leaderstats

        -- listen to data changes
        DataFolder:GetAttributeChangedSignal("Kills"):Connect(function()
            TotalKills.Value = DataFolder:GetAttribute("Kills")
        end)
    end
end

-- Data Interface
function Controller:FolderToData(Directory)
    if not Directory then 
        Constants:Debug("[ProfileController] FolderToData: Directory is nil: ", Directory)
        return
    end
    local Data = Directory:GetAttributes()

    for _, Folder in ipairs(Directory:GetChildren()) do
        Data[Folder.Name] = Controller:FolderToData(Folder)
    end

    return Data
end

function Controller:DataToFolder(Data): Folder
    local Folder = Instance.new("Folder")

    for Index, Value in pairs(Data) do
        if type(Value) == "table" then
            local NewFolder = Controller:DataToFolder(Value)
            NewFolder.Name = Index
            NewFolder.Parent = Folder
        else
            Folder:SetAttribute(Index, Value)
        end
    end

    return Folder
end

function Controller:GetProfile(player)
    if player:IsA("Player") then
        return Controller.Profiles[player]
    elseif type(player) == "number" then--userid
        for Player, Profile in pairs(Controller.Profiles) do
            if Player.UserId == player then
                return Profile
            end
        end
    elseif type(player) == "string" then--username
        for Player, Profile in pairs(Controller.Profiles) do
            if Player.Name == player then
                return Profile
            end
        end
    end
end

return Controller