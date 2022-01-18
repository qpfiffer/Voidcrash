local FrameObject = {}
FrameObject.__index = FrameObject

local constants = require("src/Constants")
local Utils = require("src/Utils")

local CollectorObject = require("src/objects/CollectorObject")
local ObjectType = require("src/objects/ObjectType")
local OrderType = require("src/management/OrderType")
local UnitCommand = require("src/management/UnitCommand")
local RelayObject = require("src/objects/RelayObject")

local SPEED = 0.0002
local BASE_WEIGHT_TONS = 0.2

function FrameObject:init(name, x, y, orders)
    local this = {
        object_type = ObjectType.FRAME + ObjectType.DISPATCHABLE + ObjectType.CARGOABLE,
        speed = SPEED,
        ticks_advanced = SPEED,
        progress = 0,

        origin_x = x,
        origin_y = y,

        dest_x = dest_x,
        dest_y = dest_y,

        world_x = x,
        world_y = y,

        name = name,
        cargo_max = 2, -- Tons
        cargo = {},

        orders = {},
        current_order = nil,

        deployed = false,
    }
    setmetatable(this, self)

    table.insert(this.cargo, RelayObject:init("RL-01, Relay", nil, nil, false))

    return this
end

function FrameObject:get_object_type()
    return self.object_type
end

function FrameObject:get_x()
    return self.world_x
end

function FrameObject:set_x(val)
    --print("Setting X to " .. val)
    self.world_x = val
end

function FrameObject:get_y()
    return self.world_y
end

function FrameObject:set_y(val)
    --print("Setting Y to " .. val)
    self.world_y = val
end

function FrameObject:get_icon()
    return 178
end

function FrameObject:get_name()
    return self.name
end

function FrameObject:get_deployed()
    return self.deployed
end

function FrameObject:set_deployed(val)
    self.deployed = val
end

function FrameObject:add_order(game_state, new_order)
    table.insert(self.orders, new_order)
    local msg = self.name .. " is following new order."
    game_state.player_info.radio:add_message(msg)
end

function FrameObject:get_tonnage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used + BASE_WEIGHT_TONS
end

function FrameObject:get_cargo()
    return self.cargo
end

function FrameObject:_start_drop_order(game_state, movement_order)
    local msg = self.name .. " will dispatch next available item."
    game_state.player_info.radio:add_message(msg)
end

function FrameObject:_handle_drop_order(game_state)
    --self.world_x = movement_order["data"]["start_x"]
    --self.world_y = movement_order["data"]["start_y"]
    self.current_order = nil

    local deployable_cargo = self:_pop_deployable_cargo()
    deployable_cargo:set_x(self.world_x)
    deployable_cargo:set_y(self.world_y)
    deployable_cargo:set_deployed(true)
    game_state.player_info:add_world_object(deployable_cargo)

    local msg = self.name .. " has deployed " .. deployable_cargo:get_name()
    game_state.player_info.radio:add_message(msg)
end

function FrameObject:_pop_deployable_cargo()
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        if bit.band(cargo_item:get_object_type(), ObjectType.DEPLOYABLE) == ObjectType.DEPLOYABLE then
            table.remove(self.cargo, i)
            return cargo_item
        end
    end

    return nil
end

function FrameObject:_start_movement_order(game_state, movement_order)
    self.origin_x = movement_order["data"]["start_x"]
    self.origin_y = movement_order["data"]["start_y"]
    self.world_x = movement_order["data"]["start_x"]
    self.world_y = movement_order["data"]["start_y"]
    self.dest_x = movement_order["data"]["dest_x"]
    self.dest_y = movement_order["data"]["dest_y"]

    local msg = self.name .. " begins to move."
    game_state.player_info.radio:add_message(msg)
end

function FrameObject:_handle_movement_order(game_state)
    local x_not_equal = self.world_x ~= self.dest_x
    local y_not_equal = self.world_y ~= self.dest_y
    if x_not_equal or y_not_equal then
        local distance = Utils.dist(self.origin_x, self.origin_y, self.dest_x, self.dest_y)
        self.progress = self.progress + (self.speed * 1/distance)

        if self.progress >= 1 then
            self.progress = 1
        end

        if x_not_equal then
            self:set_x(Utils.lerp(self.origin_x, self.dest_x, self.progress))
        end

        if y_not_equal then
            self:set_y(Utils.lerp(self.origin_y, self.dest_y, self.progress))
        end
    elseif self.progress == 1 then
        self.current_order = nil
        self.progress = 0
        self.origin_x = nil
        self.origin_y = nil
        self.dest_x = nil
        self.dest_y = nil

        local msg = self.name .. " has arrived at destination."
        game_state.player_info.radio:add_message(msg)
    end
end

function FrameObject:get_deployable_cargo()
    local to_return = {}
    for i in pairs(self.cargo) do
        local item = self.cargo[i]
        if bit.band(item:get_object_type(), ObjectType.DEPLOYABLE) == ObjectType.DEPLOYABLE then
            table.insert(to_return, item)
        end
    end

    return to_return
end

function FrameObject:get_context_cursor_items(game_state, exit_callback)
    add_drop_order_callback = function ()
        self:add_order(game_state, UnitCommand:init(OrderType.DROP, {}))
        exit_callback()
    end

    local list = {
        {["name"]="Drop Item", ["enabled"] = #self:get_deployable_cargo() > 0, ["callback"]=add_drop_order_callback},
        {["name"]="Return to Hull", ["enabled"] = self.deployed, ["callback"]=exit_callback}
    }
    return list
end

function FrameObject:update(game_state, dt)
    if not self.current_order and #self.orders > 0 then
        self.current_order = table.remove(self.orders)

        local orders_table = {}
        orders_table[OrderType.MOVEMENT] = function() self:_start_movement_order(game_state, self.current_order) end
        orders_table[OrderType.DROP] = function() self:_start_drop_order(game_state, self.current_order) end

        orders_table[self.current_order:get_type()]()
    end

    if not self.deployed then
        return
    end

    if self.current_order then
        local orders_table = {}
        orders_table[OrderType.MOVEMENT] = function() self:_handle_movement_order(game_state) end
        orders_table[OrderType.DROP] = function() self:_handle_drop_order(game_state) end

        orders_table[self.current_order:get_type()]()
    end
end

return FrameObject
