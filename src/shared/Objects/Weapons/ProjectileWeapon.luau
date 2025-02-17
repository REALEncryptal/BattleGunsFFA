local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FirearmBase = require(script.Parent.FirearmBase)

local ProjectileWeapon = setmetatable({}, FirearmBase)
ProjectileWeapon.__index = ProjectileWeapon

--[[

    Implements caster for firearms
    
]]

function ProjectileWeapon.new(Weapon)
    local self = setmetatable(FirearmBase.new(Weapon), ProjectileWeapon)

    local FastCast = shared.Import("FastCastRedux")
    FastCast.VisualizeCasts = shared.Import("Constants").SHOW_CASTS

    self.Caster = FastCast.new()
    self.CastBehaviour = FastCast.newBehavior()

    --
    self.CastBehaviour.RaycastParams = self:CreateParams()
    self.CastBehaviour.Acceleration = shared.Import("Constants").BULLET_ACCELERATION
    self.CastBehaviour.CosmeticBulletTemplate = ReplicatedStorage.Assets.Tracers.Physical
    self.CastBehaviour.CosmeticBulletContainer = workspace.Ignore

    -- events
    self.Caster.RayHit:Connect(function(_, RaycastResult:RaycastResult, _, _)
        self:BulletHit(RaycastResult)
    end)

    self.Caster.LengthChanged:Connect(function(cast, segmentOrigin, segmentDirection, length, _, cosmeticBulletObject)
	    if cosmeticBulletObject == nil then return end

	    local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
        segmentOrigin += cast.UserData.CosmeticOffset
        local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin+ segmentDirection)

	    cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
    end)

    self.Caster.CastTerminating:Connect(function(cast)
        local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
        if cosmeticBullet ~= nil then
            cosmeticBullet:Destroy()
        end
    end)

    return self
end

function ProjectileWeapon:FunctionalValidateHit(RaycastResult:RaycastResult) 
    local Event = shared.Import "Event"

    task.spawn(function()
        local Valid = Event:InvokeServer("RaycastWeapon", self.OriginalWeapon, RaycastResult.Position, RaycastResult.Instance, RaycastResult.Normal)
        if not Valid then
            warn("[FireProjectile] Server rejected hit")
        end
    end)


    -- DONE this is when the client hit something so call RaycastWeapon on event
    -- DONE then implement the firing. the client needs to use fast cast
    -- then u need to tell the server about the shot
    -- the server then needs to validate it and tell other
    -- clients to replicate the shot and then put any hit effects.
end

function ProjectileWeapon:FunctionalFire(Origin:Vector3, SpreadDirection:Vector3, Params:RaycastParams)
    -- looks like the bullet is fired from the tip of the weapon
    local offset = self.Weapon.PrimaryPart.Tip.WorldCFrame.Position - workspace.CurrentCamera.CFrame.Position

    -- move the bullet forward a little
    offset += self.Weapon.PrimaryPart.Tip.WorldCFrame.LookVector * 5

    self.Caster:Fire(Origin, SpreadDirection, self.Config.BulletVelocity or shared.Import("Constants").BULLET_SPEED, offset, self.CastBehaviour)

    -- tell server to replicate the shot visually
    shared.Import("Event"):FireServer("FireProjectile", self.OriginalWeapon, Origin, SpreadDirection)
end

return ProjectileWeapon