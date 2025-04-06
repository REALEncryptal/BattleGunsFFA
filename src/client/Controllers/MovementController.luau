local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Controller = {}

local Constants, Signal, CameraController, Catchup

local function lerp(a,b,t)
    return a + (b - a) * t
end

local function roundVector(v:Vector3, d:number)
    d = d or 0
    v *= d
    return Vector3.new(math.round(v.X), math.round(v.Y), math.round(v.Z))/d
end

function Controller:PreInit()
    Signal = shared.Import "Signal"
    Catchup = shared.Import "Catchup"
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
    Controller.LastValidVelocityUnit = Vector3.new()
    Controller.LastPosition = Vector3.new()
    Controller.WallJumps = 2
    Controller.WasWishJump = false
    Controller.LastSlide = tick()
    Controller.LerpedFov = 0
    Controller.FOVMod = 7
    Controller.SlideCancelQueued = false

    Controller.WallSliding = false
    Controller.Sliding = false
    Controller.WishSlide = false
    Controller.WasWishSlide = false

    Controller.DebugRays = {}
    --

    Controller.Speed = Constants.SPEED -- momentum without the mass type sh
    
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

function Controller:CalculateSlide(Grounded, MoveDirection, WishJump, DT, Speed)
    Controller.WishSlide = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    Controller.WasSliding = Controller.Sliding

    if 
        Grounded 
        and Controller.WishSlide 
        and not Controller.WasWishSlide 
        and tick()-Controller.LastSlide > Constants.SLIDE_COOLDOWN
        and MoveDirection.Magnitude > 0
        and not Controller.Sliding
        and not WishJump
    then
        -- slide start
        Controller.SlideCancelQueued = false
        Controller.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        Controller.LastSlide = tick()
        Controller.Sliding = true
        Controller.SlideDir = MoveDirection
        if Speed <= Constants.SLIDE_MOD_MAX_SPEED then
            Controller.Speed += Constants.SLIDE_MOD
        end

        -- get ground normal
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Blacklist
        Params.FilterDescendantsInstances = {workspace.Ignore, Controller.Humanoid.Parent, workspace.CurrentCamera}
        local Result:RaycastResult = workspace:Raycast(Controller.Humanoid.Parent.HumanoidRootPart.Position, Vector3.new(0,-5,0), Params)

        if Result and Speed <= Constants.SLIDE_MOD_MAX_SPEED then
            local Normal = Result.Normal

            local SlideDirection = Controller.SlideDir.Unit
            local Alignment = SlideDirection:Dot(Normal)

            Controller.Speed += Constants.SLIDE_ALIGNMENT_MOD * Alignment
        end

    end


    if WishJump or (not Controller.WasWishSlide and Controller.WishSlide and Controller.WasSliding) then
        Controller.Sliding = false
    end

    if Controller.Sliding and Controller.Speed > 5   then
        -- apply slide friction
        Controller.Speed = Catchup(Controller.Speed, 0, Constants.SLIDE_DECEL * DT)

        -- bounces
        local Cast:RaycastResult = Controller:GetWallCast(2,3)

        if Cast and Cast.Distance < 1.5 and Constants.SLIDE_BOUNCE then
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
    end

    if not Controller.WasSliding and Controller.Sliding then
        Controller.Slide:Fire(true)
    elseif Controller.WasSliding and not Controller.Sliding then
        if Speed <= Constants.SLIDE_MOD_MAX_SPEED then
            Controller.Speed = math.clamp(Controller.Speed + Constants.SLIDE_EXIT_MOD, Constants.SPEED, Constants.SPEED_CAP)
        end

        Controller.SlideCancelQueued = false

        Controller.Slide:Fire(false)
    end
   
    Controller.WasWishSlide = Controller.WishSlide
end

function Controller:Accelerate(DT, MoveDirection, LastMoveDirection, Grounded, Speed)
    if MoveDirection.Magnitude <= 0.1 then return end -- no acceleration if not moving
    if Controller.Sliding then return end -- no acceleration while sliding

    local MaxSpeed = Grounded and Constants.MAX_ACCEL_SPEED or Constants.MAX_ACCEL_AIR_SPEED
    local Accel = Grounded and Constants.ACCEL or Constants.ACCEL_AIR

    local NewSpeed = Catchup(Controller.Speed, MaxSpeed, Accel * DT)

    Controller.Speed = NewSpeed
end

function Controller:Decelerate(DT, MoveDirection, ActualVelocityUnit, ActualVelocity, Grounded)
    if MoveDirection.Magnitude > 0.1 and ActualVelocityUnit:Dot(MoveDirection) > .7 then return end -- no deceleration if moving
    if Controller.Sliding then return end -- no deceleration while sliding

    local NewSpeed = Catchup(Controller.Speed, Constants.SPEED, Constants.DECEL * DT)

    if MoveDirection.Magnitude <= 0 and Grounded and ActualVelocity.Magnitude <= 4 then
        NewSpeed = Constants.SPEED
    end

    Controller.Speed = NewSpeed
end

function Controller:CalculateFOV(DT, Speed)
    Speed/= Controller.FOVMod

    -- instead of lerp change the lerped by catchup * delta time
    local Increment = 100 * DT
    Speed *= .2

    Controller.LerpedFov = Catchup(Controller.LerpedFov, Speed, Increment)

    Controller.FOVMod = Controller.Sliding and 1 or 2

    CameraController:AddOffset(Controller.LerpedFov)
end

function Controller.Update(DT)
    if not game.Players.LocalPlayer.Character then return end
    if not Controller.Humanoid then return end
    if Controller.Humanoid.Health <= 0 then return end

    local Grounded = Controller.Humanoid.FloorMaterial ~= Enum.Material.Air
    local MoveDirection = Controller.Humanoid.MoveDirection
    local LastMoveDirection = Controller.LastMoveDirection
    local WishJump = Controller.Humanoid.Jump and Controller.Humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
    local PlaneVelocity = Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1,0,1)
    local Speed = PlaneVelocity.Magnitude
    local Position = Controller.Humanoid.Parent.PrimaryPart.Position

    Controller.SlideCancelQueued = Controller.SlideCancelQueued or (Controller.Humanoid.Jump and Controller.Sliding)

    -- This gets the actual velocity of the player and ignores most of the vibration
    local ActualVelocity = (roundVector(Position, 10) - roundVector(Controller.LastPosition, 10)) * Vector3.new(1,0,1)
    local ActualVelocityUnit = ActualVelocity.Unit

    if (ActualVelocityUnit ~= ActualVelocityUnit) then
        ActualVelocityUnit = Vector3.new()
    end

    -- Momentum 
    Controller:Accelerate(DT, MoveDirection, LastMoveDirection, Grounded, Speed)
    Controller:Decelerate(DT, MoveDirection, ActualVelocityUnit, ActualVelocity, Grounded)

    -- Slide cancel
    local MinTimeMet = tick() - Controller.LastSlide > Constants.SLIDE_MIN_TIME

    if Controller.Sliding and MinTimeMet then
        Controller.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)   
    end

    if Controller.SlideCancelQueued and MinTimeMet then
        WishJump = true
    end

    if 
        (WishJump or Controller.SlideCancelQueued)
        and Controller.Sliding 
        and Speed <= Constants.SLIDE_MOD_MAX_SPEED 
        and MinTimeMet
    then
        Controller.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        Controller.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity = Controller.SlideDir.Unit * 30
        Controller.Speed = math.clamp(Controller.Speed + Constants.SLIDE_CANCEL_MOD, Constants.SPEED, Constants.SPEED_CAP)
        Controller.SlideCancelQueued = false
    end

    -- slide
    Controller:CalculateSlide(Grounded, MoveDirection, WishJump, DT, Speed)

    -- Cap speed
    Controller.Speed = math.clamp(Controller.Speed, 0, Constants.SPEED_CAP)

    -- fov
    Controller:CalculateFOV(DT, Speed)

    -- update state
    Controller.LastMoveDirection = Controller.Humanoid.MoveDirection
    Controller.WasWishJump = WishJump
    Controller.LastPosition = Controller.Humanoid.Parent.PrimaryPart.Position
    Controller.LastValidVelocityUnit = ActualVelocityUnit

    -- Update humanoid speed
    Controller.Humanoid.WalkSpeed = Controller.Speed
end

return Controller