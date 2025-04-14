local INF = math.huge

local Constants = {
    -- PLACE
    VERSION = 1,
    DEBUG = false,
    LOOP = false, -- run the game loop
    SHOW_CASTS = false, -- show debug casts
    SHOW_MOVE_CASTS = false, -- show debug move casts
    SHOW_SOUNDS = false, -- show where sounds are coming from and what they are
    DATASAVE = true, -- toggles player data load and save

    -- MUSIC
    BACKGROUND_VOLUME = 0.3,

    -- WEAPON
    HITMARK = false, -- debug hitmarks
    BULLET_SPEED = 1000, 
    BULLET_ACCELERATION = -Vector3.yAxis * 50,
    MIN_KILLSTREAK = 2, -- minimum killstreak to get shown

    -- MAPS
    VOTE_TIME = 10,
    ROUND_TIME = 160,

    -- PROFILE
    PROFILE_TEMPLATE = {
        Money = 0,
        Kills = 0,
        Votes = 1,
        KillEffect = "Conffeti",
        
        Equipped = {
            Skin = "Drefault",
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
    SPEED_CAP = 75, -- Absolute max speed
    JUMP_HEIGHT = 6,

    SPEED = 40,
    ACCEL = 3, -- Multiplied by delta time then added to speed every frame'
    ACCEL_AIR = 2,
    DECEL = 20, -- Only applies when no wish direction
    MAX_ACCEL_SPEED =  27, -- MAX SPS before no more acceleration
    MAX_ACCEL_AIR_SPEED = 30, -- MAX SPS before no more acceleration in air
    
    SLIDE_BOUNCE = false,
    SLIDE_MOD = 5, -- added to player speed when sliding
    SLIDE_MOD_MAX_SPEED = 38, -- speed must be less than this get a boost
    SLIDE_CANCEL_MOD = 9, -- added to player speed when jump canceling a slide
    SLIDE_EXIT_MOD = -9, -- added to player speed when exiting a slide
    SLIDE_ALIGNMENT_MOD = 5, -- boost based on the slope of the surface vs the player camera
    SLIDE_DECEL = 10, -- Same as accel but to slow down while sliding
    SLIDE_COOLDOWN = .7,
    SLIDE_MIN_TIME = 0.15, -- how long the player must be sliding before they can cancel
    SLIDE_CLIFF_BOOST_VERTICAL = 10, -- how much to boost the player up when sliding off an dege
    SLIDE_CLIFF_BOOST_HORIZONTAL = 10, -- how much to boost the player forward


    SLIDE_SPEED = 50,
    SLIDE_TIME = 2,


    -- MOVEMENT LEGACY
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