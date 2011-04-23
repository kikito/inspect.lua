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

local controlCharsTranslation = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f",  ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v",  ["\\"] = "\\\\"
}

local function unescapeChar(c) return controlCharsTranslation[c] end

local function unescape(str)
  return string.gsub( str, "(%c)", unescapeChar )
end

local function isIdentifier(str)
  return string.match( str, "^[_%a][_%a%d]*$" )
end

local function isArrayKey(k, length)
  return type(k)=='number' and 1 <= k and k <= length
end

local function isDictionaryKey(k, length)
  return not isArrayKey(k, length)
end

local function isDictionary(t)
  local length = #t
  for k,_ in pairs(t) do
    if isDictionaryKey(k, length) then return true end
  end
  return false
end

local Inspector = {}

function Inspector:new()
  return setmetatable( { buffer = {} }, { 
    __index = Inspector,
    __tostring = function(instance) return table.concat(instance.buffer) end
  } )
end

function Inspector:puts(...)
  local args = {...}
  for i=1, #args do
    table.insert(self.buffer, tostring(args[i]))
  end
  return self
end

function Inspector:tabify(level)
  self:puts("\n", string.rep("  ", level))
  return self
end

function Inspector:addTable(t, level)
  self:puts('{')
  local length = #t
  local needsComma = false
  for i=1, length do
    if i > 1 then
      self:puts(', ')
      needsComma = true
    end
    self:addValue(t[i], level + 1)
  end

  for k,v in pairs(t) do
    if isDictionaryKey(k, length) then
      if needsComma then self:puts(',') end
      needsComma = true
      self:tabify(level+1):addKey(k):puts(' = '):addValue(v)
    end
  end
  
  if isDictionary(t) then self:tabify(level) end
  self:puts('}')
  return self
end

function Inspector:addValue(v, level)
  local tv = type(v)

  if tv == 'string' then
    self:puts(smartQuote(unescape(v)))
  elseif tv == 'number' or tv == 'boolean' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:addTable(v, level)
  else
    self:puts('<',tv,'>')
  end
  return self
end

function Inspector:addKey(k, level)
  if type(k) == "string" and isIdentifier(k) then
    return self:puts(k)
  end
  return self:puts( "[" ):addValue(k, level):puts("]")
end

local function inspect(t)
  return tostring(Inspector:new():addValue(t,0))
end

return inspect

