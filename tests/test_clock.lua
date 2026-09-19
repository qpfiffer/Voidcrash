local Clock = require("src/Clock")

local tests = {}

local function _counting_clock(opts)
    local clock = Clock.new(opts)
    local steps = {count = 0}
    clock:on_step(function(step) steps.count = steps.count + 1 end)
    return clock, steps
end

function tests.fixed_step_counts_for_irregular_dt(T)
    local clock, steps = _counting_clock({step = 1/60})
    local dts = {0.001, 0.03, 0.0005, 0.016, 0.0021, 0.05, 0.0034}
    local total = 0
    for i=1, #dts do
        clock:advance(dts[i])
        total = total + dts[i]
    end
    T.eq(steps.count, math.floor(total * 60))
    T.near(clock.sim.time, steps.count / 60)
    T.near(clock.ui.time, total)
end

function tests.tiny_dt_does_not_step_every_frame(T)
    -- The old accumulators with sub-frame intervals fired once per frame.
    local clock, steps = _counting_clock({step = 1/60})
    for i=1, 1000 do
        clock:advance(0.001)
    end
    T.eq(steps.count, 60)
end

function tests.stall_is_clamped_and_steps_are_capped(T)
    local clock, steps = _counting_clock({step = 1/60, max_catchup = 0.25, max_steps = 8})
    clock:advance(30)
    T.near(clock.ui.time, 0.25)
    T.eq(steps.count, 8)

    -- The dropped steps are gone, not deferred.
    clock:advance(1/60)
    T.eq(steps.count, 9)
end

function tests.pause_freezes_sim_but_not_ui(T)
    local clock, steps = _counting_clock({step = 0.1})
    local ui_fired, sim_fired = 0, 0
    clock.ui:every(0.1, function() ui_fired = ui_fired + 1 end)
    clock.sim:every(0.1, function() sim_fired = sim_fired + 1 end)

    clock:set_paused(true)
    for i=1, 10 do clock:advance(0.1) end
    T.eq(steps.count, 0)
    T.eq(sim_fired, 0)
    T.eq(clock.sim.time, 0)
    T.eq(ui_fired, 10)

    clock:set_paused(false)
    for i=1, 10 do clock:advance(0.1) end
    T.eq(steps.count, 10)
    T.eq(sim_fired, 10)
end

function tests.after_fires_once(T)
    local clock = Clock.new()
    local fired = 0
    clock.ui:after(0.5, function() fired = fired + 1 end)
    clock:advance(0.2)
    T.eq(fired, 0)
    clock:advance(0.2)
    clock:advance(0.2)
    T.eq(fired, 1)
    clock:advance(0.2)
    clock:advance(0.2)
    T.eq(fired, 1)
    T.eq(clock.ui:next_due(), nil)
end

function tests.every_holds_its_average_rate_under_jitter(T)
    local clock = Clock.new()
    local fired = 0
    clock.ui:every(1/60, function() fired = fired + 1 end)
    -- Frames that alternate slightly early and slightly late.
    for i=1, 300 do
        clock:advance(1/60 - 0.0005)
        clock:advance(1/60 + 0.0005)
    end
    T.ok(fired >= 598 and fired <= 600, "fired " .. fired)
end

function tests.every_does_not_burst_after_a_stall(T)
    local clock = Clock.new({max_catchup = 0.25})
    local fired = 0
    clock.ui:every(0.01, function() fired = fired + 1 end)
    clock:advance(0.25)
    T.eq(fired, 1)
    clock:advance(0.001)
    T.eq(fired, 1)
    clock:advance(0.01)
    T.eq(fired, 2)
end

function tests.every_passes_elapsed_time(T)
    local clock = Clock.new()
    local total = 0
    clock.ui:every(0.1, function(elapsed) total = total + elapsed end)
    for i=1, 20 do clock:advance(0.05) end
    T.near(total, 1.0, 1e-6)
end

function tests.function_period_is_asked_after_every_fire(T)
    local clock = Clock.new()
    local periods = {0.1, 0.3, 0.2}
    local asked = 0
    local fired_at = {}
    clock.ui:every(function()
        asked = asked + 1
        return periods[asked] or 1000
    end, function() table.insert(fired_at, clock.ui.time) end)

    for i=1, 100 do clock:advance(0.01) end
    T.eq(#fired_at, 3)
    T.near(fired_at[1], 0.1, 1e-6)
    T.near(fired_at[2], 0.4, 1e-6)
    T.near(fired_at[3], 0.6, 1e-6)
end

function tests.cancel_inside_a_callback(T)
    local clock = Clock.new()
    local fired = 0
    local handle = nil
    handle = clock.ui:every(0.1, function()
        fired = fired + 1
        handle:cancel()
    end)
    for i=1, 10 do clock:advance(0.1) end
    T.eq(fired, 1)
    T.eq(#clock.ui.timers, 0)
end

function tests.scope_cancel_all(T)
    local clock = Clock.new()
    local scope = clock.ui:scope()
    local fired = 0
    local other = 0
    scope:every(0.1, function() fired = fired + 1 end)
    scope:after(0.1, function() fired = fired + 1 end)
    clock.ui:every(0.1, function() other = other + 1 end)

    scope:cancel_all()
    for i=1, 5 do clock:advance(0.1) end
    T.eq(fired, 0)
    T.eq(other, 5)
end

function tests.scope_cancel_all_from_its_own_timer(T)
    -- A screen's timer switches screens, and leaving cancels the scope.
    local clock = Clock.new()
    local scope = clock.ui:scope()
    local fired = 0
    scope:every(0.1, function()
        fired = fired + 1
        scope:cancel_all()
    end)
    scope:every(0.1, function() fired = fired + 100 end)
    for i=1, 5 do clock:advance(0.1) end
    T.eq(fired, 1)
end

function tests.scope_suspend_and_resume_keep_remaining_time(T)
    local clock = Clock.new()
    local scope = clock.ui:scope()
    local fired = 0
    scope:after(1.0, function() fired = fired + 1 end)

    clock:advance(0.25)
    clock:advance(0.25)
    clock:advance(0.1)
    scope:suspend()
    T.eq(clock.ui:next_due(), nil)
    for i=1, 40 do clock:advance(0.25) end
    T.eq(fired, 0)

    scope:resume()
    clock:advance(0.25)
    T.eq(fired, 0)
    clock:advance(0.25)
    T.eq(fired, 1)
end

function tests.timers_added_to_a_suspended_scope_wait(T)
    local clock = Clock.new()
    local scope = clock.ui:scope()
    scope:suspend()
    local fired = 0
    scope:after(0.1, function() fired = fired + 1 end)
    clock:advance(0.2)
    T.eq(fired, 0)
    scope:resume()
    clock:advance(0.2)
    T.eq(fired, 1)
end

function tests.idle_sim_fast_forwards_without_stepping(T)
    local clock, steps = _counting_clock({step = 0.1})
    clock:set_sim_active(function() return false end)
    for i=1, 10 do clock:advance(0.1) end
    T.eq(steps.count, 0)
    T.near(clock.sim.time, 1.0)
end

function tests.idle_fast_forward_stops_at_a_timer_that_wakes_the_sim(T)
    local clock, steps = _counting_clock({step = 0.01, max_steps = 1000})
    local active = false
    local fired_at = nil
    clock:set_sim_active(function() return active end)
    clock.sim:after(0.1, function()
        fired_at = clock.sim.time
        active = true
    end)

    clock:advance(0.25)
    T.near(fired_at, 0.1)
    -- 25 steps of time passed; the first 10 were skipped, the rest were real.
    T.eq(steps.count, 15)
    T.near(clock.sim.time, 0.25)
end

function tests.next_wake(T)
    local clock = Clock.new({step = 0.1})
    T.eq(clock:next_wake(), nil)

    clock.ui:after(0.5, function() end)
    T.near(clock:next_wake(), 0.5)
    clock:advance(0.2)
    T.near(clock:next_wake(), 0.3)

    -- An active sim wants its next step.
    local active = true
    clock:on_step(function() end)
    clock:set_sim_active(function() return active end)
    clock:advance(0.03) -- accumulator is now 0.03 past the 0.2 step boundary
    T.near(clock:next_wake(), 0.07)

    -- Paused: only the ui timer counts.
    clock:set_paused(true)
    T.near(clock:next_wake(), 0.27)
    clock:set_paused(false)

    -- Idle sim: only its timers count.
    active = false
    T.near(clock:next_wake(), 0.27)
    clock.sim:after(0.1, function() end)
    T.near(clock:next_wake(), 0.07)
end

function tests.blink(T)
    local clock = Clock.new({blink_period = 0.5})
    T.eq(clock:blink_on(), true)
    clock:advance(0.25)
    clock:advance(0.2)
    T.eq(clock:blink_on(), true)
    clock:advance(0.1)
    T.eq(clock:blink_on(), false)

    clock:reset_blink()
    T.eq(clock:blink_on(), true)

    T.eq(clock:next_wake(), nil)
    clock:set_blink_needed(true)
    T.near(clock:next_wake(), 0.5)
    clock:advance(0.2)
    T.near(clock:next_wake(), 0.3)
end

return tests
