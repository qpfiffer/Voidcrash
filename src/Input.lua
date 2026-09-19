-- Which keys are currently held, tracked from key events rather than polled.
-- The main loop sleeps when nothing is going on, so "is anything held?" has to
-- be answerable without spinning.
local Input = {}

local held = {}

function Input.key_pressed(key)
    held[key] = true
end

function Input.key_released(key)
    held[key] = nil
end

-- A release that happens while we're unfocused never reaches us, so drop everything.
function Input.clear()
    held = {}
end

function Input.is_down(key)
    return held[key] == true
end

function Input.any_down(keys)
    for i=1, #keys do
        if held[keys[i]] then
            return true
        end
    end
    return false
end

return Input
