local Screen = require("src/Screen")
local GameStartState = Screen.extend()

local MapState = require("src/states/MapState")
local LatticeState = require("src/states/LatticeState")
local FrameState = require("src/states/FrameState")
local HullState = require("src/states/HullState")
local RadioState = require("src/states/RadioState")

function GameStartState:init()
    local this = {}
    setmetatable(this, self)

    return this
end

-- Not really a screen: it sets up the gameplay tabs and hands over to the map.
function GameStartState:on_start(game_state)
    game_state:add_active_state(MapState:init(game_state))
    game_state:add_active_state(LatticeState:init())
    game_state:add_active_state(FrameState:init())
    game_state:add_active_state(HullState:init())
    game_state:add_active_state(RadioState:init())
    game_state:set_game_started(true)
    game_state:switch_active_state(1)
end

return GameStartState
