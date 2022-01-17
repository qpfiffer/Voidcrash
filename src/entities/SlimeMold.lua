local SlimeMold = {}
SlimeMold.__index = SlimeMold

local constants = require("src/Constants")
local Utils = require("src/Utils")

local ObjectType = require("src/objects/ObjectType")
local OrderType = require("src/management/OrderType")

local SPEED = 0.0001
local BASE_WEIGHT_TONS = 0.0
local SPREAD_TICK_RATE = 100

function SlimeMold:init(x, y, parent, deployed)
    local this = {
        object_type = ObjectType.CARGOABLE,
        ticks_advanced = 0,
        speed = SPEED,
        ticks_advanced = SPEED,
        progress = 0,

        world_x = x,
        world_y = y,

        name = "SlimeMold",
        children = {},
        parent = parent,

        orders = {},
        current_order = nil,

        deployed = deployed,
    }
    setmetatable(this, self)

    return this
end

function SlimeMold:get_object_type()
    return self.object_type
end

function SlimeMold:get_x()
    return self.world_x
end

function SlimeMold:set_x(val)
    --print("Setting X to " .. val)
    self.world_x = val
end

function SlimeMold:get_y()
    return self.world_y
end

function SlimeMold:set_y(val)
    --print("Setting Y to " .. val)
    self.world_y = val
end

function SlimeMold:get_icon()
    return 178
end

function SlimeMold:get_name()
    return self.name
end

function SlimeMold:get_deployed()
    return self.deployed
end

function SlimeMold:set_deployed(val)
    self.deployed = val
end

function SlimeMold:add_order(game_state, new_order)
    table.insert(self.orders, new_order)
    local msg = self.name .. " is following new order."
    game_state.player_info.radio:add_message(msg)
end

function SlimeMold:get_tonnage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used + BASE_WEIGHT_TONS
end

function SlimeMold:update(game_state, dt)
    if not self.deployed then
        return
    end

    self.ticks_advanced = self.ticks_advanced + 1
    if self.ticks_advanced > SPREAD_TICK_RATE then
        self.ticks_advanced = 0
        if #self.children > 0 then
            return
        end

        --if self.parent then
        --end

        self.children = {
            SlimeMold:init(self.world_x - 0.01, self.world_y, self, true),
            SlimeMold:init(self.world_x + 0.01, self.world_y, self, true),
            SlimeMold:init(self.world_x, self.world_y - 0.01, self, true),
            SlimeMold:init(self.world_x, self.world_y + 0.01, self, true)
        }
        for i in pairs(self.children) do
            game_state.player_info:add_world_object(self.children[i])
        end
    end
end

return SlimeMold
