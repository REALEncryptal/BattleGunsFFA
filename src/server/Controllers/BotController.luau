local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local WeaponController
function Controller:Init()
    WeaponController = shared.Import "WeaponController"

    
end

function Controller:NewBot(Entity:string, Amount:number, Position:Vector3)
    local EntityModel = ReplicatedStorage.Assets.Bots:FindFirstChild(Entity)

    for _=1,Amount do
        local NewModel = EntityModel:Clone()
        NewModel:PivotTo(CFrame.new(Position + Vector3.new(0, 4, 0) + Vector3.new(math.random(-7,7),0,math.random(-7,7))))
        NewModel.Parent = workspace.Bots

        WeaponController.CharacterAdded(NewModel)
    end
end

function Controller:Update()
    
end

return Controller