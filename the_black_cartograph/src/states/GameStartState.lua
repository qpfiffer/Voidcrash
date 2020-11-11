local GameStartState = {}
GameStartState.__index = GameStartState

local constants = require("src/Constants")

local MapState = require("src/states/MapState")
local LatticeState = require("src/states/LatticeState")
local FrameState = require("src/states/FrameState")

function GameStartState:init()
    local this = {}
    setmetatable(this, self)

    return this
end

function GameStartState:key_pressed(game_state, key)
end

function GameStartState:update(game_state, dt)
    game_state:add_active_state(MapState:init())
    game_state:add_active_state(LatticeState:init())
    game_state:add_active_state(FrameState:init())
    game_state:set_game_started(true)
    game_state:switch_active_state(1)
end

function GameStartState:render(renderer)
end

return GameStartState
