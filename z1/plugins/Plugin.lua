require "z1.tools.Svg"
require "z1.Handling"

BORDER = 20
STANDARD_LIGATION_SIZE = 30

---@class Plugin
---@field svg Svg
---@field tags string[]
---@field atoms Atom[]
---@field ligations Ligation[]
Plugin = {
    svg = Svg:new()
}

---constroi um novo Plugin padrao
---@param o Handling
---@return Plugin
function Plugin:new(o)
    local obj = {
        tags = o.tags,
        atoms = o.atoms,
        ligations = o.ligations
    }

    setmetatable(obj, self)
    self.__index = self
    return obj
end

---build the svg
---@return string?, Error?
function Plugin:build()
    self:calcAtomsPosition()

    local err = self:measureBounds()
    if err ~= nil then return nil, err end

    err = self:drawAtom()
    if err ~= nil then return nil, err end

    err = self:drawLigation()
    if err ~= nil then return nil, err end

    local svg_content, e = self.svg:build(self.width, self.height)
    return svg_content, e
end

---calcula posiçao dos atomos
---@param atom Atom?
---@param dad_atom Atom?
---@param ligation Ligation?
---@param order number
function Plugin:calcAtomsPosition(atom, dad_atom, ligation, order)
    if atom == nil then atom = self.atoms[1] end
    if atom.already == true then return end

    if ligation and dad_atom then
        if not ligation.angle then
            local default_dad_ligation = atom.parent_ligation and atom.parent_ligation.angle or 0
            local antipodal_pai = default_dad_ligation + 180
            local angulo_fatia = 360 / atom.ligation_num
            local angulo = antipodal_pai + angulo_fatia * (order + (atom.parent_ligation and 1 or 0))
            ligation.angle = math.floor(angulo % 360)
        end
    end

    local x = 0
    local y = 0
    if dad_atom ~= nil and ligation then
        local angle_rad = math.pi * ligation.angle / 180
        x = dad_atom.x + math.cos(angle_rad) * STANDARD_LIGATION_SIZE
        y = dad_atom.y + math.sin(angle_rad) * STANDARD_LIGATION_SIZE
    end

    atom.x = x
    atom.y = y
    atom.already = true

    for idx, lig in ipairs(atom.ligations) do
        self:calcAtomsPosition(lig.to, atom, lig, idx)
    end
end

---draw the atoms
---@return Error?
function Plugin:drawAtom()
    return Error:new("Method drawAtom not Implemented")
end

---draw the ligations
---@return Error?
function Plugin:drawLigation()
    return Error:new("Method drawLigation not Implemented")
end

function Plugin:measureBounds()
    local min_x = 0
    local min_y = 0
    local max_x = 0
    local max_y = 0

    for _, atom in ipairs(self.atoms) do
        local x = atom["x"]
        local y = atom["y"]

        if atom["symbol"] == "X" then
            goto continue
        end

        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end

        ::continue::
    end

    local cwidth = max_x + -min_x
    local cheight = max_y + -min_y

    self.width = BORDER * 2 + cwidth
    self.height = BORDER * 2 + cheight

    self.center_x = BORDER + math.abs(min_x)
    self.center_y = BORDER + math.abs(min_y)

    return nil
end