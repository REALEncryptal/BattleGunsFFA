local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Controller = {}

function Controller:PreInit()
    Controller.Gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Game")
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end

local 
    Event, 
    MonetizationController, 
    NumberFormat, 
    UiScale, 
    Constants, 
    WeaponController, 
    Spring3, 
    PlaySound,
    SoundtrackController,
    InputUtil

function Controller:Init()
    Event = shared.Import "Event"
    MonetizationController = shared.Import "MonetizationController"
    NumberFormat = shared.Import "NumberFormat"
    UiScale = shared.Import "UiScale"
    Constants = shared.Import "Constants"
    WeaponController = shared.Import "WeaponController"
    Spring3 = shared.Import "Spring3"
    PlaySound = shared.Import "PlaySound"
    SoundtrackController = shared.Import "SoundtrackController"
    InputUtil = shared.Import "InputUtil"

    Controller.SpreadAngle = 0
    Controller.Crosshair = nil
    Controller.StartTime = 0
    Controller.CurrentFrame = nil
    Controller.Enabled = true
    Controller.CrosshairSpring = Spring3.new(3, 50, 4, 10)
    Controller.DefaultSpringData = {3, 50, 4, 10}
    Controller.DamageIndicators = {}
    --mass, force, damping, speed
    -- 5     50     4        4

    Event:Listen("Kill", function(Player:Player)
        Controller:KillResult(Player)
    end)

    Event:Listen("Hit", function(Attacker:Player, IsHeadShot)
        Controller:DamageIndicator(Attacker.Character.PrimaryPart.Position)
    end)

    -- Setup Frames
    task.spawn(function()
        Controller:SetupLoadingScreen()
    end)
    
    Controller:SetupAnimations()
    Controller:SetupVoteScreen()
    Controller:SetupShopFrame()
    Controller:SetupGunsFrame()
    Controller:SetupMoney()
    Controller:SetupUiScale()
    Controller:SetupGameState()
    Controller:SetupKillStreak()

    Controller:SetupSplats()
    

    -- Check if we joined during a map vote
    local GameState = Event:InvokeServer("GameState")
    if GameState.State == "MapVote" then
        Controller:StartVote(GameState.Maps, GameState.StartTime)
    end
end

-- mobile controls
function Controller:SetupMobileControls()
    local FireButton:ImageButton = InputUtil:GetButton("Fire")
    InputUtil:SetPosition("Fire",UDim2.new(
        FireButton.Position.X.Scale,
        FireButton.Position.X.Offset - FireButton.Size.X.Offset/2,
        FireButton.Position.Y.Scale,
        FireButton.Position.Y.Offset - FireButton.Size.Y.Offset*2
    ))
    InputUtil:SetSize("Fire", FireButton.Size.X.Offset*1.5)

    InputUtil:SetDragCallback("Fire", function(Offset, DeltaTime)
        print(Offset, DeltaTime)
    end)
end


-- splats
function Controller:SetupSplats()
    local SplatContainer = Controller.Gui:WaitForChild("Splats")

    Event:Listen("ScreenSplat", function()
        Controller:NewSplat()
    end)
end

function Controller:NewSplat()
    PlaySound(ReplicatedStorage.Assets.SFX.Splat)

    local Splat = ReplicatedStorage.Assets.Interface.Splat:Clone()
    Splat.Parent = Controller.Gui.Splats
    Splat.Position = UDim2.new(math.random(), 0, math.random(), 0)
    Splat.Size = UDim2.new(0, 0, 0, 0)
    Splat.ImageTransparency = 1
    Splat.Rotation = math.random(0, 360)

    TweenService:Create(
        Splat,
        TweenInfo.new(.1, Enum.EasingStyle.Quad),
        {
            Size = UDim2.new(math.random() * .2 + .4, 0, math.random() * .2 + .4, 0),
            ImageTransparency = 0
        }
    ):Play()

    task.wait(2)

    TweenService:Create(
        Splat,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        {
            Position = UDim2.new(Splat.Position.X.Scale, 0, Splat.Position.Y.Scale + .3, 0),
            ImageTransparency = 1,
        }
    ):Play()

    Debris:AddItem(Splat, 2)
end

-- kill streaks
function Controller:SetupKillStreak()
    Controller.KillStreakLeader = Controller:GetKillStreakLeader()

    local function ListenToPlayer(Player)
        Player:GetAttributeChangedSignal("KillStreak"):Connect(function()
            Controller.KillStreakLeader = Controller:GetKillStreakLeader()
            Controller:UpdateKillStreak()
        end)
    end

    -- create tweens
    Controller.StreakTweenIn = TweenService:Create(Controller.Gui.GoldenVignette, TweenInfo.new(1, Enum.EasingStyle.Quad), {ImageTransparency = .5})
    Controller.StreakTweenOut = TweenService:Create(Controller.Gui.GoldenVignette, TweenInfo.new(1, Enum.EasingStyle.Quad), {ImageTransparency = 1})

    -- listen for kill streak updates
    Players.PlayerAdded:Connect(function(Player:Player)
        ListenToPlayer(Player)
    end)

    for _, Player:Player in ipairs(Players:GetPlayers()) do
        ListenToPlayer(Player)
    end
    Controller:UpdateKillStreak()
end

function Controller:UpdateKillStreak()
    if not Controller.KillStreakLeader then return end
    local Kills = Controller.KillStreakLeader:GetAttribute("KillStreak")

    if Kills <= Constants.MIN_KILLSTREAK then
        Controller.Gui.KillStreakLeader.Text = ""
        Controller.StreakTweenOut:Play()
        return
    end

    if Controller.KillStreakLeader == Players.LocalPlayer then
        Controller.StreakTweenIn:Play()
    else
        Controller.StreakTweenOut:Play()
    end

    local LeaderName = Controller.KillStreakLeader == Players.LocalPlayer and "You are" or Controller.KillStreakLeader.Name.." is"

    Controller.Gui.KillStreakLeader.Text = "👑 "..LeaderName.." on a "..Kills.." kill streak 👑"

    Controller.KillStreakLeader.Character:FindFirstChild("Highlight").OutlineColor = Constants.KILL_STREAK_LEADER_OUTLINE
end

function Controller:GetKillStreakLeader():Player
    local OldLeader = Controller.KillStreakLeader

    local Leader = nil
    local MaxStreak = -1

    for _, Player:Player in ipairs(Players:GetPlayers()) do
        local Streak = Player:GetAttribute("KillStreak")
        if not Streak then continue end

        if Streak > MaxStreak then
            MaxStreak = Streak
            Leader = Player
        end
    end

    if OldLeader and OldLeader ~= Leader then
        OldLeader.Character:FindFirstChild("Highlight").OutlineColor = Constants.PLAYER_OUTLINE
    end

    return Leader
end

-- damage indicator
function Controller:DamageIndicator(Position:Vector3)
    local Indicator = ReplicatedStorage.Assets.Interface.Indicator:Clone()
    Indicator.Parent = Controller.Gui.DamageIndicators

    table.insert(Controller.DamageIndicators, {Position, Indicator})
    task.spawn(function()
        task.wait(5)
        TweenService:Create(Indicator.ImageLabel, TweenInfo.new(.5, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
        task.wait(.5)
        Indicator:Destroy()

    end)
end

function Controller:UpdateDamageIndicators()
    local myPosition = game.Players.LocalPlayer.Character.PrimaryPart.Position

    if not myPosition then
        return
    end

    for i, Data in ipairs(Controller.DamageIndicators) do
        if not Data[2] then
            table.remove(Controller.DamageIndicators, i)
            continue
        end

        local Position = Data[1]
        local Indicator = Data[2]

	    local camCFrame = workspace.Camera.CFrame
	    local enemyPosition = Position
	    local flatCFrame = CFrame.lookAt(myPosition, myPosition + camCFrame.LookVector * Vector3.new(1, 0, 1)) 
	    local travel = flatCFrame:Inverse() * enemyPosition 
	    local rot = math.atan2(travel.Z, travel.X)
	    Indicator.Rotation = math.deg(rot) + 90
    end
end

-- LOADING SCREEN
function Controller:SetupLoadingScreen()
    local LoadingScreen = Controller.Gui.Screens:WaitForChild("Loading")

    LoadingScreen.Visible = true

    game.Players.LocalPlayer.AttributeChanged:Connect(function(Attribute)
        if Attribute == "Loaded" then
            LoadingScreen.Visible = false

            --SoundtrackController:Play()
        end
    end)
end

-- Ui Scale
function Controller:SetupUiScale()
    Controller.FrameSizes = {}

    -- save the original sizes
    for FrameName, _ in pairs(UiScale) do
        local Frame = Controller.Gui.Frames:FindFirstChild(FrameName) or Controller.Gui:FindFirstChild(FrameName)
        if not Frame then continue end

        Controller.FrameSizes[FrameName] = Frame.Size
    end

    -- update current scale
    Controller:UpdateScale()

    -- listen for window resizes
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        Controller:UpdateScale()
    end)
end

function Controller:UpdateScale()
    for FrameName, ScaleData in pairs(UiScale) do
        local Frame = Controller.Gui.Frames:FindFirstChild(FrameName) or Controller.Gui:FindFirstChild(FrameName)
        if not Frame then continue end

        Controller:ScaleFrame(Frame, ScaleData)
    end
end

function Controller:ScaleFrame(Frame:Frame, ScaleData)
    local ViewportSize = workspace.CurrentCamera.ViewportSize.X

    local LastSize = ScaleData[1].Scale
    local LastName = ScaleData[1].MaxWidth
    -- find the size that fits
    for _, Data in ipairs(ScaleData) do
        if ViewportSize > Data.MaxWidth then
            LastSize = Data.Scale
            LastName = Data.MaxWidth
        end
    end

    -- scale the ui according
    local FrameSize = Controller.FrameSizes[Frame.Name]
    Frame.Size = UDim2.new(LastSize[1] * FrameSize.X.Scale, 0, LastSize[2] * FrameSize.Y.Scale, 0)
end

-- Animate
function Controller:SetupAnimations()
    Controller.FrameOpenTweens = {
        TweenService:Create(game.Lighting.Blur, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Size = 20}),
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(.2, Enum.EasingStyle.Quad), {FieldOfView = 50}),
    }

    Controller.FrameCloseTweens = {
        TweenService:Create(game.Lighting.Blur, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Size = 0}),
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(.2, Enum.EasingStyle.Quad), {FieldOfView = Constants.DEFAULT_FOV}),
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
            Controller.Gui.GameState.Visible = true
            Controller:ToggleMouse(false)
            Controller:PlayTweens(Controller.FrameCloseTweens)
        else
            if Controller.CurrentFrame then
                Controller.CurrentFrame.Visible = false
            end

            Controller.CurrentFrame = Frame
            Frame.Visible = true
            Controller.Gui.GameState.Visible = false
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

-- GAME STATE DISPLAY
function Controller:SetupGameState()
    Event:Listen("GameState", function(GameState)
        Controller:UpdateGameState(GameState)
    end)

    game.Players.LocalPlayer:WaitForChild("Data"):GetAttributeChangedSignal("Kills"):Connect(function()
        Controller:UpdateKills()
    end)

    Controller:UpdateKills()
    Controller:UpdateGameState(Event:InvokeServer("GameState"))
end

function Controller:UpdateKills()
    Controller.Gui.GameState.Right.Main.Kills.Text = NumberFormat(game.Players.LocalPlayer.Data:GetAttribute("Kills"))
end

function Controller:UpdateGameState(State)
    local Frame = Controller.Gui.GameState
    local StateLabel = Frame.Main.Main.State

    local StateName = State.State
    local StartTime = State.StartTime

    local NameMap = {
        GameLoop = "FFA",
        MapVote = "Map Vote",
    }

    local ConstantsMap = {
        GameLoop = "ROUND",
        MapVote = "VOTE",
    }

    --

    StateLabel.Text = NameMap[StateName] or StateName
    Controller.StartTime = StartTime

    local StateLength = math.huge

    if ConstantsMap[StateName] then
        StateLength = Constants[ConstantsMap[StateName] .. "_TIME"]
    end

    Controller.EndTime = StartTime + StateLength
end

function Controller:StateDataUpdate()
    local Frame = Controller.Gui.GameState
    local DataLabel = Frame.Main.Main.Data

    if not Controller.EndTime then return end
    DataLabel.Text = math.abs(math.clamp(math.floor(Controller.EndTime - workspace:GetServerTimeNow()) , 0, math.huge))
end

function Controller:ToggleGameState(Enabled:boolean)

end

-- MONEY DISPLAY
function Controller:SetupMoney()
    local Data = game.Players.LocalPlayer:WaitForChild("Data")
    
    Controller:UpdateMoney(Data)

    Data:GetAttributeChangedSignal("Money"):Connect(function()
        Controller:UpdateMoney(Data)
    end)
end

function Controller:UpdateMoney(Data)
    if not Controller.PrevMoney then
        Controller.PrevMoney = Data:GetAttribute("Money")
    end

    local MoneyFrame = Controller.Gui.LeftBar.Money.Money
    local Amount = Data:GetAttribute("Money")

    MoneyFrame.Amount.Text = NumberFormat(Amount)

    if Amount ~= Controller.PrevMoney then
        Controller:MoneyChanged(Amount - Controller.PrevMoney)
    end

    Controller.PrevMoney = Amount
end

function Controller:MoneyChanged(Amount)
    local AmountChangedLabel = ReplicatedStorage.Assets.Interface.AmountChangedLabel:Clone()
    AmountChangedLabel.TextColor3 = Amount > 0 and Color3.fromRGB(125, 255, 125) or Color3.fromRGB(255, 125, 125)
    AmountChangedLabel.Text = (Amount > 0 and "+" or "-") .. NumberFormat(Amount)
    AmountChangedLabel.Parent = Controller.Gui.LeftBar.Money.Money

    AmountChangedLabel.UIStroke.Color = Amount > 0 and Color3.fromRGB(87, 163, 87) or Color3.fromRGB(163, 87, 87)

    local NewPosition = UDim2.new(AmountChangedLabel.Position.X.Scale, 0, AmountChangedLabel.Position.Y.Scale - (Amount > 0 and 1 or -1), 0)

    local TextTween = TweenService:Create(AmountChangedLabel, TweenInfo.new(1, Enum.EasingStyle.Quad), {Position = NewPosition, TextTransparency = 1})
    local StrokeTween = TweenService:Create(AmountChangedLabel.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Quad), {Transparency = 1})

    TextTween:Play()
    StrokeTween:Play()

    SoundService:PlayLocalSound(ReplicatedStorage.Assets.SFX.Money) 

    Debris:AddItem(AmountChangedLabel, 1)
end

-- VOTE SCREEN
function Controller:SetupVoteScreen() -- screens are just frames that cover the whole screen and should hide the gamestate
    local Frame:Frame = Controller.Gui.Screens:WaitForChild("Vote")

    Controller.Voting = false
    
    -- Listen for map vote start
    Event:Listen("MapVote", function(RandomMaps)
        Controller:StartVote(RandomMaps)
    end)

    -- Listen for map vote end
    Event:Listen("MapVoteEnd", function()
        Controller:EndVote()
    end)

    -- Listen for vote updates
    Event:Listen("Vote", function()
        if not Controller.Voting then
            Constants:Debug("[InterfaceController] Vote update received while not voting")
            return
        end

        local GameState = Event:InvokeServer("GameState")

        for _, MapName in ipairs(Controller.MapPool) do
            Controller:UpdateVoteEntry(MapName, Controller.MapEntries[MapName], GameState)
        end
    end)
end


function Controller:StartVote(RandomMaps)
    Controller.MapPool = RandomMaps
    local Frame:Frame = Controller.Gui.Screens:WaitForChild("Vote")
    local InitialGameState = Event:InvokeServer("GameState")

    -- Update state
    Controller.Voting = true

    -- Enable input from player
    -- TODO: Disable weapons
    Controller:ToggleMouse(true)
    Controller:ToggleCrosshair(false)
    WeaponController:Toggle(false)
    WeaponController:Destroy()

    -- Show screen
    -- TODO: Animate
    Frame.Visible = true

    -- firing squad
    for _, MapEntry in ipairs(Frame.Vote.Maps:GetChildren()) do
        if not MapEntry:IsA("Frame") then continue end

        MapEntry:Destroy()
    end
   
    -- populate
    Controller.MapEntries = {}

    for _, MapName in ipairs(RandomMaps) do
        local MapModel = ReplicatedStorage.Assets.Maps:FindFirstChild(MapName)

        -- create intial visuals
        local MapEntry = ReplicatedStorage.Assets.Interface.MapEntry:Clone()
        MapEntry.MapEntry.MapName.Text = MapModel.Configuration:GetAttribute("DisplayName") or MapName

        if Constants.DEBUG then
            MapEntry.MapEntry.MapName.Text = MapEntry.MapEntry.MapName.Text .. " (" .. MapName .. ")"
        end

        MapEntry.MapEntry.MapImage.Image = "rbxassetid://" .. MapModel.Configuration:GetAttribute("DisplayImage")
        MapEntry.Parent = Frame.Vote.Maps

        -- store frame
        Controller.MapEntries[MapName] = MapEntry

        -- display any existing votes
        Controller:UpdateVoteEntry(MapName, MapEntry, InitialGameState)

        -- listen to trigger    
        Controller:TweenButton(MapEntry.MapEntry, MapEntry.Trigger)

        MapEntry.Trigger.Activated:Connect(function()
            Event:InvokeServer("Vote", MapName)
        end)
    end
end

function Controller:EndVote()
    local Frame:Frame = Controller.Gui.Screens:WaitForChild("Vote")

    -- Update state
    Controller.Voting = false

    -- TODO: Enable weapons
    Controller:ToggleMouse(false)
    Controller:ToggleCrosshair(true)
    WeaponController:Toggle(true)

    -- hide screen
    -- TODO: Animate
    Frame.Visible = false
end

function Controller:UpdateVoteEntry(MapName, MapEntry:Frame, InitialGameState)
    local Votes = InitialGameState.Votes[MapName]

    -- Clear any existing votes
    for _, Vote in ipairs(MapEntry.MapEntry.Votes:GetChildren()) do
        if not Vote:IsA("ImageLabel") then continue end

        Vote:Destroy()
    end

    if not Votes then
        return
    end

    -- Populate
    --TODO: Cache the uservote image
    for i, Player:Player in ipairs(Votes) do
        local UserVote = ReplicatedStorage.Assets.Interface.UserVote:Clone()
        UserVote.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        UserVote.LayoutOrder = i + 1
        UserVote.Parent = MapEntry.MapEntry.Votes

        -- Prioritize local player
        if Player == Players.LocalPlayer then
            UserVote.UIStroke.Enabled = true
            UserVote.LayoutOrder = 0
        end
    end
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
function Controller:KillResult(Player:Player | Model) -- Player or NPC
    Controller.Gui.KillResult.Text = "You killed " .. Player.Name

    -- Tween the text
    Controller.KillResultTween = Controller.KillResultTween or TweenService:Create(Controller.Gui.KillResult, TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {TextTransparency = 1})
    Controller.KillResultTweenStroke = Controller.KillResultTweenStroke or TweenService:Create(Controller.Gui.KillResult.UIStroke, TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Transparency = 1})
    Controller.Gui.KillResult.TextTransparency = 0
    Controller.Gui.KillResult.UIStroke.Transparency = 0
    Controller.KillResultTween:Play()
    Controller.KillResultTweenStroke:Play()

    -- Tween kill effect
    Controller.KillVignetteTween = Controller.KillVignetteTween or TweenService:Create(Controller.Gui.WhiteVignette, TweenInfo.new(.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {ImageTransparency = 1})
    Controller.Gui.WhiteVignette.ImageTransparency = 0
    Controller.KillVignetteTween:Play()
end

function Controller:Hitmarker()
    Controller.HitmarkTween = Controller.HitmarkTween or TweenService:Create(Controller.Gui.Hitmarker, TweenInfo.new(.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 0})
    TweenService:Create(Controller.Gui.Hitmarker, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Rotation = math.random(-15,15)}):Play()

    Controller.HitmarkTweenEvent = Controller.HitmarkTweenEvent or Controller.HitmarkTween.Completed:Connect(function()
        Controller.Gui.Hitmarker.ImageTransparency = 1
    end)

    Controller.HitmarkTween:Play()
end

function Controller:UseCrosshair(CrosshairName)
    if Controller.Crosshair then
        Controller.Crosshair.Visible = false
    end

    Controller.Crosshair = Controller.Gui:WaitForChild("Crosshairs"):FindFirstChild(CrosshairName)

    Controller.OffsetLeft = if Controller.Crosshair:FindFirstChild("Left") then Controller.Crosshair:FindFirstChild("Left").Position else nil
    Controller.OffsetRight = if Controller.Crosshair:FindFirstChild("Right") then Controller.Crosshair:FindFirstChild("Right").Position else nil
    Controller.OffsetUp = if Controller.Crosshair:FindFirstChild("Up") then Controller.Crosshair:FindFirstChild("Up").Position else nil
    Controller.OffsetDown = if Controller.Crosshair:FindFirstChild("Down") then Controller.Crosshair:FindFirstChild("Down").Position else nil

    Controller.Crosshair.Visible = true
end

function Controller:ToggleWeapons(Enabled)
    Controller.Crosshair.Visible = Enabled
    Controller.Gui.WeaponInfo.Visible = Enabled
end

function Controller:ToggleCrosshair(State:boolean)
    Controller.Crosshair.Visible = State
end

function Controller:ApplyCrosshairSpringData(Data)
    for Name, Value in pairs(Data) do
        Controller.CrosshairSpring[Name] = Value or Controller.DefaultSpringData[Name]
    end
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
    Controller.OffsetLeft = Left.Position
    Controller.OffsetRight = Right.Position

    if not Up or not Down then return end

    Up.Position = UDim2.new(0.5, 0, -Offset, 0)
    Down.Position = UDim2.new(0.5, 0, 1 + Offset, 0)
    Controller.OffsetUp = Up.Position
    Controller.OffsetDown = Down.Position
end

function Controller:ShoveCrosshair(Amount)
    Controller.CrosshairSpring:Shove(Vector3.new(Amount, 0,0))
end

function Controller:UpdateCrosshair(DT)
    local Position = Controller.CrosshairSpring:Update(DT)

    if not Controller.Crosshair then return end
    local Left = Controller.Crosshair:FindFirstChild("Left")
    local Right = Controller.Crosshair:FindFirstChild("Right")
    local Up = Controller.Crosshair:FindFirstChild("Up")
    local Down = Controller.Crosshair:FindFirstChild("Down")

    if Left and Controller.OffsetLeft then
        Left.Position = UDim2.new(Controller.OffsetLeft.X.Scale - Position.X, 0, Controller.OffsetLeft.Y.Scale, 0)
    end

    if Right and Controller.OffsetRight then
        Right.Position = UDim2.new(Controller.OffsetRight.X.Scale + Position.X, 0, Controller.OffsetRight.Y.Scale, 0)
    end

    if Up and Controller.OffsetUp then
        Up.Position = UDim2.new(Controller.OffsetUp.X.Scale, 0, Controller.OffsetUp.Y.Scale - Position.X, 0)
    end

    if Down and Controller.OffsetDown then
        Down.Position = UDim2.new(Controller.OffsetDown.X.Scale, 0, Controller.OffsetDown.Y.Scale + Position.X, 0)
    end
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
function Controller.Update(DT)
    for _, Viewport in pairs(Controller.ViewportFrames) do
        local Camera = Viewport:FindFirstChildOfClass("Camera")
        local HoverTick = Viewport:GetAttribute("HoverTick")

        if not HoverTick then continue end

        local Angle =  math.rad((tick() - HoverTick) * 50)
        local Offset = CFrame.Angles(math.rad(35),0, 0) * Camera:GetAttribute("DefaultCFrame")

        Camera.CFrame = Offset
        Viewport:FindFirstChildOfClass("Model"):PivotTo(CFrame.Angles(0, Angle, 0))
    end

    -- update countdown
    Controller:StateDataUpdate()

    -- update crosshair
    if Controller.Crosshair then
        Controller:UpdateCrosshair(DT)
    end

    -- update damage indicators
    Controller:UpdateDamageIndicators()
end

return Controller