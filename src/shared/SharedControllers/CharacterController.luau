local Controller = {}
Controller.Characters = {}
Controller.Players = {}

local RunService = game:GetService("RunService")
local Signal, Constants

function Controller:Init()
    Signal = shared.Import "Signal"
    Constants = shared.Import "Constants"

    if RunService:IsClient() then
       for _, Player in pairs(game:GetService("Players"):GetPlayers()) do
            Controller.PlayerAdded(Player)
        end
    end

end

function Controller.PlayerAdded(Player:Player)
    Controller.Players[Player] = {
        CharacterAdded = Signal.new()
    }

    Player.CharacterAdded:Connect(function(Character)
        Controller._CharacterAdded(Character, Player)

        if RunService:IsServer() then
            for _, Accessory in pairs(Character:GetChildren()) do
                if Accessory:IsA("Accessory") then
                    Accessory:FindFirstChild("Handle").CanQuery = false
                end
            end
        end
    end)
end

function Controller._CharacterAdded(Character: Model, Player:Player)
    Controller.Characters[Character] = {
        HealthChanged = Signal.new(),
        Died = Signal.new()
    }

    if RunService:IsServer() then
        Character:SetAttribute("Health", 100)
        Instance.new("BoolValue", Character).Name = "BoolValue"
    end

    Character:WaitForChild("BoolValue")
    
    local con con = Character:GetAttributeChangedSignal("Health"):Connect(function()
        Controller.Characters[Character].HealthChanged:Fire(Character:GetAttribute("Health"))

        Character.Humanoid.Health = Character:GetAttribute("Health")

        if Character:GetAttribute("Health") <= 0 then
            con:Disconnect()
            Character:SetAttribute("Died", true)
            Controller:CharacterDied(Character)
        end
    end)


    -- finished
    Controller.Players[Player].CharacterAdded:Fire(Character)
end

-- private
function Controller:CharacterDied(Character)
    -- Fire Signal
    Controller.Characters[Character].Died:Fire()

    if not RunService:IsServer() then return end

    task.wait(Constants.RESPAWN_TIME)
    local Player = game.Players:GetPlayerFromCharacter(Character)
    if not Player then return end

    Player:LoadCharacter()
end

-- public
function Controller:GetSignals(Character)
    return Controller.Characters[Character]
end

function Controller:OnCharacterAdded(Player)
    repeat
        task.wait()
    until Controller.Players[Player]

    return Controller.Players[Player].CharacterAdded
end

function Controller:IsCharacterMoving(Character): boolean
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")

    if not Root then return false end

    local MoveDir = Humanoid.MoveDirection.Magnitude > 0
    local Vel = Root.AssemblyLinearVelocity.Magnitude > 0

    return MoveDir and Vel
end

return Controller