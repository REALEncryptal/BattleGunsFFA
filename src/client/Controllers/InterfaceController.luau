local TweenService = game:GetService("TweenService")
local Controller = {}

function Controller:PreInit()
    Controller.Gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Game")
end

function Controller:Init()
    

    Controller.Crosshair = nil
end

function Controller:UseCrosshair(CrosshairName)
    if Controller.Crosshair then
        Controller.Crosshair.Visible = false
    end

    Controller.Crosshair = Controller.Gui:WaitForChild("Crosshairs"):FindFirstChild(CrosshairName)
    Controller.Crosshair.Visible = true
end

function Controller:TweenAmmoUi()
    Controller.AmmoTweenIn = Controller.AmmoTweenIn or TweenService:Create(Controller.Gui.WeaponInfo.Ammo.Ammo, TweenInfo.new(.05, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,.7,0)})
    Controller.AmmoTweenOut = Controller.AmmoTweenOut or TweenService:Create(Controller.Gui.WeaponInfo.Ammo.Ammo, TweenInfo.new(.1, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,1,0)})



    if not Controller.TweenConnection then
        Controller.TweenConnection = Controller.AmmoTweenIn.Completed:Connect(function()
            Controller.AmmoTweenOut:Play()
        end)
    end

    Controller.AmmoTweenIn:Play()
end

function Controller:TweenCooldown(Time): Tween
    Controller.Gui.Cooldown.Visible = true

    Controller.Gui.Cooldown.Bar.Size = UDim2.new(0,0,1,0)
    local Tween = TweenService:Create(Controller.Gui.Cooldown.Bar, TweenInfo.new(Time, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)})

    Tween:Play()

    Tween.Completed:Connect(function()
        Controller.Gui.Cooldown.Visible = false
    end)

    return Tween
end

return Controller