local InitialState = {}
InitialState.__index = InitialState

function InitialState:init()
    local this = {
    }
    setmetatable(this, self)

    return this
end

function InitialState:render(renderer)
    local accum = 0
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("Init...", 0, accum)
end

return InitialState
