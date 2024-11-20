local Util = {}

local TweenService = game:GetService("TweenService")
local Camera = game.Workspace.CurrentCamera

local userInputService = game:GetService("UserInputService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local SensModifier = 1

local mouseDeltaSensitivity = SensModifier  / UserGameSettings.MouseSensitivity 
userInputService.MouseDeltaSensitivity = mouseDeltaSensitivity

UserGameSettings:GetPropertyChangedSignal("MouseSensitivity"):Connect(function()
	mouseDeltaSensitivity = SensModifier  / UserGameSettings.MouseSensitivity 
	userInputService.MouseDeltaSensitivity = mouseDeltaSensitivity
end)

function Util:SetSensitivityModifier(Mod)
    SensModifier = Mod
    mouseDeltaSensitivity = SensModifier  / UserGameSettings.MouseSensitivity 
    userInputService.MouseDeltaSensitivity = mouseDeltaSensitivity
end

function Util:TweenFov(Fov, Time)
    Time = Time or 0.5

    local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
    local Tween = TweenService:Create(Camera, TweenInfo, {FieldOfView = Fov})

    Tween:Play()
end

function Util:KilledBy(Player:Player)
    local KillerCharacter = Player.Character
    workspace.CurrentCamera.CameraType = Enum.CameraType.Watch
    workspace.CurrentCamera.CameraSubject = KillerCharacter:FindFirstChildOfClass("Humanoid")
end

return Util