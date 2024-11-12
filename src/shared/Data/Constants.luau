return {
    -- PLACE
    VERSION = 1,
    DEBUG = true,
    DATASAVE = false, -- toggles player data load and save

    -- CAMERA
    DEFAULT_FOV = 70,

    -- MOVEMENT
    GRAVITY = 75,
    SPEED = 20,
    JUMP = 350,
    AUTO_JUMP = false, -- bhop style
    JUMPS = 1, -- how many jumps can be done withtout touching the ground
    JUMP_DELAY = 0.4, -- how long to wait before allowing another jump
    AIR_SPEED = 1.1, -- Modifier for air speed
    AIR_FORCE = 1000;
    TURN_SPEED = 1,
    ACCEL_TIME = 0.01,
    DECEL_TIME = 0.1,   
    FRICTION_WEIGHT = 10,

    -- CHARACTER
    HEALTH = 100,
    RESPAWN_TIME = 3,
}