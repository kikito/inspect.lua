-----------------------------------------------------------------------------------------------------------------------
-- inspect.lua - v0.1 (2011-04)
-- Enrique García Cota - enrique.garcia.cota [AT] gmail [DOT] com
-- human-readable representations of tables.
-- inspired by http://lua-users.org/wiki/TableSerialization
-----------------------------------------------------------------------------------------------------------------------

-- public function

local bufferMethods = {
  add = function(self, ...)
    local args = {...}
    for i=1, #args do
      table.insert(self.data, tostring(args[i]))
    end
    return self
  end
}

local function newBuffer()
  return setmetatable( { data = {} }, { 
    __index = bufferMethods,
    __tostring = function(self) return table.concat(self.data) end
  } )
end

local function inspect(t)
  local buffer = newBuffer()
  buffer:add('{')
  for i=1, #t do
    if i > 1 then buffer:add(', ') end
    buffer:add(tostring(t[i]))
  end
  buffer:add('}')
  return tostring(buffer)
end

return inspect

