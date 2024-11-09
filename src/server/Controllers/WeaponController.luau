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
    local Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild("M4A1")

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
function Controller:BulletHit(Player, RaycastResult:RaycastResult, Weapon:Model)
    if not ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon.Name) then return end

    local Config = require(Weapon:FindFirstChild("Configuration"))

    -- sound
    Controller:PlaySound(Player.Character.Head.Position, Weapon.Sounds.Shoot, Player)

    -- Damage
    local HitPart = RaycastResult.Instance
    local IsHeadShot = HitPart.Name == "Head"

    if HitPart.Parent:IsA("Model") then
        HitPart = HitPart.Parent
    end

    local Health = HitPart:GetAttribute("Health")
    if Health then
        Health -= Config.Damage * (IsHeadShot and Config.HeadshotMultiplier or 1)
        HitPart:SetAttribute("Health", Health)
    end
end

-- Shot validation
function Controller.RaycastWeapon(Player:Player, Origin: Vector3, Direction: Vector3, Weapon:Model): boolean
    -- Validate player
    local Character = Player.Character
    if not Character then return false end

    local Health = Character:GetAttribute("Health")
    if not Health or Health <= 0 then return false end

    local PlayerHeadPosition = Character:WaitForChild("Head").Position
    local Distance = (Origin - PlayerHeadPosition).Magnitude
    if Distance > 15  then return false end

    --TODO: CHECK WEAPON STATS (Bullets, Damage, etc)

    -- Raycast
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {Player.Character, workspace.Debug}
    Params.FilterType = Enum.RaycastFilterType.Exclude

    local RaycastResult = workspace:Raycast(Origin, Direction, Params)
    if RaycastResult then
        Controller:BulletHit(Player, RaycastResult, Weapon)

        return true
    end

    return false
end

return Controller