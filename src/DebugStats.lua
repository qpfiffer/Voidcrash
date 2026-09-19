-- Per-second counters for measuring how busy the game is, plus a tiny input
-- script runner so a run can be driven without anyone at the keyboard.
--
--   VOIDCRASH_STATS=1            print a stats line every second (F3 toggles it)
--   VOIDCRASH_KEYS=return,space  press these keys in order ("-" waits a beat)
--   VOIDCRASH_KEY_INTERVAL=0.5   seconds between scripted keys
--   VOIDCRASH_EXIT_AFTER=10      quit after this many seconds
local DebugStats = {}

local enabled = os.getenv("VOIDCRASH_STATS") == "1"
local exit_after = tonumber(os.getenv("VOIDCRASH_EXIT_AFTER") or "")
local key_interval = tonumber(os.getenv("VOIDCRASH_KEY_INTERVAL") or "") or 0.5

local scripted_keys = {}
for key in (os.getenv("VOIDCRASH_KEYS") or ""):gmatch("[^,]+") do
    table.insert(scripted_keys, key)
end

local counters = {}
local counter_names = {}

local started_at = nil
local last_report_at = nil
local last_report_cpu = nil
local next_key_at = nil
local next_key_idx = 1

function DebugStats.is_enabled()
    return enabled
end

function DebugStats.toggle()
    enabled = not enabled
end

function DebugStats.count(name, n)
    if not enabled then
        return
    end

    if not counters[name] then
        counters[name] = 0
        table.insert(counter_names, name)
        table.sort(counter_names)
    end
    counters[name] = counters[name] + (n or 1)
end

-- Seconds until this module next needs the main loop to be awake, or nil.
function DebugStats.next_wake(now)
    local wake = nil
    if enabled and last_report_at then
        wake = last_report_at + 1 - now
    end
    if next_key_at and next_key_idx <= #scripted_keys then
        wake = math.min(wake or math.huge, next_key_at - now)
    end
    if exit_after and started_at then
        wake = math.min(wake or math.huge, started_at + exit_after - now)
    end

    if wake then
        return math.max(wake, 0)
    end
    return nil
end

local function _report(now)
    local elapsed = now - last_report_at
    local cpu = os.clock()

    local parts = {}
    for i=1, #counter_names do
        local name = counter_names[i]
        table.insert(parts, name .. "=" .. string.format("%.1f", counters[name] / elapsed))
        counters[name] = 0
    end
    table.insert(parts, string.format("cpu=%.1f%%", 100 * (cpu - last_report_cpu) / elapsed))
    table.insert(parts, string.format("heap=%dKB", collectgarbage("count")))
    print("stats: " .. table.concat(parts, " "))

    last_report_at = now
    last_report_cpu = cpu
end

-- Call once per main loop iteration.
function DebugStats.tick()
    local now = love.timer.getTime()
    if not started_at then
        started_at = now
        last_report_at = now
        last_report_cpu = os.clock()
        next_key_at = now + 1
    end

    DebugStats.count("loop")

    if next_key_idx <= #scripted_keys and now >= next_key_at then
        local key = scripted_keys[next_key_idx]
        next_key_idx = next_key_idx + 1
        next_key_at = now + key_interval
        if key ~= "-" then
            love.event.push("keypressed", key, key, false)
            love.event.push("keyreleased", key, key)
        end
    end

    if enabled and now - last_report_at >= 1 then
        _report(now)
    end

    if exit_after and now - started_at >= exit_after then
        love.event.quit()
    end
end

return DebugStats
