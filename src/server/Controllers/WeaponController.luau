local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local Constants, Event, CharacterController, KillEffectController
function Controller:Init()
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"
    CharacterController = shared.Import "CharacterController"
    KillEffectController = shared.Import "KillEffectController"

    Event:Listen("RaycastWeapon", Controller.RaycastWeapon)
    Event:Listen("SelectWeapon", Controller.SelectWeapon)
end

function Controller.PlayerAdded(Player: Player)
    CharacterController:OnCharacterAdded(Player):Connect(function()
        Controller.CharacterAdded(Player.Character, Player)
    end)

    Player:SetAttribute("EquippedWeapon", "Random")
end

function Controller.CharacterAdded(Character, Player)
    local Weapons = ReplicatedStorage.Assets.Weapons:GetChildren()
    local EquippedWeapon = Player:GetAttribute("EquippedWeapon")

    -- Select a weapon
    local Weapon = Weapons[math.random(1, #Weapons)]
    if EquippedWeapon ~= "Random" then
        Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild(EquippedWeapon)
    end

    -- Tag accessories for raycasting
    for _, Accessory:Accessory in pairs(Character:GetDescendants()) do
        if not Accessory:IsA("Accessory") then continue end

        CollectionService:AddTag(Accessory, "Accesory")
    end

    -- Equip weapon
    Controller:EquipWeapon(Player, Weapon)

    -- Kill event
    CharacterController:GetSignals(Character).Died:Connect(function()
        if not Character:GetAttribute("LastHitBy") then return end

        local Killer = game.Players:GetPlayerByUserId(Character:GetAttribute("LastHitBy"))

        -- award killer
        if Killer then
            Killer.Data:SetAttribute("Kills", Killer.Data:GetAttribute("Kills") + 1)
        end

        -- effects
        Event:FireClient(Killer, "Kill", Player)
        KillEffectController:KillEffect(ReplicatedStorage.Assets.KillEffects:FindFirstChild(Killer.Data:GetAttribute("KillEffect") or "Conffeti"), Character, Killer, Character.PrimaryPart.CFrame)
    end)
end

-- Weapon selection for client
function Controller.SelectWeapon(Player, WeaponName)
    local Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild(WeaponName)
    if not Weapon and WeaponName ~= "Random" then return false end

    if WeaponName ~= "Random" then
        if not Player:GetAttribute("UnlockWeapons") then return false end
    end

    Player:SetAttribute("EquippedWeapon", WeaponName)
    return true
end

-- Shot validation
function Controller.RaycastWeapon(Player:Player, Weapon:Model, Position: Vector3, Instance: Instance, Normal:Vector3): boolean
    if not Instance then return false end

    -- Validate weapon
    if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) then return false end

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
    if Instance.Parent then
        if Instance.Parent:IsA("Model") then
            local Health = Instance.Parent:GetAttribute("Health") 
            if Health then 
                return Controller:BulletHit(Player, Weapon, Position, Instance)
            end
        end
    end

    -- Create bullet hole
    local BulletHole = ReplicatedStorage.Assets.BulletHole:Clone()
    BulletHole.Position = Position
    BulletHole.CFrame = CFrame.new(Position, Position + Normal) * CFrame.Angles(0, 0, math.random(0, 360))
    BulletHole.Parent = workspace.Ignore

    Debris:AddItem(BulletHole, 10)

    return true
end

-- Weapon equip
function Controller:RecursiveTag(Instance, ObjectType, Tag)
    if Instance:IsA(ObjectType) then
        CollectionService:AddTag(Instance, Tag)
    end
    for _, child in Instance:GetChildren() do
        Controller:RecursiveTag(child, ObjectType, Tag)
    end
    Instance.ChildAdded:Connect(function(child)
        Controller:RecursiveTag(child, ObjectType, Tag)
    end)
end

function Controller:EquipWeapon(Player, Weapon)
    Event:FireClient(Player, "SetWeapon", Weapon)

    local Config = require(Weapon:FindFirstChild("Configuration"))
    local Character = Player.Character

    if not Character then return end
    
    local WeaponModel = Weapon:Clone()
    WeaponModel.Parent = Character

    local Motor6D = Instance.new("Motor6D")
    Motor6D.Part0 = Character:WaitForChild("Right Arm")
    Motor6D.Part1 = WeaponModel:WaitForChild("Handle")

    Motor6D.Parent = Character:FindFirstChild("Right Arm")

    -- Create tags for raycasting
    Controller:RecursiveTag(WeaponModel, "BasePart", "Weapon")

    -- Load Animation
    local Animation = Instance.new("Animation")
    Animation.AnimationId = Config.ServerIdle

    local Track = Character:WaitForChild("Humanoid"):WaitForChild("Animator"):LoadAnimation(Animation)
    Track:Play()
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
        Instance:SetAttribute("LastHit", tick())
        Instance:SetAttribute("LastHitBy", Player.UserId)
    end

    return true
end

return Controller