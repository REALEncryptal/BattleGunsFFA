local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controller = {}

local Constants, Event, FastCast, WeaponController
function Controller:Init() 
    Constants = shared.Import "Constants"
    FastCast = shared.Import "FastCastRedux"
    WeaponController = require(script.Parent.WeaponController)

    -- setup
    Controller.Caster = FastCast.new()

    -- caster events
    Controller.Caster.RayHit:Connect(function(cast, RaycastResult:RaycastResult, _, _)
        print("Big Black Something Else")
        WeaponController.RaycastWeapon(nil, cast.UserData.Config, RaycastResult.Position, RaycastResult.Instance, RaycastResult.Normal)
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
end

function Controller.FireProjectile(Attacker:Model, Weapon: Model | ModuleScript, Origin: Vector3, Direction: Vector3)
    local ConfigModule = Weapon:IsA("ModuleScript") and Weapon or Weapon:FindFirstChild("Configuration")
    local WeaponConfig =  require(ConfigModule)
    local Behaviour  = Controller:NewBehaviour(Attacker, WeaponConfig)

    Controller.Caster:Fire(Origin, Direction, WeaponConfig.BulletVelocity or Constants.BULLET_SPEED, Vector3.zero, Behaviour, WeaponConfig)
end

--
function Controller:NewBehaviour(Attacker:Model|BasePart, Config)
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Blacklist
    Params.FilterDescendantsInstances = {workspace.Ignore, Attacker}

    local CastBehaviour = FastCast.newBehavior()
    CastBehaviour.RaycastParams = Params
    CastBehaviour.MaxDistance = 99999999
    CastBehaviour.Acceleration = Constants.BULLET_ACCELERATION
    CastBehaviour.CosmeticBulletContainer = workspace.Ignore

    return CastBehaviour
end

return Controller