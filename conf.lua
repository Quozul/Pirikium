function love.conf(t)
    t.identity = "Pirikium"             -- The name of the save directory (string)
    t.appendidentity = false            -- Search files in source directory before save directory (boolean)
    t.version = "11.1"                  -- The LÖVE version this game was made for (string)
    t.console = false                   -- Attach a console (boolean, Windows only)
    t.accelerometerjoystick = false     -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
    t.externalstorage = false           -- True to save files (and read from the save directory) in external storage on Android (boolean)
    t.gammacorrect = false              -- Enable gamma-correct rendering, when supported by the system (boolean)

    t.audio.mixwithsystem = true        -- Keep background music playing when opening LOVE (boolean, iOS and Android only)

    t.window.title = "Pirikium"         -- The window title (string)
    t.window.icon = "data/icon.png"     -- Filepath to an image to use as the window's icon (string)
    t.window.width = 853                -- The window width (number)
    t.window.height = 480               -- The window height (number)
    t.window.borderless = false         -- Remove all border visuals from the window (boolean)
    t.window.resizable = true           -- Let the window be user-resizable (boolean)
    t.window.minwidth = 853             -- Minimum window width if the window is resizable (number)
    t.window.minheight = 480            -- Minimum window height if the window is resizable (number)
    t.window.fullscreen = false         -- Enable fullscreen (boolean)
    t.window.fullscreentype = "desktop" -- Choose isBetween "desktop" fullscreen or "exclusive" fullscreen mode (string)
    t.window.vsync = 1                  -- Vertical sync mode (number)
    t.window.msaa = 0                   -- The number of samples to use with multi-sampled antialiasing (number)
    t.window.display = 1                -- Index of the monitor to show the window in (number)
    t.window.highdpi = false            -- Enable high-dpi mode for the window on a Retina display (boolean)
    t.window.x = nil                    -- The x-coordinate of the window's position in the specified display (number)
    t.window.y = nil                    -- The y-coordinate of the window's position in the specified display (number)

    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = true
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true -- Disabling it will result 0 delta time in love.update
    t.modules.touch = true
    t.modules.video = true
    t.modules.window = true
end