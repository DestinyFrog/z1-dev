
---@class Z13
---@field atoms table[]
Z13 = {}

---construct new z13
---@return Z13
function Z13:new()
    local obj = {
        atoms = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

---add new atom to z13
---@param color string
---@param radius number
---@param x number
---@param y number
---@param z number
function Z13:add(color, radius, x, y, z)
    local atom = {
        color = color,
        radius = radius,
        x = x,
        y = y,
        z = z
    }

    table.insert(self.atoms, atom)
end

function Z13:build(width, height, depth)
    local content = string.format("%.2f %.2f %.2f", width, height, depth)
    for _, atom in ipairs(self.atoms) do
        content = string.format("%s\n%s %.2f %.2f %.2f %.2f", content, atom.color, atom.radius, atom.x, atom.y, atom.z)
    end
    return content
end