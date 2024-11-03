local Controller = {}
Controller.Characters = {}
Controller.Players = {}

local RunService = game:GetService("RunService")
local Signal

function Controller:Init()
    Signal = shared.Import "Signal"

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
    end)
end

function Controller._CharacterAdded(Character: Model, Player:Player)
    Controller.Characters[Character] = {
        HealthChanged = Signal.new(),
        Died = Signal.new()
    }

    if RunService:IsServer() then
        Character:SetAttribute("Health", 100)
    end
    
    Character:GetAttributeChangedSignal("Health"):Connect(function()
        Controller.Characters[Character].HealthChanged:Fire(Character:GetAttribute("Health"))

        if Character:GetAttribute("Health") <= 0 then
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

    task.wait(3)
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

    local MoveDir = Humanoid.MoveDirection.Magnitude > 0
    local Vel = Root.AssemblyLinearVelocity.Magnitude > 0

    return MoveDir and Vel
end

return Controller