function love.conf(t)
    t.version = "11.5"
    t.console = false

    t.window.title = "black_cartograph.exe"
    -- 0/0 means "use the desktop size".
    t.window.width = 0
    t.window.height = 0
    t.window.resizable = false
    t.window.vsync = 0

    -- Nothing uses these, and audio spins up a mixer thread for no reason.
    t.modules.audio = false
    t.modules.sound = false
    t.modules.physics = false
    t.modules.joystick = false
    t.modules.touch = false
    t.modules.video = false
end
