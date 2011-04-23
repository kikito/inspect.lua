-----------------------------------------------------------------------------------------------------------------------
-- inspect.lua - v0.1 (2011-04)
-- Enrique García Cota - enrique.garcia.cota [AT] gmail [DOT] com
-- human-readable representations of tables.
-- inspired by http://lua-users.org/wiki/TableSerialization
-----------------------------------------------------------------------------------------------------------------------

-- public function

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
  if tv == 'table' then
    self:add('{')
    for i=1, #v do
      if i > 1 then self:add(', ') end
      self:addValue(v[i])
    end
    self:add('}')
  else
    self:add(tostring(v))
  end
  return self
end

local function newBuffer()

end

local function inspect(t)
  return tostring(Buffer:new():addValue(t))
end

return inspect

