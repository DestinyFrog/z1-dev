---@class Vector
---@field x number
---@field y number
Vector2 = {}

---construct Vector2 object
---@param x number
---@param y number
---@param atom Atom
function Vector2:new(x, y, atom)
    local obj = { x = x, y = y, atom = atom }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

