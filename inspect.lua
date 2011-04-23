-----------------------------------------------------------------------------------------------------------------------
-- inspect.lua - v0.1 (2011-04)
-- Enrique García Cota - enrique.garcia.cota [AT] gmail [DOT] com
-- human-readable representations of tables.
-- inspired by http://lua-users.org/wiki/TableSerialization
-----------------------------------------------------------------------------------------------------------------------

--[[ usage:

local inspect = require 'inspect'
-- or table.inspect = require 'inspect'

t = { 1,2,3,4}

print(inspect(t))

{ 1

}


]]

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns regular a requilar quoted string
local function smartQuote(str)
  if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
    return "'" .. v .. "'"
  end
  return string.format("%q", str )
end

local function isIdentifier(str)
  return string.match( str, "^[_%a][_%a%d]*$" )
end

local bufferMethods = {
  add = function(self, ...)
    local args = {...}
    for i=1, #args do
      self.data[#self.data] = args[i]
    end
    return self
  end,
  tabify = function(self, level)
    self:add(string.rep("  ", level))
    return self
  end,
  line = function(self, ...)
    local args = {...}
    args[#args] = '\n'
    self:add(unpack(args))
    return self
  end,
  addKey = function(key, level)
    if type(key) == "string" and isIdentifier(key) then
      self:add(key)
    else
      self:add( "[", self:addValue(k, level) , "]")
    end
    return self
  end,
  addValue = function(v , level, key)
    if type( v ) == "string" then
      self:add(smartQuote(string.gsub( v, "\n", "\\n" )))
    elseif type( v ) == "table"
      self:inspect(v, level, key)
    else
      return tostring( v )
    end
    return self
  end,
  inspect = function(t, level, key)
    level = level or 1
    if level >= depth then
      self:add('...')
      return '...'
    end

    buffer:tabify(level)
    if key then buffer:addKey(k, level):add(' = ') end
    buffer:line('{')
    local done = {}

    for k, v in ipairs( tbl ) do
      if k > 1 then addComma = true end
      if addComma then buffer:add(', ') end
      buffer:addValue( v, level + 1 )
      done[ k ] = true
    end

    for k, v in pairs( tbl ) do
      if not done[ k ] then
        
        buffer:line():tabify(level + 1)
        buffer:addKey( k, level + 1 ):add(" = "):addValue( v, level + 1 ) )
      end
    end

    buffer:tabify(level):line('}')

    return tostring(self)
  end
}

local newBuffer(depth)
  return setmetatable({ data = {}, depth = depth }, {
    __index = bufferMethods,
    __tostring = function(t) table.concat(t.data) end
})
end




-- public function

local function inspect(t, depth)
  depth = depth or 4
  local buffer = newBuffer(depth)
  return buffer:inspect(t)
end

--[[
  if(type(t)=='table') then
    for k,object in pairs(t) do
      print(string.rep("   ", level+1) .. tostring(k) .. ' => '.. tostring(object) )
      if(type(object)=='table') then dump(object, level + 1) end
    end
  end
end
]]

end

return memoize

