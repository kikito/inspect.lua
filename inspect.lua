local inspect ={
  _VERSION = 'inspect.lua 1.2.2',
  _URL     = 'http://github.com/kikito/inspect.lua',
  _DESCRIPTION = 'human-readable representations of tables',
  _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
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
  local result, _ = string.gsub( str, "(%c)", unescapeChar )
  return result
end

local function isIdentifier(str)
  return type(str) == 'string' and str:match( "^[_%a][_%a%d]*$" )
end

local function isArrayKey(k, length)
  return type(k) == 'number' and 1 <= k and k <= length
end

local function isDictionaryKey(k, length)
  return not isArrayKey(k, length)
end

local sortOrdersByType = setmetatable({
  ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
},
{ __index = function (t, k)
  if not rawget(t, k) then
    return math.huge
  end
end })

local function sortKeys(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then return sortOrdersByType[ta] < sortOrdersByType[tb] end
  if ta == 'string' or ta == 'number' then return a < b end
  return false
end

local function getDictionaryKeys(t)
  local length = #t
  local keys = {}
  for k,_ in pairs(t) do
    if isDictionaryKey(k, length) then table.insert(keys, k) end
  end
  table.sort(keys, sortKeys)
  return keys
end

local function getToStringResultSafely(t, mt)
  local __tostring = type(mt) == 'table' and rawget(mt, '__tostring')
  local string, status
  if type(__tostring) == 'function' then
    status, string = pcall(__tostring, t)
    string = status and string or 'error: ' .. tostring(string)
  end
  return string
end

local inspectorMaxIdsMetaTable = {
  __index = function (t, k)
    if not rawget(t, k) then
      rawset(t, k, 0)
    end
    return 0
  end
}

local inspectorIdsMetaTable = {
  __index = function (t, k)
    local v = rawget(t, k)
    if not v then
      rawset(t, k, setmetatable({}, {__mode = "kv"}))
      v = rawget(t, k)
    end
    return v
  end
}

local Inspector = {}

function Inspector:new(t, depth)
  local inspector = {
    buffer = {},
    depth = depth,
    level = 0,
    maxIds = setmetatable({}, inspectorMaxIdsMetaTable),
    ids = setmetatable({}, inspectorIdsMetaTable),
    tableAppearances = setmetatable({}, {__mode = "k"})
  }

  setmetatable(inspector, {__index = Inspector})

  inspector:countTableAppearances(t)

  return inspector:putValue(t)
end

function Inspector:countTableAppearances(t)
  if type(t) == 'table' then
    if not self.tableAppearances[t] then
      self.tableAppearances[t] = 1
      for k,v in pairs(t) do
        self:countTableAppearances(k)
        self:countTableAppearances(v)
      end
      self:countTableAppearances(getmetatable(t))
    else
      self.tableAppearances[t] = self.tableAppearances[t] + 1
    end
  end
end

function Inspector:tabify()
  self:puts("\n", string.rep("  ", self.level))
  return self
end

function Inspector:up()
  self.level = self.level - 1
end

function Inspector:down()
  self.level = self.level + 1
end

function Inspector:puts(...)
  local args = {...}
  local len = #self.buffer
  for i=1, #args do
    len = len + 1
    self.buffer[len] = tostring(args[i])
  end
  return self
end

function Inspector:commaControl(comma)
  if comma then self:puts(',') end
  return true
end

function Inspector:putTable(t)
  if self:alreadyVisited(t) then
    self:puts('<table ', self:getId(t), '>')
  elseif self.depth and self.level >= self.depth then
    self:puts('{...}')
  else
    if self.tableAppearances[t] > 1 then
      self:puts('<',self:getId(t),'>')
    end
    self:puts('{')
    self:down()

      local length = #t
      local mt = getmetatable(t)

      local string = getToStringResultSafely(t, mt)
      if type(string) == 'string' and #string > 0 then
        self:puts(' -- ', unescape(string))
        if length >= 1 then self:tabify() end -- tabify the array values
      end

      local comma = false
      for i=1, length do
        comma = self:commaControl(comma)
        self:puts(' '):putValue(t[i])
      end

      local dictKeys = getDictionaryKeys(t)

      for _,k in ipairs(dictKeys) do
        comma = self:commaControl(comma)
        self:tabify():putKey(k):puts(' = '):putValue(t[k])
      end

      if mt then
        comma = self:commaControl(comma)
        self:tabify():puts('<metatable> = '):putValue(mt)
      end

    self:up()

    if #dictKeys > 0 or mt then -- dictionary table. Justify closing }
      self:tabify()
    elseif length > 0 then -- array tables have one extra space before closing }
      self:puts(' ')
    end
    self:puts('}')
  end
  return self
end

function Inspector:alreadyVisited(v)
  return self.ids[type(v)][v] ~= nil
end

function Inspector:getId(v)
  local tv = type(v)
  local id = self.ids[tv][v]
  if not id then
    id              = self.maxIds[tv] + 1
    self.maxIds[tv] = id
    self.ids[tv][v] = id
  end
  return id
end

function Inspector:putValue(v)
  local tv = type(v)

  if tv == 'string' then
    self:puts(smartQuote(unescape(v)))
  elseif tv == 'number' or tv == 'boolean' or tv == 'nil' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:putTable(v)
  else
    self:puts('<',tv,' ',self:getId(v),'>')
  end
  return self
end

function Inspector:putKey(k)
  if isIdentifier(k) then return self:puts(k) end
  return self:puts( "[" ):putValue(k):puts("]")
end

function Inspector:tostring()
  return table.concat(self.buffer)
end

setmetatable(inspect, { __call = function(_,t,depth)
  return Inspector:new(t, depth):tostring()
end })

return inspect

