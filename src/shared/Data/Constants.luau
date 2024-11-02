return {
    -- PLACE
    VERSION = 1,
    DEBUG = true,
    DATASAVE = false, -- toggles player data load and save

    -- MOVEMENT
    GRAVITY = 80,
    SPEED = 20,
    JUMP = 250,
    AUTO_JUMP = false, -- bhop style
    JUMPS = 1, -- how many jumps can be done withtout touching the ground
    JUMP_DELAY = 0.4, -- how long to wait before allowing another jump
    AIR_SPEED = 1.2, -- Modifier for air speed
    AIR_FORCE = 300;
    TURN_SPEED = 10,
    ACCEL_TIME = 0.02,
    DECEL_TIME = 0.2,   
    FRICTION_WEIGHT = 10,

    -- HEALTH
    HEALTH = 200,
}