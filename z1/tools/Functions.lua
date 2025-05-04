
---matches a pattern in string
---@param text string
---@param pattern string
---@param from number?
---@return string?, number?
function Match_substr(text, pattern, from)
    local start_s, end_s = string.find(text, pattern, from)
    if not start_s then return nil end
    return string.sub(text, start_s, end_s), end_s
end

---matches a pattern in string
---@param text string
---@param pattern string
---@param remove string
---@param from number?
---@return string?, number?
function Match_remove_substr(text, pattern, remove, from)
    local value, end_s = Match_substr(text, pattern, from):gsub(remove, "")
    return value, end_s
end

function Split_string(txt, separator)
    for param in txt:gmatch("[^" .. (separator or "%s") .. "]+") do
        coroutine.yield(param)
    end
end

function Dump(o, c)
    if c == nil then c = 0 end

    if type(o) == 'table' then
        if o.print == nil then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. string.rep("\t",c) .. '\n['..k..'] = ' .. Dump(v, c+1) .. ','
       end
       return s .. '} '
    else
        return o:print():gsub("\n", "\n" .. string.rep("\t",c-1))
    end
    else
       return tostring(o)
    end
 end