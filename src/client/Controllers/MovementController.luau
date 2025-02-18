local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Controller = {}

local Constants, Signal

function Controller:PreInit()
    Signal = shared.Import "Signal"
    Controller.WallJump = Signal.new()
    Controller.WallSlide = Signal.new()
    Controller.WallDismount = Signal.new()
    Controller.Slide = Signal.new()
end

function Controller:Init()
    Constants = shared.Import "Constants"
    --
    Controller.Humanoid = nil

    Controller.LastMoveDirection = Vector3.new()
    Controller.WallJumps = 2
    Controller.WasWishJump = false
    Controller.LastSlide = tick()

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

function Controller:GetWallCast(Offset,Layers)
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Blacklist
    Params.FilterDescendantsInstances = {workspace.Ignore, Controller.Humanoid.Parent, workspace.CurrentCamera}

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

            Controller:DebugRay((y*10*360)+i,O, if Result then Result.Position else O+Direction, C)

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

function Controller:WallJumpWallSlide(Grounded, WishJump)
    local WasSliding = Controller.WallSliding
    Controller.WallSliding = false

    if not Grounded then
        local Result:RaycastResult = Controller:GetWallCast(1, 4)

        if Result then
            if Result.Distance <= 1.5 and WishJump and not Controller.WasWishJump and Controller.WallJumps > 0 then
                Controller.WallJump:Fire()
                Controller.WallJumps-=1

                local v = Vector3.yAxis * 30 + Result.Normal * 20
                -- add the current velocity of the player
                v = v + Controller.Humanoid.Parent.HumanoidRootPart.AssemblyLinearVelocity* 1.4 * Vector3.new(1,0,1)


                local LV = Instance.new("LinearVelocity")
                LV.Name = "BOOST"
                LV.Attachment0 = Controller.Humanoid.Parent.HumanoidRootPart.RootAttachment
                LV.ForceLimitsEnabled = false
                LV.VectorVelocity = v
                LV.Parent = Controller.Humanoid.Parent.HumanoidRootPart
                game.Debris:AddItem(LV, .1)--lifespan = 0.5
                Controller.WallJumpStart = nil
            elseif WishJump and not Controller.WasWishJump and Result.Distance <= 1.5 then
                -- jump off wall slide
                Controller.WallDismount:Fire()
                Controller.WallJumps = -1
                local LV = Instance.new("LinearVelocity")
                LV.Name = "BOOST"
                LV.Attachment0 = Controller.Humanoid.Parent.HumanoidRootPart.RootAttachment
                LV.ForceLimitsEnabled = false
                LV.VectorVelocity = Result.Normal * 20 + Vector3.yAxis * -30
                LV.Parent = Controller.Humanoid.Parent.HumanoidRootPart
                game.Debris:AddItem(LV, .1)--lifespan = 0.5
                
            elseif  Result.Distance <= 1.5 and Controller.WallJumps >= 0 then
                
                if not Controller.WallJumpStart then
                    Controller.WallJumpStart = tick()
                end

                if tick()-Controller.WallJumpStart <= 2 then
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
        local Cast:RaycastResult = Controller:GetWallCast(2,2)

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
    if not Controller.Humanoid then return end

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

    Controller.LastMoveDirection = Controller.Humanoid.MoveDirection
    Controller.WasWishJump = WishJump
end

return Controller