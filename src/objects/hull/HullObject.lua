local HullObject = {}
HullObject.__index = HullObject

local bit = require("src/vendor/bitop-funcs")
local constants = require("src/Constants")

-- Worldly objects
local FrameObject = require("src/objects/FrameObject")
local ObjectType = require("src/objects/ObjectType")
local RelayObject = require("src/objects/RelayObject")

-- Hull objects
local EMFieldObject = require("src/objects/hull/EMFieldObject")
local LatticeCommunicationsArrayObject = require("src/objects/hull/LatticeCommunicationsArray")
local RadioObject = require("src/objects/RadioObject")
local SleeperObject = require("src/objects/hull/SleeperObject")

local Utils = require("src/Utils")

function HullObject:init(initial_state)
    local this = {
        hull_name = "TH-51US",

        integrity = 1000,

        cargo = {},

        radio = RadioObject:init(),

        full_power = constants.MAX_POWER,
        powered_on = {
            EMFieldObject:init(),
            LatticeCommunicationsArrayObject:init(),
            SleeperObject:init(),
        },
    }
    setmetatable(this, self)

    this.cargo = {
        FrameObject:init(Utils.generate_frame_name(), 0, 0, 0, 0),
        FrameObject:init(Utils.generate_frame_name(), 0, 0, 0, 0),
        FrameObject:init(Utils.generate_frame_name(), 0, 0, 0, 0)
    }

    table.insert(this.powered_on, this.radio)
    table.insert(this.cargo, this.radio)
    for i in pairs(this.powered_on) do
        local item = this.powered_on[i]
        table.insert(this.cargo, item)
    end


    return this
end

function HullObject:get_name()
    return self.hull_name
end

function HullObject:get_cargo()
    return self.cargo
end

function HullObject:get_power_items()
    return self.powered_on
end

function HullObject:get_cargo_items_of_type(object_type)
    return Utils.get_objects_of_type(self.cargo, object_type)
end

function HullObject:add_item_to_cargo(object)
    table.insert(self.cargo, object)
end

function HullObject:pop_item_from_cargo_of_type(object_type)
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        if bit.band(cargo_item.object_type, object_type) == object_type then
            table.remove(self.cargo, i)
            print(#self.cargo)
            return cargo_item
        end
    end

    return nil
end

function HullObject:get_power_usage()
    local total_used = 0
    for i in pairs(self.powered_on) do
        local active_power_item = self.powered_on[i]
        total_used = total_used + active_power_item:get_power_usage()
    end

    return total_used
end

function HullObject:get_cargo_usage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used
end

function HullObject:has_dispatchable()
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        if bit.band(cargo_item.object_type, ObjectType.DISPATCHABLE) == ObjectType.DISPATCHABLE then
            return true
        end
    end

    return false
end

return HullObject
