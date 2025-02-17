local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local Constants, Event, PlaySound, FastCast, ImpactEffect
function Controller:Init() 
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"
    PlaySound = shared.Import "PlaySound"
    FastCast = shared.Import "FastCastRedux"
    ImpactEffect = shared.Import "ImpactEffect"

    -- setup
    Controller.Caster = FastCast.new()


    -- caster events
    Controller.Caster.RayHit:Connect(function(_, RaycastResult:RaycastResult, _, _)
        ImpactEffect(RaycastResult)
    end)

    Controller.Caster.LengthChanged:Connect(function(cast, segmentOrigin, segmentDirection, length, _, cosmeticBulletObject)
	    if cosmeticBulletObject == nil then return end

	    local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
        segmentOrigin += cast.UserData.CosmeticOffset
        local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin+ segmentDirection)

	    cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
    end)

    Controller.Caster.CastTerminating:Connect(function(cast)
        local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
        if cosmeticBullet ~= nil then
            cosmeticBullet:Destroy()
        end
    end)

    -- events
    Event:Listen("PlaySound", Controller.PlaySound)
    Event:Listen("FireProjectile", Controller.FireProjectile)
end

function Controller.PlaySound(Position: Vector3, Sound: Sound)
    PlaySound(Sound, Position)
end

function Controller.FireProjectile(Attacker:Model, Weapon: Model, Origin: Vector3, Direction: Vector3)
    local WeaponConfig = require(Weapon.Configuration)
    local Behaviour  = Controller:NewBehaviour(Attacker)


    Controller.Caster:Fire(Origin, Direction, WeaponConfig.BulletVelocity or Constants.BULLET_SPEED, Vector3.zero, Behaviour)
end

--
function Controller:NewBehaviour(Attacker:Model)
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Blacklist
    Params.FilterDescendantsInstances = {workspace.Ignore, Attacker}

    local CastBehaviour = FastCast.newBehavior()
    CastBehaviour.RaycastParams = Params
    CastBehaviour.Acceleration = Constants.BULLET_ACCELERATION
    CastBehaviour.CosmeticBulletTemplate = ReplicatedStorage.Assets.Tracers.Physical
    CastBehaviour.CosmeticBulletContainer = workspace.Ignore

    return CastBehaviour
end

return Controller