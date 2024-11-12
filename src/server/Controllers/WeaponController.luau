local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local Constants, Event
function Controller:Init()
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"

    Event:Listen("RaycastWeapon", Controller.RaycastWeapon)
end

function Controller.PlayerAdded(Player: Player)
    Player.CharacterAdded:Connect(function(character)
        Controller.CharacterAdded(character, Player)
    end)
end

function Controller.CharacterAdded(Character, Player)
    local Weapons = ReplicatedStorage.Assets.Weapons:GetChildren()
    local Weapon = Weapons[math.random(1, #Weapons)]

    for _, Accessory:Accessory in pairs(Character:GetDescendants()) do
        if not Accessory:IsA("Accessory") then continue end

        CollectionService:AddTag(Accessory, "Accesory")
    end

    Event:FireClient(Player, "SetWeapon", Weapon)
end

-- Sound
function Controller:PlaySound(Position: Vector3, Sound: Sound, ExcludedPlayer:Player)
    for _, Player in pairs(game.Players:GetPlayers()) do
        if Player == ExcludedPlayer then continue end

        Event:FireClient(Player, "PlaySound", Position, Sound)
    end
end

-- Bullet hit
function Controller:BulletHit(Player, Weapon:Model, Position:Vector3, Instance:Instance): boolean
    if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) then return false end

    local Config = require(Weapon:FindFirstChild("Configuration"))

    -- Check distance
    local Distance = (Position - Instance.Position).Magnitude
    if Distance > 10 then return false end

    -- Damage
    local IsHeadShot = Instance.Name == "Head"

    Instance = Instance.Parent

    local Health = Instance:GetAttribute("Health")
    if Health then
        Health -= Config.Damage * (IsHeadShot and Config.HeadshotMultiplier or 1)
        Instance:SetAttribute("Health", Health)
    end

    return true
end

-- Shot validation
function Controller.RaycastWeapon(Player:Player, Weapon:Model, Position: Vector3, Instance: Instance): boolean
    -- Validate weapon
    if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) then return end

    -- Validate player
    local Character = Player.Character
    if not Character then return false end

    local Health = Character:GetAttribute("Health")
    if not Health or Health <= 0 then return false end

    --TODO: CHECK WEAPON STATS (Bullets, Damage, etc)

    -- Play Sound
    Controller:PlaySound(Player.Character.Head.Position, Weapon.Sounds.Shoot, Player)

    -- Raycast

    -- Check humanoid
    if Instance.Parent:IsA("Model") then
        local Health = Instance.Parent:GetAttribute("Health") 
        if Health then 
            return Controller:BulletHit(Player, Weapon, Position, Instance)
        end
    end

    -- TODO: CREATE BULLET HOLE

    return true
end

return Controller