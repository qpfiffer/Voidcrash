-- Headless test runner for the pure-Lua modules (nothing here may touch love.*).
-- Run from the repo root: luajit tests/run.lua [test_name ...]

local T = {}

local passed = 0
local failed = 0

function T.eq(got, want, msg)
    if got ~= want then
        error((msg or "eq") .. ": expected " .. tostring(want) .. ", got " .. tostring(got), 2)
    end
end

function T.near(got, want, eps, msg)
    if math.abs(got - want) > (eps or 1e-9) then
        error((msg or "near") .. ": expected ~" .. tostring(want) .. ", got " .. tostring(got), 2)
    end
end

function T.ok(val, msg)
    if not val then
        error(msg or "expected a truthy value", 2)
    end
end

function T.list_eq(got, want, msg)
    T.eq(#got, #want, (msg or "list_eq") .. " (length)")
    for i=1, #want do
        T.eq(got[i], want[i], (msg or "list_eq") .. " [" .. i .. "]")
    end
end

local function run_file(name)
    local cases = require("tests/" .. name)
    local names = {}
    for case_name in pairs(cases) do
        table.insert(names, case_name)
    end
    table.sort(names)

    for i=1, #names do
        local ok, err = xpcall(function() cases[names[i]](T) end, debug.traceback)
        if ok then
            passed = passed + 1
        else
            failed = failed + 1
            print("FAIL " .. name .. "." .. names[i] .. "\n  " .. tostring(err))
        end
    end
end

local files = {...}
if #files == 0 then
    files = require("tests/all")
end

for i=1, #files do
    run_file(files[i])
end

print(passed .. " passed, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
