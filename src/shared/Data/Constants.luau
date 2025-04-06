local INF = math.huge

local Constants = {
    -- PLACE
    VERSION = 1,
    DEBUG = true,
    LOOP = true, -- run the game loop
    SHOW_CASTS = true, -- show debug casts
    SHOW_MOVE_CASTS = true, -- show debug move casts
    SHOW_SOUNDS = true, -- show where sounds are coming from and what they are
    DATASAVE = false, -- toggles player data load and save 

    -- WEAPON
    HITMARK = false, -- debug hitmarks
    BULLET_SPEED = 1000, 
    BULLET_ACCELERATION = -Vector3.yAxis * 50,
    MIN_KILLSTREAK = 2, -- minimum killstreak to get shown

    -- MAPS
    VOTE_TIME = 10,
    ROUND_TIME = INF,

    -- PROFILE
    PROFILE_TEMPLATE = {
        Money = 0,
        Kills = 0,
        Votes = 1,
        KillEffect = "Conffeti",
        
        Equipped = {
            Skin = "Default",
            KillEffect = "Default"
        },
        Skins = {
            Default=true
        },
        KillEffects = {
            Default=true
        }
    },

    -- REWARDS
    KILL_REWARD = 10,
    HEAD_KILL_REWARD = 20,

    -- CAMERA
    DEFAULT_FOV = 100,
    MOVE_FOV = 104,
    SLIDE_FOV = 110,

    FOV_CHANGE_TIME = 0.15,
    FOV_CHANGE_EASING = Enum.EasingStyle.Linear,
    FOV_CHANGE_EASING_DIRECTION = Enum.EasingDirection.In,

    -- MOVEMENT
    GRAVITY = 70,
    SPEED = 25,
    SLIDE_SPEED = 35,
    SLIDE_TIME = 2,
    SLIDE_COOLDOWN = .5,
    JUMP = 380,
    AUTO_JUMP = false, -- bhop style
    JUMPS = 1, -- how many jumps can be done withtout touching the ground
    JUMP_DELAY = 0.2, -- how long to wait before allowing another jump
    AIR_SPEED = 1.0, -- Modifier for air speed
    AIR_FORCE = 2000;
    TURN_SPEED = 4,
    ACCEL_TIME = 0,
    DECEL_TIME = 0,    
    FRICTION_WEIGHT = 100,

    -- CHARACTER
    HEALTH = 100,
    RESPAWN_TIME = 5,
    PLAYER_OUTLINE = Color3.fromRGB(58, 4, 0),
    KILL_STREAK_LEADER_OUTLINE = Color3.fromRGB(255, 214, 142),

    -- GAMEPASSES
    
}

function Constants:Debug(...)
    if not Constants.DEBUG then return end
    print(...)
end

return Constants