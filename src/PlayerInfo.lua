local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

local constants = require("src/Constants")

local FrameObject = require("src/objects/FrameObject")

local EMFieldObject = require("src/objects/hull/EMFieldObject")
local LatticeCommunicationsArrayObject = require("src/objects/hull/LatticeCommunicationsArray")
local SleeperObject = require("src/objects/hull/SleeperObject")

local Utils = require("src/Utils")

function PlayerInfo:init()
    local this = {
        hull_name = "TH-51US",

        cur_tick = math.random(constants.GENESIS),

        overmap_x = math.random(constants.OVERMAP_MAX_X),
        overmap_y = math.random(constants.OVERMAP_MAX_Y),

        frames = {},
        cargo = {},

        full_power = constants.MAX_POWER,
        powered_on = {
            EMFieldObject:init(),
            LatticeCommunicationsArrayObject:init(),
            SleeperObject:init(),
        },

        current_lattice_step = 1,
    }
    setmetatable(this, self)

    this.cargo = {
        FrameObject:init(Utils.generate_frame_name(),
            this.overmap_x, this.overmap_y,
            math.random(constants.OVERMAP_MAX_X), math.random(constants.OVERMAP_MAX_Y)),
        FrameObject:init(Utils.generate_frame_name(),
            this.overmap_x, this.overmap_y,
            math.random(constants.OVERMAP_MAX_X), math.random(constants.OVERMAP_MAX_Y)),
        FrameObject:init(Utils.generate_frame_name(),
            this.overmap_x, this.overmap_y,
            math.random(constants.OVERMAP_MAX_X), math.random(constants.OVERMAP_MAX_Y)),
    }

    return this
end

function PlayerInfo:get_power_items()
    return self.powered_on
end

function PlayerInfo:get_frames()
    return self.frames
end

function PlayerInfo:get_cargo()
    return self.cargo
end

function PlayerInfo:get_power_usage()
    local total_used = 0
    for i in pairs(self.powered_on) do
        local active_power_item = self.powered_on[i]
        total_used = total_used + active_power_item:get_power_usage()
    end

    return total_used
end

function PlayerInfo:get_cargo_usage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used
end

function PlayerInfo:get_current_lattice_step()
    return self.current_lattice_step
end

function PlayerInfo:set_current_lattice_step(val)
    self.current_lattice_step = val
end

function PlayerInfo:get_lattice_intensity(world_x, world_y)
    -- Returns the value of the lattice, (0 - 1000), for an x/y pair.
    local _world_x = world_x + constants.LATTICE_NOISE_OFFSET_X
    local _world_y = world_y + constants.LATTICE_NOISE_OFFSET_Y
    local raw_noise_val = love.math.noise(world_x, world_y, self.current_lattice_step)
    local noise_val = math.floor(raw_noise_val * 1000)

    return noise_val
end

return PlayerInfo
