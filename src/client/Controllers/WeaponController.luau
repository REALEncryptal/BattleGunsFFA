local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Controller = {}

local Event, RaycastWeapon, CharacterController, Camera, Constants, PlaySound, Signal
function Controller:Init()
    Event = shared.Import "Event"
    RaycastWeapon = shared.Import "RaycastWeapon"
    CharacterController = shared.Import "CharacterController"
    Camera = shared.Import "Camera"
    Constants = shared.Import "Constants"
    PlaySound = shared.Import "PlaySound"
    Signal = shared.Import "Signal"

    Controller.WeaponTypes = {
        RaycastWeapon =  shared.Import "RaycastWeapon",
        ProjectileWeapon =  shared.Import "ProjectileWeapon",
        WeaponBase =  shared.Import "WeaponBase",
    }

    Controller.Weapon = nil
    Controller.Enabled = true

    Event:Listen("SetWeapon", Controller.SetWeapon)

    CharacterController:OnCharacterAdded(game.Players.LocalPlayer):Connect(Controller._CharacterAdded)

    --
    Controller.UpdateParams = Signal.new()

    -- when a player is added
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            Controller.UpdateParams:Fire()
        end)
    end)

    -- when a folder changes
    local Folders = {"Bots"}

    for _, folder in ipairs(Folders) do
        local Folder = workspace:WaitForChild(folder)
        Folder.ChildAdded:Connect(function()
            Controller.UpdateParams:Fire()
        end)
    end

    -- when the game loop starts
    Event:Listen("GameState", function(State)
        if not State == "GameLoop" then return end
        Controller.UpdateParams:Fire()
    end)
end

function Controller._CharacterAdded(Character)
    CharacterController:GetSignals(Character).Died:Connect(function()
        if Controller.Weapon then
            Controller.Weapon:Destroy()
        end

        if Character:GetAttribute("LastHitBy") then
            local Killer = game.Players:GetPlayerByUserId(Character:GetAttribute("LastHitBy"))
            if not Killer then return end
            Camera:KilledBy(Killer)
        end
    end)

    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    workspace.CurrentCamera.FieldOfView = Constants.DEFAULT_FOV
end

function Controller.SetWeapon(Weapon:Model)
    local Config = require(Weapon.Configuration)

    
    if not Controller.WeaponTypes[Config.Type] then
        Constants:Debug("Invalid weapon type or missing type")
        return
    end

    if Controller.Weapon then 
        Controller.Weapon:Destroy()
        workspace.CurrentCamera:ClearAllChildren()
    end

    Controller.Weapon = Controller.WeaponTypes[Config.Type].new(Weapon)

    Controller.Weapon:Toggle(Controller.Enabled)
end

function Controller:Destroy()
    if not Controller.Weapon then return end
    Controller.Weapon:Destroy()
end

function Controller:Toggle(Enabled)
    Controller.Enabled = Enabled

    if Controller.Weapon then
        Controller.Weapon:Toggle(Enabled)
    end
end

function Controller.Update(DeltaTime)
    if not Controller.Weapon then return end

    Controller.Weapon:Update(DeltaTime)
end

return Controller