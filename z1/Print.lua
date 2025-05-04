require "os"
require "z1.Handling"

---@type string
local file_name = arg[2]

local f = io.open(file_name, "r")
if not f then
    Error:new("File not found"):print()
    os.exit(1)
end
local content = f:read("*a")
f:close()

local handling = Handling:new()
local error = handling:handle_sections(content)
if error then
    error:print()
    os.exit(1)
end

---@type string
local plugin_name = arg[1]

local plugin = nil

if plugin_name == "standard" then
    require "z1.plugins.StandardPlugin"
    plugin = StandardPlugin:new(handling)
elseif plugin_name == "z13" then
    require "z1.plugins.Z13Plugin"
    plugin = Z13Plugin:new(handling)
end

if plugin == nil then
    Error:new("Plugin not found"):print()
    os.exit(1)
end

local svg_content, err = plugin:build()
if err ~= nil then err:print() end

print(svg_content)