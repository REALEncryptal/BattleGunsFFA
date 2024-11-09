local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local WeaponBase = require(script.Parent.WeaponBase)

local RaycastWeapon = setmetatable({}, WeaponBase)
RaycastWeapon.__index = RaycastWeapon

function RaycastWeapon.new(Weapon)
    local self = setmetatable(WeaponBase.new(Weapon), RaycastWeapon)

    self.OriginalWeapon = Weapon

    local Spring3 = shared.Import "Spring3"
    
    self.WishFire = false
    self.LastDischarge = tick()
    self.Bullets = self.Config.Bullets

    self.Gui = Players.LocalPlayer.PlayerGui:WaitForChild("Game")

    self.Animations.Reload.DidLoop:Connect(function()
        self.Bullets = self.Config.Bullets
    end)

    ContextActionService:BindAction("Reload", function(Type)
        if not Type == Enum.UserInputState.Begin then return end
        self:Reload()
    end, true, Enum.KeyCode.R)

    return self
end

function RaycastWeapon:Reload()
    if self.Bullets == self.Config.Bullets then return end
    if self.Animations.Reload.IsPlaying then return end

    self.Animations.Reload:Play()
end

function RaycastWeapon:Fire()
    if self.Bullets <= 0 then return end
    self.Animations.Reload:Stop()
    self.Bullets -= 1
    self.LastDischarge = tick()

    -- client raycast
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {self.Viewmodel, game.Players.LocalPlayer.Character, workspace.Debug}
    Params.FilterType = Enum.RaycastFilterType.Exclude

    local Direction = workspace.CurrentCamera.CFrame.LookVector * 10000
    local Origin = workspace.CurrentCamera.CFrame.Position
    local RaycastResult:RaycastResult = workspace:Raycast(Origin, Direction, Params)

    if RaycastResult then
        local DebugSurface = ReplicatedStorage.Assets.DebugSurface:Clone()
        DebugSurface.Position = RaycastResult.Position
        DebugSurface.CFrame = CFrame.new(RaycastResult.Position, RaycastResult.Normal + RaycastResult.Position)
        DebugSurface.Parent = workspace.Debug

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            workspace.Debug:ClearAllChildren()
        end

        -- Validate hit
        task.spawn(function()
            local Valid = shared.Import("Event"):InvokeServer("RaycastWeapon", Origin, Direction, self.OriginalWeapon)
            if not Valid then
                print("Server invalidated hit")
                DebugSurface.CylinderHandleAdornment.Color3 = Color3.fromRGB(255,0,0)
            else
                print("Server validated hit")
                DebugSurface.CylinderHandleAdornment.Color3 = Color3.fromRGB(0,255,0)

                if RaycastResult.Instance.Parent:IsA("Model") then
                    local Health = RaycastResult.Instance.Parent:GetAttribute("Health")

                    if not Health then return end
                    SoundService:PlayLocalSound(ReplicatedStorage.Assets.Hitmarker)
                end
                
            end
        end)

        Direction = RaycastResult.Position
    end

    shared.Import("RayEffect")(self.Weapon.PrimaryPart.Tip.WorldPosition, Direction)

    -- Effects
    SoundService:PlayLocalSound(self.Weapon.Sounds.Shoot)
    self.Animations.Fire:Play() 
    self.Springs.Recoil:Shove(Vector3.new(self.Config.RecoilY,self.Config.RecoilX(),.2*30))
end

function RaycastWeapon:FunctionalUpdate(DeltaTime)
    if not self.Enabled then return end

    self.Gui.Ammo.Text = self.Bullets .. "/" .. self.Config.Bullets

    if tick() - self.LastDischarge < 60 / self.Config.RPM then return end

    local WasWishFire = self.WishFire
    self.WishFire = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

    if not WasWishFire and self.WishFire and self.Bullets <= 0 then
        SoundService:PlayLocalSound(ReplicatedStorage.Assets.Empty)
    end

    if self.WishFire and self.Config.Automatic then
        self:Fire()
    elseif not WasWishFire and self.WishFire and not self.Config.Automatic then
        self:Fire()
    end
end

function RaycastWeapon:FunctionalUpdateViewmodel(UpdatedSprings, DeltaTime): CFrame
    local Final = CFrame.new()

    -- looks kinda goofy
    --Final *= CFrame.new(UpdatedSprings.Recoil)
    --      * CFrame.Angles(math.rad(UpdatedSprings.Recoil.Y*50),0,0)

    return Final
end

function RaycastWeapon:FunctionalUpdateCamera(UpdatedSprings, DeltaTime): CFrame
    local Final = CFrame.new()

    -- Up/Down, Left/Right, Tilt
    Final *= CFrame.Angles(math.rad(UpdatedSprings.Recoil.X), math.rad(UpdatedSprings.Recoil.Y), math.rad(UpdatedSprings.Recoil.Z))

    return Final
    
end

return RaycastWeapon