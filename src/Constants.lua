local constants = {}

-- Time. Everything is in seconds (or per second); src/Clock.lua is the only
-- thing that ever sees dt.
constants.SIM_HZ = 60               -- Fixed simulation steps per second.
constants.BLINK_PERIOD = 1/3        -- Seconds per blink phase (on, then off).
constants.BOOT_TEXT_CPS = 60        -- Boot sequence characters per second.
constants.WIPE_TICK = 1/60          -- Left-wipe advances every 1-3 of these.
constants.SLEEPER_TICK = 1/170      -- Sleeper dialog types a letter every 2-7 of these (~38 cps).
constants.HELD_KEY_HZ = 60          -- How often held keys (pan, zoom) are applied.
constants.OVERLAY_REDRAW_HZ = 8     -- Redraws per second while an animated map overlay shows.
constants.SIM_REDRAW_HZ = 4         -- Most redraws per second caused by the simulation moving (frames crawl).
constants.IDLE_SLICE = 1/30         -- Longest the main loop sleeps when it has to poll for input...
constants.DEEP_IDLE_SLICE = 1/10    -- ...and once nobody has touched a key for half a minute.

constants.FRAME_SPEED = 0.012       -- Frame travel, world units per second.
constants.WEATHER_RATE = 0.012      -- Weather noise drift per second.
constants.LATTICE_RATE = 0.0013     -- Lattice noise drift per second.
constants.PAN_SPEED = 1.2           -- Map pan, world units per second.
constants.CURSOR_SPEED = 24         -- Map cursor, cells per second.
constants.ZOOM_SPEED = 1.2          -- Zoom levels per second.

constants.OVERMAP_MAX_X = 65536
constants.OVERMAP_MAX_Y = 65536

constants.MAP_X_MAX = 68
constants.MAP_Y_MAX = 28

constants.GENESIS = 65536
constants.TICK_SLOW_FACTOR = 53     -- Seconds of sim time per displayed tick.

constants.LATTICE_NOISE_OFFSET_X = 48765
constants.LATTICE_NOISE_OFFSET_Y = 32455
constants.LATTICE_MINUMUM_INTENSITY = 300

return constants
