local Utils = {}

local bit = require("src/vendor/bitop-funcs")

function Utils.tern(pred, a, b)
    if pred then return a else return b end
end

function Utils.generate_frame_name()
    local name = ""
    for i = 1, math.random(2,3) do
        name = name .. string.char(math.random(65, 90))
    end

    name = name .. "-"

    for i = 1, 3 do
        name = name .. string.char(math.random(48, 57))
    end

    return name
end

function Utils.get_objects_of_type(from, object_type)
    local to_return = {}
    for i in pairs(from) do
        local item = from[i]
        if bit.band(item:get_object_type(), object_type) == object_type then
            table.insert(to_return, item)
        end
    end

    return to_return
end

function Utils.lerp(a, b, t)
    return a * (1-t) + b * t
end

function Utils.dist(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

return Utils
