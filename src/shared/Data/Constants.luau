local Constants = {
    -- PLACE
    VERSION = 1,
    DEBUG = true,
    LOOP = true, -- run the game loop
    SHOW_CASTS = false, -- show debug casts
    DATASAVE = false, -- toggles player data load and save 

    -- WEAPON
    HITMARK = false, -- debug hitmarks
    BULLET_SPEED = 1000, 
    BULLET_ACCELERATION = -Vector3.yAxis * 50,

    -- MAPS
    VOTE_TIME = 20,
    ROUND_TIME = 60*5,

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

    -- MOVEMENT
    GRAVITY = 70,
    SPEED = 20,
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
    RESPAWN_TIME = 3,

    -- GAMEPASSES
    
}

function Constants:Debug(...)
    if not Constants.DEBUG then return end
    print(...)
end

return Constants