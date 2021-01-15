local Utils = {}

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

return Utils
