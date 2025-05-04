require "z1.plugins.Plugin"
require "z1.tools.z13"

---@class Z13Plugin
---@field z13 Z13
Z13Plugin = {}

---construct Z13 plugin
---@param h Handling
---@return Z13Plugin
function Z13Plugin:new(h)
    local obj = {
        z13 = Z13:new(),
        atoms = h.atoms
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Z13Plugin:measureBounds()
    local min_x = 0
    local min_y = 0
    local min_z = 0
    local max_x = 0
    local max_y = 0
    local max_z = 0

    for _, atom in ipairs(self.atoms) do
        local x = atom["x"]
        local y = atom["y"]
        local z = atom["z"]

        if atom["symbol"] == "X" then
            goto continue
        end

        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
        if z > max_z then max_z = z end
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end
        if z < min_z then min_z = z end

        ::continue::
    end

    self.width = max_x + math.abs(min_x)
    self.height = max_y + math.abs(min_y)
    self.depth = max_z + math.abs(min_z)

    self.center_x = min_x + self.width/2
    self.center_y = min_y + self.height/2
    self.center_z = min_z + self.depth/2

    return nil
end

---calcula posiçao dos atomos
---@param atom Atom?
---@param dad_atom Atom?
---@param ligation Ligation?
function Z13Plugin:calcAtomsPosition(atom, dad_atom, ligation, order)
    if atom == nil then atom = self.atoms[1] end
    if atom.already == true then return end

    local x = 0
    local y = 0
    local z = 0

    if dad_atom ~= nil and ligation ~= nil then
        local radius = atom.atomic_radius + dad_atom.atomic_radius
        if ligation.type == "iônica" then
            radius = radius + 60
        else
            radius = radius - 20
        end

        if ligation and dad_atom then
            if not ligation.angle then
                local default_dad_ligation = atom.parent_ligation and atom.parent_ligation.angle or 0
                local antipodal_pai = default_dad_ligation
                local angulo_fatia = 360 / dad_atom.ligation_num
                local angulo = antipodal_pai + angulo_fatia * (order -1 + (atom.parent_ligation and 1 or 0))
                ligation.angle = math.floor(angulo % 360)
            end
        end

        if not ligation.angle3d then
            ligation.angle3d = {(ligation.angle or 0)+90, 90}
        end

        local angle_theta_rad = math.pi * ligation.angle3d[1] / 180
        local angle_phi_rad = math.pi * ligation.angle3d[2] / 180

        x = dad_atom.x + radius * math.sin(angle_theta_rad) * math.cos(angle_phi_rad)
        y = dad_atom.y + radius * math.cos(angle_theta_rad)
        z = dad_atom.z + radius * math.sin(angle_theta_rad) * math.sin(angle_phi_rad)
    end

    atom.x = math.floor(x)
    atom.y = math.floor(y)
    atom.z = math.floor(z)
    atom.already = true

    for idx, lig in ipairs(atom.ligations) do
        self:calcAtomsPosition(lig.to, atom, lig, idx)
    end
end

function Z13Plugin:drawAtom()
    for _, atom in ipairs(self.atoms) do
        if atom.symbol == "X" then
            goto continue
        end

        self.z13:add(atom.color, atom.atomic_radius,
            atom.x - self.center_x,
            atom.y - self.center_y,
            atom.z - self.center_z
        )
        ::continue::
    end
    return nil
end

---build the z13
---@return string?, Error?
function Z13Plugin:build()
    self:calcAtomsPosition()
    self:measureBounds()

    local err = self:drawAtom()
    if err ~= nil then return nil, err end

    local z13_content, e = self.z13:build(self.width, self.height, self.depth)
    return z13_content, e
end