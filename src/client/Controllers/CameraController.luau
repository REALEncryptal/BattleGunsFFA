local TweenService = game:GetService("TweenService")
local Controller = {
    Tweens = {}
}

local Constants
function Controller:Init()
    Constants = shared.Import "Constants"

    Controller.FOV = Instance.new("NumberValue")
    Controller.FOV.Name = "FOV"
    Controller.FOV.Value = Constants.DEFAULT_FOV
    Controller.FOV.Parent = workspace.CurrentCamera

    Controller.Offsets = {}

    local FOVS = {
        "DEFAULT_FOV",
        "MOVE_FOV",
        "SLIDE_FOV"
    }
    
    for _, FOV_NAME in ipairs(FOVS) do
        local FOV = Constants[FOV_NAME]

        Controller.Tweens[FOV_NAME] = TweenService:Create(
            Controller.FOV,
            TweenInfo.new(
                Constants.FOV_CHANGE_TIME,
                Constants.FOV_CHANGE_EASING,
                Constants.FOV_CHANGE_EASING_DIRECTION
            ),
            {
                Value = FOV
            }
        )
    end
end

function Controller:AddOffset(Value)
    table.insert(Controller.Offsets, Value)
end

function Controller:GetTween(FOV_Name)
    return Controller.Tweens[FOV_Name]
end

function Controller.Update()
    local FOVOffsets = 0

    for _, Offset in pairs(Controller.Offsets) do
        FOVOffsets += Offset
    end

    Controller.Offsets = {}

    workspace.CurrentCamera.FieldOfView = Controller.FOV.Value + FOVOffsets
end

return Controller