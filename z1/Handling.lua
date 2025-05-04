require "z1.tools.Error"
require "z1.tools.Functions"
require "z1.types.Atom"
require "z1.Config"

---@class Handling
---@field tags string[]
---@field atoms Atom[]
---@field ligations Ligation[]
Handling = {}

---constructs Handling object
---@return Handling
function Handling:new()
    local obj = {
        names = {},
        tags = {},
        atoms = {},
        ligations = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

--- Receives a line and split it into params
---@param line string
---@param separator string?
---@return string[]
function Handling:split_params(line, separator)
    local params = {}
    separator = separator or "%s"
    for param in line:gmatch("[^" .. separator .. "]+") do
        table.insert(params, param)
    end
    return params
end

--- Receives a line and remove comment
---@param line string
---@private
---@return string
function Handling:remove_comment(line)
    local comment_position = string.find(line, "%-%-")

    if comment_position then
        return line:sub(1, comment_position - 1)
    end
    return line
end

--- Receives a line (tag) and return tag
---@param line string
---@return (string|nil)
function Handling:handle_line_tag(line)
    local text = Match_remove_substr(line, "@tag%s.+", "@tag%s")
    if not text then return end
    table.insert(self.tags, text)
end

--- Receives a line and return a atom object
---@param line string
---@return Atom?, Error?
function Handling:handle_line_atom(line)
    local text = self:remove_comment(line)

    local symbol, end_symbol = Match_substr(text, "[A-Z][a-z]?")
    if not symbol then return nil, Error:new("symbol not found") end

    local charge_str, end_charge = Match_substr(text, "[+|-]%d")
    local charge = 0
    if charge_str then
        charge_str = charge_str:gsub("[+|-]", "")
        charge = tonumber(charge_str)
    end

    local atom = Atom:new(symbol, charge)
    table.insert(self.atoms, atom)

    local init_ligations = (end_charge and end_charge or end_symbol) + 1
    local ligations_str = line:sub(init_ligations)
    if not ligations_str then return end

    local my_Split_string = coroutine.wrap(Split_string)
    local ligation_key = my_Split_string(ligations_str)

    while ligation_key do
        if not self.ligations[ligation_key] then
            self.ligations[ligation_key] = Ligation:new()
        end

        if not self.ligations[ligation_key].from then
            self.ligations[ligation_key].from = atom
            atom:add_ligation(self.ligations[ligation_key])
        else
            self.ligations[ligation_key].to = atom
            atom:set_parent(self.ligations[ligation_key])
        end

        ligation_key = my_Split_string()
    end
end

---@param line string
---@return Error?
function Handling:handle_line_ligation(line)
    local ligation_tag = Match_substr(line, "%d+")

    local function str_to_type(p)
        if p == "c" then
            return "covalente"
        elseif p == 'd' then
            return "covalente dativa"
        elseif p == 'h' then
            return "hidrogênio"
        elseif p == 'i' then
            return "iônica"
        end
        return nil
    end

    local type_str = Match_substr(line, "[i|d|h|c];")
    local type = nil
    if type_str then
        type = str_to_type(type_str:gsub(";", ""))
    end

    local function str_to_eletron(p)
        if p == "-" then return 1
        elseif p == '=' then return 2
        elseif p == '%' then return 3 end
    end

    local eletrons_str = Match_substr(line, "[-|=|%%]")
    local eletrons = str_to_eletron(eletrons_str)

    local angle_str = Match_substr(line, "%d+°")
    local angle = nil
    if angle_str then
        local s = string.gsub(angle_str, "°", "")
        angle = tonumber(s)
    end

    local angle_3d_str = Match_substr(line, "%b[]")
    local angle_3d = nil
    if angle_3d_str then
        local angle_x_str, end_angle_x = Match_substr(angle_3d_str, "-?%d+")
        local angle_y_str = Match_substr(angle_3d_str, "-?%d+", end_angle_x+1)

        local angle_x = tonumber(angle_x_str)
        local angle_y = tonumber(angle_y_str)

        angle_3d = {angle_x, angle_y}
    end

    if not self.ligations[ligation_tag] then
        self.ligations[ligation_tag] = Ligation:new(type, eletrons, angle, angle_3d)
    else
        if type then self.ligations[ligation_tag].type = type end
        if eletrons then self.ligations[ligation_tag].eletrons = eletrons end
        if angle then self.ligations[ligation_tag].angle = angle end
        if angle_3d then self.ligations[ligation_tag].angle3d = angle_3d end
    end
    return nil
end

--- Receives a line and return a pattern object
---@param line string
---@return Error?
function Handling:handle_line_pattern(line)
    local pattern_name = Match_remove_substr(line, "@p%s[%a|_]+", "@p%s")

    local pattern = io.open(PATTERN_FOLDER .. pattern_name .. ".pre.z1", "r")
    if pattern == nil then
        return Error:new("Pattern '" .. pattern_name .. "' not found")
    end
    local pattern_content = pattern:read("*a")
    pattern:close()

    local params = self:split_params(line)

    local pattern_params = self:split_params(params[3], ",")
    for k, pattern_param in ipairs(pattern_params) do
        pattern_content = pattern_content:gsub("$" .. k, pattern_param)
    end

    return self:handle_sections(pattern_content)
end

function Handling:handle_line_name(line)
    local name = Match_remove_substr(line, "@name%s.+", "@name%s")
    table.insert(self.names, name)
end

--- Receives a text and return a table with tags, atoms and ligations
---@param text string
---@return Error?
function Handling:handle_sections(text)
    for line in text:gmatch("[^\n]+") do
        if string.find(line, "@name") then
            self:handle_line_name(line)
        elseif string.find(line, "@tag") then
            local tag = self:handle_line_tag(line)
            table.insert(self.tags, tag)
        elseif string.find(line, "@p ") then
            local error = self:handle_line_pattern(line)
            if error then return error end
        elseif string.find(line, "[A-Z][a-z]?%s[+|-0-9]?[%s%d+]*") then
            local atom, error = self:handle_line_atom(line)
            if error then return error end
        elseif string.find(line, "[%d+|@%a+][%s%d+°]?[%s@type-h|c|d|i]?[%s-|=|%%]?[%s%b[%d+%s%d+]]?") then
            local error = self:handle_line_ligation(line)
            if error then return error end
        end
    end

    return nil
end

function Handling:print()
    print("TAGS:")
    for _, tag in ipairs(self.tags) do
        print(tag)
    end

    print("\nATOMS:")
    for _, atom in ipairs(self.atoms) do
        print(atom.symbol)
        for k, l in ipairs(atom.ligations) do
            print("  " .. k .. " - " .. l.to.symbol)
        end
    end

    print("\nLIGATIONS:")
    for key, ligation in pairs(self.ligations) do
        print(ligation.angle)
        -- print(key .. " | " .. ligation.from.symbol .. " -> " .. ligation.to.symbol .. " | " .. ligation.angle)
    end
end