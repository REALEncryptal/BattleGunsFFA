local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local Constants, Event, CharacterController, KillEffectController, ReplicateController
function Controller:Init()
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"
    CharacterController = shared.Import "CharacterController"
    KillEffectController = shared.Import "KillEffectController"
    ReplicateController = shared.Import "ReplicateController"

    Controller.PlayerAnimations = {}

    Event:Listen("FireProjectile", Controller.FireProjectile) -- replicate fast cast shots to other clients
    Event:Listen("RaycastWeapon", Controller.RaycastWeapon)-- for raycasting
    Event:Listen("SelectWeapon", Controller.SelectWeapon)

    Event:Listen("AnimationState", function(Player, State)
        if not Controller.PlayerAnimations[Player] then return end

        if State == "Slide" then
            Controller.PlayerAnimations[Player].Slide:Play()
        else
            Controller.PlayerAnimations[Player].Slide:Stop()
        end
    end)
end

function Controller:ServerProjectile(Ignore:BasePart | Model, Config:ModuleScript, Origin:Vector3, Direction:Vector3)
    local Data = require(Config)
    
    for _=1, Data.BulletsPerShot do
        -- Generate a random angle and a random radius within the spread circle
        local SpreadRadius = math.rad(Data.Spread) -- Maximum spread radius in radians

        local RandomAngle = math.random() * 2 * math.pi -- Random angle in the circular area
        local RandomRadius = math.sqrt(math.random()) * SpreadRadius -- Random distance from the center
            
        -- Calculate spread components based on the random angle and radius
        local SpreadX = math.cos(RandomAngle) * RandomRadius
        local SpreadY = math.sin(RandomAngle) * RandomRadius
            
        -- Apply the spread to the direction vector
        local SpreadDirection = (CFrame.new(Origin, Origin + Direction) 
            * CFrame.Angles(SpreadY, SpreadX, 0)).LookVector * 10000

        task.spawn(ReplicateController.FireProjectile, Ignore, Config, Origin, SpreadDirection)
        Event:FireAllClients("FireProjectile", Ignore, Config, Origin, SpreadDirection)
    end
end

function Controller.PlayerAdded(Player: Player)
    CharacterController:OnCharacterAdded(Player):Connect(function()
        Controller.CharacterAdded(Player.Character, Player)
    end)

    Player:SetAttribute("Kills", 0)
    Player:SetAttribute("KillStreak", 0)
    Player:SetAttribute("EquippedWeapon", "Random")
end

function Controller.CharacterAdded(Character, Player)
    -- only do this for players not bots
    if Player then
        local Weapons = ReplicatedStorage.Assets.Weapons:GetChildren()
        local EquippedWeapon = Player:GetAttribute("EquippedWeapon")

        -- Select a weapon
        local Weapon = Weapons[math.random(1, #Weapons)]
        if EquippedWeapon ~= "Random" then
            Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild(EquippedWeapon)
        end

        -- Equip weapon
        Controller:EquipWeapon(Player, Weapon)
    end

    -- Tag accessories for raycasting
    for _, Accessory:Accessory in pairs(Character:GetDescendants()) do
        if Accessory:IsA("BasePart") then
            Accessory.CollisionGroup = "Player"
        end
        if not Accessory:IsA("Accessory") then continue end

        CollectionService:AddTag(Accessory.Handle, "Accessory")
    end

    -- add effects
    ReplicatedStorage.Assets.VFX.Blood:Clone().Parent = Character.HumanoidRootPart
    ReplicatedStorage.Assets.Highlight.OutlineColor = Constants.PLAYER_OUTLINE
    ReplicatedStorage.Assets.Highlight:Clone().Parent = Character

    -- Kill event for players and bots
    local Signal = if Player then CharacterController:GetSignals(Character).Died else Character:FindFirstChild("Humanoid").Died

    Signal:Connect(function()
         -- remove killstreak
         if Player then
            Player:SetAttribute("KillStreak", 0)
        end

        -- has a killer only
        if not Character:GetAttribute("LastHitBy") then return end
        if not Character:GetAttribute("LastHitBy")==0 then return end
        local Killer = game.Players:GetPlayerByUserId(Character:GetAttribute("LastHitBy"))
        if not Killer then
            KillEffectController:KillEffect(ReplicatedStorage.Assets.KillEffects:FindFirstChild("Conffeti"), Character, nil, Character.PrimaryPart.CFrame)
        else
            KillEffectController:KillEffect(ReplicatedStorage.Assets.KillEffects:FindFirstChild(Killer.Data:GetAttribute("KillEffect") or "Conffeti"), Character, Killer, Character.PrimaryPart.CFrame)
        end
        
        if not Killer then return end

        -- award killer
        if Killer then
            --TODO: BETTER HEADSHOT DETECTION
            Killer.Data:SetAttribute("Kills", Killer.Data:GetAttribute("Kills") + 1)

            -- kill streak
            Killer:SetAttribute("KillStreak", Killer:GetAttribute("KillStreak") + 1)
            Killer:SetAttribute("Kills", Killer:GetAttribute("Kills") + 1)

            local MoneyReward = Character:GetAttribute("LastHitHeadshot") and Constants.HEAD_KILL_REWARD or Constants.KILL_REWARD
            Killer.Data:SetAttribute("Money", Killer.Data:GetAttribute("Money") + MoneyReward)

            Killer.Character:SetAttribute("Health", 100)
            Killer.Character.Humanoid.Health = 100

            Event:FireClient(Killer, "Speedboost")
        end

        -- effects
        Event:FireClient(Killer, "Kill", Player or Character)
    end)

    if Player then
        -- add animatoins
        Controller.PlayerAnimations[Player] = {}

        local SlideAnimation = Instance.new("Animation")
        SlideAnimation.AnimationId = "rbxassetid://139482801025731"
        Controller.PlayerAnimations[Player].Slide = Character:WaitForChild("Humanoid"):WaitForChild("Animator"):LoadAnimation(SlideAnimation)
    end
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

-- Projectile fire
function Controller.FireProjectile(Player:Player, Weapon:Model, Origin:Vector3, Direction:Vector3)
    -- Validate weapon
    if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) and not ReplicatedStorage.Assets.AdminWeapons:FindFirstChild(Weapon.Name) then return false end

    -- Validate player
    local Character = Player.Character
    if not Character then return false end

    local Health = Character:GetAttribute("Health")
    if not Health or Health <= 0 then return false end

    -- Replicate shot
    for _, OtherPlayer in pairs(game.Players:GetPlayers()) do
        if OtherPlayer == Player then continue end

        Event:FireClient(OtherPlayer, "FireProjectile", Player.Character, Weapon, Origin, Direction)
    end
end

-- Shot validation
function Controller.RaycastWeapon(Player:Player|Model, Weapon:any, Position: Vector3, Instance: Instance, Normal:Vector3): boolean
    if not Instance then return false end

    -- Validate weapon
    if Player:IsA("Player") then
        if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) and not ReplicatedStorage.Assets.AdminWeapons:FindFirstChild(Weapon.Name) then return false end

        -- Validate playerw
        if Player then
            local Character = Player.Character
            if not Character then return false end

            local Health = Character:GetAttribute("Health")
            if not Health or Health <= 0 then return false end
        end

        Controller:PlaySound(Player.Character.Head.Position, Weapon.Sounds.Shoot, Player)
    else
        if Player:FindFirstChild("Humanoid") then
            local Health = Player.Humanoid.Health
            if not Health or Health <= 0 then return false end
        end
    end


    --TODO: CHECK WEAPON STATS (Bullets, Damage, etc)

    -- Play Sound
    

    -- Raycast

    -- Check humanoid
    if Instance.Parent then
        if Instance.Parent:IsA("Model") then
            local Health = Instance.Parent:GetAttribute("Health") 

            if Health or Instance.Parent:FindFirstChild("Humanoid") then 
                return Controller:BulletHit(Player, Weapon, Position, Instance)
            end
        end
    end

    -- Create bullet hole
    local Config = typeof(Weapon) == "Instance" and require(Weapon:FindFirstChild("Configuration")) or Weapon

    if Config.CreateBulletHole then
        task.spawn(Config.CreateBulletHole, Player, Position, Instance, Normal)
        return true
    end

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
    WeaponModel.Name = "Weapon"
    WeaponModel.Parent = Character

    local Motor6D = Instance.new("Motor6D")
    Motor6D.Part0 = Character:WaitForChild("Right Arm")
    Motor6D.Part1 = WeaponModel:WaitForChild("Handle")

    Motor6D.Name = "WeaponMotor"
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
function Controller:BulletHit(Player:Player|Model, Weapon:any, Position:Vector3, Instance:Instance): boolean
    if Player:IsA("Player") then
        if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) and not ReplicatedStorage.Assets.AdminWeapons:FindFirstChild(Weapon.Name) then return false end
    end

    local Config = typeof(Weapon) == "Instance" and require(Weapon:FindFirstChild("Configuration")) or Weapon

    if Config.BulletHitEvent then
        task.spawn(Config.BulletHitEvent, Player, Position, Instance)
    end

    -- Damage
    if not Instance then return false end
    
    local IsHeadShot = Instance.Name == "Head"

    Instance = Instance.Parent
    if not Instance then return false end

    local Health = Instance:GetAttribute("Health")
    local Damage = Config.Damage * (IsHeadShot and Config.HeadshotMultiplier or 1)
    if Health then
        Health -= Damage
        Instance:SetAttribute("Health", Health)
    else
        if Instance:FindFirstChild("Humanoid") then
            Instance.Humanoid.Health = Instance.Humanoid.Health - Damage
        else
            return false
        end
    end

    local Victim = game.Players:GetPlayerFromCharacter(Instance)
    if Victim then
        Event:FireClient(Victim, "Hit", Player, IsHeadShot)
    end

    if Config.PlayerHitEvent then
        task.spawn(Config.PlayerHitEvent, Player, Position, Instance, Victim, Damage, IsHeadShot)
    end
    
    Instance:SetAttribute("LastHit", tick())
    if Player:IsA("Player") then
        Instance:SetAttribute("LastHitBy", Player.UserId)
    else
        Instance:SetAttribute("LastHitBy", 0)
    end
    Instance:SetAttribute("LastHitHeadshot", IsHeadShot)

    return true
end

return Controller