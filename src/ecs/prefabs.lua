-- What used to be one class per kind of object is now one function per kind,
-- and the kinds are just different handfuls of components.
local C = require("src/ecs/components")
local constants = require("src/Constants")

local prefabs = {}

function prefabs.hull(world, x, y)
    return world:spawn({
        Hull = C.Hull("TH-51US", 1000, constants.MAX_POWER),
        Named = C.Named("TH-51US"),
        Position = C.Position(x, y),
        CargoHold = C.CargoHold(constants.HULL_CARGO_TONS),
        FogReveal = C.FogReveal(0.75),
    })
end

function prefabs.relay(world, container)
    return world:spawn({
        Named = C.Named("RL-01, Relay"),
        Icon = C.Icon(8),
        Mass = C.Mass(0.02),
        FogReveal = C.FogReveal(0.25),
        Deployable = true,
        InCargo = C.InCargo(container),
    })
end

-- A frame comes with a relay on board.
function prefabs.frame(world, name, container)
    local frame = world:spawn({
        Named = C.Named(name),
        Icon = C.Icon(178),
        Mass = C.Mass(0.2),
        CargoHold = C.CargoHold(2),
        FogReveal = C.FogReveal(0.25),
        Frame = true,
        Dispatchable = true,
        InCargo = C.InCargo(container),
    })
    prefabs.relay(world, frame)
    return frame
end

local function _hull_module(name, power_usage, tons)
    return function(world, container)
        return world:spawn({
            Named = C.Named(name),
            Powered = C.Powered(power_usage),
            Mass = C.Mass(tons),
            InCargo = C.InCargo(container),
        })
    end
end

prefabs.em_field = _hull_module("EM FIELD GEN", 15, 0.8)
prefabs.lattice_array = _hull_module("L. Comms Array", 10, 0.8)
prefabs.sleeper = _hull_module("Sleeper", 10, 5)

function prefabs.radio(world, container)
    local radio = _hull_module("Radio", 2, 0.002)(world, container)
    world:add(radio, "RadioLog", C.RadioLog(200))
    return radio
end

return prefabs
