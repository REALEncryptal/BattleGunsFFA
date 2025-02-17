local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local WeaponBase = require(script.Parent.WeaponBase)

local FirearmBase = setmetatable({}, WeaponBase)
FirearmBase.__index = FirearmBase

function FirearmBase.new(Weapon)
    local self = setmetatable(WeaponBase.new(Weapon), FirearmBase)

    if self.Config.Springs then
        for SpringName, SpringData in pairs(self.Config.Springs) do
            if not self.Springs[SpringName] then continue end
            self.Springs[SpringName].Mass = SpringData.Mass or self.Springs[SpringName].Mass
            self.Springs[SpringName].Force = SpringData.Force or self.Springs[SpringName].Force
            self.Springs[SpringName].Damping = SpringData.Damping or self.Springs[SpringName].Damping
            self.Springs[SpringName].Speed = SpringData.Speed or self.Springs[SpringName].Speed
        end
        shared.Import("InterfaceController"):ApplyCrosshairSpringData(self.Config.Springs.Crosshair or {})
    end

    self.OriginalWeapon = Weapon

    self.IsADS = false
    self.WishFire = false
    self.LastDischarge = tick()
    self.Bullets = self.Config.Bullets

    self.Gui = Players.LocalPlayer.PlayerGui:WaitForChild("Game")

    shared.Import("InterfaceController"):UseCrosshair(self.Config.Crosshair)  
    shared.Import("InterfaceController"):SetSpread(self.Config.VisualSpread or self.Config.Spread)

    self.Animations.Reload.DidLoop:Connect(function()
        self.Bullets = self.Config.Bullets
        shared.Import("InterfaceController"):TweenAmmoUi()
    end)

    -- TODO: MOBILE SUPPORT
    ContextActionService:BindAction("Reload", function(_, Type)
        if not Type == Enum.UserInputState.Begin then return end
        self:Reload()
    end, true, Enum.KeyCode.R)

    ContextActionService:BindAction("ADS", function(_, Type)
        self:ADS(Type == Enum.UserInputState.Begin)
    end, true, Enum.UserInputType.MouseButton2)--, Enum.KeyCode.LeftShift)

    ContextActionService:BindAction("Fire", function(_, Type)
        self.IsFirePressed = Type == Enum.UserInputState.Begin
    end, true, Enum.UserInputType.MouseButton1)

    self.Trove:Add(function()
        ContextActionService:UnbindAction("Reload")
        ContextActionService:UnbindAction("ADS")

        self:ADS(false)
        self.Animations.Reload:Stop()
        self.Animations.Fire:Stop()
    end)

    return self
end

function FirearmBase:Toggle(Enabled)
    self.Enabled = Enabled
    
    if self.Viewmodel and not self.Destroyed then
        self.Viewmodel.Parent = Enabled and workspace.CurrentCamera or ReplicatedStorage
    end
    shared.Import("InterfaceController"):ToggleWeapons(Enabled)
end

function FirearmBase:Reload()
    if not self.Enabled then return end
    if self.Bullets == self.Config.Bullets then return end
    if self.Animations.Reload.IsPlaying then return end

    self.Animations.Reload:Play()
    
    self.CooldownTween = shared.Import("InterfaceController"):TweenCooldown(self.Animations.Reload.Length)
end

function FirearmBase:ADS(ADS:boolean)
    if self.Destroyed then return end
    if not self.Config.ADS then return end

    local InterfaceController = shared.Import("InterfaceController")
    local CameraUtil = shared.Import("Camera")

    if ADS then
        if not self.Enabled then return end
        CameraUtil:SetSensitivityModifier(.5)
        self.Offsets.Hide = CFrame.new(0,-100,0)
        InterfaceController:UseCrosshair(self.Config.CrosshairADS)
        CameraUtil:TweenFov(self.Config.FovADS, .1)
        InterfaceController.Enabled = falseRa
    else
        CameraUtil:SetSensitivityModifier(1)
        self.Offsets.Hide = CFrame.new(0,0,0)
        InterfaceController:UseCrosshair(self.Config.Crosshair)
        CameraUtil:TweenFov(shared.Import("Constants").DEFAULT_FOV, .2)
        InterfaceController.Enabled = true
    end

    self.IsADS = ADS
end

function FirearmBase:CreateParams():RaycastParams
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {
        self.Viewmodel, 
        game.Players.LocalPlayer.Character, 
        workspace.Debug, 
        workspace.Ignore, 
        unpack(CollectionService:GetTagged("Accessory")), 
        unpack(CollectionService:GetTagged("Ignore")),
        unpack(CollectionService:GetTagged("Weapon"))
    }
    Params.RespectCanCollide = false
    Params.FilterType = Enum.RaycastFilterType.Exclude

    return Params
end

function FirearmBase:Fire()
    if self.Destroyed then return end
    if not self.Enabled then return end
    if self.Bullets <= 0 then return end
    self.Animations.Reload:Stop()
    if self.CooldownTween then
        self.CooldownTween:Cancel()
    end
    self.Bullets -= 1
    self.LastDischarge = tick()

    -- open crosshair
    shared.Import("InterfaceController"):ShoveCrosshair(self.Config.CrosshairRecoil*self.DeltaTime)

    -- tween
    shared.Import("InterfaceController"):TweenAmmoUi()

    -- client raycast
    local Params = self:CreateParams()

    -- fire
    local HitCharacter = false

    for i=1, self.Config.BulletsPerShot do
        local Direction = workspace.CurrentCamera.CFrame.LookVector * 10000
        local Origin = workspace.CurrentCamera.CFrame.Position
            
        -- Generate a random angle and a random radius within the spread circle
        local SpreadRadius = math.rad(self.Config.Spread) -- Maximum spread radius in radians

        if self.IsADS then
            SpreadRadius = math.rad(self.Config.SpreadADS)
        end

        local RandomAngle = math.random() * 2 * math.pi -- Random angle in the circular area
        local RandomRadius = math.sqrt(math.random()) * SpreadRadius -- Random distance from the center
            
        -- Calculate spread components based on the random angle and radius
        local SpreadX = math.cos(RandomAngle) * RandomRadius
        local SpreadY = math.sin(RandomAngle) * RandomRadius
            
        -- Apply the spread to the direction vector
        local SpreadDirection = (CFrame.new(Origin, Origin + Direction) 
            * CFrame.Angles(SpreadY, SpreadX, 0)).LookVector * 10000


        -- raycast
        self:FunctionalFire(Origin, SpreadDirection, Params)
    end

    -- Effects
    SoundService:PlayLocalSound(self.Weapon.Sounds.Shoot)
    shared.Import("ShellEffect")(self.Weapon, self.Config.EjectPower or 10)
    self.Animations.Fire:Play() 
    self.Springs.Recoil:Shove(Vector3.new(self.Config.RecoilY,self.Config.RecoilX(),.2*30) * self.DeltaTime)
    self.Springs.WeaponRecoil:Shove(Vector3.new(0,0,self.Config.SpringRecoil) * self.DeltaTime)
end 

function FirearmBase:HitEffect(HitCharacter)
    shared.Import("InterfaceController"):Hitmarker()
    task.spawn(function()
        --effects
        local BloodEmitter = HitCharacter.Parent.HumanoidRootPart:FindFirstChild("Blood")
        if BloodEmitter then
            BloodEmitter:Emit(20)
        else
            shared.Import("Constants"):Debug("[FirearmBase] No blood emitter found, is this a registered character?")
        end

        task.wait(.05)
        if HitCharacter.Name == "Head" then
            SoundService:PlayLocalSound(ReplicatedStorage.Assets.Hitmarker1)
        else
            SoundService:PlayLocalSound(ReplicatedStorage.Assets.Hitmarker)
        end
    end)
end

function FirearmBase:FunctionalValidateHit(RaycastResult:RaycastResult) end

function FirearmBase:BulletHit(RaycastResult): boolean

    -- Validate hit
    self:FunctionalValidateHit(RaycastResult)

    if RaycastResult.Instance.Parent:IsA("Model") then
        local Health = RaycastResult.Instance.Parent:GetAttribute("Health")

        if Health or RaycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid") then
            return RaycastResult.Instance
        end
    end

    return false
end

function FirearmBase:UpdateUi(DeltaTime)
    self.Gui.WeaponInfo.Weapon.Text = self.Config.Name
    self.Gui.WeaponInfo.Ammo.Ammo.Text = self.Bullets
    self.Gui.WeaponInfo.Ammo.Sub.Text = "/"..self.Config.Bullets

    local LowOnAmmo = self.Bullets <= self.Config.Bullets / 4

    self.Gui.WeaponInfo.Ammo.Ammo.TextColor3 = LowOnAmmo and Color3.fromRGB(255, 162, 0) or Color3.fromRGB(255,255,255)

    if self.Bullets == 0 then
        self.Gui.WeaponInfo.Ammo.Ammo.TextColor3 = Color3.fromRGB(255, 70, 70)
    end 
end

function FirearmBase:FunctionalUpdate(DeltaTime)
    if not self.Enabled then return end
    if self.Destroyed then return end

    self:UpdateUi(DeltaTime)

    if tick() - self.LastDischarge < 60 / self.Config.RPM then return end

    local WasWishFire = self.WishFire
    self.WishFire = self.IsFirePressed

    if not WasWishFire and self.WishFire and self.Bullets <= 0 then
        SoundService:PlayLocalSound(ReplicatedStorage.Assets.Empty)
    end

    if self.WishFire and self.Config.Automatic then
        self:Fire()
    elseif not WasWishFire and self.WishFire and not self.Config.Automatic then
        self:Fire()
    end
end

function FirearmBase:FunctionalUpdateViewmodel(UpdatedSprings, DeltaTime): CFrame
    local Final = CFrame.new()

    self.Gui.Crosshairs.Sniper.Center.Reticle.Position = UDim2.new(0.498 - UpdatedSprings.Sway.X/10, 0, 0.506 + UpdatedSprings.Sway.Y/10, 0)

    -- looks kinda goofy
    Final *= CFrame.new(UpdatedSprings.WeaponRecoil)

    return Final
end

function FirearmBase:FunctionalUpdateCamera(UpdatedSprings, DeltaTime): CFrame
    local Final = CFrame.new()

    -- Up/Down, Left/Right, Tilt
    Final *= CFrame.Angles(math.rad(UpdatedSprings.Recoil.X), math.rad(UpdatedSprings.Recoil.Y), math.rad(UpdatedSprings.Recoil.Z))

    return Final
    
end

return FirearmBase