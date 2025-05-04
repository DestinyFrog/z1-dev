require "z1.types.Ligation"
require "z1.types.AtomsInfo"

---@class Atom
---@field symbol string
---@field charge number
---@field ligations Ligation[]
---@field atomic_radius number?
---@field atomic_number number?
---@field ligation_num number
---@field parent Atom?
---@field parent_ligation Ligation?
Atom = {
    last_id = 1
}

---Constructs a atom object
---@param symbol string
---@param charge number?
---@return Atom
function Atom:new(symbol, charge)
    Atom.last_id = Atom.last_id + 1

    local obj = {
        id = Atom.last_id,
        symbol = symbol,
        charge = charge or 0,
        ligations = {},
        ligation_num = 0,
        parent = nil,
        x = nil,
        y = nil,
    }

    local data = AtomsInfo:find(symbol)

    if data then
        for key, field in pairs(data) do
            obj[key] = field
        end
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

---add parent to atom
---@param parent_ligation Ligation
function Atom:set_parent(parent_ligation)
    self.parent = parent_ligation.from
    self.parent_ligation = parent_ligation
    self.ligation_num = self.ligation_num + 1
end

function Atom:add_ligation(ligation)
    table.insert(self.ligations, ligation)
    self.ligation_num = self.ligation_num + 1
end

function Atom:print()
    return "Atom {" ..
    "\n\tatomic number: " .. self.atomic_number ..
    "\n\tsymbol: " .. self.symbol ..
    "\n\tcharge: " .. self.charge ..
    "\n\tatomic radius: " .. self.atomic_radius ..
    "\n}"
end