local UnitCommand = {}
UnitCommand.__index = UnitCommand

function UnitCommand:init(order_type, data)
    local this = {
        order_type = order_type,
        data = data
    }
    setmetatable(this, self)

    return this
end

function UnitCommand:get_type()
    return self.order_type
end

return UnitCommand
