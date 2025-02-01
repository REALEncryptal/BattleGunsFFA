return {
    -- PLACE
    VERSION = 1,
    DEBUG = true,
    DATASAVE = false, -- toggles player data load and save 

    -- MAPS
    VOTE_TIME = 5,
    ROUND_TIME = 5,

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

    -- CAMERA
    DEFAULT_FOV = 80,

    -- MOVEMENT
    GRAVITY = 70,
    SPEED = 20,
    JUMP = 380,
    AUTO_JUMP = false, -- bhop style
    JUMPS = 1, -- how many jumps can be done withtout touching the ground
    JUMP_DELAY = 0.4, -- how long to wait before allowing another jump
    AIR_SPEED = 1.1, -- Modifier for air speed
    AIR_FORCE = 2000;
    TURN_SPEED = 1,
    ACCEL_TIME = 0,
    DECEL_TIME = 0,    
    FRICTION_WEIGHT = 100,

    -- CHARACTER
    HEALTH = 100,
    RESPAWN_TIME = 3,

    -- GAMEPASSES
    
}