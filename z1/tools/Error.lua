
---@class Error
---@field private message string
---@field line number?
Error = {}

---Constructs a error object
---@param message string
---@param line number?
---@return Error
function Error:new(message, line)
    local obj = {
        message = message,
        line = line
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

---Prints the error
function Error:print()
    if self.line then
        print(self.line .. ": " .. self.message)
    else
        print("Error: " .. self.message)
    end
end
