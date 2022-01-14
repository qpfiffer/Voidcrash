local ObjectType = {
    BASE = 1,
    DEPLOYABLE = 2,   -- Can exist in the overworld
    DISPATCHABLE = 4, -- Can be "sent" from the ship. Dispatched.
    CARGOABLE = 8     -- Can be held in cargo.
}

-- All objects have a type, they work as tags for operations upon them:
-- As an example, a deployable object can be deployed. BASE operates as a
-- base-type, all objects are assumed to have the base type.

return ObjectType
