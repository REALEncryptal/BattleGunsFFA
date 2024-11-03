local Util = {}

local TweenService = game:GetService("TweenService")
local Camera

function Util:TweenFov(Fov, Time)
    Time = Time or 0.5

    local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
    local Tween = TweenService:Create(Camera, TweenInfo, {FieldOfView = Fov})

    Tween:Play()
end

return Util