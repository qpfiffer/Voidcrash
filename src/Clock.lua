-- The one place time enters the game. Nothing else should accumulate dt.
--
-- A Clock owns two timelines:
--   clock.ui   wall time, never paused. Blinking, typewriters, transitions.
--   clock.sim  game time, advances in fixed steps, frozen while paused.
--              sim.time is always steps * step, so it never drifts.
--
-- Pure Lua on purpose (no love.*) so it can be tested with plain luajit.
local Clock = {}
Clock.__index = Clock

local Timeline = {}
Timeline.__index = Timeline

local Scope = {}
Scope.__index = Scope

local Timer = {}
Timer.__index = Timer

local EPSILON = 1e-9

----------------------------------------------------------------------------
-- Timer

function Timer:cancel()
    self.cancelled = true
end

function Timer:is_active()
    return not self.cancelled
end

local function _period_of(timer)
    if type(timer.period) == "function" then
        return timer.period()
    end
    return timer.period
end

----------------------------------------------------------------------------
-- Timeline

local function _new_timeline(stats)
    local this = {
        time = 0,
        timers = {},
        stats = stats,
    }
    return setmetatable(this, Timeline)
end

function Timeline:_add(delay, period, fn)
    local timer = {
        due = self.time + delay,
        last_fired = self.time,
        period = period, -- nil for one-shots, a number, or a function returning seconds
        fn = fn,
        cancelled = false,
        suspended = false,
    }
    setmetatable(timer, Timer)
    table.insert(self.timers, timer)
    return timer
end

-- Calls fn(elapsed) once, `seconds` from now.
function Timeline:after(seconds, fn)
    return self:_add(seconds, nil, fn)
end

-- Calls fn(elapsed) every `period` seconds. `period` may be a function, which is
-- asked for a fresh value after every fire (randomised cadences).
function Timeline:every(period, fn)
    local timer = self:_add(0, period, fn)
    timer.due = self.time + _period_of(timer)
    return timer
end

function Timeline:scope()
    return setmetatable({timeline = self, timers = {}, suspended = false}, Scope)
end

-- When the next live timer is due (absolute timeline time), or nil.
function Timeline:next_due()
    local soonest = nil
    for i=1, #self.timers do
        local timer = self.timers[i]
        if not timer.cancelled and not timer.suspended then
            if not soonest or timer.due < soonest then
                soonest = timer.due
            end
        end
    end
    return soonest
end

-- Fires everything that is due. A repeating timer fires at most once per call:
-- animations should drop beats after a stall, not burst to catch up.
function Timeline:_fire_due()
    local now = self.time
    local count = #self.timers -- Timers added by callbacks wait for the next call.
    local any_dead = false

    for i=1, count do
        local timer = self.timers[i]
        if not timer.cancelled and not timer.suspended and timer.due <= now + EPSILON then
            local elapsed = now - timer.last_fired
            timer.last_fired = now

            if timer.period then
                -- Stay on the ideal grid so the average rate holds under frame
                -- jitter (a beat that's slightly late is made up next advance),
                -- but after a real stall just start over from now.
                local period = _period_of(timer)
                timer.due = timer.due + period
                if timer.due < now - period then
                    timer.due = now + period
                end
            else
                timer.cancelled = true
            end

            self.stats.fires = self.stats.fires + 1
            timer.fn(elapsed, timer)
        end
        any_dead = any_dead or timer.cancelled
    end

    if any_dead then
        local live = {}
        for i=1, #self.timers do
            if not self.timers[i].cancelled then
                table.insert(live, self.timers[i])
            end
        end
        self.timers = live
    end
end

----------------------------------------------------------------------------
-- Scope: a bag of timers that live and die together (one per screen/widget).

function Scope:_track(timer)
    if self.suspended then
        timer.suspended = true
        timer.remaining = timer.due - self.timeline.time
    end
    table.insert(self.timers, timer)
    return timer
end

function Scope:after(seconds, fn)
    return self:_track(self.timeline:after(seconds, fn))
end

function Scope:every(period, fn)
    return self:_track(self.timeline:every(period, fn))
end

function Scope:cancel_all()
    for i=1, #self.timers do
        self.timers[i]:cancel()
    end
    self.timers = {}
end

-- Freezes every timer in the scope, remembering how long each had left.
function Scope:suspend()
    if self.suspended then
        return
    end

    self.suspended = true
    local live = {}
    for i=1, #self.timers do
        local timer = self.timers[i]
        if not timer.cancelled then
            timer.suspended = true
            timer.remaining = timer.due - self.timeline.time
            table.insert(live, timer)
        end
    end
    self.timers = live
end

function Scope:resume()
    if not self.suspended then
        return
    end

    self.suspended = false
    for i=1, #self.timers do
        local timer = self.timers[i]
        timer.suspended = false
        timer.due = self.timeline.time + math.max(timer.remaining or 0, 0)
        timer.last_fired = self.timeline.time
        timer.remaining = nil
    end
end

----------------------------------------------------------------------------
-- Clock

-- opts: step (seconds per sim step), max_catchup (largest real dt accepted),
--       max_steps (most sim steps per advance), blink_period.
function Clock.new(opts)
    opts = opts or {}
    local stats = {steps = 0, fires = 0}
    local this = {
        step = opts.step or 1/60,
        max_catchup = opts.max_catchup or 0.25,
        max_steps = opts.max_steps or 8,
        blink_period = opts.blink_period or 1/3,

        ui = _new_timeline(stats),
        sim = _new_timeline(stats),
        stats = stats, -- Cumulative, for DebugStats.

        steps = 0,
        accumulator = 0,
        paused = false,

        step_fn = nil,
        sim_active_fn = nil,

        blink_epoch = 0,
        blink_needed = false,
    }
    return setmetatable(this, Clock)
end

-- fn(step_seconds) runs once per sim step. There is exactly one: the world.
function Clock:on_step(fn)
    self.step_fn = fn
end

-- fn() -> bool. While it returns false no steps are run; sim time is simply
-- advanced to wherever it should be (or to the next sim timer).
function Clock:set_sim_active(fn)
    self.sim_active_fn = fn
end

function Clock:_sim_is_active()
    if self.sim_active_fn then
        return self.sim_active_fn()
    end
    return self.step_fn ~= nil
end

function Clock:set_paused(paused)
    self.paused = paused and true or false
end

function Clock:is_paused()
    return self.paused
end

function Clock:_set_steps(steps)
    self.steps = steps
    self.sim.time = steps * self.step
end

function Clock:advance(real_dt)
    -- A huge dt is a stall (suspend, window drag), not time we want to simulate.
    local dt = math.min(math.max(real_dt, 0), self.max_catchup)

    self.ui.time = self.ui.time + dt
    self.ui:_fire_due()

    if self.paused then
        return
    end

    self.accumulator = self.accumulator + dt
    local pending = math.floor(self.accumulator / self.step + EPSILON)
    self.accumulator = math.max(self.accumulator - pending * self.step, 0)

    local stepped = 0
    while pending > 0 do
        if self:_sim_is_active() then
            if stepped >= self.max_steps then
                break -- Too far behind; drop the rest rather than spiral.
            end
            stepped = stepped + 1
            pending = pending - 1
            self:_set_steps(self.steps + 1)
            self.stats.steps = self.stats.steps + 1
            self.sim:_fire_due()
            if self.step_fn then
                self.step_fn(self.step)
            end
        else
            -- Nothing to simulate: jump straight to the next sim timer (it may
            -- wake the sim up), or to the end of this advance.
            local jump = pending
            local due = self.sim:next_due()
            if due then
                local steps_until_due = math.ceil((due - self.sim.time) / self.step - EPSILON)
                jump = math.min(pending, math.max(steps_until_due, 1))
            end
            pending = pending - jump
            self:_set_steps(self.steps + jump)
            self.sim:_fire_due()
        end
    end
end

-- Blink is a pure function of ui time, shared by every screen.
function Clock:blink_on()
    local phase = math.floor((self.ui.time - self.blink_epoch) / self.blink_period + EPSILON)
    return phase % 2 == 0
end

-- Restart the blink in its "on" phase (input feedback).
function Clock:reset_blink()
    self.blink_epoch = self.ui.time
end

-- Whether blink edges should wake the main loop (is a blinking thing on screen?).
function Clock:set_blink_needed(needed)
    self.blink_needed = needed and true or false
end

-- Seconds until something next needs advance() to be called, or nil if nothing
-- ever will without outside input.
function Clock:next_wake()
    local wake = nil
    local function consider(seconds)
        if seconds and (not wake or seconds < wake) then
            wake = seconds
        end
    end

    local ui_due = self.ui:next_due()
    if ui_due then
        consider(ui_due - self.ui.time)
    end

    if not self.paused then
        if self:_sim_is_active() then
            consider(self.step - self.accumulator)
        else
            local sim_due = self.sim:next_due()
            if sim_due then
                consider(sim_due - self.sim.time - self.accumulator)
            end
        end
    end

    if self.blink_needed then
        local since_epoch = self.ui.time - self.blink_epoch
        local next_edge = (math.floor(since_epoch / self.blink_period + EPSILON) + 1) * self.blink_period
        consider(next_edge - since_epoch)
    end

    if wake then
        return math.max(wake, 0)
    end
    return nil
end

return Clock
