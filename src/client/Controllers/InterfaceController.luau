local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Controller = {}

function Controller:PreInit()
    Controller.Gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Game")
end

local Event, MonetizationController, NumberFormat
function Controller:Init()
    Event = shared.Import "Event"
    MonetizationController = shared.Import "MonetizationController"
    NumberFormat = shared.Import "NumberFormat"

    Controller.SpreadAngle = 0
    Controller.Crosshair = nil
    Controller.CurrentFrame = nil
    Controller.Enabled = true

    Event:Listen("Kill", function(Player:Player)
        Controller:KillResult(Player)
    end)

    -- Setup Frames
    Controller:SetupAnimations()
    Controller:SetupShopFrame()
    Controller:SetupGunsFrame()
    Controller:SetupMoney()
end

-- Animate
function Controller:SetupAnimations()
    Controller.FrameOpenTweens = {
        TweenService:Create(game.Lighting.Blur, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Size = 20}),
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(.2, Enum.EasingStyle.Quad), {FieldOfView = 50}),
    }

    Controller.FrameCloseTweens = {
        TweenService:Create(game.Lighting.Blur, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Size = 0}),
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(.2, Enum.EasingStyle.Quad), {FieldOfView = 70}),
    }
end

function Controller:ToggleMouse(Visible)
    UserInputService.MouseIconEnabled = Visible
    Controller.Gui.ToggleCursor.Visible =  Visible
end

function Controller:TweenButton(Frame:Frame, Trigger:GuiButton)
    local BaseTween = TweenService:Create(Frame, TweenInfo.new(.1, Enum.EasingStyle.Quad), {Size = Frame.Size})
    local HoverTween = TweenService:Create(Frame, TweenInfo.new(.1, Enum.EasingStyle.Quad), {Size = UDim2.new(1.1 * Frame.Size.X.Scale,0,1.1 * Frame.Size.Y.Scale,0)})
    local PressTween = TweenService:Create(Frame, TweenInfo.new(.1, Enum.EasingStyle.Quad), {Size = UDim2.new(.9 * Frame.Size.X.Scale,0,.9 * Frame.Size.Y.Scale,0)})

    local Hovered = false

    Trigger.MouseEnter:Connect(function()
        Hovered = true
        HoverTween:Play()
    end)

    Trigger.MouseLeave:Connect(function()
        Hovered = false
        BaseTween:Play()
    end)


    Trigger.MouseButton1Down:Connect(function()
        PressTween:Play()
    end)

    Trigger.MouseButton1Up:Connect(function()
        BaseTween:Play()
    end)
end

function Controller:PlayTweens(Tweens)
    for _, Tween in ipairs(Tweens) do
        Tween:Play()
    end
end

function Controller:StopTweens(Tweens)
    for _, Tween in ipairs(Tweens) do
        Tween:Cancel()
    end
end

function Controller:AnimateFrame(Frame, Triggers, KeyBind)
    local function Toggle()
        if not Controller.Enabled then return end
        if Controller.CurrentFrame == Frame then
            Controller.CurrentFrame = nil
            Frame.Visible = false
            Controller:ToggleMouse(false)
            Controller:PlayTweens(Controller.FrameCloseTweens)
        else
            if Controller.CurrentFrame then
                Controller.CurrentFrame.Visible = false
            end

            Controller.CurrentFrame = Frame
            Frame.Visible = true
            Controller:ToggleMouse(Frame.Visible)
            Controller:PlayTweens(Controller.FrameOpenTweens)
        end
    end

    for _, Trigger:GuiButton in ipairs(Triggers) do
        Trigger.Activated:Connect(Toggle)
        if KeyBind then
            ContextActionService:BindAction("Toggle" .. Frame.Name, function(_, State)
                if State == Enum.UserInputState.End then
                    Toggle()
                end
            end, false, KeyBind)
        end
    end
end

-- MONEY DISPLAY
function Controller:SetupMoney()
    local Data = game.Players.LocalPlayer:WaitForChild("Data")
    
    Controller:UpdateMoney(Data)

    Data.AttributeChanged:Connect(function()
        Controller:UpdateMoney(Data)
    end)
end

function Controller:UpdateMoney(Data)
    local MoneyFrame = Controller.Gui.LeftBar.Money.Money
    local Amount = Data:GetAttribute("Money")

    MoneyFrame.Amount.Text = NumberFormat(Amount)
end

-- SHOP FRAME
function Controller:SetupShopFrame()
    local Frame:Frame = Controller.Gui.Frames:WaitForChild("Shop")

    -- Animate
    Controller:TweenButton(Frame.Exit, Frame.Exit)
    Controller:AnimateFrame(Frame, {Frame.Exit, Controller.Gui.LeftBar.Shop.Trigger}, Enum.KeyCode.B)
    Controller:TweenButton(Controller.Gui.LeftBar.Shop.Frame, Controller.Gui.LeftBar.Shop.Trigger)

    -- Link purchase buttons
    for _, Config:Configuration in ipairs(Frame.Shop.Selector:GetDescendants()) do
        if not Config:IsA("Configuration") then continue end

        local ButtonFrame = Config.Parent
        local Trigger = ButtonFrame.Trigger

        Controller:TweenButton(ButtonFrame, Trigger)

        -- Connection
        Trigger.Activated:Connect(function()
            MonetizationController:PromptPurchase(Config:GetAttribute("AssetName"))
        end)
    end
end

-- GUNS FRAME
-- Source: https://devforum.roblox.com/t/camerazoomtoextents/1514600/5
local function getModelFitDistance(model, vpf, camera) 
	local modelCFrame, modelSize = model:GetBoundingBox()
	local vpfSize = vpf.AbsoluteSize
	
	-- clamped b/c we only want to scale the xfov2 if width < height
	-- otherwise if width > height then xfov2 == yfov2
	local wh = math.min(1, vpfSize.X / vpfSize.Y)

	local yfov2 = math.rad(camera.FieldOfView / 2)
	local xfov2 = math.atan(math.tan(yfov2) * wh)
	local radius = modelSize.Magnitude / 2

	return radius / math.sin(xfov2)
end

function Controller:SetupGunsFrame()
    local Frame:Frame = Controller.Gui.Frames:WaitForChild("Guns")

    -- Animate
    Controller:TweenButton(Frame.Exit, Frame.Exit)
    Controller:AnimateFrame(Frame, {Frame.Exit, Controller.Gui.LeftBar.Guns.Trigger}, Enum.KeyCode.G)
    Controller:TweenButton(Controller.Gui.LeftBar.Guns.Frame, Controller.Gui.LeftBar.Guns.Trigger)

    -- Setup Viewport
    Controller:PopulateGunsFrame()
end

function Controller:PopulateGunsFrame()
    local Frame:Frame = Controller.Gui.Frames:WaitForChild("Guns")
    local Entries:ScrollingFrame = Frame.Guns.Selector
    local Weapons = ReplicatedStorage.Assets.Weapons:GetChildren()

    if not Controller.ViewportFrames then
        Controller.ViewportFrames = {}

        for _, Weapon in ipairs(Weapons) do
            -- Setup Viewport
            local Viewport:ViewportFrame = ReplicatedStorage.Assets.Interface.Viewport:Clone()
            Viewport.LightColor = Color3.fromRGB(255, 255, 255)
            Viewport.Ambient = Color3.fromRGB(255, 255, 255)
            Viewport.LightDirection = Vector3.new(-1,-.2,0)
            local WeaponModel:Model = Weapon:Clone()
            WeaponModel.Parent = Viewport
            WeaponModel:PivotTo(CFrame.new(0, 0, 0))
    
            local ViewportCamera = Instance.new("Camera")
            ViewportCamera.Parent = Viewport
            Viewport.CurrentCamera = ViewportCamera

            local BoundingBox = WeaponModel:GetBoundingBox()
            local Distance = getModelFitDistance(WeaponModel, Viewport, ViewportCamera)
            ViewportCamera.CFrame = CFrame.new(Vector3.new(Distance*.7, 0, 0), BoundingBox.Position/2) * CFrame.Angles(0, 0, math.rad(-35))
            ViewportCamera:SetAttribute("DefaultCFrame", ViewportCamera.CFrame)

            -- Hover
            Viewport.MouseEnter:Connect(function()
                Viewport:SetAttribute("HoverTick", tick())
            end)

            Viewport.MouseLeave:Connect(function()
                Viewport:SetAttribute("HoverTick", nil)
                WeaponModel:PivotTo(CFrame.new(0, 0, 0))
                ViewportCamera.CFrame = ViewportCamera:GetAttribute("DefaultCFrame")
            end)

            -- Store
            Controller.ViewportFrames[Weapon.Name] = Viewport
        end
    end

    --
    local EquippedWeapon = game.Players.LocalPlayer:GetAttribute("EquippedWeapon")

    -- Clear any existing entries
    for _, Entry in pairs(Entries:GetChildren()) do
        if not Entry:IsA("Frame") then continue end

        -- Move viewports back to storage
        if Entry.Name ~= "Random" then
            Entry.Frame.Viewport.Parent = ReplicatedStorage
        end

        Entry:Destroy()
    end

    -- TODO: Animate buttons

    -- Add random
    local RandomEntry:Frame = ReplicatedStorage.Assets.Interface.Random:Clone()
    RandomEntry.Name = "Random"
    RandomEntry.Parent = Entries

    -- Populate frame

    for i, Weapon in ipairs(Weapons) do
        local WeaponEntry:Frame = ReplicatedStorage.Assets.Interface.Entry:Clone()
        WeaponEntry.Name = Weapon.Name
        WeaponEntry.LayoutOrder = i + 1 -- Ensure random is always first
        WeaponEntry.Parent = Entries

        WeaponEntry.Frame.Title.Text = require(Weapon:FindFirstChild("Configuration")).Name
        
        -- Setup Viewport
        local Viewport:ViewportFrame = Controller.ViewportFrames[Weapon.Name]
        Viewport.Parent = WeaponEntry.Frame
    end

    -- Go through all entries
    for _, Entry in pairs(Entries:GetChildren()) do
        if not Entry:IsA("Frame") then continue end

        -- Animate
        Controller:TweenButton(Entry.Frame, Entry.Trigger)

        if Entry.Name == EquippedWeapon then
            -- Show state
            Entry.Frame.Check.Visible = true
            Entry.Frame.BackgroundColor3 = Color3.fromRGB(179, 255, 185)
        end

        -- Connect
        Entry.Trigger.Activated:Connect(function()
            if Entry.Name ~= "Random" then
                if not game.Players.LocalPlayer:GetAttribute("UnlockWeapons") then
                    MonetizationController:PromptPurchase("UnlockWeapons")
                    return
                end
            end

            Event:InvokeServer("SelectWeapon", Entry.Name)
            Controller:PopulateGunsFrame()
        end) 
    end
end


-- Misc
function Controller:KillResult(Player:Player)
    Controller.Gui.KillResult.Text = "You killed " .. Player.Name

    Controller.KillResultTween = Controller.KillResultTween or TweenService:Create(Controller.Gui.KillResult, TweenInfo.new(2, Enum.EasingStyle.Quad), {TextTransparency = 1})
    Controller.KillResultTweenStroke = Controller.KillResultTweenStroke or TweenService:Create(Controller.Gui.KillResult.UiStroke, TweenInfo.new(2, Enum.EasingStyle.Quad), {Transparency = 1})
    Controller.Gui.KillResult.TextTransparency = 0
    Controller.Gui.KillResult.UiStroke.Transparency = 0
    Controller.KillResultTween:Play()
end

function Controller:Hitmarker()
    Controller.HitmarkTween = Controller.HitmarkTween or TweenService:Create(Controller.Gui.Hitmarker, TweenInfo.new(.2, Enum.EasingStyle.Quad), {ImageTransparency = 1})

    Controller.Gui.Hitmarker.ImageTransparency = 0
    Controller.HitmarkTween:Play()
end

function Controller:UseCrosshair(CrosshairName)
    if Controller.Crosshair then
        Controller.Crosshair.Visible = false
    end

    Controller.Crosshair = Controller.Gui:WaitForChild("Crosshairs"):FindFirstChild(CrosshairName)
    Controller.Crosshair.Visible = true
end

function Controller:SetSpread(Spread)
    Controller.SpreadAngle = Spread

    if not Controller.Crosshair then return end
    if Controller.Crosshair.Name == "Regular" then return end
    if Controller.Crosshair.Name == "Dot" then return end

    local Left = Controller.Crosshair:FindFirstChild("Left")
    local Right = Controller.Crosshair:FindFirstChild("Right")
    local Up = Controller.Crosshair:FindFirstChild("Up")
    local Down = Controller.Crosshair:FindFirstChild("Down")

    local Offset = math.tan(math.rad(Spread) / 2)

    Left.Position = UDim2.new(-Offset, 0, 0.5, 0)
    Right.Position = UDim2.new(1 + Offset, 0, 0.5, 0)

    if not Up or not Down then return end

    Up.Position = UDim2.new(0.5, 0, -Offset, 0)
    Down.Position = UDim2.new(0.5, 0, 1 + Offset, 0)
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

-- UPDATE
function Controller.Update()
    for _, Viewport in pairs(Controller.ViewportFrames) do
        local Camera = Viewport:FindFirstChildOfClass("Camera")
        local HoverTick = Viewport:GetAttribute("HoverTick")

        if not HoverTick then continue end

        local Angle =  math.rad((tick() - HoverTick) * 50)
        local Offset = CFrame.Angles(math.rad(35),0, 0) * Camera:GetAttribute("DefaultCFrame")

        Camera.CFrame = Offset
        Viewport:FindFirstChildOfClass("Model"):PivotTo(CFrame.Angles(0, Angle, 0))
    end
end

return Controller