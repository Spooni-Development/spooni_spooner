Config = {}

Config.DevMode = true

-- MOVEMENT SETTINGS
Config.Movement = {
    MaxSpeed = 1.00,
    MinSpeed = 0.01,
    SpeedIncrement = 0.01,
    Speed = 0.10
}

-- CAMERA SETTINGS
Config.Camera = {
    SpeedLr = 8.0,  -- X-axis rotation speed
    SpeedUd = 8.0   -- Y-axis rotation speed
}

-- ADJUSTMENT SETTINGS
Config.Adjustment = {
    -- Position
    MinSpeed = 0.001,
    MaxSpeed = 100.0,
    SpeedIncrement = 0.001,
    Speed = 0.01,
    
    -- Rotation
    MinRotateSpeed = 0.1,
    MaxRotateSpeed = 360.0,
    RotateSpeedIncrement = 0.1,
    RotateSpeed = 1.0
}

-- ENTITY SETTINGS
Config.Entity = {
    GroupMemberBlipSprite = -214162151,
    HandleDrawDistance = 20.0,
    CleanUpOnStop = true
}

-- DATABASE SETTINGS
Config.Database = {
    AutoSaveInterval = 0,
    KeepBackup = true
}

-- CONTROLS SETTINGS
Config.Controls = {
    -- Movement
    Forward = `INPUT_MOVE_UP_ONLY`, -- W
    Backward = `INPUT_MOVE_DOWN_ONLY`, -- S
    Left = `INPUT_MOVE_LEFT_ONLY`, -- A
    Right = `INPUT_MOVE_RIGHT_ONLY`, -- D
    Up = `INPUT_JUMP`, -- Spacebar
    Down = `INPUT_SPRINT`, -- Shift
    IncreaseSpeed = {`INPUT_CREATOR_LT`, `INPUT_PREV_WEAPON`}, -- Page Up, Mouse Wheel Up
    DecreaseSpeed = {`INPUT_CREATOR_RT`, `INPUT_NEXT_WEAPON`}, -- Page Down, Mouse Wheel Down
    SpeedMode = `INPUT_RELOAD`, -- R
    
    -- Camera
    LookLr = `INPUT_LOOK_LR`,
    LookUd = `INPUT_LOOK_UD`,
    Focus = `INPUT_PC_FREE_LOOK`, -- Alt
    ToggleFocusMode = {`INPUT_DUCK`, `INPUT_HORSE_STOP`}, -- Ctrl
    
    -- Actions
    Spawn = `INPUT_DYNAMIC_SCENARIO`, -- E
    Select = `INPUT_CURSOR_ACCEPT`, -- Left mouse button
    Delete = `INPUT_CONTEXT_LT`, -- Right mouse button
    Clone = `INPUT_INTERACT_ANIMAL`, -- G
    Toggle = `INPUT_FRONTEND_DELETE`, -- Del
    
    -- Adjustments
    AdjustUp = `INPUT_FRONTEND_LB`, -- Q
    AdjustDown = `INPUT_FRONTEND_LS`, -- Z
    AdjustForward = `INPUT_FRONTEND_UP`, -- Up arrow
    AdjustBackward = `INPUT_FRONTEND_DOWN`, -- Down arrow
    AdjustLeft = `INPUT_FRONTEND_LEFT`, -- Left arrow
    AdjustRight = `INPUT_FRONTEND_RIGHT`, -- Right arrow
    AdjustMode = `INPUT_QUICK_USE_ITEM`, -- I
    AdjustOff = `INPUT_SELECT_QUICKSELECT_THROWN`, -- 7
    FreeAdjustMode = `INPUT_SELECT_QUICKSELECT_PRIMARY_LONGARM`, -- 8
    PlaceOnGround = `INPUT_AIM_IN_AIR`, -- U
    
    -- Rotation
    RotateRight = `INPUT_CREATOR_RS`, -- C
    RotateLeft = `INPUT_NEXT_CAMERA`, -- V
    RotateMode = `INPUT_OPEN_SATCHEL_MENU`, -- B
    
    -- Menus
    SpawnMenu = `INPUT_CONTEXT_B`, -- F
    DbMenu = `INPUT_SWITCH_SHOULDER`, -- X
    PropMenu = `INPUT_CREATOR_MENU_TOGGLE`, -- Tab
    SaveLoadDbMenu = `INPUT_OPEN_JOURNAL`, -- J
    HelpMenu = {`INPUT_WHISTLE_HORSEBACK`, `INPUT_WHISTLE`}, -- H
    
    -- Display
    EntityHandles = `INPUT_PUSH_TO_TALK`, -- N
    ToggleControls = `INPUT_SELECT_QUICKSELECT_SIDEARMS_LEFT` -- 1
}