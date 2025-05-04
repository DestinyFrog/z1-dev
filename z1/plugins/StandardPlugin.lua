require "z1.plugins.Plugin"

STANDARD_ATOM_RADIUS = 9

StandardPlugin = {}

function StandardPlugin:new(h)
    local obj = StandardPlugin
    local p = Plugin:new(h)
    setmetatable(self, obj)
    self.__index = p
    return obj
end

function StandardPlugin:drawAtom()
    for _, atom in ipairs(self.atoms) do
        local symbol = atom["symbol"]
        local x = self.center_x + atom["x"]
        local y = self.center_y + atom["y"]

        if symbol == "X" then
            goto continue
        end

        self.svg:text(atom["symbol"], x, y)

        local charge = atom["charge"]

        if charge ~= 0 then
            if charge == 1 then
                charge = "+"
            end
            if charge == -1 then
                charge = "-"
            end
            self.svg:subtext(charge, x + STANDARD_ATOM_RADIUS, y - STANDARD_ATOM_RADIUS)
        end

        ::continue::
    end

    return nil
end

STANDARD_DISTANCE_BETWEEN_LIGATIONS = 20

STANDARD_WAVES = {
    { 0 },
    {STANDARD_DISTANCE_BETWEEN_LIGATIONS / 2, -STANDARD_DISTANCE_BETWEEN_LIGATIONS / 2},
    {STANDARD_DISTANCE_BETWEEN_LIGATIONS, 0, -STANDARD_DISTANCE_BETWEEN_LIGATIONS}
}

function StandardPlugin:drawLigation()
    for _, ligation in pairs(self.ligations) do
        local from_atom = ligation.from
        local to_atom = ligation.to

        if to_atom.symbol == "X" then
            goto continue
        end

        local ax = self.center_x + from_atom.x
        local ay = self.center_y + from_atom.y
        local bx = self.center_x + to_atom.x
        local by = self.center_y + to_atom.y

        local angles = STANDARD_WAVES[ligation.eletrons]

        local a_angle = math.atan((by - ay), (bx - ax))
        local b_angle = math.pi + a_angle

        if ligation.type ~= "iônica" then
            for _, angle in ipairs(angles) do
                local nax = ax + math.cos(a_angle - (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS
                local nay = ay + math.sin(a_angle - (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS

                local nbx = bx + math.cos(b_angle + (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS
                local nby = by + math.sin(b_angle + (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS

                self.svg:line(nax, nay, nbx, nby)
            end
        end

        ::continue::
    end

    return nil
end