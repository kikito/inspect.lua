-----------------------------------------------------------------------------------------------------------------------
-- inspect.lua - v0.1 (2011-04)
-- Enrique García Cota - enrique.garcia.cota [AT] gmail [DOT] com
-- human-readable representations of tables.
-- inspired by http://lua-users.org/wiki/TableSerialization
-----------------------------------------------------------------------------------------------------------------------

-- public function

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns regular a requilar quoted string
local function smartQuote(str)
  if string.match( string.gsub(str,"[^'\"]",""), '^"+$' ) then
    return "'" .. str .. "'"
  end
  return string.format("%q", str )
end

local unescapedChars = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f",  ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v",  ["\\"] = "\\\\"
}

local function unescapeChar(c)
  return unescapedChars[c]
end

local function unescape(str)
  return string.gsub( str, "(%c)", unescapeChar )
end


local Buffer = {}

function Buffer:new()
  return setmetatable( { data = {} }, { 
    __index = Buffer,
    __tostring = function(instance) return table.concat(instance.data) end
  } )
end

function Buffer:add(...)
  local args = {...}
  for i=1, #args do
    table.insert(self.data, tostring(args[i]))
  end
  return self
end

function Buffer:addValue(v)
  local tv = type(v)
  
  if tv == 'string' then
    self:add(smartQuote(unescape(v)))
  elseif tv == 'number' or tv == 'boolean' then
    self:add(tostring(v))
  elseif tv == 'table' then
    self:add('{')
    for i=1, #v do
      if i > 1 then self:add(', ') end
      self:addValue(v[i])
    end
    self:add('}')
  else
    self:add('<',tv,'>')
  end

  return self
end

local function inspect(t)
  return tostring(Buffer:new():addValue(t))
end

return inspect

