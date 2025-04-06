local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Controller = {}

local Constants, Signal, CameraController

local function lerp(a,b,t)
    return a + (b - a) * t
end

function Controller:PreInit()
    Signal = shared.Import "Signal"
    Controller.WallJump = Signal.new()
    Controller.WallSlide = Signal.new()
    Controller.WallDismount = Signal.new()
    Controller.Slide = Signal.new()
    Controller.Vault = Signal.new()
end

function Controller:Init()
    Constants = shared.Import "Constants"
    CameraController = shared.Import "CameraController"
    --
    Controller.Humanoid = nil

    Controller.LastMoveDirection = Vector3.new()
    Controller.WallJumps = 2
    Controller.WasWishJump = false
    Controller.LastSlide = tick()
    Controller.LerpedFov = 0
    Controller.FOVMod = 7

    Controller.WallSliding = false
    Controller.Sliding = false
    Controller.WishSlide = false
    Controller.WasWishSlide = false

    Controller.DebugRays = {}

    --
end

function Controller.CharacterAdded(Character)
    Controller.Humanoid = Character:WaitForChild("Humanoid")
end

function Controller:DebugRay(i,Start, End, Color)
    local Ray = Controller.DebugRays[i] or Instance.new("Part")
    Ray.Material = Enum.Material.Neon
    Ray.Anchored = true
    Ray.CanCollide = false
    Ray.Size = Vector3.new(1,1,1)*.1
    Ray.Position = End
    Ray.Color = Color
    Ray.Transparency = 0.7
    Ray.Shape = Enum.PartType.Ball
    Ray.Parent = workspace.Ignore

    Controller.DebugRays[i] = Ray
end

function Controller:ClearDebugRays()
    for _, Ray in pairs(Controller.DebugRays) do
        Ray:Destroy()
    end

    Controller.DebugRays = {}
end

function Controller:GetParams():RaycastParams
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Blacklist
    Params.FilterDescendantsInstances = {workspace.Ignore, Controller.Humanoid.Parent, workspace.CurrentCamera}

    return Params
end

function Controller:GetWallCast(Offset,Layers)
    local Params = Controller:GetParams()

    -- 360 degree wall check
    local Closest:{dist:number, result:RaycastResult} = {dist = math.huge, result = nil}
    local Origin = Controller.Humanoid.Parent.HumanoidRootPart.Position

    for iy = 0, Layers*.5, .5 do
        for i = 0, 360, 45/3 do
            local y = iy -Offset
            local O = Origin+Vector3.yAxis*y
            local Direction = CFrame.Angles(0, math.rad(i), 0).LookVector * 3
            local Result:RaycastResult = workspace:Raycast(O, Direction, Params)

            local C = if Result then Color3.new(0, 1, 0) else Color3.new(1, 0, 0)
            if Result then
                if Result.Distance < 1.5 then
                    C = Color3.new(0,Result.Distance/1.5, Result.Distance/1.5)
                end
            end

            if Constants.SHOW_MOVE_CASTS then Controller:DebugRay((y*10*360)+i,O, if Result then Result.Position else O+Direction, C) end

            if Result then
                local Dist = (O - Result.Position).Magnitude
                if Dist < Closest.dist then
                    Closest.dist = Dist
                    Closest.result = Result
                end
            end
        end
    end

    return Closest.result
end

function Controller:LineCast(Start, End, Rays, Direction, Params): RaycastResult|nil
    local Origin = Start
    local Closest:{dist:number, result:RaycastResult} = {dist = math.huge, result = nil}

    for i = 0, Rays, 1 do
        -- interpolate between the start and end
        local O = Origin + (End - Origin) * (i / Rays)
        --
        local Result:RaycastResult = workspace:Raycast(O, Direction, Params)

        --
        if Constants.SHOW_MOVE_CASTS then Controller:DebugRay(i+100000,O, if Result then Result.Position else O+Direction, if Result then Color3.new(1, 0, 0.882352) else Color3.new(1, 0.682352, 0.290196)) end

        --
        if Result then
            local Dist = (O - Result.Position).Magnitude
            if Dist < Closest.dist then
                Closest.dist = Dist
                Closest.result = Result
            end
        end
    end

    return Closest.result
end

function Controller:CanVault():boolean
    local RootPart:Part = Controller.Humanoid.Parent.HumanoidRootPart
    local Head:Part = Controller.Humanoid.Parent.Head
    local Direction = RootPart.CFrame.LookVector
    local Params = Controller:GetParams()
    local TorsoOffset = Vector3.yAxis
    local HeadOffset = Vector3.yAxis * .5

    -- Can our head fit?
    local HeadResult:RaycastResult|nil = Controller:LineCast(Head.Position+Vector3.yAxis, Head.Position+Vector3.yAxis, 1, Direction * 2, Params)

    -- Is our torso touching the wall
    local TorsoResult:RaycastResult|nil = Controller:LineCast(RootPart.Position-TorsoOffset, RootPart.Position+TorsoOffset, 10, Direction * 2, Params)
    return not HeadResult and TorsoResult
end

function Controller:ApplyVelocity(Velocity:Vector3, TimeLength:number): LinearVelocity
    local LV = Instance.new("LinearVelocity")
    LV.Name = "Velocity"
    LV.Attachment0 = Controller.Humanoid.Parent.HumanoidRootPart.RootAttachment
    LV.ForceLimitsEnabled = false
    LV.VectorVelocity = Velocity
    LV.Parent = Controller.Humanoid.Parent.HumanoidRootPart
    Debris:AddItem(LV, TimeLength)
    
    return LV
end

function Controller:WallJumpWallSlide(Grounded, WishJump)
    local WasSliding = Controller.WallSliding
    Controller.WallSliding = false

    if not Grounded then
        local Result:RaycastResult = Controller:GetWallCast(1, 4)

        if Result and Result.Distance <= 1.5  then
            local CanVault = Controller:CanVault()

            if WishJump and not Controller.WasWishJump and CanVault then
                -- vault
                Controller.Vault:Fire()
                Controller:ApplyVelocity(
                    Vector3.yAxis * 30, 
                    .1
                )


                local RootPart:Part = Controller.Humanoid.Parent.HumanoidRootPart
                local InitalVelocity = RootPart.AssemblyLinearVelocity
                local Direction = RootPart.CFrame.LookVector
                local Params = Controller:GetParams()
                local TorsoOffset = Vector3.yAxis
                local TorsoResult:RaycastResult|nil = Controller:LineCast(RootPart.Position-TorsoOffset, RootPart.Position+TorsoOffset, 10, Direction * 2, Params)

                local Normal = TorsoResult.Normal
                Direction = Normal * -1
                local NewCFrame = CFrame.new(RootPart.Position + Direction * 6 + Vector3.new(0, 5, 0))
                local Info = TweenInfo.new(.3, Enum.EasingStyle.Linear)
                local Tween = TweenService:Create(RootPart, Info, {CFrame = NewCFrame})
                Tween.Completed:Connect(function()
                    local Direction = workspace.CurrentCamera.CFrame.LookVector*Vector3.new(1,0,1)
                    Direction = Direction.Unit
                    local Velocity = Direction * 30 + Vector3.yAxis * 10 + InitalVelocity
                    RootPart.AssemblyLinearVelocity = Velocity*.6
                    Controller:ApplyVelocity(Velocity, .1)
                end)
                Tween:Play()

            elseif  WishJump and not Controller.WasWishJump and Controller.WallJumps > 0 then
                Controller.WallJump:Fire()
                Controller.WallJumps-=1

                local v = Vector3.yAxis * 30 + Result.Normal * 20
                v = v + Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity* 1.4 * Vector3.new(1,0,1) 

                Controller:ApplyVelocity(v, .1)
                
                Controller.WallJumpStart = nil
            elseif WishJump and not Controller.WasWishJump then
                -- jump off wall slide
                Controller.WallDismount:Fire()
                Controller.WallJumps = -1

                Controller:ApplyVelocity(Result.Normal * 20 + Vector3.yAxis * -30, .1)

            elseif Controller.WallJumps >= 0 then
                
                if not Controller.WallJumpStart then
                    Controller.WallJumpStart = tick()
                end

                if tick()-Controller.WallJumpStart <= 2 and not Controller.WishSlide then
                    Controller.WallSliding = true
                    local v = Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity
                    Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                        v.X,
                        math.clamp(v.Y, -10, math.huge),
                        v.Z
                    )
                end
            end
        end
    else
        Controller.WallJumpStart = nil
        Controller.WallJumps = 2
        Controller:ClearDebugRays()
    end

    if not WasSliding and Controller.WallSliding then
        Controller.WallSlide:Fire(true)
    elseif WasSliding and not Controller.WallSliding then
        Controller.WallSlide:Fire(false)
    end
end

function Controller:CalculateSlide(Grounded, MoveDirection, WishJump, DT)
    Controller.WishSlide = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    Controller.WasSliding = Controller.Sliding

    if 
        Grounded 
        and Controller.WishSlide 
        and not Controller.WasWishSlide 
        and tick()-Controller.LastSlide > Constants.SLIDE_COOLDOWN
        and MoveDirection.Magnitude > 0
        and not Controller.Sliding
        and not Controller.WallSliding
        and not WishJump
    then
        -- slide start
        Controller.LastSlide = tick()
        Controller.Sliding = true
        Controller.SlideDir = MoveDirection
        Controller.SlideSpeed = Constants.SLIDE_SPEED

        -- get ground normal
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Blacklist
        Params.FilterDescendantsInstances = {workspace.Ignore, Controller.Humanoid.Parent, workspace.CurrentCamera}
        local Result:RaycastResult = workspace:Raycast(Controller.Humanoid.Parent.HumanoidRootPart.Position, Vector3.new(0,-5,0), Params)

        if Result then
            local Normal = Result.Normal

            local SlideDirection = Controller.SlideDir.Unit
            local Alignment = SlideDirection:Dot(Normal)

            Controller.SlideSpeed += Alignment * 20
        end

    end


    if WishJump or (not Controller.WasWishSlide and Controller.WishSlide and Controller.WasSliding) then
        Controller.Sliding = false
        Controller.Humanoid.WalkSpeed = Constants.SPEED
    end

    if Controller.Sliding and Controller.SlideSpeed > 5   then
        Controller.SlideSpeed = Constants.SLIDE_SPEED * (1-(tick()-Controller.LastSlide)/Constants.SLIDE_TIME)
        Controller.Humanoid.WalkSpeed = Controller.SlideSpeed

        -- bounces
        local Cast:RaycastResult = Controller:GetWallCast(2,3)

        if Cast and Cast.Distance < 1.5 then
            -- reflect the player
            local Normal = Cast.Normal

            -- do not reflect off of slopes
            local Angle = math.deg(math.acos(Normal:Dot(Vector3.yAxis)))
            local CanReflect = math.abs(90-Angle) <= 10

            -- do not reflect if moving away from the wall
            local SlideDirection = Controller.SlideDir.Unit
            local Alignment = SlideDirection:Dot(Normal)
            CanReflect = CanReflect and Alignment < 0

            if CanReflect then
                -- reflect direction
                local ReflectedDir = Controller.SlideDir - 2 * Controller.SlideDir:Dot(Normal) * Normal
                Controller.SlideDir = ReflectedDir

                -- reflect velocity as well
                local v = Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity
                local ReflectedVelocity = v - 2 * v:Dot(Normal) * Normal
                Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity = ReflectedVelocity
            end
        end

        -- move it
        Controller.Humanoid:Move(Controller.SlideDir)
    else
        Controller.Sliding = false
        Controller.Humanoid.WalkSpeed = Constants.SPEED
    end

    if not Controller.WasSliding and Controller.Sliding then
        Controller.Slide:Fire(true)
    elseif Controller.WasSliding and not Controller.Sliding then
        Controller.Slide:Fire(false)
    end
   
    Controller.WasWishSlide = Controller.WishSlide
end

function Controller.Update(DT)
    if not game.Players.LocalPlayer.Character then return end
    if not Controller.Humanoid then return end
    if Controller.Humanoid.Health <= 0 then return end

    local Grounded = Controller.Humanoid.FloorMaterial ~= Enum.Material.Air
    local MoveDirection = Controller.Humanoid.MoveDirection
    local LastMoveDirection = Controller.LastMoveDirection
    local WishJump = Controller.Humanoid.Jump

    if WishJump and Controller.Sliding then
        Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity = Controller.SlideDir.Unit * 30
    end

    -- wall jump
    Controller:WallJumpWallSlide(Grounded, WishJump)

    -- slide
    Controller:CalculateSlide(Grounded, MoveDirection, WishJump, DT)

    -- check moving state
    if MoveDirection.Magnitude > 0 then
        if MoveDirection ~= LastMoveDirection then
            --CameraController:GetTween("MOVE_FOV"):Play()
        end
    else
        --CameraController:GetTween("DEFAULT_FOV"):Play()
    end

    local PlaneVelocity = Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1,0,1)
    local Speed = PlaneVelocity.Magnitude/Controller.FOVMod

    -- instead of lerp change the lerped by catchup * delta time
    local Catchup = 100 * DT
    Speed *= .2

    if Controller.LerpedFov > Speed then
        Controller.LerpedFov = math.clamp(Controller.LerpedFov - Catchup, Speed, Controller.LerpedFov)
    elseif Controller.LerpedFov < Speed then
        Controller.LerpedFov = math.clamp(Controller.LerpedFov + Catchup, 0, Speed)
    end

    if Controller.Sliding then
        Controller.FOVMod = 1
    else
        Controller.FOVMod = 2
    end

    print(Controller.LerpedFov)

    CameraController:AddOffset(Controller.LerpedFov)

    Controller.LastMoveDirection = Controller.Humanoid.MoveDirection
    Controller.WasWishJump = WishJump
end

return Controller