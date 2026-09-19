-- A small entity-component-system.
--
--   Entities are integer ids (never reused). They have no behaviour and no type;
--   an entity "is" whatever components it currently has.
--   Components are plain data tables (or `true` for tags), stored per name.
--   Systems are functions that run every sim step over the entities matching a
--   query. A system whose query matches nothing doesn't run, and if none would
--   run the world is idle, which is what lets the game sleep.
--   Events decouple systems from whoever cares about what happened (the radio
--   log, the UI).
--
-- Pure Lua on purpose (no love.*) so it can be tested with plain luajit.
local World = {}
World.__index = World

function World.new()
    local this = {
        next_id = 1,
        entities = {},    -- id -> true
        components = {},  -- name -> {id -> data}
        dying = {},       -- id -> true; destroyed at the end of the step

        version = 0,      -- Bumped whenever any query's result could have changed.
        query_cache = {}, -- key -> {version, ids}

        systems = {},
        listeners = {},   -- event name -> {fn, ...}

        res = {},         -- Singletons: well-known entity ids and the like.
    }
    return setmetatable(this, World)
end

----------------------------------------------------------------------------
-- Entities and components

-- components: {Name = data, ...}
function World:spawn(components)
    local id = self.next_id
    self.next_id = id + 1
    self.entities[id] = true
    for name, data in pairs(components or {}) do
        self:add(id, name, data)
    end
    self.version = self.version + 1
    return id
end

-- Deferred: the entity stays fully usable until the end of the current step, so
-- systems never trip over something that vanished mid-iteration.
function World:destroy(id)
    if self.entities[id] then
        self.dying[id] = true
    end
end

function World:flush()
    if next(self.dying) == nil then
        return
    end

    for id in pairs(self.dying) do
        for _, store in pairs(self.components) do
            store[id] = nil
        end
        self.entities[id] = nil
    end
    self.dying = {}
    self.version = self.version + 1
end

function World:alive(id)
    return self.entities[id] == true and not self.dying[id]
end

-- `data` defaults to true, for tag components.
function World:add(id, name, data)
    assert(self.entities[id], "add: no such entity")
    local store = self.components[name]
    if not store then
        store = {}
        self.components[name] = store
    end

    if data == nil then
        data = true
    end
    if store[id] == nil then
        self.version = self.version + 1
    end
    store[id] = data
    return data
end

function World:remove(id, name)
    local store = self.components[name]
    if store and store[id] ~= nil then
        store[id] = nil
        self.version = self.version + 1
    end
end

function World:get(id, name)
    local store = self.components[name]
    return store and store[id]
end

function World:has(id, name)
    local store = self.components[name]
    return store ~= nil and store[id] ~= nil
end

----------------------------------------------------------------------------
-- Queries

-- Ids of every entity having all the named components, in ascending order (so
-- lists built from queries are stable). The returned array is a snapshot: treat
-- it as read-only, and if you add/remove components while walking it, re-check
-- has() on the entities you haven't reached yet.
function World:query(...)
    local key = table.concat({...}, "|")
    local cached = self.query_cache[key]
    if cached and cached.version == self.version then
        return cached.ids
    end

    local names = {...}
    local ids = {}
    local first = self.components[names[1]]
    if first then
        for id in pairs(first) do
            local matches = true
            for i=2, #names do
                if not self:has(id, names[i]) then
                    matches = false
                    break
                end
            end
            if matches then
                table.insert(ids, id)
            end
        end
    end
    table.sort(ids)

    self.query_cache[key] = {version = self.version, ids = ids}
    return ids
end

----------------------------------------------------------------------------
-- Systems

-- system: {name = "...", query = {"A", "B"}, step = function(world, ids, dt) end}
-- Systems run in the order they were added.
function World:add_system(system)
    assert(system.name and system.query and system.step, "a system needs a name, a query and a step")
    table.insert(self.systems, system)
end

function World:step(dt)
    for i=1, #self.systems do
        local system = self.systems[i]
        local ids = self:query(unpack(system.query))
        if #ids > 0 then
            system.step(self, ids, dt)
        end
    end
    self:flush()
end

-- Would step() do anything? If not, nobody needs to call it.
function World:has_active_systems()
    if next(self.dying) ~= nil then
        return true
    end

    for i=1, #self.systems do
        if #self:query(unpack(self.systems[i].query)) > 0 then
            return true
        end
    end
    return false
end

----------------------------------------------------------------------------
-- Events (synchronous)

function World:on(event, fn)
    local listeners = self.listeners[event]
    if not listeners then
        listeners = {}
        self.listeners[event] = listeners
    end
    table.insert(listeners, fn)
end

function World:emit(event, payload)
    local listeners = self.listeners[event]
    if not listeners then
        return
    end
    for i=1, #listeners do
        listeners[i](payload)
    end
end

return World
