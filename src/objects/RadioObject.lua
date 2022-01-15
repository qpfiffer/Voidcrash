local RadioObject = {}
RadioObject.__index = RadioObject

local ObjectType = require("src/objects/ObjectType")

function RadioObject:init(x, y)
    local this = {
        object_type = ObjectType.BASE,

        power_usage = 2,

        messages = {}
    }
    setmetatable(this, self)

    return this
end

function RadioObject:add_message(msg)
    table.insert(self.messages, msg)
end

function RadioObject:get_messages()
    return self.messages
end

function RadioObject:get_name()
    return "Radio"
end

function RadioObject:get_power_usage()
    return self.power_usage
end

function RadioObject:update(game_state, dt)
end

return RadioObject
