local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local inspect = {Options = {}, }

















inspect._VERSION = 'inspect.lua 3.1.0'
inspect._URL = 'http://github.com/kikito/inspect.lua'
inspect._DESCRIPTION = 'human-readable representations of tables'
inspect._LICENSE = [[
  MIT LICENSE

  Copyright (c) 2022 Enrique García Cota

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
inspect.KEY = setmetatable({}, { __tostring = function() return 'inspect.KEY' end })
inspect.METATABLE = setmetatable({}, { __tostring = function() return 'inspect.METATABLE' end })

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

local function rawpairs(t)
   return next, t, nil
end



local function smartQuote(str)
   if match(str, '"') and not match(str, "'") then
      return "'" .. str .. "'"
   end
   return '"' .. gsub(str, '"', '\\"') .. '"'
end


local shortControlCharEscapes = {
   ["\a"] = "\\a", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r", ["\t"] = "\\t", ["\v"] = "\\v", ["\127"] = "\\127",
}
local longControlCharEscapes = { ["\127"] = "\127" }
for i = 0, 31 do
   local ch = char(i)
   if not shortControlCharEscapes[ch] then
      shortControlCharEscapes[ch] = "\\" .. i
      longControlCharEscapes[ch] = fmt("\\%03d", i)
   end
end

local function escape(str)
   return (gsub(gsub(gsub(str, "\\", "\\\\"),
   "(%c)%f[0-9]", longControlCharEscapes),
   "%c", shortControlCharEscapes))
end

local function isIdentifier(str)
   return type(str) == "string" and not not str:match("^[_%a][_%a%d]*$")
end

local flr = math.floor
local function isSequenceKey(k, sequenceLength)
   return type(k) == "number" and
   flr(k) == k and
   1 <= (k) and
   k <= sequenceLength
end

local defaultTypeOrders = {
   ['number'] = 1, ['boolean'] = 2, ['string'] = 3, ['table'] = 4,
   ['function'] = 5, ['userdata'] = 6, ['thread'] = 7,
}

local function sortKeys(a, b)
   local ta, tb = type(a), type(b)


   if ta == tb and (ta == 'string' or ta == 'number') then
      return (a) < (b)
   end

   local dta = defaultTypeOrders[ta] or 100
   local dtb = defaultTypeOrders[tb] or 100


   return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t)

   local seqLen = 1
   while rawget(t, seqLen) ~= nil do
      seqLen = seqLen + 1
   end
   seqLen = seqLen - 1

   local keys, keysLen = {}, 0
   for k in rawpairs(t) do
      if not isSequenceKey(k, seqLen) then
         keysLen = keysLen + 1
         keys[keysLen] = k
      end
   end
   table.sort(keys, sortKeys)
   return keys, keysLen, seqLen
end

local function countRefs(x, refs)
   if type(x) == "table" then
      if not refs[x] then
         refs[x] = 1
         for k, v in rawpairs(x) do
            countRefs(k, refs)
            countRefs(v, refs)
         end
         countRefs(getmetatable(x), refs)
      else
         refs[x] = refs[x] + 1
      end
   end
end

local function makePath(path, a, b)
   local newPath = {}
   local len = #path
   for i = 1, len do newPath[i] = path[i] end

   newPath[len + 1] = a
   newPath[len + 2] = b

   return newPath
end


local function processRecursive(process,
   item,
   path,
   visited)
   if item == nil then return nil end
   if visited[item] then return visited[item] end

   local processed = process(item, path)
   if type(processed) == "table" then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey

      for k, v in rawpairs(processed) do
         processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
         if processedKey ~= nil then
            processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
         end
      end

      local mt = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end
      setmetatable(processedCopy, mt)
      processed = processedCopy
   end
   return processed
end





local Inspector = {}









local Inspector_mt = { __index = Inspector }

function Inspector:tabify()
   self.puts(self.newline .. rep(self.indent, self.level))
end

function Inspector:getId(v)
   local id = self.ids[v]
   local ids = self.ids
   if not id then
      local tv = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return tostring(id)
end

function Inspector:putValue(v)
   local puts = self.puts
   local tv = type(v)
   if tv == 'string' then
      puts(smartQuote(escape(v)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
      tv == 'cdata' or tv == 'ctype' then
      puts(tostring(v))
   elseif tv == 'table' and not self.ids[v] then
      local t = v

      if t == inspect.KEY or t == inspect.METATABLE then
         puts(tostring(t))
      elseif self.level >= self.depth then
         puts('{...}')
      else
         if self.refs[t] > 1 then puts(fmt('<%d>', self:getId(t))) end

         local keys, keysLen, seqLen = getKeys(t)

         puts('{')
         self.level = self.level + 1

         for i = 1, seqLen + keysLen do
            if i > 1 then puts(',') end
            if i <= seqLen then
               puts(' ')
               self:putValue(t[i])
            else
               local k = keys[i - seqLen]
               self:tabify()
               if isIdentifier(k) then
                  puts(k)
               else
                  puts("[")
                  self:putValue(k)
                  puts("]")
               end
               puts(' = ')
               self:putValue(t[k])
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
            if seqLen + keysLen > 0 then puts(',') end
            self:tabify()
            puts('<metatable> = ')
            self:putValue(mt)
         end

         self.level = self.level - 1

         if keysLen > 0 or type(mt) == 'table' then
            self:tabify()
         elseif seqLen > 0 then
            puts(' ')
         end

         puts('}')
      end

   else
      puts(fmt('<%s %d>', tv, self:getId(v)))
   end
end




function inspect.inspect(root, options)
   options = options or {}

   local depth = options.depth or (math.huge)
   local newline = options.newline or '\n'
   local indent = options.indent or '  '
   local process = options.process

   if process then
      root = processRecursive(process, root, {}, {})
   end

   local refs = {}
   countRefs(root, refs)

   local buf = {}
   local blen = 0
   local puts = function(str)
      blen = blen + 1
      buf[blen] = str
   end

   local inspector = setmetatable({
      depth = depth,
      level = 0,
      puts = puts,
      ids = {},
      newline = newline,
      indent = indent,
      refs = refs,
   }, Inspector_mt)

   inspector:putValue(root)

   return table.concat(buf)
end

setmetatable(inspect, {
   __call = function(_, root, options)
      return inspect.inspect(root, options)
   end,
})

return inspect
