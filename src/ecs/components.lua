-- Every component the simulation uses, in one place. Components are plain data:
-- no methods, no references to love, nothing that couldn't be written to a save
-- file. Tags are just `true`.
--
--   world:spawn({Named = C.Named("TH-51US"), Position = C.Position(3, 4)})
local C = {}

-- Where something is in the world. Exactly one of Position / InCargo is present
-- on anything that can be carried; only src/ecs/containment.lua switches them.
function C.Position(x, y)
    return {x = x, y = y}
end

-- Being carried by (or installed in) another entity.
function C.InCargo(container)
    return {of = container}
end

function C.Named(name)
    return {name = name}
end

-- Glyph shown on the map.
function C.Icon(glyph)
    return {glyph = glyph}
end

-- Own weight in tons, not counting anything carried.
function C.Mass(tons)
    return {tons = tons}
end

-- Draws hull power while installed.
function C.Powered(usage)
    return {usage = usage}
end

-- Can carry things (capacity in tons).
function C.CargoHold(capacity)
    return {capacity = capacity}
end

-- Lifts the fog of war around itself (radius in world units).
function C.FogReveal(radius)
    return {radius = radius}
end

function C.Hull(name, integrity, full_power)
    return {name = name, integrity = integrity, full_power = full_power}
end

-- The message log shown on the radio tab.
function C.RadioLog(max)
    return {messages = {}, max = max}
end

-- Orders waiting to be carried out. Only present while there are any, which is
-- what tells the world this entity needs simulating.
function C.Orders()
    return {queue = {}, current = nil}
end

-- In transit. Only present while moving.
function C.Movement(origin_x, origin_y, dest_x, dest_y, speed)
    return {
        origin_x = origin_x, origin_y = origin_y,
        dest_x = dest_x, dest_y = dest_y,
        progress = 0,  -- 0..1 along the line
        speed = speed, -- World units per second.
    }
end

-- Tags:
--   Frame         a drone that carries out orders
--   Dispatchable  can be sent out from the hull
--   Deployable    can be dropped into the world by whatever carries it

return C
