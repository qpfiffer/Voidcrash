local Stack = {}
Stack.__index = Stack

function Stack:init()
    local this = {
        t = {}
    }
    setmetatable(this, self)

    return this
end

function Stack:peek()
    return self.t[#self.t + 1]
end

function Stack:push(item)
    table.insert(self.t, item)
    return item
end

function Stack:pop()
    if #self.t <= 0 then
        return nil
    end

    local item = self.peek()
    table.remove(self.t, #self.t)

    return item
end

function Stack:map(f)
    local results = {}
    for i=1, #self.t do
        results[i] = f(self.t[i])
    end

    return results
end

return Stack
