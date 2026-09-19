local Utils = require("src/Utils")

local tests = {}

function tests.lerp_hits_both_ends_exactly(T)
    -- Frame arrival depends on lerp(a, b, 1) being exactly b.
    T.eq(Utils.lerp(3.25, 9.75, 0), 3.25)
    T.eq(Utils.lerp(3.25, 9.75, 1), 9.75)
    T.eq(Utils.lerp(41234.1, 41233.7, 1), 41233.7)
end

function tests.dist(T)
    T.eq(Utils.dist(0, 0, 3, 4), 5)
    T.eq(Utils.dist(1, 1, 1, 1), 0)
end

function tests.frame_names_look_right(T)
    for i=1, 20 do
        T.ok(Utils.generate_frame_name():match("^%u%u%u?%-%d%d%d$"))
    end
end

return tests
