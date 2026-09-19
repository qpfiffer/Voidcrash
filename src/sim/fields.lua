-- The noise fields the world is made of. Weather and the lattice drift with
-- sim time; they are functions of it, not counters somebody has to keep
-- bumping, so they're correct whether or not anyone was simulating or looking.
--
-- The noise function is passed in (love.math.noise in the game) so this stays
-- testable without love.
local constants = require("src/Constants")

local Fields = {}
Fields.__index = Fields

local WEATHER_MAP_DIVISOR = 1600

function Fields.new(noise)
    return setmetatable({noise = noise}, Fields)
end

-- 0..1000; low is red/impassable-looking, high fades to dark.
function Fields:terrain(x, y)
    return self.noise(x, y) * 1000
end

-- 0..WEATHER_MAP_DIVISOR. The lower half is weather.
function Fields:weather(x, y, sim_time)
    return math.floor(self.noise(x, y, 1 + constants.WEATHER_RATE * sim_time) * WEATHER_MAP_DIVISOR)
end

function Fields:in_weather(x, y, sim_time)
    return self:weather(x, y, sim_time) <= WEATHER_MAP_DIVISOR / 2
end

-- 0..1000.
function Fields:lattice_intensity(x, y, sim_time)
    return math.floor(self.noise(
        x + constants.LATTICE_NOISE_OFFSET_X,
        y + constants.LATTICE_NOISE_OFFSET_Y,
        1 + constants.LATTICE_RATE * sim_time) * 1000)
end

Fields.WEATHER_MAP_DIVISOR = WEATHER_MAP_DIVISOR

return Fields
