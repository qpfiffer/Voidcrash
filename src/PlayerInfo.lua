local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

local constants = require("src/Constants")

local HullObject = require("src/objects/hull/HullObject")

local Utils = require("src/Utils")

function PlayerInfo:init(clock)
    local this = {
        clock = clock,
        hull = HullObject:init(),

        genesis_tick = math.random(constants.GENESIS), -- What T read when the game began.

        overmap_x = math.random(constants.OVERMAP_MAX_X),
        overmap_y = math.random(constants.OVERMAP_MAX_Y),

        world_objects = {},
        world_objects_to_remove = {},
    }

    setmetatable(this, self)
    return this
end

function PlayerInfo:get_world_objects()
    return self.world_objects
end

function PlayerInfo:add_world_object(object)
    table.insert(self.world_objects, object)
end

function PlayerInfo:remove_world_object(object)
    self.world_objects_to_remove[object] = true
end

-- One fixed simulation step. Only ever called by the clock.
function PlayerInfo:step(game_state, step)
    self:_remove_tombstoned_world_objects()
    for i=1, #self.world_objects do
        self.world_objects[i]:update(game_state, step)
    end
end

-- The in-fiction clock. Sim time, so it stops while paused.
function PlayerInfo:get_cur_tick()
    return self.genesis_tick + self.clock.sim.time / constants.TICK_SLOW_FACTOR
end

function PlayerInfo:_remove_tombstoned_world_objects()
    if next(self.world_objects_to_remove) == nil then
        return
    end

    local new_world_objects = {}
    for i in pairs(self.world_objects) do
        local item = self.world_objects[i]
        if not self.world_objects_to_remove[item] then
            table.insert(new_world_objects, item)
        end
    end

    self.world_objects = new_world_objects
    self.world_objects_to_remove = {}
end

function PlayerInfo:get_world_objects_of_type(object_type)
    return Utils.get_objects_of_type(self.world_objects, object_type)
end

-- The lattice drifts with sim time rather than being stepped by whoever's on screen.
function PlayerInfo:get_current_lattice_step()
    return 1 + constants.LATTICE_RATE * self.clock.sim.time
end

function PlayerInfo:get_lattice_intensity(world_x, world_y)
    -- Returns the value of the lattice, (0 - 1000), for an x/y pair.
    local _world_x = world_x + constants.LATTICE_NOISE_OFFSET_X
    local _world_y = world_y + constants.LATTICE_NOISE_OFFSET_Y
    local raw_noise_val = love.math.noise(world_x, world_y, self:get_current_lattice_step())
    local noise_val = math.floor(raw_noise_val * 1000)

    return noise_val
end

return PlayerInfo
